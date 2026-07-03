# \# 26s-AZ800-Labs: Complete Hyper-V Lab Series for Windows Server Hybrid Administrator (AZ-800)

# 

# \*\*Author:\*\* Mark Kruse  

# \*\*Location:\*\* Anchorage, Alaska  

# \*\*GitHub:\*\* \[19BlueBomber87/26s-AZ800-Labs](https://github.com/19BlueBomber87/26s-AZ800-Labs)  

# \*\*YouTube Playlist:\*\* \[26s-AZ-800 Labs Playlist](https://www.youtube.com/playlist?list=PLNCpp1kkXtdLMO55tSqb15Ra-CC6wAAcC)

# 

# \---

# 

# \## Overview

# 

# This repository contains a complete, progressive set of \*\*Hyper-V lab environments\*\* designed for the \*\*AZ-800 Windows Server Hybrid Administrator\*\* certification, real-world enterprise skills, and hands-on learning. Labs are themed around Anchorage, Alaska (with Nome, Juneau, Eagle River, etc.) and use fun "moose" naming conventions.

# 

# \*\*Core Technologies Covered:\*\*

# \- Hyper-V + Golden Images + Quick VM Creation

# \- Multi-network RRAS Routing, DHCP, and NAT

# \- Complex Active Directory (Root, Tree, Child domains + separate forest with trusts)

# \- Entra ID Hybrid Identity (Entra Connect)

# \- Storage (NTFS/ReFS, Storage Spaces, S2D, Azure File Sync, Azure Arc)

# \- Windows Containers + Docker

# \- MicroK8s (mixed Linux/Windows workers) with custom IIS

# \- Full Kubernetes (kubeadm) multi-node Linux cluster with Calico, MetalLB, NGINX Ingress, and custom Nginx website

# 

# All labs are designed to run on a single Windows 10/11 or Windows Server host with Hyper-V.

# 

\---

Laboratory Prerequisites
===

This folder contains the core PowerShell scripts needed to build the foundational infrastructure for the **AZ-800 Hyper-V Lab Environments** (Anchorage, Alaska themed lab).

These scripts are designed to be run **in order** and prepare the networking, Active Directory, routing/NAT, and management tools required for the rest of the lab series.

\---

## 📁 Files Included

|File|Purpose|
|-|-|
|**QuickCreateDCwithUsers.ps1**|Creates the first Domain Controller (`ANC-DC01`), installs AD DS, promotes it to a DC for the root domain `minecraftmoose.com`, and creates a test OU with sample users (Mega Man themed).|
|**RRAS Setup.ps1**|Creates the RRAS server (`YAHOO-RRAS01`) with 6 network adapters, sets up multiple Hyper-V virtual switches, configures IP addressing, installs and configures **DHCP** (one scope per LAN), and enables **NAT/Routing** for internet access from all lab networks.|
|**wacOnServerCore.ps1**|Deploys **Windows Admin Center (WAC)** on a Server Core VM (`YAHOO-WAC01`), creates a Privileged Access Workstation (`YAHOO-PAW01`), and prepares everything for centralized management of the lab.|

\---

## 🛠️ Lab Architecture Overview

* **Primary Domain**: `minecraftmoose.com`
* **Root DC**: `ANC-DC01` (192.168.77.7)
* **RRAS Server**: `YAHOO-RRAS01` (multi-homed router + DHCP + NAT)
* **Networks**:

  * ANC-NET:     192.168.77.0/24   (`minecraftmoose.com`)
  * Nome-NET:    192.168.88.0/24   (`moosewyre.fun`)
  * JUN-NET:     192.168.99.0/24   (`megamooselabsfun.com`)
  * ER-NET:      192.168.100.0/24  (`megamooseforge.com`)
  * LINUX-NET:   192.168.11.0/24   (`yahoomoose.com`)
* **External Switch**: `EXT-INT` (connected to host's Wi-Fi for internet)

\---

## 📋 Recommended Execution Order

1. **QuickCreateDCwithUsers.ps1**  
→ Builds the root domain and creates test users.
2. **RRAS Setup.ps1**  
→ Creates the multi-homed RRAS server, all virtual switches, DHCP scopes, and NAT routing.
3. **wacOnServerCore.ps1**  
→ Deploys Windows Admin Center and management workstations.

> \*\*Tip\*\*: Run these scripts from your Hyper-V host (Windows 10/11 Pro or Server with Hyper-V enabled).

\---

## 🔗 Dependencies

* [New-Lab\_VM function](https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/HyperV%20Lab%20Creation%20and%20Disk%20Functions.ps1)  
(Required — must be loaded before running any of these scripts)
* Generalized Windows Server images (Desktop Experience + Server Core)
* Sufficient RAM and disk space on the Hyper-V host
* Internet access on the host

\---

## 💡 Notes \& Best Practices

* All scripts include extensive `-Verbose` output for easier troubleshooting.
* Firewall rules for ICMP (ping) are added for lab convenience.
* DHCP exclusions are set for .1–.9 in each scope (reserved for static servers).
* NAT is configured using both `New-NetNat` and legacy `netsh` commands for maximum compatibility.
* Windows Admin Center is installed on Server Core and accessed via HTTPS.

\---

## 📍 Lab Location Theme

All labs are themed around **Anchorage, Alaska** and surrounding areas (Nome, Juneau, Eagle River) with fun "moose" and "yahoo" naming conventions.

\---

## Next Steps

After completing the scripts in this folder, continue with the rest of the **26s-AZ800-Labs** series:

* Domain Controller additional setups
* Entra ID / Hybrid Identity labs
* Group Policy, DHCP failover, etc.

\---

**Author**: Mark Kruse  
**Location**: Anchorage, Alaska  
**GitHub**: [19BlueBomber87](https://github.com/19BlueBomber87)

\---

## YouTube Videos

### Latest Video

**AZ-800 Lab Video**  
[AZ 800 Hyper-V Windows Server as Lab Router, PromoteDC, DomainJoin and WAC Demo](https://youtu.be/XytLCQXKcNU?si=GKiYzkb9bvpOMRPH)

### Full Video Series Playlist

## [26s-AZ-800 Labs Playlist](https://www.youtube.com/playlist?list=PLNCpp1kkXtdLMO55tSqb15Ra-CC6wAAcC)

**Happy Lab Building!** 🧪❄️



# Hyper-V Lab: Active Directory Domain Services \& Entra Connect Lab

This Hyper-V lab environment allows you to build a complex, multi-domain Active Directory infrastructure. The lab consists of two forests connected together by a "forest trust". One of the forests contains a root domain, a tree domain, and a child domain (The root, tree and child domains share an "AD DS Schema"). Once the AD DS environment is built, we will configure Entra Connect to synchronize all users to Entra ID.

\---

## Overview

This project automates the deployment of:

* 4 Domain Controllers across multiple networks
* Root Domain: `minecraftmoose.com`
* Tree Domain: `moosewyre.fun`
* Child Domain: `dev.moosewyre.fun`
* Separate Forest: `megamooselabsfun.com`
* Two-way Forest Trust between the forests
* AD Sites \& Subnets
* Bulk creation of realistic test users in custom OUs

!\[Domain Trust Plan](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/01-AD%20DS%20Domain%20Trust%20Plan.png)



\---

## Features

* How to create and promote Domain Controllers
* Complex AD structure (Root, Tree, Child, Separate Forest)
* Conditional DNS forwarders
* Two-way Forest Trust
* Automated test user creation with custom "Entra Synced Users" OU
* Mega Man themed users for fun lab testing
* Use Windows Admin Center to manage environment

\---

## Prerequisites

* Windows 10/11 or Windows Server with Hyper-V enabled
* New-Lab\_VM function (from the HyperV helper script in the repo)
* Generalized Windows Server images (Desktop Experience)
* At least 16GB RAM, 32GB recommended for smooth performance
* Hyper-V Windows Server acting as a router
* Azure Tenant(Entra ID - Ownership of domain names used in AD DS domains)

\---

## How to Use

Follow the detailed comments inside each script.

\---

## Lab Architecture

|Server|Domain/Forest|IP Address|Role|
|-|-|-|-|
|ANC-DC01|minecraftmoose.com (Root)|192.168.77.7|Root Domain Controller|
|Nome-DC01|moosewyre.fun (Tree)|192.168.88.8|Tree Domain Controller|
|ER-DC01|dev.moosewyre.fun (Child)|192.168.100.9|Child Domain Controller|
|JUN-DC01|megamooselabsfun.com|192.168.99.9|Forest Root DC|

!\[Network Topology](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/00-NetworkTopologyDiagram.jpg)

!\[Full Mesh Basic Diagram](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/02-Mesh-BasicDiagram.jpg)

\---

## Hybrid Identity with Entra ID

This lab is designed for testing hybrid identity scenarios including Password Hash Sync and multi-forest synchronization to a single Entra ID tenant.
!\[Full Mesh Topology - IP Ranges](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/EntraConnect02.jpg)

!\[Multiple Forests, Single Entra Tenant](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/EntraConnect01.png)

!\[Azure AD Hybrid Identity with Password Hash Sync](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/Password%20Hash%20Sync-EntraID.jpg)

\---

## Default Credentials

* Safe Mode / DSRM Password: `P@ssword1!`
* Test User Password: `Password123!`

\---

## Author

**Mark Kruse**  
GitHub: https://github.com/19BlueBomber87  
X: [@19BlueBomber87](https://x.com/19BlueBomber87)

\---

## YouTube Videos

### Latest Video

**AZ-800 Lab Video**  
[Active Directory Domain Services \& Entra Connect Lab Video](https://youtu.be/cQnUAGSW8Qs)

### Full Video Series Playlist

[26s-AZ-800 Labs Playlist](https://www.youtube.com/playlist?list=PLNCpp1kkXtdLMO55tSqb15Ra-CC6wAAcC)
⭐ Star the repo if this lab helped you!



# MicroK8s with Windows Worker Nodes to Run IIS Lab

**Custom IIS Website. Uses a custom image built from Docker + Windows Worker Nodes**

A complete hands-on lab that demonstrates building a custom Windows IIS Docker image, pushing it to Docker Hub, and deploying it as Pods in a **MicroK8s** Kubernetes cluster with Windows Server worker nodes.

\---

## Overview

This project shows a full end-to-end workflow for running **Windows containers** (IIS) inside Kubernetes using Windows worker nodes.

**Key Technologies:**

* Windows Server 2025 LTSC
* Docker Windows Containers
* MicroK8s (Lightweight Kubernetes)
* Calico CNI
* MetalLB Load Balancer
* Hyper-V Isolated Containers
* Nested Virtualization

\---

## Features

* Custom IIS Docker image with dynamic homepage (shows Pod Name, IP, CPU, OS info, etc.)
* Multi-stage Windows container build
* Mixed OS Kubernetes cluster (Linux control plane + multiple Windows workers)
* Support for both Process and Hyper-V isolation
* NodePort and LoadBalancer (MetalLB) service examples
* Automated container startup and page customization

\---

## Visualization Diagrams

This lab includes the following conceptual diagrams to help you understand the underlying technologies:

### 01\. CPU - User Mode vs Kernel Mode

!\[01-CPU-User-Kernel](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/01-CPU-User-Kernel.jpg)

Shows the fundamental separation between **User Mode** (where applications run) and **Kernel Mode** (where core OS components and device drivers operate). This is the foundation for understanding container isolation.

### 02\. Hypervisor and Host Kernel Architecture

!\[02-Hypervisor-HostKernel](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/02-Hypervisor-HostKernel.jpg)

Illustrates the **Hyper-V** architecture layers: Hardware → Hypervisor (Level 0) → Host Windows Kernel → Guest OS. Critical for understanding how Windows containers run on top of the host.

### 03\. Virtual Machines vs Containers

!\[03-VMS vs Containers](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/03-VMS%20vs%20Containers.jpg)

Classic side-by-side comparison showing why containers are much lighter than VMs — containers share the host OS kernel while VMs each have their own guest OS.

### 04\. Windows Container Architecture

!\[04-Container-Kernel](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/04Container-Kernel.jpg)

Details the Windows container stack including **Dockerd**, **HCSv1/HCSv2**, **HNS** (Host Network Service), and how Kubernetes (kubelet) interacts with the Windows container runtime.

### 05\. Process Isolation vs Hyper-V Isolation

!\[05-Process vs Hyper-V Isolation](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/05-Process%20vs.%20Hyper-V%20Isolation.jpg)

Explains the two Windows container isolation modes:

* **Process Isolation** (shared kernel — faster)
* **Hyper-V Isolation** (each container gets its own lightweight VM with isolated kernel — more secure)

### 06\. Kubernetes Cluster Architecture (Master + Nodes)

!\[06-ClusterMaster](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/06-ClusterMaster.jpg)

Shows the relationship between the **Kubernetes Control Plane** (Linux) and **Worker Nodes** (supporting both Linux and Windows).

### 07\. Kubernetes Overview - Pods, Containers, Nodes

!\[07-k8s-Overview](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/07-k8s-Overview.jpg)

Comprehensive overview of Kubernetes concepts: **Control Plane**, **Nodes**, **Pods**, and **Containers**.

### 08\. Nested Virtualization

!\[08-Nesting](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/08-Nesting.jpg)

Explains **nested virtualization** — running Hyper-V inside another Hyper-V environment (important when running Windows containers inside VMs).

### 09\. Docker Build Process (High Level)

!\[09-BuildDockerImage-Basic](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/b5802a0f296e7672c6a46dcc1c2dbf44ceee840c/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/09-BuildDockerImage-Basic.jpg)

High-level view of the Docker workflow: **Dockerfile → Docker Image → Docker Container**.

### 10\. Docker Build Steps (Detailed)

!\[10-BuildDockerImage](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/10-BuildDockerImageFromDockerFile.jpg)

Step-by-step breakdown of creating and running Docker images.

### 11\. Docker Workflow Diagram

!\[11-Docker build flow](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Docker-Microk8s2RunIIS\_CustomImageFromDockerFile/Visualization%20Diagrams/11-Docker%20Workflow-DockerHub.jpg)

Technical flowchart showing the full Docker lifecycle from Dockerfile to pushing to Docker Hub and deploying to servers.

\---

## Prerequisites

* Windows 11 / Windows Server host with Hyper-V enabled
* At least 16GB RAM recommended
* Windows Server 2025 evaluation ISO
* Ubuntu 26.04 Server ISO
* Docker Hub account
* Internet access

\---

## YouTube Videos

### Latest Video

**AZ-800 Lab Video**  
[AZ 800 Containers, K8s, Nested VMs and Images built from Docker Files Video](https://youtu.be/S_TRvjmDOtg)

### Full Video Series Playlist

[26s-AZ-800 Labs Playlist](https://www.youtube.com/playlist?list=PLNCpp1kkXtdLMO55tSqb15Ra-CC6wAAcC)



# RRAS \& DHCP Multi-Network Setup

**File:** `RRAS Setup.ps1`

This script builds the core networking infrastructure for the entire Hyper-V lab environment.

It creates a multi-homed **RRAS server** that acts as a router, DHCP server, and NAT gateway for five separate isolated lab networks.

\---

## Purpose

* Create and configure the central **YAHOO-RRAS01** server
* Set up multiple private Hyper-V virtual switches (one per LAN)
* Configure DHCP scopes for each network
* Enable routing and NAT so all lab VMs can access the internet
* Prepare the foundation for domain controllers and other servers in each subnet

\---

## Lab Networks Created

|Network Name|Subnet|Default Gateway|DHCP Scope|Associated Domain|
|-|-|-|-|-|
|ANC-NET|192.168.77.0/24|192.168.77.1|Anchorage-NET-Scope|minecraftmoose.com|
|Nome-NET|192.168.88.0/24|192.168.88.1|Nome-NET-Scope|moosewyre.fun|
|JUN-NET|192.168.99.0/24|192.168.99.1|Juneau-NET-Scope|megamooselabsfun.com|
|ER-NET|192.168.100.0/24|192.168.100.1|EagleRiver-NET-Scope|megamooseforge.com|
|LINUX-NET|192.168.11.0/24|192.168.11.1|yahoomoose.com-NET-Scope|yahoomoose.com|

**External Interface:** `EXT-INT` (connected to host Wi-Fi for internet access)

\---

## Prerequisites

* Hyper-V enabled on the host
* The `New-Lab\_VM` function loaded (from the HyperV-QuickCreate-GoldenImages folder)
* A generalized Windows Server Desktop Experience golden image
* Sufficient RAM and storage on the host
* Internet access on the Hyper-V host

\---

## Execution Steps (in order)

1. **Create the RRAS VM** with 6 network adapters
2. **Create Hyper-V Switches** (uses `CreateLabSwitches` function or manual creation)
3. **Rename computer** and configure network adapter names + disable IPv6
4. **Match virtual adapters** (verify MAC addresses between host and guest)
5. **Assign static IPs** and DNS on RRAS interfaces
6. **Install DHCP + Remote Access** roles
7. **Configure 5 DHCP scopes** with proper options and exclusions
8. **Configure Routing \& NAT** (using both `New-NetNat` and `netsh`)
9. **Create test VMs** in each network to validate DHCP and internet connectivity

\---

## Key Features

* Automatic adapter renaming and IPv6 disabling
* Detailed MAC address matching section for troubleshooting
* DHCP exclusions (.1 – .9) reserved for static servers
* Full NAT configuration for internet access from all internal networks
* ICMP ping allowed on RRAS for easy testing
* Comprehensive verbose output for troubleshooting

\---

## Important Notes

* The script assumes the RRAS VM is created on the `ER-NET` switch initially.
* After running, verify NAT with `Get-NetNat` and `netsh routing ip nat show interface`
* DNS servers in DHCP scopes point to the future domain controllers (adjust if needed)
* Run this script **after** the root domain controller (`minecraftmoose.com`) is online if possible



## YouTube Videos

### Latest Video

**AZ-800 Lab Video**  
[AZ 800 Hyper-V Windows Server as Lab Router, PromoteDC, DomainJoin and WAC Demo](https://youtu.be/XytLCQXKcNU?si=GKiYzkb9bvpOMRPH)

### Full Video Series Playlist

## [26s-AZ-800 Labs Playlist](https://www.youtube.com/playlist?list=PLNCpp1kkXtdLMO55tSqb15Ra-CC6wAAcC)

## Author

Mark Kruse  
Anchorage, Alaska

\---



# Hyper-V Lab Creation - Quick Create Tools

A powerful set of PowerShell tools designed to quickly build, manage, and reset Hyper-V lab environments — ideal for learning, testing, and certification labs (AZ-800, AZ-801, AZ-802, etc.).

Created and maintained by **Mark Kruse** in Anchorage, Alaska.

\---

## Features

* **Quick VM Creation** (`New-Lab\_VM`)

  * Create VMs from Windows Server ISO (clean install)
  * Create VMs from generalized **Desktop Experience** or **Server Core** golden images
  * Support for creating multiple VMs at once
  * Configurable RAM, vCPU count, dynamic memory
  * Add multiple network adapters during creation
  * Function to add extra data disks
* **Add Extra Disks** (`Add-Disks2VM`)

  * Easily attach multiple identically sized data disks to an existing VM
* **Initialize Raw Disks** (`Initialize-RawOfflineDisks`)

  * Quickly initialize, partition, and format offline RAW disks inside a VM (ReFS)
* **Lab Networking** (`CreateLabSwitches`)

  * Creates standard isolated lab switches (`ANC-Net`, `Nome-Net`, `JUN-Net`, `ER-Net`, `LINUX-Net`)
  * Creates one external switch (`EXT-INT`) bound to Wi-Fi with host management enabled
* **Lab Reset** (`\_ResetLabNow`)

  * Destructive "nuke everything" function to start completely fresh
* **Power Management**

  * `SaveAllRunningVMs` – Quickly save (suspend) all running VMs for fast resume

\---

## Prerequisites

* Windows 10 / 11 Pro or Enterprise (or Windows Server) with **Hyper-V** enabled
* Run **PowerShell as Administrator**
* At least one Wi-Fi or Ethernet adapter for the external switch

## 🔗 Dependencies

* [GoldenImage.ps1](https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/GoldenImage.ps1)
* [Unattend.xml](https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/unattend.xml)

\---

## Setup Instructions

1. **Enable Hyper-V** (if not already enabled)
2. Clone or download this repository
3. Place your golden images in `C:\\GoldenImages\\`:

   * `GoldenImage-DesktopExperience.vhdx`
   * `GoldenImage-ServerCore.vhdx`
4. (Optional) Place your Windows Server evaluation ISO in `C:\\ISO\\`
5. Open PowerShell **as Administrator**
6. Dot-source the script:

. ".\\HyperV Lab Creation and Disk Functions.ps1"

Usage Examples

1. Create Lab Networking
PowerShellCreateLabSwitches
2. Create VMs from Golden Image (Recommended)
PowerShell# Two Domain Controllers from Server Core golden image
New-Lab\_VM -VMNames "DC01","DC02" -HyperVSwitch "ANC-Net" -RAM 4GB -GeneralizedImageCore
New-Lab\_VM -VMNames "FS01" -HyperVSwitch "JUN-Net" -RAM 6GB -nonOSdiskcount 6 -nonOSdiskSizeGB 200 -GeneralizedImageDE
3. Create VM from ISO
PowerShell$iso = "C:\\ISO\\SERVER\_EVAL\_x64FRE\_en-us.iso"
New-Lab\_VM -VMNames "ANC-RRAS01" -HyperVSwitch "EXT-INT" -AdapterCount 6 -ISOPath $iso
4. Add Extra Disks to Existing VM
PowerShellAdd-Disks2VM -VMName "FS01" -DiskSetName "Data" -DiskCount 4 -DiskSize 500
5. Initialize Disks (Run inside the VM)
PowerShellInitialize-RawOfflineDisks
6. Save All Running VMs (Fast suspend)
PowerShellSaveAllRunningVMs
7. Full Lab Reset (Destructive!)
PowerShell\_ResetLabNow

Golden Image Preparation
See the included comments in the script or the companion script:

GoldenImage.ps1 (in the repo)

* [GoldenImage.ps1](https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/GoldenImage.ps1)  
Key steps:

Build a reference VM
Run sysprep.exe /generalize /oobe /shutdown
Copy the resulting .vhdx to C:\\GoldenImages  
Rename to GoldenImage-DesktopExperience.vhdx or GoldenImage-ServerCore.vhdx



Important Notes

All functions must be run as Administrator
The script is designed to be safe to rerun (idempotent where possible)
\_ResetLabNow is destructive — use with caution
Change the Wi-Fi adapter name in CreateLabSwitches if needed



Author
Mark Kruse
Anchorage, Alaska
GitHub: 19BlueBomber87

License
This project is open-source and free to use for personal and educational purposes.

Happy Lab Building! 🚀

# Hyper-V Golden Image Preparation

PowerShell script and supporting files to create **generalized golden images** for fast VM deployment in Hyper-V labs.

Author: **Mark Kruse**  
Location: Anchorage, Alaska

\---

## Purpose

This script helps you build reusable, sysprepped golden images for:

* **GoldenImage-DesktopExperience.vhdx** (Full GUI)
* **GoldenImage-ServerCore.vhdx** (Server Core)

These images are then used by the main `New-Lab\_VM` function for extremely fast VM creation.

\---

## Files Included

* `GoldenImage.ps1` – Main preparation script
* `unattend.xml` – Unattend file used during sysprep (creates local accounts, sets timezone, etc.) AKA: Unattend Answer File
* Main wallpaper image (Main.jpg) – Optional custom background

\---

## Prerequisites

* Hyper-V enabled on Windows 10/11 Pro or Windows Server
* Windows Server 2025 Evaluation ISO (or newer)
* PowerShell running **as Administrator**
* Internet access (for downloading Python and wallpaper)

\---

\---

## YouTube Videos

### Latest Video

**AZ-800 Lab Video**  
[AZ 800 Labs HyperV VMQuickCreate GoldenImages DiskFunctions](https://youtu.be/bEgB61Q-PMs?si=Sq0qTz3u5t8s_WbP)

### Full Video Series Playlist

[26s-AZ-800 Labs Playlist](https://www.youtube.com/playlist?list=PLNCpp1kkXtdLMO55tSqb15Ra-CC6wAAcC)

## Step-by-Step Guide

### 1\. Create Base VMs (First Run)

Run the following commands from `GoldenImage.ps1`:

```powershell
# Creates two temporary VMs for golden image preparation
New-Lab\_VM -VMNames GoldenImage-ServerCore -HyperVSwitch EXT-INT -ISOPath "C:\\ISO\\2025\_26100.32230.260111-0550.lt\_release\_svc\_refresh\_SERVER\_EVAL\_x64FRE\_en-us.iso"

New-Lab\_VM -VMNames GoldenImage-DesktopExperience -HyperVSwitch EXT-INT -ISOPath "C:\\ISO\\2025\_26100.32230.260111-0550.lt\_release\_svc\_refresh\_SERVER\_EVAL\_x64FRE\_en-us.iso"
Tip: Update the ISO path to match your actual ISO filename and location.
2. Prepare the Golden Image (Inside the VM)
Start the VM and perform these steps manually:

At the first OOBE screen, press CTRL + SHIFT + F3 to enter Audit Mode.
Install latest Windows Updates.
(Optional) Install any tools or applications you want in the golden image.
(Desktop Experience only) Set custom wallpaper if desired.

3. Run Golden Image Preparation Script (Inside the VM)
Inside the VM (still in Audit Mode), run:
PowerShell# Download and run the preparation script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/GoldenImage.ps1" -OutFile "C:\\GoldenImage.ps1"
.\\GoldenImage.ps1
The script will automatically:

Install Python 3.12.6 (silent install)
Create Unicode test files (yahoo.py section)
Download and place MegaMan.jpg custom wallpaper (Desktop Experience only)
Download unattend.xml to "C:\\windows\\System32\\Sysprep"
Run Sysprep with /generalize /oobe /shutdown /unattend
C:\\windows\\System32\\Sysprep\\sysprep.exe /generalize /oobe /shutdown /unattend:C:\\Windows\\System32\\Sysprep\\unattend.xml

The VM will shut down automatically when sysprep completes.
4. Finalize Golden Image
After the VM shuts down:

In Hyper-V Manager, right-click the VM → Delete (do not delete the VHDX).
Locate the VHDX file:
C:\\ProgramData\\Microsoft\\Windows\\Virtual Hard Disks\\GoldenImage-DesktopExperience.vhdx
C:\\ProgramData\\Microsoft\\Windows\\Virtual Hard Disks\\GoldenImage-ServerCore.vhdx

Copy and rename it to:

cmdC:\\GoldenImages\\GoldenImage-DesktopExperience.vhdx
C:\\GoldenImages\\GoldenImage-ServerCore.vhdx
Make sure the folder C:\\GoldenImages\\ exists.
5. Test the Golden Images
PowerShell# Test Desktop Experience golden image
New-Lab\_VM -VMNames "Test-DE" -HyperVSwitch "ANC-Net" -RAM 4GB -GeneralizedImageDE

# Test Server Core golden image
New-Lab\_VM -VMNames "Test-Core" -HyperVSwitch "ANC-Net" -RAM 4GB -GeneralizedImageCore

What the unattend.xml Does

Sets timezone to Alaskan Standard Time
Creates local Administrator account: MegaMan (password: Taz14Spaz!@#)
Creates standard user account: Rush
Skips EULA and online account screens
Enables CopyProfile during specialize pass


Important Notes

Always run sysprep from Audit Mode (CTRL+SHIFT+F3 at OOBE).
The golden images must be generalized — never boot them directly after sysprep.
You can rerun the entire process anytime you want to update the golden images.
The Python section is optional and mainly used for Unicode/character testing in labs.


Happy Lab Building!


# Storage - AZ-800 Labs

This section covers core \*\*Storage\*\* concepts for the Windows Server Hybrid Administrator (AZ-800) certification. It includes file systems, sectors/allocation units, Storage Spaces, Storage Spaces Direct (S2D), SMB 3.0, Failover Clustering, and hybrid file server solutions with Azure Files.

Perfect for hands-on lab work, exam prep, and real-world enterprise storage design.

## What is a File System?

A file system is the method and data structure that an operating system uses to control how data is stored and retrieved on a storage device. It defines the rules for organizing files in a hierarchical structure, managing file names, formats, permissions, and metadata.

All Windows file systems are built around three core storage components:
- \*\*Files\*\* — A logical unit that contains related data.
- \*\*Directories (Folders)\*\* — Containers used to organize files and other directories.
- \*\*Volumes\*\* — Logical partitions that hold directories and files.

!\[Windows File System Types](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/01-WhatIsAFileSystem.jpg)

### Windows File System Types

#### FAT, FAT32, and exFAT
Oldest and simplest. Not suitable for production servers (no file-level security). Best for removable media.

#### NTFS (NT File System)
The standard for Windows Server. Required for AD DS and most server roles.

\*\*Key Features:\*\*
- ACLs, auditing, granular permissions
- Journaling for crash recovery
- Compression and EFS (mutually exclusive)
- Disk quotas, hard links, symbolic links

#### ReFS (Resilient File System)
Microsoft’s modern file system for high reliability and large-scale storage.

\*\*Strengths:\*\*
- Excellent data integrity and online repair
- Massive volume/file support (up to 35 PB+)
- Block-level deduplication
- Optimized for virtualized workloads

\*\*Recommended\*\* for data volumes in Windows Server 2025.

!\[What is A File System](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/02-WindowsFileSystemTypes.jpg)

## Sectors and Allocation Units

!\[Sector Allocation units](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/03-SectorAllocationUnits.jpg)

\*\*Sector\*\* = Smallest physical unit the disk can read/write (usually 4 KB on modern drives).

\*\*Cluster (Allocation Unit)\*\* = Smallest amount of disk space a file system can allocate to a file.

!\[Physical vs. Logical Sector Size](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/04-Physical%20vs.%20Logical%20SectorSize.jpg)

\*\*Best Practice:\*\* Match cluster size to your workload and ensure alignment with physical sectors.

## Storage Spaces (Normal / Traditional)

!\[Storage Spaces Overview](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/05-StorageSpaces.jpg)

Storage Spaces is Microsoft’s software-defined storage feature (introduced in Windows Server 2012). It pools physical disks and creates resilient virtual disks.

\*\*Key Features:\*\*
- Storage Pools (groups of disks)
- Virtual Disks with resiliency: Simple, Mirror (2/3-way), Parity (single/dual)
- Thin provisioning and tiering (SSD + HDD)
- Single-server only

\*\*Limitations:\*\* No automatic failover across servers.

\*\*Regular Storage Spaces does NOT require SMB 3.0\*\* — storage is local to one server.


## Horizontal Scaling vs Vertical Scaling

Horizontal scaling is often considered more cost-effective because you can grow incrementally using commodity hardware, while vertical scaling usually requires increasingly expensive high-end hardware.

### Why Horizontal Scaling Can Be More Cost-Effective

\* Scale gradually: Add servers only when needed.
\* Use cheaper hardware: Several standard servers are often less expensive than one high-performance enterprise server.
\* Avoid large upfront investments: Buy one additional server instead of replacing an entire server.
\* Better availability: If one server fails, others continue serving users.
\* Lower upgrade risk: Adding a node is typically easier than migrating to a larger server.
\* Cloud-friendly: Easily add or remove instances in Azure, AWS, etc.

!\[Vertical Scaling vs Horizontal Scaling](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/05.1-Vertical%20scaling%20vs.Horizontal%20scaling.jpg)



## SMB (Server Message Block)

!\[SMB](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/06-SMB.jpg)

SMB is the standard Windows file-sharing protocol.

\*\*SMB 3.0+ Key Enhancements:\*\*
- \*\*SMB Direct (RDMA)\*\* — Low-latency, low-CPU data transfers
- \*\*SMB Multichannel\*\* — Uses multiple NICs for bandwidth + redundancy

## Storage Spaces Direct (S2D)

!\[S2D](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/07-S2D.jpg)

S2D is Microsoft’s hyper-converged software-defined storage (Windows Server 2016+). It pools local disks across multiple cluster nodes.

\*\*Requires:\*\*
- Windows Failover Clustering
- SMB 3.0+ (Software Storage Bus)
- Recommended: 10 GbE+ with RDMA

\*\*Benefits:\*\* High availability, scalability (2–16 nodes), tiering, deduplication, etc.

## Failover Clustering

!\[Fail Over Cluster ADDS](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/08-FailOverCluster-%20ADDS.jpg)

Failover Clustering provides high availability by allowing multiple servers (nodes) to act as one system. Essential for S2D.

\*\*Core Components:\*\*
- Cluster Nodes (same AD domain)
- Cluster Shared Volumes (CSV)
- Networks (Management, Heartbeat, Live Migration)
- Quorum (Disk, File Share, Cloud Witness)

## Hybrid File Server Infrastructure with Azure Files

!\[Hybrid File Server Infrastructure](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/09-Hybrid%20File%20Server%20Infrastructure.jpg)

\*\*Azure Files\*\* — Fully managed, serverless file shares in Azure (SMB, NFS, REST).

\*\*Azure File Sync\*\* — Syncs Azure Files with on-premises servers for hybrid scenarios:
- Cloud tiering
- Multi-site sync
- Cloud backup \& snapshots
- Disaster recovery

## Azure Arc + RBAC

\*\*Azure Arc\*\* extends Azure’s security, governance, and cloud-native services to your hybrid, multicloud, and edge environments — including Windows/Linux servers, Kubernetes clusters, SQL Servers, and more.

Once onboarded, Arc-enabled resources become native Azure Resource Manager (ARM) resources, giving you \*\*full Azure RBAC support\*\*.

!\[RBAC Basics](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/10-RBAC-BasicDiagram.jpg)

!\[Azure Arc Overview](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/11-AzArc.jpg)

### Key Capabilities
- Azure Policy (guest configuration)
- Microsoft Defender for Cloud
- Microsoft Sentinel
- Azure Monitor
- Azure RBAC at any scope

\*\*Example:\*\* Grant the Operations team \*Contributor\* access on an Arc Resource Group, while Auditors get \*Reader\* access.

## Lab Recommendations
- Build Storage Spaces labs (single server)
- Deploy a 2-node S2D cluster with Failover Clustering
- Configure Azure File Sync for hybrid scenarios
- Practice NTFS vs ReFS formatting and performance testing

---

\*\*Repo:\*\* \[26s-AZ800-Labs](https://github.com/19BlueBomber87/26s-AZ800-Labs)  


## YouTube Videos

### Latest Video
\*\*AZ-800 Lab Video\*\*  
\[AZ 800 Storage Storage Spaces, S2D, Vertical and Horizontal Scaling, ReFs and AZ File sync](https://youtu.be/IGe08UdTjTc?si=v0\_gpRzbe1Qm5hBJ)

### Full Video Series Playlist
\[26s-AZ-800 Labs Playlist](https://www.youtube.com/playlist?list=PLNCpp1kkXtdLMO55tSqb15Ra-CC6wAAcC)


# Kubernetes Lab: Multi-Node k8s Cluster with Linux Workers Serving a Custom Nginx Website

## Overview
This lab guides you through building a \*\*Kubernetes (k8s) cluster\*\* using \*\*kubeadm\*\* on Ubuntu Linux. It includes:

- 1 Control Plane node
- Multiple Linux Worker nodes
- \*\*containerd\*\* as the container runtime
- Calico as the CNI networking plugin
- MetalLB + NGINX Ingress for Load Balancing
- A custom static website served via scaled \*\*Nginx\*\* pods

The goal is to demonstrate \*\*container orchestration\*\* in action — deploying, scaling, and accessing a real web application across multiple nodes.

---

## Visualization Diagrams

### 1. Processor Modes (CPU Rings)
!\[Processor Modes](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/k8s2ServeCustomeNginxWebsite/Visualization%20Diagrams/01-CPU-User-Kernel.jpg)

Shows the different privilege levels (rings) of a CPU. The kernel runs in Ring 0 (highest privilege), while user applications run in Ring 3. This is foundational for understanding how containers and VMs achieve isolation.

### 2. Virtual Machines vs Containers
!\[VMs vs Containers](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/k8s2ServeCustomeNginxWebsite/Visualization%20Diagrams/02-VMS%20vs%20Containers.jpg)

Compares traditional VMs (each with its own guest OS and kernel) to Containers (which share the host kernel). Containers are much lighter and more efficient — the core reason Kubernetes can run hundreds of workloads on modest hardware.

### 3. Kubernetes Control Plane (Master Node)
!\[Cluster Master](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/k8s2ServeCustomeNginxWebsite/Visualization%20Diagrams/03-ClusterMaster.jpg)

Illustrates the Kubernetes architecture. The \*\*Control Plane\*\* (API Server) receives commands from the administrator and schedules work. \*\*Kubelet\*\* on each Node works with the container runtime to run Pods.

### 4. Nodes, Pods and Containers
!\[Nodes, Pods and Containers](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/k8s2ServeCustomeNginxWebsite/Visualization%20Diagrams/04-k8s-Overview.jpg)

Shows the hierarchy: A \*\*Node\*\* runs the Kubelet + container runtime. The Kubelet manages \*\*Pods\*\*, which are the smallest deployable units containing one or more containers.

---

## Prerequisites

- Hyper-V Host (Windows 10/11 or Server)
- `New-Lab\_VM` function from your lab repo
- Ubuntu 26.04 ISO
- At least 8–16 GB RAM on the host
- External Hyper-V Switch recommended

## Lab Steps (Summary)

1. \*\*Create VMs\*\* using the provided PowerShell script (`k8s2ServeNginx.ps1`)
2. Install OS on Control Plane (`k8s`) and Worker nodes (`k8s-node01`, `k8s-node02`, ...)
3. Run `initialConfig.sh` on every node (installs containerd + Kubernetes tools)
4. Initialize the Control Plane with `kubeadm init`
5. Join worker nodes with `kubeadm join`
6. Install Calico CNI
7. Deploy \*\*MetalLB\*\* + \*\*NGINX Ingress Controller\*\*
8. Deploy the custom Nginx website (with dynamic content pulled from GitHub)

## Key Files

- \*\*`initialConfig.sh`\*\* → Prepares each Linux node (containerd, kube tools, sysctl, swap disable)
- \*\*`k8s2ServeNginx.ps1`\*\* → Main automation script for VM creation and high-level steps

---

## Accessing the Website

After deployment, use the \*\*MetalLB External IP\*\* (e.g. `192.168.11.200`) in your browser. Refresh to see different pods serving requests (load balancing in action).

You can scale the deployment live:

```bash
kubectl scale deployment custom-static-site --replicas=20
```

## YouTube Videos

### Latest Video

**AZ-800 Lab Video**  
[AZ 800 Containers, K8s, Nested VMs and Images built from Docker Files](https://youtu.be/S_TRvjmDOtg?si=6-V1MTjo56cJn3oB)

### Full Video Series Playlist

## [26s-AZ-800 Labs Playlist](https://www.youtube.com/playlist?list=PLNCpp1kkXtdLMO55tSqb15Ra-CC6wAAcC)

## Author

**Mark Kruse**  
GitHub: https://github.com/19BlueBomber87  
X: [@19BlueBomber87](https://x.com/19BlueBomber87)

\---

⭐ Star the repo if this lab helped you!

