"""
This is an example script to test submitting ray jobs from CLI.
You can run it with the following command:
ray job submit --address="http://localhost:10000" --working-dir="/home/nandita/work/k8s/test/ray_package" -- python ray_job.py
"""

import os

import ray
import torch
import torch.nn as nn
import torch.optim as optim
from ray.air.config import RunConfig
from ray.train import ScalingConfig
from ray.train.torch import TorchTrainer

# Initialize Ray without the local_dir parameter
ray.init()

# Define your PyTorch model
num_samples = 20
input_size = 10
layer_size = 15
output_size = 5

class NeuralNetwork(nn.Module):
    def __init__(self):
        super(NeuralNetwork, self).__init__()
        self.layer1 = nn.Linear(input_size, layer_size)
        self.relu = nn.ReLU()
        self.layer2 = nn.Linear(layer_size, output_size)

    def forward(self, input_data):
        return self.layer2(self.relu(self.layer1(input_data)))

# Define the training function
def train_func(config):
    import os

    import ray.train.torch
    import torch
    import torch.nn as nn
    import torch.optim as optim
    from torch.utils.data import DataLoader, TensorDataset

    # 3. Initialize the model
    model = NeuralNetwork()
    model = ray.train.torch.prepare_model(model)

    # 4. Define loss and optimizer
    loss_fn = nn.MSELoss()
    optimizer = optim.SGD(model.parameters(), lr=0.1)

    # 5. Prepare data loader
    dataset = TensorDataset(
        torch.randn(config["num_samples"], config["input_size"]),
        torch.randn(config["num_samples"], config["output_size"])
    )
    dataloader = DataLoader(dataset, batch_size=4)

    # 6. Training loop
    num_epochs = config["num_epochs"]
    for epoch in range(num_epochs):
        epoch_loss = 0.0
        for batch_inputs, batch_labels in dataloader:
            outputs = model(batch_inputs)
            loss = loss_fn(outputs, batch_labels)
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item()
        avg_loss = epoch_loss / len(dataloader)
        print(f"Epoch {epoch+1}/{num_epochs}, Loss: {avg_loss:.4f}")

# Define configuration parameters
config = {
    "num_samples": num_samples,
    "input_size": input_size,
    "layer_size": layer_size,
    "output_size": output_size,
    "num_epochs": 3,
}

# Define the trainer with ScalingConfig
trainer = TorchTrainer(
    train_loop_per_worker=train_func,
    scaling_config=ScalingConfig(
        num_workers=2,  # Adjust based on available resources
        use_gpu=False,   # Set to True if GPUs are used
        trainer_resources={"CPU": 1},
    ),
    train_loop_config=config,
    run_config = RunConfig(storage_path="/tmp/ray", name="test_experiment")
)

# Start the training
trainer.fit()

ray.shutdown()