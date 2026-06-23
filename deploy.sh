#!/bin/bash
# ============================================
# 明日方舟干员助手 - 一键部署脚本
# 部署微调模型到 vLLM + OpenCode
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# 配置（可修改）
# ============================================
MODEL_PATH="${MODEL_PATH:-./models/Qwen/Qwen3-0___6B}"
LORA_PATH="${LORA_PATH:-./output/Qwen3_Arknights_LoRA_final}"
PORT="${PORT:-8000}"
MODEL_NAME="arknights-assistant"
VLLM_LOG="vllm.log"

# ============================================
# 步骤 1: 检查环境
# ============================================
print_info "检查环境..."

# 检查是否在项目目录
if [ ! -f "01-Qwen3-Arknights-LoRA.ipynb" ]; then
    print_error "请在项目根目录运行此脚本"
    exit 1
fi

# 检查模型路径
if [ ! -d "$MODEL_PATH" ]; then
    print_error "模型路径不存在: $MODEL_PATH"
    print_info "请先运行 Notebook 训练模型，或设置 MODEL_PATH 环境变量"
    exit 1
fi

# 检查 LoRA 路径
if [ ! -d "$LORA_PATH" ]; then
    print_error "LoRA 权重不存在: $LORA_PATH"
    print_info "请先运行 Notebook 训练模型，或设置 LORA_PATH 环境变量"
    exit 1
fi

# 检查 vLLM 是否安装
if ! command -v vllm &> /dev/null; then
    print_info "安装 vLLM..."
    pip install -q vllm -i https://mirrors.cloud.tencent.com/pypi/simple/
fi

print_success "环境检查通过"

# ============================================
# 步骤 2: 释放显存（如果有残留进程）
# ============================================
print_info "检查显存占用..."

# 检查是否有占用显存的进程
VRAM_USED=$(rocm-smi --showmeminfo vram 2>/dev/null | grep "VRAM Total Used" | awk '{print $6}' || echo "0")
VRAM_TOTAL=$(rocm-smi --showmeminfo vram 2>/dev/null | grep "VRAM Total Memory" | awk '{print $6}' || echo "1")

if [ -n "$VRAM_USED" ] && [ -n "$VRAM_TOTAL" ]; then
    VRAM_USED_GB=$(echo "scale=1; $VRAM_USED / 1073741824" | bc 2>/dev/null || echo "0")
    VRAM_TOTAL_GB=$(echo "scale=1; $VRAM_TOTAL / 1073741824" | bc 2>/dev/null || echo "0")
    print_info "显存使用: ${VRAM_USED_GB}GB / ${VRAM_TOTAL_GB}GB"
    
    # 如果显存占用超过 30GB，提示释放
    VRAM_USED_INT=$(echo "$VRAM_USED / 1073741824" | bc 2>/dev/null || echo "0")
    if [ "$VRAM_USED_INT" -gt 30 ]; then
        print_warning "显存占用较高，尝试释放..."
        pkill -9 -f "ipykernel" 2>/dev/null || true
        pkill -9 -f "jupyter" 2>/dev/null || true
        sleep 3
        print_success "已尝试释放显存"
    fi
fi

# ============================================
# 步骤 3: 启动 vLLM 服务
# ============================================
print_info "启动 vLLM 服务..."

# 先停掉已有的 vLLM 进程
pkill -f "vllm serve" 2>/dev/null || true
sleep 2

# 根据可用显存自动选择配置
VRAM_FREE_GB=$(rocm-smi --showmeminfo vram 2>/dev/null | grep "VRAM Total Used" | awk '{printf "%.0f", ($6 > 0) ? (51522830336 - $6) / 1073741824 : 48}' || echo "48")

if [ "$VRAM_FREE_GB" -gt 30 ]; then
    GPU_MEM_UTIL=0.7
    MAX_MODEL_LEN=2048
elif [ "$VRAM_FREE_GB" -gt 15 ]; then
    GPU_MEM_UTIL=0.4
    MAX_MODEL_LEN=1024
else
    GPU_MEM_UTIL=0.2
    MAX_MODEL_LEN=512
fi

print_info "配置: GPU内存利用率=${GPU_MEM_UTIL}, 最大长度=${MAX_MODEL_LEN}"

# 启动 vLLM
nohup vllm serve "$MODEL_PATH" \
    --served-model-name "$MODEL_NAME" \
    --enable-lora \
    --lora-modules arknights-lora="$LORA_PATH" \
    --port "$PORT" \
    --max-model-len "$MAX_MODEL_LEN" \
    --dtype bfloat16 \
    --gpu-memory-utilization "$GPU_MEM_UTIL" \
    > "$VLLM_LOG" 2>&1 &

VLLM_PID=$!
print_info "vLLM 进程 PID: $VLLM_PID"
print_info "等待 vLLM 启动（约 30-60 秒）..."

# 等待启动
for i in $(seq 1 60); do
    if grep -q "Application startup complete" "$VLLM_LOG" 2>/dev/null; then
        print_success "vLLM 启动成功！"
        break
    fi
    if grep -q "Error\|ERROR\|Traceback" "$VLLM_LOG" 2>/dev/null; then
        print_error "vLLM 启动失败，查看日志: $VLLM_LOG"
        tail -20 "$VLLM_LOG"
        exit 1
    fi
    sleep 2
    printf "."
done
echo ""

# 验证服务
if curl -s "http://localhost:$PORT/v1/models" | grep -q "$MODEL_NAME"; then
    print_success "vLLM 服务验证通过"
else
    print_error "vLLM 服务未响应"
    tail -20 "$VLLM_LOG"
    exit 1
fi

# ============================================
# 步骤 4: 测试模型
# ============================================
print_info "测试模型..."

TEST_RESPONSE=$(curl -s "http://localhost:$PORT/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL_NAME\",
        \"messages\": [{\"role\": \"user\", \"content\": \"银灰是什么职业？\"}],
        \"max_tokens\": 100
    }")

if echo "$TEST_RESPONSE" | grep -q "choices"; then
    print_success "模型测试通过"
    echo -e "${GREEN}模型回答: ${NC}$(echo "$TEST_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'][:100])" 2>/dev/null || echo "解析失败")"
else
    print_warning "模型测试失败，但服务已启动"
fi

# ============================================
# 步骤 5: 安装和配置 OpenCode
# ============================================
print_info "配置 OpenCode..."

# 安装 OpenCode（如果没装）
if ! command -v opencode &> /dev/null; then
    print_info "安装 OpenCode..."
    curl -fsSL -k https://opencode.ai/install | bash || {
        print_warning "OpenCode 安装失败，请手动安装: https://opencode.ai"
    }
fi

# 创建配置文件
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/config.json <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "arknights": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Arknights Assistant",
      "options": {
        "baseURL": "http://localhost:$PORT/v1"
      },
      "models": {
        "$MODEL_NAME": {
          "name": "Arknights Assistant"
        }
      }
    }
  }
}
EOF

print_success "OpenCode 配置完成"

# ============================================
# 步骤 6: 创建便捷脚本
# ============================================
print_info "创建便捷脚本..."

# 创建对话脚本
cat > chat.sh <<'EOF'
#!/bin/bash
# 明日方舟干员助手 - 命令行对话
MODEL_NAME="arknights-assistant"
PORT=8000

if [ -z "$1" ]; then
    echo "用法: ./chat.sh \"你的问题\""
    echo "示例: ./chat.sh \"银灰是什么职业？\""
    exit 1
fi

QUESTION="$1"
curl -s "http://localhost:$PORT/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL_NAME\",
        \"messages\": [{\"role\": \"user\", \"content\": \"$QUESTION\"}],
        \"max_tokens\": 500
    }" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data['choices'][0]['message']['content'])
except:
    print('请求失败，请检查 vLLM 服务是否启动')
"
EOF
chmod +x chat.sh

# 创建停止脚本
cat > stop.sh <<'EOF'
#!/bin/bash
# 停止 vLLM 服务
echo "停止 vLLM 服务..."
pkill -f "vllm serve" 2>/dev/null
echo "已停止"
EOF
chmod +x stop.sh

print_success "便捷脚本创建完成"

# ============================================
# 完成
# ============================================
echo ""
echo "================================================"
print_success "部署完成！"
echo "================================================"
echo ""
echo -e "${GREEN}使用方式：${NC}"
echo ""
echo "1. 命令行对话："
echo -e "   ${BLUE}./chat.sh \"银灰是什么职业？\"${NC}"
echo ""
echo "2. 启动 OpenCode："
echo -e "   ${BLUE}opencode${NC}"
echo "   然后选择 'arknights-assistant' 模型"
echo ""
echo "3. 测试 API："
echo -e "   ${BLUE}curl http://localhost:$PORT/v1/models${NC}"
echo ""
echo "4. 停止服务："
echo -e "   ${BLUE}./stop.sh${NC}"
echo ""
echo -e "${YELLOW}提示：${NC}"
echo "   - vLLM 日志: $VLLM_LOG"
echo "   - 模型名称: $MODEL_NAME"
echo "   - API 地址: http://localhost:$PORT/v1"
echo ""
