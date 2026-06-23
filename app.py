"""
明日方舟干员助手 - Gradio 网页界面
用法：python app.py --base_model_path ./models/Qwen3 --lora_path ./output/Qwen3_Arknights_LoRA_final
"""
import argparse
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel
import gradio as gr

# 全局变量
model = None
tokenizer = None
SYSTEM_PROMPT = "你是明日方舟游戏助手，可以回答关于干员的各种问题，也能扮演干员进行对话。"


def load_model(base_model_path, lora_path):
    """加载模型"""
    global model, tokenizer
    print("加载基础模型...")
    tokenizer = AutoTokenizer.from_pretrained(base_model_path, trust_remote_code=True)
    model = AutoModelForCausalLM.from_pretrained(
        base_model_path,
        device_map="auto",
        torch_dtype=torch.bfloat16,
        trust_remote_code=True
    )
    
    if lora_path:
        print(f"加载 LoRA 权重: {lora_path}")
        model = PeftModel.from_pretrained(model, model_id=lora_path)
    
    print("模型加载完成！")


def chat(message, history):
    """对话函数"""
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    for h in history:
        messages.append({"role": "user", "content": h[0]})
        messages.append({"role": "assistant", "content": h[1]})
    messages.append({"role": "user", "content": message})
    
    inputs = tokenizer.apply_chat_template(
        messages,
        add_generation_prompt=True,
        tokenize=True,
        return_tensors="pt",
        return_dict=True,
        enable_thinking=False
    ).to(model.device)
    
    gen_kwargs = {
        "max_new_tokens": 512,
        "do_sample": True,
        "top_k": 50,
        "top_p": 0.9,
        "temperature": 0.7
    }
    with torch.no_grad():
        outputs = model.generate(**inputs, **gen_kwargs)
        outputs = outputs[:, inputs['input_ids'].shape[1]:]
    return tokenizer.decode(outputs[0], skip_special_tokens=True)


# 预设问题示例
EXAMPLES = [
    "银灰是什么职业的干员？",
    "介绍一下阿米娅这名干员",
    "扮演银灰，说一句任命助理的台词",
    "推荐几个强力的狙击干员",
    "6星医疗干员有哪些？",
    "真银斩是什么技能？",
    "星熊的满级属性是多少？",
    "谢拉格阵营有哪些干员？",
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base_model_path", required=True, help="基础模型路径")
    parser.add_argument("--lora_path", default=None, help="LoRA 权重路径")
    parser.add_argument("--port", type=int, default=7860, help="端口")
    args = parser.parse_args()
    
    load_model(args.base_model_path, args.lora_path)
    
    # 创建界面
    with gr.Blocks(title="明日方舟干员助手", theme=gr.themes.Soft()) as demo:
        gr.Markdown("""
        # 🎮 明日方舟干员助手
        
        基于 Qwen3-0.6B + LoRA 微调的明日方舟干员问答助手。
        
        **能力**：干员知识问答、角色扮演、干员推荐、技能查询
        """)
        
        chatbot = gr.ChatInterface(
            fn=chat,
            examples=EXAMPLES,
            title="对话",
            description="问任何关于明日方舟干员的问题，或让模型扮演干员对话",
        )
    
    demo.launch(server_port=args.port, share=True)


if __name__ == "__main__":
    main()
