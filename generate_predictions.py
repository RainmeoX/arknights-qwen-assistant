"""
生成模型预测结果，用于评估
用法：python generate_predictions.py --model_path ./output --base_model_path ./models/Qwen3 --test_dir ./eval --output predictions.json
"""
import json
import os
import argparse
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel


def load_model(base_model_path, lora_path):
    """加载基础模型 + LoRA 权重"""
    print("加载基础模型...")
    tokenizer = AutoTokenizer.from_pretrained(base_model_path, trust_remote_code=True)
    model = AutoModelForCausalLM.from_pretrained(
        base_model_path,
        device_map="auto",
        torch_dtype=torch.bfloat16,
        trust_remote_code=True
    )
    
    if lora_path and os.path.exists(lora_path):
        print(f"加载 LoRA 权重: {lora_path}")
        model = PeftModel.from_pretrained(model, model_id=lora_path)
    
    return model, tokenizer


def generate_answer(model, tokenizer, question, system_prompt="你是明日方舟游戏助手，可以回答关于干员的各种问题，也能扮演干员进行对话。"):
    """生成回答"""
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": question}
    ]
    inputs = tokenizer.apply_chat_template(
        messages,
        add_generation_prompt=True,
        tokenize=True,
        return_tensors="pt",
        return_dict=True,
        enable_thinking=False
    ).to(model.device)
    
    gen_kwargs = {"max_new_tokens": 512, "do_sample": False, "top_k": 1}
    with torch.no_grad():
        outputs = model.generate(**inputs, **gen_kwargs)
        outputs = outputs[:, inputs['input_ids'].shape[1]:]
    return tokenizer.decode(outputs[0], skip_special_tokens=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base_model_path", required=True, help="基础模型路径")
    parser.add_argument("--lora_path", default=None, help="LoRA 权重路径（可选）")
    parser.add_argument("--test_dir", required=True, help="测试集目录")
    parser.add_argument("--output", default="predictions.json", help="输出文件")
    args = parser.parse_args()
    
    # 加载模型
    model, tokenizer = load_model(args.base_model_path, args.lora_path)
    
    # 加载测试集
    predictions = {}
    test_files = ["test_knowledge.json", "test_roleplay.json", "test_hallucination.json"]
    
    for test_file in test_files:
        test_path = os.path.join(args.test_dir, test_file)
        if not os.path.exists(test_path):
            continue
        
        with open(test_path, encoding="utf-8") as f:
            tests = json.load(f)
        
        print(f"\n处理 {test_file} ({len(tests)} 题)...")
        for i, test in enumerate(tests):
            qid = test["id"]
            question = test["question"]
            answer = generate_answer(model, tokenizer, question)
            predictions[qid] = answer
            
            if (i + 1) % 20 == 0:
                print(f"  进度: {i+1}/{len(tests)}")
    
    # 保存预测结果
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(predictions, f, ensure_ascii=False, indent=2)
    
    print(f"\n预测完成！共 {len(predictions)} 条")
    print(f"结果保存到: {args.output}")


if __name__ == "__main__":
    main()
