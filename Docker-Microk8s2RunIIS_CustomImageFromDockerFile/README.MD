# MicroK8s with Windows Worker Nodes to Run IIS Lab  
**Custom IIS Website. Uses a custom image built from Docker + Windows Worker Nodes**

A complete hands-on lab that demonstrates building a custom Windows IIS Docker image, pushing it to Docker Hub, and deploying it as Pods in a **MicroK8s** Kubernetes cluster with Windows Server worker nodes.

---

## Overview

This project shows a full end-to-end workflow for running **Windows containers** (IIS) inside Kubernetes using Windows worker nodes.

**Key Technologies:**
- Windows Server 2025 LTSC
- Docker Windows Containers
- MicroK8s (Lightweight Kubernetes)
- Calico CNI
- MetalLB Load Balancer
- Hyper-V Isolated Containers
- Nested Virtualization

---

## Features

- Custom IIS Docker image with dynamic homepage (shows Pod Name, IP, CPU, OS info, etc.)
- Multi-stage Windows container build
- Mixed OS Kubernetes cluster (Linux control plane + multiple Windows workers)
- Support for both Process and Hyper-V isolation
- NodePort and LoadBalancer (MetalLB) service examples
- Automated container startup and page customization

---

## Visualization Diagrams

This lab includes the following conceptual diagrams to help you understand the underlying technologies:

### 01. CPU - User Mode vs Kernel Mode
![01-CPU-User-Kernel](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/01-CPU-User-Kernel.jpg)

Shows the fundamental separation between **User Mode** (where applications run) and **Kernel Mode** (where core OS components and device drivers operate). This is the foundation for understanding container isolation.

### 02. Hypervisor and Host Kernel Architecture
![02-Hypervisor-HostKernel](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/02-Hypervisor-HostKernel.jpg)

Illustrates the **Hyper-V** architecture layers: Hardware → Hypervisor (Level 0) → Host Windows Kernel → Guest OS. Critical for understanding how Windows containers run on top of the host.

### 03. Virtual Machines vs Containers
![03-VMS vs Containers](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/03-VMS%20vs%20Containers.jpg)

Classic side-by-side comparison showing why containers are much lighter than VMs — containers share the host OS kernel while VMs each have their own guest OS.

### 04. Windows Container Architecture
![04-Container-Kernel](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/04Container-Kernel.jpg)

Details the Windows container stack including **Dockerd**, **HCSv1/HCSv2**, **HNS** (Host Network Service), and how Kubernetes (kubelet) interacts with the Windows container runtime.

### 05. Process Isolation vs Hyper-V Isolation
![05-Process vs Hyper-V Isolation](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/05-Process%20vs.%20Hyper-V%20Isolation.jpg)

Explains the two Windows container isolation modes:
- **Process Isolation** (shared kernel — faster)
- **Hyper-V Isolation** (each container gets its own lightweight VM with isolated kernel — more secure)

### 06. Kubernetes Cluster Architecture (Master + Nodes)
![06-ClusterMaster](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/06-ClusterMaster.jpg)

Shows the relationship between the **Kubernetes Control Plane** (Linux) and **Worker Nodes** (supporting both Linux and Windows).

### 07. Kubernetes Overview - Pods, Containers, Nodes
![07-k8s-Overview](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/07-k8s-Overview.jpg)

Comprehensive overview of Kubernetes concepts: **Control Plane**, **Nodes**, **Pods**, and **Containers**.

### 08. Nested Virtualization
![08-Nesting](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/08-Nesting.jpg)

Explains **nested virtualization** — running Hyper-V inside another Hyper-V environment (important when running Windows containers inside VMs).

### 09. Docker Build Process (High Level)
![09-BuildDockerImage-Basic](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/09-BuildDockerImage-Basic.jpg)

High-level view of the Docker workflow: **Dockerfile → Docker Image → Docker Container**.

### 10. Docker Build Steps (Detailed)
![10-BuildDockerImage](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/10-BuildDockerImageFromDockerFile.jpg)

Step-by-step breakdown of creating and running Docker images.

### 11. Docker Workflow Diagram
![11-Docker build flow](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/Visualization%20Diagrams/11-Docker%20Workflow-DockerHub.jpg)

Technical flowchart showing the full Docker lifecycle from Dockerfile to pushing to Docker Hub and deploying to servers.

---

## Prerequisites

- Windows 11 / Windows Server host with Hyper-V enabled
- At least 16GB RAM recommended
- Windows Server 2025 evaluation ISO
- Ubuntu 26.04 Server ISO
- Docker Hub account
- Internet access

---

## YouTube Videos

### Latest Video
**AZ-800 Lab Video**  
[04 AZ 800 Containers, K8s, Nested VMs and Images built from Docker Files](https://youtu.be/S_TRvjmDOtg)

### Full Series Playlist
[26s-AZ-800 Labs Playlist](https://www.youtube.com/playlist?list=PLNCpp1kkXtdLMO55tSqb15Ra-CC6wAAcC)
