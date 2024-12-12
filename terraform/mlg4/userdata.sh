#!/bin/bash

# Function to print green text
print_green() {
    echo -e "\033[0;32m$1\033[0m"
}

print_green "Configuring Kubernetes worker node with NVIDIA GPU support..."

# Install required packages
print_green "Installing required packages..."
DEBIAN_FRONTEND=noninteractive apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl software-properties-common nfs-common

# Install containerd
print_green "Installing containerd..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
DEBIAN_FRONTEND=noninteractive apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y containerd.io

# Configure containerd
print_green "Configuring containerd..."
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

# Install NVIDIA Container Toolkit
print_green "Installing NVIDIA Container Toolkit..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y nvidia-container-toolkit

# Configure NVIDIA Container Toolkit for containerd
print_green "Configuring NVIDIA Container Toolkit for containerd..."
nvidia-ctk runtime configure --runtime=containerd
# Update the default runtime to nvidia
print_green "Setting default runtime to NVIDIA in containerd config..."
sed -i 's/default_runtime_name = "runc"/default_runtime_name = "nvidia"/' /etc/containerd/config.toml
systemctl restart containerd

# Install kubeadm, kubelet, and kubectl
print_green "Adding Kubernetes signing key..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

print_green "Adding Kubernetes repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

print_green "Updating package information..."
DEBIAN_FRONTEND=noninteractive apt-get update -y

print_green "Installing Kubernetes components..."
DEBIAN_FRONTEND=noninteractive apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Configure cgroup driver for kubelet
print_green "Configuring cgroup driver for kubelet..."
cat <<EOF | tee /var/lib/kubelet/config.yaml > /dev/null
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

# Restart kubelet
print_green "Restarting kubelet..."
systemctl daemon-reload
systemctl restart kubelet

print_green "Configuration complete. You can now join the cluster using the kubeadm join command."
kubeadm join 172.31.1.230:6443 --token <token> --discovery-token-ca-cert-hash <hash> --cri-socket unix:///run/containerd/containerd.sock

# sleep 2

# # Fetch the region from EC2 metadata
# region=$(curl -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT "http://169.254.169.254/latest/api/token" | xargs -I {} curl -s -H "X-aws-ec2-metadata-token: {}" "http://169.254.169.254/latest/dynamic/instance-identity/document" | jq -r .region)

# # Fetch the private IP of the instance
# private_ip=$(curl -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT "http://169.254.169.254/latest/api/token" | xargs -I {} curl -s -H "X-aws-ec2-metadata-token: {}" "http://169.254.169.254/latest/meta-data/local-ipv4")

# # Define the node name based on the private IP
# node_name="ip-$(echo $private_ip | tr '.' '-')"

# kubectl label node "$node_name" topology.kubernetes.io/region="$region" --kubeconfig /etc/kubernetes/kubelet.conf
# kubectl label node "$node_name" topology.kubernetes.io/type="gpu" --kubeconfig /etc/kubernetes/kubelet.conf