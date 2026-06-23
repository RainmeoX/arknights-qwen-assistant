# Arknights Qwen Assistant - 一键部署

> 基于 Qwen3-0.6B + LoRA 微调的明日方舟干员问答助手，支持一键部署到 OpenCode

## 🚀 快速开始

### 前置条件

1. **AMD GPU 环境**（ROCm）
2. **已训练好的模型**（运行完 `01-Qwen3-Arknights-LoRA.ipynb`）

### 一键部署

```bash
# 1. 克隆项目
git clone https://github.com/RainmeoX/arknights-qwen-assistant.git
cd arknights-qwen-assistant

# 2. 克隆数据集（训练用）
git clone https://github.com/RainmeoX/arknights-dataset.git

# 3. 安装依赖
pip install -r requirements.txt

# 4. 训练模型（约 8-15 分钟）
jupyter notebook 01-Qwen3-Arknights-LoRA.ipynb
# 点击 Run All 运行所有 cell

# 5. 一键部署
./deploy.sh
```

部署完成后，你可以：

```bash
# 命令行对话
./chat.sh "银灰是什么职业？"

# 或启动 OpenCode
opencode
```

## 📁 项目结构

```
arknights-qwen-assistant/
├── 01-Qwen3-Arknights-LoRA.ipynb   # 微调训练 Notebook
├── deploy.sh                        # 一键部署脚本
├── chat.sh                          # 命令行对话脚本
├── stop.sh                          # 停止服务脚本
├── app.py                           # Gradio 网页部署（可选）
├── generate_predictions.py          # 评估预测脚本
├── requirements.txt                 # 依赖清单
└── README.md
```

## 🎯 功能特性

- 🎮 **干员知识问答**：回答干员的职业、星级、属性、技能等问题
- 🎭 **角色扮演**：扮演干员用其语气说话
- 📊 **干员推荐**：根据需求推荐合适干员
- 🏰 **阵营查询**：按阵营或职业筛选干员

## 📊 训练配置

| 配置项 | 值 |
|:---|:---|
| 基础模型 | Qwen3-0.6B |
| 微调方法 | LoRA |
| 训练数据 | 449 个干员，22,621 条问答 |
| 训练时间 | 约 8-15 分钟（AMD ROCm 单卡） |

## 🔧 部署方式

### 方式 1：一键部署（推荐）

```bash
./deploy.sh
```

脚本会自动：
1. 检查环境
2. 释放显存
3. 启动 vLLM 服务
4. 测试模型
5. 配置 OpenCode
6. 创建便捷脚本

### 方式 2：手动部署

```bash
# 1. 启动 vLLM
nohup vllm serve ./models/Qwen/Qwen3-0___6B \
    --served-model-name arknights-assistant \
    --enable-lora \
    --lora-modules arknights-lora=./output/Qwen3_Arknights_LoRA_final \
    --port 8000 \
    --max-model-len 1024 \
    --dtype bfloat16 \
    --gpu-memory-utilization 0.5 \
    > vllm.log 2>&1 &

# 2. 配置 OpenCode
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/config.json <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "arknights": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Arknights Assistant",
      "options": {
        "baseURL": "http://localhost:8000/v1"
      },
      "models": {
        "arknights-assistant": {
          "name": "Arknights Assistant"
        }
      }
    }
  }
}
EOF

# 3. 启动 OpenCode
opencode
```

### 方式 3：Gradio 网页界面

```bash
python app.py \
    --base_model_path ./models/Qwen/Qwen3-0___6B \
    --lora_path ./output/Qwen3_Arknights_LoRA_final
```

访问 `http://localhost:7860`

## 📋 使用示例

### 命令行对话

```bash
./chat.sh "银灰是什么职业？"
./chat.sh "介绍一下阿米娅"
./chat.sh "扮演银灰，说一句任命助理的台词"
./chat.sh "推荐几个强力的近卫干员"
```

### OpenCode 中使用

启动 `opencode` 后，选择 `arknights-assistant` 模型，然后可以直接对话：

```
> 银灰的技能有哪些？
> 扮演阿米娅跟我打招呼
> 6星医疗干员有哪些？
```

## ⚙️ 自定义配置

### 修改模型路径

```bash
export MODEL_PATH=/path/to/your/model
export LORA_PATH=/path/to/your/lora
./deploy.sh
```

### 修改端口

```bash
export PORT=9000
./deploy.sh
```

## 🛠️ 故障排查

### vLLM 启动失败

```bash
# 查看日志
tail -50 vllm.log

# 检查显存
rocm-smi --showmeminfo vram

# 释放显存
pkill -f "ipykernel"
pkill -f "jupyter"
```

### OpenCode 连接失败

```bash
# 检查 vLLM 是否运行
curl http://localhost:8000/v1/models

# 检查配置
cat ~/.config/opencode/config.json
```

### 模型回答有 `<think>` 标签

这是 Qwen3 的思考模式，可以在提问时加 `/no_think`，或重启 vLLM 加参数：

```bash
pkill -f "vllm serve"
vllm serve ... --reasoning-parser deepseek_r1
```

## 📄 License

MIT License

## 🙏 致谢

- 数据来源：[PRTS Wiki](https://prts.wiki/)
- 模型来源：[Qwen3-0.6B](https://modelscope.cn/models/Qwen/Qwen3-0.6B)
- 训练环境：AMD Radeon Cloud (ROCm)
