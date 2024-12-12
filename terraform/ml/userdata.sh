#!/bin/bash

# Update the system
apt-get update -y

apt-get install -y apt-transport-https ca-certificates curl gpg software-properties-common

# Install cri-o
KUBERNETES_VERSION=v1.30
CRIO_VERSION=v1.30
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --batch --yes --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list
apt-get update
apt-get install -y cri-o kubelet kubeadm kubectl socat

# Reload and restart kubelet
systemctl daemon-reload
systemctl start crio.service
systemctl restart kubelet

# Join the Kubernetes cluster
kubeadm join 172.31.1.230:6443 --token <token> --discovery-token-ca-cert-hash <hash> --cri-socket unix:///var/run/crio/crio.sock

sleep 2

# Fetch the region from EC2 metadata
region=$(curl -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT "http://169.254.169.254/latest/api/token" | xargs -I {} curl -s -H "X-aws-ec2-metadata-token: {}" "http://169.254.169.254/latest/dynamic/instance-identity/document" | jq -r .region)

# Fetch the private IP of the instance
private_ip=$(curl -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT "http://169.254.169.254/latest/api/token" | xargs -I {} curl -s -H "X-aws-ec2-metadata-token: {}" "http://169.254.169.254/latest/meta-data/local-ipv4")

# Define the node name based on the private IP
node_name="ip-$(echo $private_ip | tr '.' '-')"

kubectl label node "$node_name" topology.kubernetes.io/region="$region" --kubeconfig /etc/kubernetes/kubelet.conf
kubectl label node "$node_name" topology.kubernetes.io/type="gpu" --kubeconfig /etc/kubernetes/kubelet.conf