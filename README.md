# Arknights Qwen Assistant

> 🎮 基于 Qwen3-0.6B + LoRA 微调的明日方舟六星干员助手 —— 支持干员问答、资料查询、角色扮演

## ✨ 功能特性

| 功能 | 说明 | 示例 |
|:---|:---|:---|
| 🎮 **干员问答** | 回答干员的职业、星级、阵营等基础信息 | "银灰是什么职业？" |
| 📊 **资料查询** | 查询技能、天赋、满级属性等详细数据 | "银灰的技能有哪些？" |
| 🎭 **角色扮演** | 扮演干员用其语气说话 | "扮演银灰，说一句任命助理的台词" |
| 💬 **自由对话** | 多轮对话，自然交流 | "推荐几个强力的近卫干员" |

## 📊 模型信息

| 项目 | 内容 |
|:---|:---|
| **基础模型** | Qwen3-0.6B |
| **微调方法** | LoRA (r=8, alpha=32) |
| **训练数据** | 133 个六星干员，8,846 条问答 |
| **训练环境** | AMD Radeon Cloud (ROCm 单卡) |
| **训练时长** | 约 8-15 分钟 |
| **模型大小** | LoRA adapter ~20MB |

## 🚀 快速开始

### 方式 1：使用预训练权重（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/RainmeoX/arknights-qwen-assistant.git
cd arknights-qwen-assistant

# 2. 克隆数据集（用于依赖）
git clone https://github.com/RainmeoX/arknights-dataset.git

# 3. 安装依赖
pip install -r requirements.txt

# 4. 下载基础模型（Qwen3-0.6B）
python -c "from modelscope import snapshot_download; snapshot_download('Qwen/Qwen3-0.6B', cache_dir='./models')"
# 重命名模型目录
mv ./models/Qwen/Qwen3-0___6B ./models/Qwen3-0.6B 2>/dev/null || true

# 5. 一键部署
./arknights-deploy

# 6. 开始对话
arknights-chat "银灰是什么职业？"
```

### 方式 2：自己训练模型

```bash
# 1. 克隆项目和数据集
git clone https://github.com/RainmeoX/arknights-qwen-assistant.git
cd arknights-qwen-assistant
git clone https://github.com/RainmeoX/arknights-dataset.git

# 2. 安装依赖
pip install -r requirements.txt

# 3. 训练模型（约 8-15 分钟）
jupyter notebook 01-Qwen3-Arknights-LoRA.ipynb
# 点击 Run All 运行所有 cell

# 4. 一键部署
./arknights-deploy
```

## 📁 项目结构

```
arknights-qwen-assistant/
├── 01-Qwen3-Arknights-LoRA.ipynb        # 微调训练 Notebook
├── arknights-deploy                      # 一键部署脚本（vLLM + OpenCode）
├── app.py                                # Gradio 网页界面（可选）
├── generate_predictions.py               # 评估预测脚本
├── requirements.txt                      # Python 依赖
├── output/
│   └── Qwen3_Arknights_LoRA_final/       # 训练好的 LoRA 权重
│       ├── adapter_model.safetensors     # LoRA 权重（核心，~20MB）
│       ├── adapter_config.json           # LoRA 配置
│       ├── tokenizer.json                # 分词器
│       ├── vocab.json                    # 词表
│       ├── merges.txt                    # BPE 合并规则
│       └── ...                           # 其他配置文件
└── README.md
```

## 🎯 使用方式

### 命令行对话

```bash
# 干员问答
arknights-chat "银灰是什么职业？"

# 资料查询
arknights-chat "银灰的技能有哪些？"
arknights-chat "星熊的满级属性是多少？"
arknights-chat "阿米娅的天赋是什么？"

# 角色扮演
arknights-chat "扮演银灰，说一句任命助理的台词"
arknights-chat "扮演阿米娅跟我打招呼"

# 干员推荐
arknights-chat "推荐几个强力的近卫干员"
arknights-chat "6星医疗干员有哪些？"
```

### OpenCode 集成

```bash
# 启动 OpenCode
opencode

# 选择 arknights-assistant 模型，直接对话
> 银灰的技能有哪些？
> 扮演阿米娅跟我打招呼
```

### Gradio 网页界面（可选）

```bash
python app.py \
    --base_model_path ./models/Qwen3-0.6B \
    --lora_path ./output/Qwen3_Arknights_LoRA_final
```

访问 `http://localhost:7860`

## 🔧 部署架构

```
用户输入
  ↓
arknights-chat / OpenCode / Gradio
  ↓
vLLM 服务 (localhost:8000)
  ├── 基础模型: Qwen3-0.6B
  └── LoRA adapter: arknights-lora
  ↓
模型推理 → 返回回答
```

## 📊 训练数据说明

训练数据来自 [arknights-dataset](https://github.com/RainmeoX/arknights-dataset) 仓库的增强版六星干员数据集：

| 数据类型 | 数量 | 说明 |
|:---|:---:|:---|
| 基础信息问答 | ~2,000 | 职业、星级、阵营、属性等 |
| 技能查询 | ~1,500 | 技能名称、效果描述 |
| 天赋查询 | ~1,200 | 天赋名称、触发条件、效果 |
| 属性查询 | ~1,000 | 满级生命、攻击、防御等 |
| 角色扮演 | ~2,500 | 干员语音台词 |
| 综合介绍 | ~600 | 干员完整介绍 |
| **总计** | **8,846** | 133 个六星干员 |

## ⚙️ 自定义配置

### 修改模型路径

```bash
export MODEL_PATH=/path/to/your/model
export LORA_PATH=/path/to/your/lora
./arknights-deploy
```

### 修改端口

```bash
export PORT=9000
./arknights-deploy
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

## 📈 模型效果

| 能力 | 效果 | 说明 |
|:---|:---:|:---|
| 角色扮演 | ⭐⭐⭐⭐⭐ | 语气、用词、背景都很准确 |
| 基础问答 | ⭐⭐⭐⭐ | 职业、星级、阵营准确 |
| 资料查询 | ⭐⭐⭐⭐ | 技能、天赋、属性较准确 |
| 综合介绍 | ⭐⭐⭐⭐ | 能整合多个信息点 |

## 📄 License

MIT License

## 🙏 致谢

- **数据来源**：[PRTS Wiki](https://prts.wiki/) - 明日方舟中文 Wiki
- **基础模型**：[Qwen3-0.6B](https://modelscope.cn/models/Qwen/Qwen3-0.6B) - 阿里通义千问
- **训练环境**：AMD Radeon Cloud (ROCm)
- **数据集仓库**：[arknights-dataset](https://github.com/RainmeoX/arknights-dataset)
