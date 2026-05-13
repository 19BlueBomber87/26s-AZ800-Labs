# Hyper-V Lab: Active Directory Domain Services & Entra Connect Lab

This Hyper-V lab environment allows you to build a complex, multi-domain Active Directory infrastructure. The lab consists of two forests connected together by a "forest trust". One of the forests contains a root domain, a tree domain, and a child domain (The root, tree and child domains share an "AD DS Schema"). Once the AD DS environment is built, we will configure Entra Connect to synchronize all users to Entra ID.

---

## Overview

This project automates the deployment of:
- 4 Domain Controllers across multiple networks
- Root Domain: `minecraftmoose.com`
- Tree Domain: `moosewyre.fun`
- Child Domain: `dev.moosewyre.fun`
- Separate Forest: `megamooselabsfun.com`
- Two-way Forest Trust between the forests
- AD Sites & Subnets
- Bulk creation of realistic test users in custom OUs

![Domain Trust Plan](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/01-AD%20DS%20Domain%20Trust%20Plan.png)


---

## Features

- Domain Controller creation and promotion
- Complex AD structure (Root, Tree, Child, Separate Forest)
- Conditional DNS forwarders
- Two-way Forest Trust
- Automated test user creation with custom "Entra Synced Users" OU
- Mega Man themed users for fun lab testing
- Use Windows Admin Center to manage environment

---

## Prerequisites

- Windows 10/11 or Windows Server with Hyper-V enabled
- New-Lab_VM function (from the HyperV helper script in the repo)
- Generalized Windows Server images (Desktop Experience)
- At least 16GB RAM, 32GB recommended for smooth performance

---

## How to Use

1. Go to the folder: `/ADDS-GPO-EntraConnect-LinuxADJoin`
2. Load the Hyper-V helper functions first
3. Run `Install AD DS - Promote DCs - Forest Trust.ps1` step by step
4. Then run `ADUserPoolQuickCreate.ps1` to create test users

Follow the detailed comments inside each script.

---

## Lab Architecture

| Server      | Domain/Forest                    | IP Address      | Role                     |
|-------------|----------------------------------|-----------------|--------------------------|
| ANC-DC01    | minecraftmoose.com (Root)       | 192.168.77.7    | Root Domain Controller   |
| Nome-DC01   | moosewyre.fun (Tree)            | 192.168.88.8    | Tree Domain Controller   |
| ER-DC01     | dev.moosewyre.fun (Child)       | 192.168.100.9   | Child Domain Controller  |
| JUN-DC01    | megamooselabsfun.com            | 192.168.99.9    | Forest Root DC           |

![Network Topology](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/00-NetworkTopologyDiagram.jpg)

![Full Mesh Basic Diagram](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/02-Mesh-BasicDiagram.jpg)

---

## Hybrid Identity with Entra ID

This lab is designed for testing hybrid identity scenarios including Password Hash Sync and multi-forest synchronization to a single Entra ID tenant.
![Full Mesh Topology - IP Ranges](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/EntraConnect02.jpg)

![Azure AD Hybrid Identity with Password Hash Sync](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/Password%20Hash%20Sync-EntraID.jpg)

![Multiple Forests, Single Entra Tenant](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect-LinuxADJoin/VisualizationDiagrams/EntraConnect01.png)

---

## Default Credentials

- Safe Mode / DSRM Password: `P@ssword1!`
- Test User Password: `Password123!`

---

## Author

**Mark Kruse**  
GitHub: https://github.com/19BlueBomber87  
X: [@19BlueBomber87](https://x.com/19BlueBomber87)

---

⭐ Star the repo if this lab helped you!
