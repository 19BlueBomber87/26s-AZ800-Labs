#!/bin/bash
set -euo pipefail

### 1. Update
sudo apt update
sudo apt install -y ca-certificates curl gnupg apt-transport-https gpg

### 2. Install containerd
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y containerd.io

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo sed -i 's#pause:3.8#pause:3.9#' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

### 3. Kubernetes repo
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update

### 4. Install kube tools
sudo apt install -y kubeadm kubelet kubectl
sudo apt-mark hold kubeadm kubelet kubectl

### 5. Disable swap permanently
sudo swapoff -a

# Disable ALL possible swap entries in fstab (the part your old script missed)
sudo sed -i '/swap.img/s/^/#/' /etc/fstab
sudo sed -i '/ swap /s/^/#/' /etc/fstab

# Remove Ubuntu auto-created swap file
sudo rm -f /swap.img || true

### 6. Kernel modules + sysctl
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sudo sysctl --system