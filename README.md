# Arknights Qwen Assistant

> 基于 Qwen3-0.6B + LoRA 微调的明日方舟干员问答助手

## 📋 项目简介

本项目使用 [Qwen3-0.6B](https://modelscope.cn/models/Qwen/Qwen3-0.6B) 模型，在 AMD Radeon Cloud（ROCm 单卡环境）上通过 LoRA 微调，打造一个能回答干员问题、扮演干员对话的专属助手。

训练数据来自 [arknights-dataset](https://github.com/RainmeoX/arknights-dataset)，包含 449 个干员的 22,621 条问答对。

## ✨ 功能特性

- 🎮 **干员知识问答**：回答干员的职业、星级、属性、技能等问题
- 🎭 **角色扮演**：扮演干员用其语气说话
- 📊 **干员推荐**：根据需求推荐合适干员
- 🏰 **阵营查询**：按阵营或职业筛选干员
- ⚔️ **技能查询**：查询干员的技能和天赋详情

## 📁 项目结构

```
arknights-qwen-assistant/
├── 01-Qwen3-Arknights-LoRA.ipynb   # 微调主程序 Notebook
├── app.py                           # Gradio 网页部署
├── generate_predictions.py          # 生成评估预测
├── requirements.txt                 # 依赖清单
└── README.md
```

## 🚀 快速开始

### 1. 环境准备

在 AMD Radeon Cloud 或本地 AMD GPU 环境上：

```bash
# 克隆项目
git clone https://github.com/RainmeoX/arknights-qwen-assistant.git
cd arknights-qwen-assistant

# 克隆数据集
git clone https://github.com/RainmeoX/arknights-dataset.git

# 安装依赖
pip install -r requirements.txt
```

### 2. 微调训练

打开 `01-Qwen3-Arknights-LoRA.ipynb`，点击 "Run All" 一键运行。

训练配置：
- 模型：Qwen3-0.6B
- 方法：LoRA（r=8, alpha=32）
- 数据：20,358 条训练集
- 训练时长：约 10-15 分钟（单卡）

### 3. 部署 Demo

```bash
python app.py \
    --base_model_path ./models/Qwen3-0.6B \
    --lora_path ./output/Qwen3_Arknights_LoRA_final
```

访问 `http://localhost:7860` 即可使用。

### 4. 运行评估

```bash
# 生成预测
python generate_predictions.py \
    --base_model_path ./models/Qwen3-0.6B \
    --lora_path ./output/Qwen3_Arknights_LoRA_final \
    --test_dir arknights-dataset/eval/ \
    --output predictions.json

# 运行评估
python arknights-dataset/eval/evaluate.py \
    --predictions predictions.json \
    --test_dir arknights-dataset/eval/ \
    --output eval_report.json \
    --fluency_score 85
```

## 📊 训练配置

| 配置项 | 值 |
|:---|:---|
| 基础模型 | Qwen3-0.6B |
| 微调方法 | LoRA |
| LoRA r | 8 |
| LoRA alpha | 32 |
| target_modules | q_proj, k_proj, v_proj, o_proj, gate_proj, up_proj, down_proj |
| 训练轮数 | 3 |
| 批大小 | 4 |
| 学习率 | 1e-4 |
| 最大长度 | 1024 |
| 精度 | BF16 |
| 训练监控 | SwanLab |

## 📈 评估方案

### 评估维度

| 维度 | 权重 | 说明 |
|:---|:---:|:---|
| 知识准确率 | 40% | 100道知识问答的正确率 |
| 角色相似度 | 25% | 50道角色扮演与真实台词的相似度 |
| 幻觉控制率 | 20% | 30道幻觉检测的拒绝率 |
| 回答流畅度 | 15% | 人工评分 |

### 等级划分

- A 优秀：≥90 分
- B 良好：80-89 分
- C 中等：70-79 分
- D 及格：60-69 分
- F 不及格：<60 分

## 🔧 技术栈

- **模型**：Qwen3-0.6B
- **框架**：PyTorch + Transformers + PEFT
- **训练**：Transformers Trainer + LoRA
- **监控**：SwanLab
- **部署**：Gradio
- **环境**：AMD ROCm

## 📄 License

MIT License

## 🙏 致谢

- 数据来源：[PRTS Wiki](https://prts.wiki/)
- 模型来源：[Qwen3-0.6B](https://modelscope.cn/models/Qwen/Qwen3-0.6B)
- 训练环境：AMD Radeon Cloud
