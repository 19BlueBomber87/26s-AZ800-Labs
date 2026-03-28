# =============================================================================
# Hyper-V Lab Creation
# =====================
# Author:   Mark Kruse
# Purpose:  Install WAC on Server Core and manage servers
# Location: Anchorage, Alaska lab environment
# ==========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-QuickCreate-GoldenImages/AZ-800Celebrate-HyperV%20Creation%20and%20Disk%20Functions.ps1
# ==========================================================================================================================================================

# ===================================================
#  Prerequisites
# ===================================================
# Complete this lab first for best results -> https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/AD%20DS/Install%20AD%20DS%20-%20Promote%20DCs.ps1
# Note: You may not have enough memory for all VMs.  Adjust memeory to run the most VMs you can on your hardware.  
# For a quicker demo, you can also do this lab with one Windows Server and the WAC server  
 
# ===================================================
# Step 1 - Create Server Core VM to be WAC Server.  It will not be domain joined
# ===================================================
New-Lab_VM -VMNames YAHOO-WAC01 -HyperVSwitch ANC-NET -GeneralizedImageCore

New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow
    
Rename-Computer -NewName YAHOO-WAC01 -Restart -Verbose *>&1

Add-Computer -DomainName minecraftmoose.com -Credential minecraftmoose\administrator -Restart -Verbose *>&1

# ===================================================
# Step 2 - Download WAC
# ===================================================
# Download the latest installer (aka.ms/WACDownload always points to current version)
# It is usually an .msi file, even if sometimes saved without extension
$url = "https://aka.ms/WACdownload"
$installer = "C:\WindowsAdminCenter.exe"

Start-BitsTransfer -Source $url -Destination $installer -Verbose *>&1


# Confirm the download
if (-not (Test-Path $installer)){
    throw "Download failed: $installer not found."
}
if ((Get-Item $installer).Length -lt 5MB){
        throw "Installer file seems small; it might not be the real EXE."
    }

# ===================================================
# Step 3 - Install WAC
# ===================================================
# Ensure log directory exists
mkdir C:\WacLogs

# Remove after testing:
# $null = New-Item -Path (Split-Path $log) -ItemType Directory -Force -ErrorAction SilentlyContinue

# mkdir temp
$log = "C:\WacLogs\WACInstall.log"

# Build installer arguments as a string:
$installerArgs = "/install /norestart /log `"$log`""


# --- Run installer.  This will open the Wizard---
Start-Process -FilePath $installer -ArgumentList $installerArgs -Verbose *>&1

# GUI Steps
# Accepts the license + privacy statement.
# Basic silent install (self-signed cert + default port 443)
# Remote access.  Use machine name or FQDN to access WAC on other devices
# HTML Form Login
# Allow Access only to tursted computers.  This is the default.  We will update to 'Allow access to any computer' for this lab with Set-Item command
# Install updates automatically 

# ===================================================
# Step 4 - Create a privileged access workstation to test WAC
# ===================================================

# Check Services are running
Get-Service *AdminCenter* -ErrorAction SilentlyContinue | Select Name, Status, StartType

# Test From PAW Workstation
New-Lab_VM -VMNames ER-PAW01 -HyperVSwitch ER-NET -GeneralizedImageDE

New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow
    
Rename-Computer -NewName ER-PAW01 -Restart -Verbose *>&1

Add-Computer -DomainName dev.moosewyre.fun -Credential moosewyre\administrator -Restart -Verbose *>&1

# ===================================================
# Step 4 - Test WAC
# ===================================================
# Access WAC from ER-PAW01.  Use minecraftmoose\administrator to login

http://YAHOO-WAC01.minecraftmoose.com