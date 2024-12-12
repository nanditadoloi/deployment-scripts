#!/bin/bash
apt-get update -y
apt-get remove --purge -y kubelet kubeadm kubectl

rm -rf /etc/systemd/system/kubelet.service.d
rm -rf /etc/kubernetes/
rm -rf /var/lib/kubelet/
rm -rf /usr/libexec/kubernetes

apt-get install -y kubelet kubeadm kubectl socat

systemctl daemon-reload
systemctl restart kubelet

kubeadm join 172.31.1.230:6443 --token <token> --discovery-token-ca-cert-hash <hash> --cri-socket unix:///var/run/crio/crio.sock