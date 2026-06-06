# =============================================================================
# Hyper-V Lab Creation - Nested Virtualization with Hyper-v
# =============================================================================
# Author:   Mark Kruse
# Purpose:  Created a Nested Hyper-V VM
# Location: Anchorage, Alaska lab environment
# =============================================================================
# =========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/HyperV%20Lab%20Creation%20and%20Disk%20Functions.ps1
# =========================================================================================================================================================
# =========================================================================================================================================================
# Recommended: How to create Hyper-V Windows Server Router\DHCP Server
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/ADDS-GPO-EntraConnect-LinuxADJoin/RRAS%20Setup.ps1
# ==================================================================================================================
# Note: For this Lab You can an External Hyper-V Switch connected to all VMs, instead of Hyper-V router
# ==================================================================================================================
# Hyper-V Nesting (also called Nested Virtualization) allows you to run a Hyper-V hypervisor inside a virtual machine.
# This means you can create VMs inside other VMs. It is very useful for labs, testing, training, and running container platforms like Kubernetes that need virtualization support.

# The diagram shows three layers of virtualization:

# Level   | Component                              | Description
# --------|----------------------------------------|--------------------------------------------------------------------------------
# Level 0 | Hardware + Hyper-V Hypervisor          | The real physical CPU (with virtualization extensions) and the outer Hyper-V 	  hypervisor. This is the foundation.
# Level 1 | Host Windows Kernel + Root Directory   | Your main Windows VM (the "management" OS). It runs on top of the outer Hyper-V.
# Level 2 | Nested Hyper-V Hypervisor + Guest OS   | Inside the Level 1 VM, you run another Hyper-V hypervisor, which then runs additional Guest VMs (with their own kernels).

# ===================================================
# Step 1 - Create the Hyper-V host and configure to support nested virtualization  
# ===================================================
$computerName = "MCM-Host01"
New-Lab_VM -VMNames  $computerName  -HyperVSwitch Linux-Net -Ram 4GB -GeneralizedImageDE
Stop-VM -VMName $computerName -Force -Verbose *>&1 
Set-VMProcessor -VMName $computerName  -ExposeVirtualizationExtensions $true -Verbose *>&1
Start-VM -VMName $computerName  -Verbose *>&1
Get-VMProcessor -VMName $computerName  | Select-Object VMName, ExposeVirtualizationExtensions
#Rename Worker Node
$computerName  =  "MCM-Host01"
Rename-Computer -NewName $computerName  -Verbose *>&1
# Install Required Windows Features
Install-WindowsFeature -Name Containers, Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1 -Restart



# ===================================================
# Step 2 - Create the Hyper-V host and configure to support nested virtualization  
# ===================================================

# On the host enalabe mac address spoofing
Set-VMNetworkAdapter -VMName "MCM-Host01" -MacAddressSpoofing On

$computerName = "MCM-Nested-Host01"
New-Lab_VM -VMNames  $computerName  -HyperVSwitch Linux-Net -Ram 4GB -GeneralizedImageDE
Install-WindowsFeature -Name Containers, Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1 -Restart

# Move Golden Images and ISOs to Nested Host

# Create Nested VM
New-Lab_VM -VMNames  MCM-Nested-VM01 -HyperVSwitch Linux-Net -GeneralizedImageDE

