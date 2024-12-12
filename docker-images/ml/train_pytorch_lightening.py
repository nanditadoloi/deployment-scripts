import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from pytorch_lightning import LightningModule, Trainer
from pytorch_lightning.callbacks import ModelCheckpoint
from datasets import load_dataset
from torch.utils.data import DataLoader

# Configuration
MODEL_NAME = "gpt2"
BATCH_SIZE = 4
EPOCHS = 3
MAX_LENGTH = 512
LR = 2e-5

class TransformerLM(LightningModule):
    def __init__(self, model_name, learning_rate):
        super().__init__()
        self.save_hyperparameters()
        self.model = AutoModelForCausalLM.from_pretrained(model_name)
        self.tokenizer = AutoTokenizer.from_pretrained(model_name)

    def forward(self, input_ids, attention_mask=None):
        return self.model(input_ids=input_ids, attention_mask=attention_mask, labels=input_ids)

    def training_step(self, batch, batch_idx):
        outputs = self(**batch)
        loss = outputs.loss
        self.log("train_loss", loss, prog_bar=True)
        return loss

    def configure_optimizers(self):
        return torch.optim.AdamW(self.parameters(), lr=self.hparams.learning_rate)

# Data Preparation
def tokenize_function(examples):
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    return tokenizer(examples["text"], padding="max_length", truncation=True, max_length=MAX_LENGTH)

def prepare_dataloader():
    dataset = load_dataset("wikitext", "wikitext-2-raw-v1", split="train")
    tokenized_dataset = dataset.map(tokenize_function, batched=True)
    tokenized_dataset.set_format(type="torch", columns=["input_ids", "attention_mask"])
    return DataLoader(tokenized_dataset, batch_size=BATCH_SIZE, shuffle=True)

# Initialize the model, data, and Trainer
def main():
    model = TransformerLM(model_name=MODEL_NAME, learning_rate=LR)
    train_dataloader = prepare_dataloader()

    # Set up checkpointing
    checkpoint_callback = ModelCheckpoint(
        monitor="train_loss",
        dirpath="checkpoints",
        filename="transformer-{epoch:02d}-{train_loss:.2f}",
        save_top_k=2,
        mode="min",
    )

    # Trainer for single-GPU training
    trainer = Trainer(
        max_epochs=EPOCHS,
        gpus=1,
        log_every_n_steps=10,
        callbacks=[checkpoint_callback]
    )
    
    # Start training
    trainer.fit(model, train_dataloader)

if __name__ == "__main__":
    main()
