import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, Trainer, TrainingArguments
from datasets import load_dataset

# Configuration
MODEL_NAME = "gpt2"  # Base model for fine-tuning
BATCH_SIZE = 4       # Adjust based on available GPU memory
EPOCHS = 3           # Number of epochs
MAX_LENGTH = 512     # Maximum token length for each input

def main():
    # Load dataset - Using a small corpus for demonstration (e.g., WikiText)
    dataset = load_dataset("wikitext", "wikitext-2-raw-v1", split="train")
    
    # Load model and tokenizer
    model = AutoModelForCausalLM.from_pretrained(MODEL_NAME)
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    
    # Tokenize dataset
    def tokenize_function(examples):
        return tokenizer(examples["text"], padding="max_length", truncation=True, max_length=MAX_LENGTH)
    
    tokenized_datasets = dataset.map(tokenize_function, batched=True)
    tokenized_datasets.set_format("torch", columns=["input_ids", "attention_mask"])
    
    # Prepare PyTorch DataLoader
    train_dataloader = torch.utils.data.DataLoader(
        tokenized_datasets, batch_size=BATCH_SIZE, shuffle=True
    )
    
    # Training arguments
    training_args = TrainingArguments(
        output_dir="./results",
        num_train_epochs=EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
        save_steps=1000,
        save_total_limit=2,
        logging_dir="./logs",
        logging_steps=100,
    )
    
    # Trainer API to handle training loop, with Hugging Face's Trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_datasets,
        tokenizer=tokenizer,
    )
    
    # Start training
    trainer.train()

if __name__ == "__main__":
    main()
