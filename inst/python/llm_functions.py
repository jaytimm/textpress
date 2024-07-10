
def initialize_model(model_name):
  
    import os
    from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
    import torch

    ##full_model_path = os.path.join(model_path, model_name)
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForCausalLM.from_pretrained(
        model_name,
        ##cache_dir = model_path,
        torch_dtype=torch.float16,
        #use_flash_attention_2=True,
        attn_implementation="flash_attention_2",
        device_map = "cuda:0"
    )
    
    model_pipeline = pipeline(
        "text-generation",
        model=model,
        tokenizer=tokenizer
    )
    return model_pipeline


def generate_text(model_pipeline, 
                  prompt, 
                  temp, 
                  max_length, 
                  max_new_tokens=None, 
                  max_attempts=20, 
                  is_json_output=True):
    
    from transformers import pipeline

    try:
        # Set max_new_tokens if specified, otherwise use max_length
        generation_kwargs = {
            "max_new_tokens": max_new_tokens if max_new_tokens is not None else max_length,
            "temperature": temp,
            "do_sample": True,
            "return_full_text": False,
            "num_return_sequences": 1,
            "eos_token_id": model_pipeline.tokenizer.eos_token_id,
            "pad_token_id": model_pipeline.tokenizer.eos_token_id
        }
        sequences = model_pipeline(prompt, **generation_kwargs)
        
        generated_text = [seq['generated_text'] for seq in sequences][0]  # Assume single sequence return

        return generated_text  # Return the generated text
    except Exception as e:
        print(f"An error occurred: {e}")
        return None  # Return None if an error occurs

    
