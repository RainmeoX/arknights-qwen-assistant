# Arknights Qwen Assistant

明日方舟六星干员问答助手。Qwen3-0.6B + LoRA 微调，AMD ROCm 单卡训练部署。

## 项目背景

和 [zzz-yixuan-assistant](https://github.com/RainmeoX/zzz-yixuan-assistant) 同一套思路，但我想验证更小模型（0.6B）做垂直领域问答是否够用——毕竟不是每个人都有 4B 模型的显存。

## 技术栈

- 基础模型：Qwen3-0.6B
- 微调：LoRA（r=8, alpha=32）
- 训练数据：133 个六星干员，8,846 条问答（来自 [arknights-dataset](https://github.com/RainmeoX/arknights-dataset)）
- 部署：vLLM，AMD Radeon Cloud（ROCm 单卡）
- LoRA adapter 约 20MB

## 实现功能

- 干员问答（职业 / 星级 / 阵营等）
- 资料查询（技能 / 天赋 / 满级属性）
- 角色扮演（用干员语气说话）
- 自由对话 / 干员推荐

## 我的工作

- 基于 arknights-dataset 构造训练样本
- 编写 LoRA 训练 notebook
- 搭建 vLLM 部署 + 命令行对话（`arknights-chat`）

## 运行中遇到的问题

- **0.6B 模型容量有限**：复杂设定容易遗漏，长上下文表现不如大模型
- **ROCm 环境**：需要特定环境变量（与 zzz 项目类似），否则 vLLM 起不来
- Qwen3 思考模式会带 `<think>` 标签，部署时需加 `--reasoning-parser deepseek_r1` 处理

## 项目不足

- 只覆盖六星干员，未扩展到全干员
- 未做系统化评测，效果靠手测
- 训练数据偏基础信息，角色扮演深度有限

## 后续计划

- 扩展到全干员
- 加自动化评估脚本量化效果
- 尝试更大 rank 看上限

## Reflection

用 0.6B 跑通整个链路，让我更清楚一件事：模型越小，数据和检索越重要。小模型容错低，喂进去的每条数据都得是"对的"。

## License

MIT
