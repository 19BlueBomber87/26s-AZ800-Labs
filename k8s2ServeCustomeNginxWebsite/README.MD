# Kubernetes Lab: Multi-Node k8s Cluster with Linux Workers Serving a Custom Nginx Website

## Overview
This lab guides you through building a **Kubernetes (k8s) cluster** using **kubeadm** on Ubuntu Linux. It includes:

- 1 Control Plane node
- Multiple Linux Worker nodes
- **containerd** as the container runtime
- Calico as the CNI networking plugin
- MetalLB + NGINX Ingress for Load Balancing
- A custom static website served via scaled **Nginx** pods

The goal is to demonstrate **container orchestration** in action — deploying, scaling, and accessing a real web application across multiple nodes.

---

## Visualization Diagrams

### 1. Processor Modes (CPU Rings)
![Processor Modes](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/k8s2ServeCustomeNginxWebsite/Visualization%20Diagrams/01-CPU-User-Kernel.jpg)

**Short Explanation**:  
Shows the different privilege levels (rings) of a CPU. The kernel runs in Ring 0 (highest privilege), while user applications run in Ring 3. This is foundational for understanding how containers and VMs achieve isolation.

### 2. Virtual Machines vs Containers
![VMs vs Containers](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/k8s2ServeCustomeNginxWebsite/Visualization%20Diagrams/02-VMS%20vs%20Containers.jpg)

**Short Explanation**:  
Compares traditional VMs (each with its own guest OS and kernel) to Containers (which share the host kernel). Containers are much lighter and more efficient — the core reason Kubernetes can run hundreds of workloads on modest hardware.

### 3. Kubernetes Control Plane (Master Node)
![Cluster Master](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/k8s2ServeCustomeNginxWebsite/Visualization%20Diagrams/03-ClusterMaster.jpg)

**Short Explanation**:  
Illustrates the Kubernetes architecture. The **Control Plane** (API Server) receives commands from the administrator and schedules work. **Kubelet** on each Node works with the container runtime to run Pods.

### 4. Nodes, Pods and Containers
![Nodes, Pods and Containers](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/k8s2ServeCustomeNginxWebsite/Visualization%20Diagrams/04-k8s-Overview.jpg)

**Short Explanation**:  
Shows the hierarchy: A **Node** runs the Kubelet + container runtime. The Kubelet manages **Pods**, which are the smallest deployable units containing one or more containers.

---

## Prerequisites

- Hyper-V Host (Windows 10/11 or Server)
- `New-Lab_VM` function from your lab repo
- Ubuntu 26.04 ISO
- At least 8–16 GB RAM on the host
- External Hyper-V Switch recommended

## Lab Steps (Summary)

1. **Create VMs** using the provided PowerShell script (`k8s2ServeNginx.ps1`)
2. Install OS on Control Plane (`k8s`) and Worker nodes (`k8s-node01`, `k8s-node02`, ...)
3. Run `initialConfig.sh` on every node (installs containerd + Kubernetes tools)
4. Initialize the Control Plane with `kubeadm init`
5. Join worker nodes with `kubeadm join`
6. Install Calico CNI
7. Deploy **MetalLB** + **NGINX Ingress Controller**
8. Deploy the custom Nginx website (with dynamic content pulled from GitHub)

## Key Files

- **`initialConfig.sh`** → Prepares each Linux node (containerd, kube tools, sysctl, swap disable)
- **`k8s2ServeNginx.ps1`** → Main automation script for VM creation and high-level steps

---

## Accessing the Website

After deployment, use the **MetalLB External IP** (e.g. `192.168.11.200`) in your browser. Refresh to see different pods serving requests (load balancing in action).

You can scale the deployment live:

```bash
kubectl scale deployment custom-static-site --replicas=20


Author: Mark Kruse Location: Anchorage, Alaska Lab Environment
Happy Orchestrating! 🚀
