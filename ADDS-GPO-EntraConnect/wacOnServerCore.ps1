# =============================================================================
# Hyper-V Lab Creation
# =====================
# Author:   Mark Kruse
# Purpose:  Install WAC on Server Core and manage servers
# Location: Anchorage, Alaska lab environment
# ==========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/HyperV%20Lab%20Creation%20and%20Disk%20Functions.ps1
# ==========================================================================================================================================================

# ===================================================
#  Prerequisites
# ===================================================
# Complete this lab first for best results -> https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/AD%20DS/Install%20AD%20DS%20-%20Promote%20DCs.ps1
# Note: You may not have enough memory for all VMs.  Adjust memeory to run the most VMs you can on your hardware.  
# For a quicker demo, you can also do this lab with one Windows Server and the WAC server  
 
# ===================================================
# Step 1 - Create Server Core VM to be WAC Server. 
#          Create Server to be privileged access workstation(PAW) management server
# ===================================================
#WAC Server
New-Lab_VM -VMNames YAHOO-WAC01 -HyperVSwitch ANC-NET -GeneralizedImageCore

Rename-Computer -NewName "YAHOO-WAC01"  -Restart -Verbose *>&1

New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow


#Make sure domain name resovles to minecraftmoose.com before joining
# ping minecraftmoose.com should return ANC-DC01 ip address -> 192.168.77.7
# If not run 'ipconfig /flushdns' and try ping again
ping minecraftmoose.com

Add-Computer -DomainName minecraftmoose.com -Credential minecraftmoose\administrator -Restart -Verbose *>&1

#PAW Server - Destkop Experience
New-Lab_VM -VMNames YAHOO-PAW01 -HyperVSwitch ANC-NET -GeneralizedImageDE

Rename-Computer -NewName "YAHOO-PAW01"  -Restart -Verbose *>&1

New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow


#Make sure domain name resovles to minecraftmoose.com before joining
# ping minecraftmoose.com should return ANC-DC01 ip address -> 192.168.77.7
# If not run 'ipconfig /flushdns' and try ping again
ping minecraftmoose.com

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
# Custom Setup
# Remote access.  Use machine name or FQDN to access WAC on other devices
# HTML Form Login
# External Port 443
# Generate a self-signed certificate (expires in 60 days)
# FQDN YAHOO-WAC01.minecraftmoose.com
# HTTP.  Default communication mechanism (WinRM over HTTP)
# Install updates automatically 
# Required diagnostic data

# Check Services are running or reboot
Get-Service *AdminCenter* -ErrorAction SilentlyContinue | Select Name, Status, StartType

Start-Service WindowsAdminCenter -Verbose *>&1

Set-Service WindowsAdminCenter -StartupType Automatic -Verbose *>&1

# ===================================================
# Step 4 - Test WAC
# ===================================================
# Access WAC from ER-PAW01.  Use minecraftmoose\administrator to login

https://YAHOO-WAC01.minecraftmoose.com


# ========================================================
# Remote Management - Windows Admin Center and Server Manger
# ========================================================
# Configure WinRm and firewall rules to allow non-domain joined servers to be added to server manager and windows admin center(WAC).  
# Connect to the server you want to mange from Server Manager or WAC.
# Run Enable-PSRemoting and set firewall rules
# ========================================================
Enable-PSRemoting -Force -Verbose *>&1


# WinRM Setup - Quick Comparison
# ============================================================

# Action                                      | winrm quickconfig          | Enable-PSRemoting -Force
# --------------------------------------------|----------------------------|-----------------------------------
# Starts WinRM service + sets to Auto         | Yes                        | Yes
# Creates HTTP listener (port 5985)           | Yes                        | Yes
# Enables basic firewall exception            | Yes (for current profile)  | Yes + more complete
# Sets up PowerShell session configurations   | No (or limited)            | Yes (main difference)
# Configures trusted hosts / security         | Basic                      | Better for PowerShell remoting
# Recommended for modern use                  | Older method               | Microsoft's preferred method
# ============================================================

New-NetFirewallRule -Name "WinRM-HTTP-All" -DisplayName "Windows Remote Management (HTTP-In)" `
  -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow `
  -Profile Any -RemoteAddress Any -Enabled True

New-NetFirewallRule -Name "WinRM-HTTPS-All" -DisplayName "Windows Remote Management (HTTPS-In)" `
  -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow `
  -Profile Any -RemoteAddress Any -Enabled True
 
# Server Manager (and PowerShell remoting) uses WinRM (Windows Remote Management) to talk to remote servers.

# Port 5985 = WinRM over HTTP (unencrypted)
# Port 5986 = WinRM over HTTPS (encrypted)

# Why Enable-PSRemoting -Force is not enough?
# Enable-PSRemoting does create WinRM firewall rules, but Microsoft made them smart/restricted by default:

# On Domain or Private network profiles → full remote access allowed.
# On Public network profile → only allows connections from the same local subnet.

# Since your servers are on two different LANs, traffic is coming from a different subnet. Even if the network is marked Private, the default rules often still block it or behave inconsistently. That's why your custom rules fixed it in the past.