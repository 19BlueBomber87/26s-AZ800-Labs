# Hyper-V Lab Creation - Quick Create Tools

A powerful set of PowerShell tools designed to quickly build, manage, and reset Hyper-V lab environments — ideal for learning, testing, and certification labs (AZ-800, AZ-801, AZ-802, etc.).

Created and maintained by **Mark Kruse** in Anchorage, Alaska.

---

## Features

- **Quick VM Creation** (`New-Lab_VM`)
  - Create VMs from Windows Server ISO (clean install)
  - Create VMs from generalized **Desktop Experience** or **Server Core** golden images
  - Support for creating multiple VMs at once
  - Configurable RAM, vCPU count, dynamic memory
  - Add multiple network adapters during creation
  - Function to add extra data disks

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
## 🔗 Dependencies

- [GoldenImage.ps1](https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/GoldenImage.ps1)
- [Unattend.xml](https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/unattend.xml)  
---

## Setup Instructions

1. **Enable Hyper-V** (if not already enabled)
2. Clone or download this repository
3. Place your golden images in `C:\GoldenImages\`:
   - `GoldenImage-DesktopExperience.vhdx`
   - `GoldenImage-ServerCore.vhdx`
4. (Optional) Place your Windows Server evaluation ISO in `C:\ISO\`
5. Open PowerShell **as Administrator**
6. Dot-source the script:

. ".\HyperV Lab Creation and Disk Functions.ps1"

Usage Examples
1. Create Lab Networking
PowerShellCreateLabSwitches
2. Create VMs from Golden Image (Recommended)
PowerShell# Two Domain Controllers from Server Core golden image
New-Lab_VM -VMNames "DC01","DC02" -HyperVSwitch "ANC-Net" -RAM 4GB -GeneralizedImageCore
New-Lab_VM -VMNames "FS01" -HyperVSwitch "JUN-Net" -RAM 6GB -nonOSdiskcount 6 -nonOSdiskSizeGB 200 -GeneralizedImageDE
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
- [GoldenImage.ps1](https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/GoldenImage.ps1)  
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

# Hyper-V Golden Image Preparation

PowerShell script and supporting files to create **generalized golden images** for fast VM deployment in Hyper-V labs.

Author: **Mark Kruse**  
Location: Anchorage, Alaska

---

## Purpose

This script helps you build reusable, sysprepped golden images for:

- **GoldenImage-DesktopExperience.vhdx** (Full GUI)
- **GoldenImage-ServerCore.vhdx** (Server Core)

These images are then used by the main `New-Lab_VM` function for extremely fast VM creation.

---

## Files Included

- `GoldenImage.ps1` – Main preparation script
- `unattend.xml` – Unattend file used during sysprep (creates local accounts, sets timezone, etc.) AKA: Unattend Answer File
- Main wallpaper image (Main.jpg) – Optional custom background

---

## Prerequisites

- Hyper-V enabled on Windows 10/11 Pro or Windows Server
- Windows Server 2025 Evaluation ISO (or newer)
- PowerShell running **as Administrator**
- Internet access (for downloading Python and wallpaper)

---

## Step-by-Step Guide

### 1. Create Base VMs (First Run)

Run the following commands from `GoldenImage.ps1`:

```powershell
# Creates two temporary VMs for golden image preparation
New-Lab_VM -VMNames GoldenImage-ServerCore -HyperVSwitch EXT-INT -ISOPath "C:\ISO\2025_26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"

New-Lab_VM -VMNames GoldenImage-DesktopExperience -HyperVSwitch EXT-INT -ISOPath "C:\ISO\2025_26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
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
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/GoldenImage.ps1" -OutFile "C:\GoldenImage.ps1"
.\GoldenImage.ps1
The script will automatically:

Install Python 3.12.6 (silent install)
Create Unicode test files (yahoo.py section)
Download and place MegaMan.jpg custom wallpaper (Desktop Experience only)
Download unattend.xml to "C:\windows\System32\Sysprep"
Run Sysprep with /generalize /oobe /shutdown /unattend
C:\windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\unattend.xml

The VM will shut down automatically when sysprep completes.
4. Finalize Golden Image
After the VM shuts down:

In Hyper-V Manager, right-click the VM → Delete (do not delete the VHDX).
Locate the VHDX file:
C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\GoldenImage-DesktopExperience.vhdx
C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\GoldenImage-ServerCore.vhdx

Copy and rename it to:

cmdC:\GoldenImages\GoldenImage-DesktopExperience.vhdx
C:\GoldenImages\GoldenImage-ServerCore.vhdx
Make sure the folder C:\GoldenImages\ exists.
5. Test the Golden Images
PowerShell# Test Desktop Experience golden image
New-Lab_VM -VMNames "Test-DE" -HyperVSwitch "ANC-Net" -RAM 4GB -GeneralizedImageDE

# Test Server Core golden image
New-Lab_VM -VMNames "Test-Core" -HyperVSwitch "ANC-Net" -RAM 4GB -GeneralizedImageCore

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
