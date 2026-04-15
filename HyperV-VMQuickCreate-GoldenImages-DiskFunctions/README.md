# Hyper-V Lab Quick Create Tools

PowerShell toolkit for fast Hyper-V lab creation in Windows (Server/Desktop) environments.

Author: **Mark Kruse**  
Location: Anchorage, Alaska

This repository provides a set of PowerShell functions to dramatically speed up building and managing Hyper-V lab environments — perfect for learning, testing, certification labs (e.g., AZ-800), or homelab experimentation.

## Features

- **CreateLabSwitches** — Quickly creates isolated private lab switches + one external switch (with host internet access).
- **New-Lab_VM** — The core function. Create one or many Gen2 VMs from:
  - Windows Server ISO (clean install)
  - Generalized **Desktop Experience** golden image
  - Generalized **Server Core** golden image
- Supports multiple network adapters at creation time, extra data disks, dynamic/fixed memory, and automatic start.
- **Add-Disks2VM** — Easily add multiple data disks to an existing VM.
- **Initialize-RawOfflineDisks** — Initializes offline RAW disks inside a VM (GPT + ReFS, auto drive letter).
- **SaveAllRunningVMs** — Saves (suspends) all running VMs for quick resume and lower resource usage.
- **_ResetLabNow** — Destructive "nuke everything" function to start fresh (VMs + disks + optional switches).

## Repository Contents

- `HyperV Lab Creation and Disk Functions.ps1` — Main script with all functions.
- `GoldenImage.ps1` — Step-by-step guide and automation for creating your own golden images (including Python install, custom wallpaper, and sysprep with unattend.xml).
- `unattend.xml` — Pre-configured answer file for sysprep (creates local admin accounts, sets Alaskan time zone, skips OOBE screens, etc.).

## Quick Start

### 1. Prerequisites
- Windows 10/11 Pro or Windows Server with **Hyper-V role** enabled.
- Run PowerShell **as Administrator**.
- Place your Windows Server ISO in `C:\ISO\` (or update the path).
- Create a `C:\GoldenImages\` folder for your sysprepped VHDX files.

### 2. Create Lab Networking

```powershell
. .\HyperV Lab Creation and Disk Functions.ps1
CreateLabSwitches
3. Create Golden Images (One-time)
See GoldenImage.ps1 for the full workflow:

Create a reference VM
Enter Audit Mode (CTRL + SHIFT + F3 at first OOBE screen)
Install updates, apps, Python, set wallpaper
Run sysprep with the included unattend.xml
Copy the resulting .vhdx to C:\GoldenImages\

4. Create VMs Rapidly
PowerShell# Example 1: Multiple DCs from Server Core golden image
New-Lab_VM -VMNames "DC01","DC02" -HyperVSwitch "ANC-Net" -RAM 4GB -GeneralizedImageCore

# Example 2: File server from Desktop Experience with extra disks
New-Lab_VM -VMNames "FS01" -HyperVSwitch "JUN-Net" -RAM 6GB -nonOSdiskcount 6 -nonOSdiskSizeGB 200 -GeneralizedImageDE

# Example 3: Router/RRAS from ISO with 6 NICs
$isoPath = "C:\ISO\SERVER_EVAL_x64FRE_en-us.iso"
New-Lab_VM -VMNames "ANC-RRAS01" -HyperVSwitch "EXT-INT" -AdapterCount 6 -ISOPath $isoPath
Golden Image Preparation
Detailed instructions are inside GoldenImage.ps1.
Key steps include:

Installing Python 3.12.6 silently
Downloading a custom MegaMan wallpaper
Pulling the unattend.xml for automated user creation and OOBE skip
Running sysprep with /generalize /oobe /shutdown /unattend

After sysprep, rename and move the .vhdx to C:\GoldenImages\.
Folder Structure Recommendation
textC:\
├── ISO\                      ← Windows Server ISOs
├── GoldenImages\             ← GoldenImage-DesktopExperience.vhdx + GoldenImage-ServerCore.vhdx
├── Hyper-V\VMs\              ← VM config files (auto-created)
└── ProgramData\Microsoft\Windows\Virtual Hard Disks\  ← VHDX files
Important Notes

Always run as Administrator.
New-Lab_VM works best in Audit Mode for golden image creation.
The _ResetLabNow function is destructive — use with caution.
Customize switch names, paths, and adapter names as needed (e.g., Wi-Fi adapter name).
Tested in Anchorage, Alaska lab environment.

Future Enhancements (Ideas)

Winget/Chocolatey app installation in golden image
Auto domain join / DSC configuration
Export/Import lab configurations
GUI wrapper (optional)

License
Free to use, modify, and share.
No warranty — test thoroughly in a non-production environment.

Made for speed and repeatability in Hyper-V labs.
Questions, issues, or improvements? Open an Issue or Pull Request!
textThis README is well-structured for GitHub (with clear sections, code blocks, and examples), informative without being overwhelming, and directly references the files you provided.

Would you like a shorter "one-screen" version, or any sections added/removed (e.g., screenshot