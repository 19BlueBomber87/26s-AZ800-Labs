# Laboratory Prerequisites

This folder contains the core PowerShell scripts needed to build the foundational infrastructure for the **AZ-800 Hyper-V Lab Environments** (Anchorage, Alaska themed lab).

These scripts are designed to be run **in order** and prepare the networking, Active Directory, routing/NAT, and management tools required for the rest of the lab series.

---

## 📁 Files Included

| File                        | Purpose |
|----------------------------|--------|
| **QuickCreateDCwithUsers.ps1** | Creates the first Domain Controller (`ANC-DC01`), installs AD DS, promotes it to a DC for the root domain `minecraftmoose.com`, and creates a test OU with sample users (Mega Man themed). |
| **RRAS Setup.ps1**         | Creates the RRAS server (`YAHOO-RRAS01`) with 6 network adapters, sets up multiple Hyper-V virtual switches, configures IP addressing, installs and configures **DHCP** (one scope per LAN), and enables **NAT/Routing** for internet access from all lab networks. |
| **wacOnServerCore.ps1**    | Deploys **Windows Admin Center (WAC)** on a Server Core VM (`YAHOO-WAC01`), creates a Privileged Access Workstation (`YAHOO-PAW01`), and prepares everything for centralized management of the lab. |

---

## 🛠️ Lab Architecture Overview

- **Primary Domain**: `minecraftmoose.com`
- **Root DC**: `ANC-DC01` (192.168.77.7)
- **RRAS Server**: `YAHOO-RRAS01` (multi-homed router + DHCP + NAT)
- **Networks**:
  - ANC-NET:     192.168.77.0/24   (`minecraftmoose.com`)
  - Nome-NET:    192.168.88.0/24   (`moosewyre.fun`)
  - JUN-NET:     192.168.99.0/24   (`megamooselabsfun.com`)
  - ER-NET:      192.168.100.0/24  (`megamooseforge.com`)
  - LINUX-NET:   192.168.11.0/24   (`yahoomoose.com`)
- **External Switch**: `EXT-INT` (connected to host's Wi-Fi for internet)

---

## 📋 Recommended Execution Order

1. **QuickCreateDCwithUsers.ps1**  
   → Builds the root domain and creates test users.

2. **RRAS Setup.ps1**  
   → Creates the multi-homed RRAS server, all virtual switches, DHCP scopes, and NAT routing.

3. **wacOnServerCore.ps1**  
   → Deploys Windows Admin Center and management workstations.

> **Tip**: Run these scripts from your Hyper-V host (Windows 10/11 Pro or Server with Hyper-V enabled).

---

## 🔗 Dependencies

- [New-Lab_VM function](https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/HyperV%20Lab%20Creation%20and%20Disk%20Functions.ps1)  
  (Required — must be loaded before running any of these scripts)

- Generalized Windows Server images (Desktop Experience + Server Core)
- Sufficient RAM and disk space on the Hyper-V host
- Internet access on the host

---

## 💡 Notes & Best Practices

- All scripts include extensive `-Verbose` output for easier troubleshooting.
- Firewall rules for ICMP (ping) are added for lab convenience.
- DHCP exclusions are set for .1–.9 in each scope (reserved for static servers).
- NAT is configured using both `New-NetNat` and legacy `netsh` commands for maximum compatibility.
- Windows Admin Center is installed on Server Core and accessed via HTTPS.

---

## 📍 Lab Location Theme

All labs are themed around **Anchorage, Alaska** and surrounding areas (Nome, Juneau, Eagle River) with fun "moose" and "yahoo" naming conventions.

---

## Next Steps

After completing the scripts in this folder, continue with the rest of the **26s-AZ800-Labs** series:
- Domain Controller additional setups
- Entra ID / Hybrid Identity labs
- Group Policy, DHCP failover, etc.

---

**Author**: Mark Kruse  
**Location**: Anchorage, Alaska  
**GitHub**: [19BlueBomber87](https://github.com/19BlueBomber87)

---

**Happy Lab Building!** 🧪❄️
