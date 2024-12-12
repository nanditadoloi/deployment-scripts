#!/bin/bash

# Update the system
apt-get update -y

# Remove old kubelet, kubeadm, and kubectl
apt-get remove --purge -y kubelet kubeadm kubectl

# Clean up any leftover Kubernetes configuration files
rm -rf /etc/systemd/system/kubelet.service.d
rm -rf /etc/kubernetes/
rm -rf /var/lib/kubelet/
rm -rf /usr/libexec/kubernetes

# Install kubelet, kubeadm, kubectl, and socat
apt-get install -y kubelet kubeadm kubectl socat nfs-common

# Reload and restart kubelet
systemctl daemon-reload
systemctl restart kubelet

# Join the Kubernetes cluster
kubeadm join 172.31.1.230:6443 --token 9wnfid.e7mdtcwun4xwi7k2 --discovery-token-ca-cert-hash sha256:99c6492442d956b39133d2cf9d904b2dc35bfb16c2c06ce928f0ad71a22acaad --cri-socket unix:///var/run/crio/crio.sock

sleep 2

# Fetch the region from EC2 metadata
region=$(curl -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT "http://169.254.169.254/latest/api/token" | xargs -I {} curl -s -H "X-aws-ec2-metadata-token: {}" "http://169.254.169.254/latest/dynamic/instance-identity/document" | jq -r .region)

# Fetch the private IP of the instance
private_ip=$(curl -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -X PUT "http://169.254.169.254/latest/api/token" | xargs -I {} curl -s -H "X-aws-ec2-metadata-token: {}" "http://169.254.169.254/latest/meta-data/local-ipv4")

# Define the node name based on the private IP
node_name="ip-$(echo $private_ip | tr '.' '-')"

kubectl label node "$node_name" topology.kubernetes.io/region="$region" --kubeconfig /etc/kubernetes/kubelet.conf