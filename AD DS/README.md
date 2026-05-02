# Hyper-V Lab: Multi-Domain Active Directory Forest Automation

A complete PowerShell automation suite for building a complex Active Directory lab environment in Hyper-V. Includes multiple domains, forests, forest trusts, and automated test user creation.

Perfect for AZ-800 study, hybrid identity testing, Entra ID sync labs, and advanced AD administration practice.

---

## Overview

This project automates the deployment of:
- 4 Domain Controllers across multiple networks
- Root Domain: minecraftmoose.com
- Tree Domain: moosewyre.fun
- Child Domain: dev.moosewyre.fun
- Separate Forest: megamooselabsfun.com
- Two-way Forest Trust between the forests
- AD Sites & Subnets
- Bulk creation of realistic test users in custom OUs

---

## GitHub Repository
https://github.com/19BlueBomber87/26s-AZ800-Labs/tree/main/AD%20DS

---

## Features

- Fully automated DC creation and promotion
- Complex AD structure (Root, Tree, Child, Separate Forest)
- Conditional DNS forwarders
- Two-way Forest Trust
- Automated test user creation with custom "Entra Synced Users" OU
- Mega Man themed users for fun lab testing

---

## Prerequisites

- Windows 10/11 or Windows Server with Hyper-V enabled
- New-Lab_VM function (from the HyperV helper script in the repo)
- Generalized Windows Server images (Desktop Experience)
- At least 16GB RAM recommended for smooth performance

---

## Lab Architecture

| Server      | Domain/Forest                    | IP Address      | Role                     |
|-------------|----------------------------------|-----------------|--------------------------|
| ANC-DC01    | minecraftmoose.com (Root)       | 192.168.77.7    | Root Domain Controller   |
| Nome-DC01   | moosewyre.fun (Tree)            | 192.168.88.8    | Tree Domain Controller   |
| ER-DC01     | dev.moosewyre.fun (Child)       | 192.168.100.9   | Child Domain Controller  |
| JUN-DC01    | megamooselabsfun.com            | 192.168.99.9    | Forest Root DC           |

---

## Author

**Mark Kruse**  
GitHub: https://github.com/19BlueBomber87  
X: @19BlueBomber87

---

⭐ Star the repo if this lab helped you!
