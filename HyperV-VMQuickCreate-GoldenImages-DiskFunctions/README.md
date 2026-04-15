# Hyper-V Lab Creation - Quick Create Tools

A powerful set of PowerShell tools designed to quickly build, manage, and reset Hyper-V lab environments — ideal for learning, testing, and certification labs (AZ-800, AZ-801, etc.).

Created and maintained by **Mark Kruse** in Anchorage, Alaska.

---

## Features

- **Quick VM Creation** (`New-Lab_VM`)
  - Create VMs from Windows Server ISO (clean install)
  - Create VMs from generalized **Desktop Experience** or **Server Core** golden images
  - Support for multiple VMs at once
  - Configurable RAM, vCPU count, dynamic memory
  - Add multiple network adapters during creation
  - Automatically add extra data disks

- **Add Extra Disks** (`Add-Disks2VM`)
  - Easily attach multiple identically sized data disks to an existing VM

- **Initialize Raw Disks** (`Initialize-RawOfflineDisks`)
  - Quickly initialize, partition, and format offline RAW disks inside a VM (ReFS)

- **Lab Networking** (`CreateLabSwitches`)
  - Creates standard isolated lab switches (`ANC-Net`, `Nome-Net`, `JUN-Net`, `ER-Net`, `LINUX-Net`)
  - Creates one external switch (`EXT-INT`) bound to Wi-Fi with host management enabled

- **Lab Reset** (`_ResetLabNow`)
  - Destructive "nuke everything" function to start completely fresh

- **Power Management**
  - `SaveAllRunningVMs` – Quickly save (suspend) all running VMs for fast resume

---

## Prerequisites

- Windows 10 / 11 Pro or Enterprise (or Windows Server) with **Hyper-V** enabled
- Run **PowerShell as Administrator**
- At least one Wi-Fi or Ethernet adapter for the external switch

---

## Repository Structure
HyperV-QuickCreate/
├── HyperV Lab Creation and Disk Functions.ps1   ← Main script
├── GoldenImage.ps1                              ← (Optional) Golden image creation helper
├── README.md
└── C:\GoldenImages\                             ← Place your sysprepped .vhdx files here
text---

## Setup Instructions

1. **Enable Hyper-V** (if not already enabled)
2. Clone or download this repository
3. Place your golden images in `C:\GoldenImages\`:
   - `GoldenImage-DesktopExperience.vhdx`
   - `GoldenImage-ServerCore.vhdx`
4. (Optional) Place your Windows Server evaluation ISO in `C:\ISO\`
5. Open PowerShell **as Administrator**
6. Dot-source the script:

```powershell
. ".\HyperV Lab Creation and Disk Functions.ps1"

Usage Examples
1. Create Lab Networking
PowerShellCreateLabSwitches
2. Create VMs from Golden Image (Recommended)
PowerShell# Two Domain Controllers from Server Core golden image
New-Lab_VM -VMNames "DC01","DC02" -HyperVSwitch "ANC-Net" -RAM 4GB -GeneralizedImageCore

# File server with extra disks from Desktop Experience image
New-Lab_VM -VMNames "FS01" -HyperVSwitch "JUN-Net" -RAM 6GB `
           -nonOSdiskcount 6 -nonOSdiskSizeGB 200 -GeneralizedImageDE
3. Create VM from ISO
PowerShell$iso = "C:\ISO\SERVER_EVAL_x64FRE_en-us.iso"
New-Lab_VM -VMNames "ANC-RRAS01" -HyperVSwitch "EXT-INT" -AdapterCount 6 -ISOPath $iso
4. Add Extra Disks to Existing VM
PowerShellAdd-Disks2VM -VMName "FS01" -DiskSetName "Data" -DiskCount 4 -DiskSize 500
5. Initialize Disks (Run inside the VM)
PowerShellInitialize-RawOfflineDisks
6. Save All Running VMs (Fast suspend)
PowerShellSaveAllRunningVMs
7. Full Lab Reset (Destructive!)
PowerShell_ResetLabNow

Golden Image Preparation
See the included comments in the script or the companion script:

GoldenImage.ps1 (in the repo)

Key steps:

Build a reference VM
Run sysprep.exe /generalize /oobe /shutdown
Copy the resulting .vhdx to C:\GoldenImages\
Rename to GoldenImage-DesktopExperience.vhdx or GoldenImage-ServerCore.vhdx


Important Notes

All functions must be run as Administrator
The script is designed to be safe to rerun (idempotent where possible)
_ResetLabNow is destructive — use with caution
Change the Wi-Fi adapter name in CreateLabSwitches if needed


Author
Mark Kruse
Anchorage, Alaska
GitHub: 19BlueBomber87

License
This project is open-source and free to use for personal and educational purposes.

Happy Lab Building! 🚀
text