# Lightweight QA Assistant

> 小参数量知识问答助手：Qwen3-0.6B + LoRA 高效微调，AMD ROCm 单卡 8 分钟完成训练 ｜ adapter 仅 20MB

验证「0.6B 级小模型 + 高质量领域语料」能否支撑垂直领域知识问答——结论：链路完全可行，且对数据质量的要求远高于大模型。

## 技术栈

| 项 | 内容 |
|:---|:---|
| 基础模型 | Qwen3-0.6B |
| 微调方法 | LoRA（r=8, alpha=32） |
| 训练数据 | 133 个知识实体，8,846 条问答语料（来自 [qa-corpus-dataset](https://github.com/RainmeoX/qa-corpus-dataset)） |
| 部署 | vLLM，AMD Radeon Cloud（ROCm 单卡） |
| LoRA adapter | 约 20MB |
| 训练时长 | 约 8 分钟 |

## 实现功能

- 领域知识问答（属性 / 分类 / 归属等结构化事实）
- 资料查询（技能参数、数值属性等）
- 风格化回复与自由对话

## 我的工作

- 基于 qa-corpus-dataset 构造训练样本（清洗 + 归一 + QA 模板化）
- 编写 LoRA 训练 notebook
- 搭建 vLLM 部署 + 命令行对话工具（一键脚本）

## 踩坑记录

- **0.6B 模型容量有限**：复杂设定容易遗漏，长上下文表现明显弱于 4B 级模型——小模型容错低，喂进去的每条数据都得是「对的」
- **ROCm 环境**：需要特定环境变量（`HSA_OVERRIDE_GFX_VERSION` 等），否则 vLLM 起不来
- Qwen3 思考模式输出带 `<think>` 标签，部署时需加 `--reasoning-parser deepseek_r1` 处理

## 项目不足

- 语料只覆盖核心实体，未扩展到全集
- 未做系统化评测，效果靠人工抽检
- 训练数据偏基础事实，开放对话深度有限

## 后续计划

- 扩展语料覆盖面
- 加自动化评估脚本量化效果
- 对比不同 LoRA rank 的上限

## Reflection

用 0.6B 跑通整条链路，最大的收获是理解了小模型场景下「数据质量 > 模型容量，检索补充 > 参数记忆」的工程取舍。

## License

MIT
