# MicroK8s Windows IIS Lab  
**Custom IIS Website using Docker + Windows Worker Nodes**

A complete hands-on lab that demonstrates building a custom Windows IIS Docker image, pushing it to Docker Hub, and deploying it as Pods in a **MicroK8s** Kubernetes cluster with Windows Server worker nodes.

---

## Overview

This project shows a full end-to-end workflow for running **Windows containers** (IIS) inside Kubernetes using a mixed Linux + Windows cluster.

**Key Technologies:**
- Windows Server 2025 LTSC
- Docker Windows Containers
- MicroK8s (Lightweight Kubernetes)
- Calico CNI
- MetalLB Load Balancer
- Hyper-V Isolated Containers

---

## Features

- Custom IIS Docker image with dynamic homepage (shows Pod Name, IP, CPU, OS info, etc.)
- Multi-stage Windows container build
- Mixed OS Kubernetes cluster (Linux control plane + multiple Windows workers)
- Support for both Process and Hyper-V isolation
- NodePort and LoadBalancer (MetalLB) service examples
- Automated container startup and page customization

---

## Repository Contents

| File                              | Description |
|-----------------------------------|-----------|
| `BuildAndPushImagefromDockerFile.ps1` | Builds custom IIS image and pushes to Docker Hub |
| `dockerfile.dockerfile`           | Dockerfile for the custom IIS website |
| `Startup.ps1`                     | PowerShell script that customizes the IIS homepage |
| `micro-k8s.ps1`                   | Full setup script for MicroK8s cluster + Windows nodes |
| `iis-simple.yaml`                 | Basic NodePort deployment |
| `iis-metallb.yaml`                | LoadBalancer deployment with MetalLB |

---

## Prerequisites

- Windows 11 / Windows Server host with Hyper-V enabled
- At least 32GB RAM recommended
- Windows Server 2025 evaluation ISO
- Ubuntu 26.04 Server ISO
- Docker Hub account
- Internet access

---

## Quick Start

### 1. Build and Push Custom Docker Image

```powershell
# Run on a Windows machine
.\BuildAndPushImagefromDockerFile.ps1
