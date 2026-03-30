# =============================================================================
# Hyper-V Lab Creation
# =====================
# Author:   Mark Kruse
# Purpose:  Create a 3-node Storage Spaces Direct (S2D) failover cluster
#           Configure failover cluster to be a 'Scale Out File Server(SOFS)'
#           Add a 4th node to the cluster
#           Example of Horizontal scaling
# Location: Anchorage, Alaska lab environment
# ==========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-QuickCreate-GoldenImages/AZ-800Celebrate-HyperV%20Creation%20and%20Disk%20Functions.ps1
# ==========================================================================================================================================================
# ===================================================
#  Prerequisites
# ===================================================
# One RRAS server for routing
# One domain controller 
# One Windows Admin Center instance
# One server to be privileged access workstation(PAW) management server
 
# ===================================================
# Step 1 - Create 3 Server Core VMs for Storage Spaces Direct Cluster
# ===================================================
New-Lab_VM -VMNames ANC-Clus01 -HyperVSwitch ANC-NET -nonOSdiskcount 5 -nonOSdiskSizeGB 200 -GeneralizedImageCore
New-Lab_VM -VMNames ANC-Clus02 -HyperVSwitch ANC-NET -nonOSdiskcount 5 -nonOSdiskSizeGB 200 -GeneralizedImageCore
New-Lab_VM -VMNames ANC-Clus03 -HyperVSwitch ANC-NET -nonOSdiskcount 5 -nonOSdiskSizeGB 200 -GeneralizedImageCore

#NOTE: Cluster Servers get IP via DCHP from RRAS Server.  

# ===================================================
# Step 2 - Rename cluster servers and join to minecraftmoose.com
# ===================================================
# Change computer name to ANC-Clus01 and join to domain
# From the ANC-Clus01 VM run:
Rename-Computer -NewName ANC-Clus01 -Restart -Verbose *>&1

Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator  -Restart -Verbose *>&1

# Change computer name to ANC-Clus02 and join to domain
# From the ANC-Clus02 VM run:
Rename-Computer -NewName ANC-Clus02 -Restart -Verbose *>&1

Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator -Restart  -Verbose *>&1

# Change computer name to ANC-Clus03 and join to domain
# From the ANC-Clus03 VM run:
Rename-Computer -NewName ANC-Clus03 -Restart -Verbose *>&1

Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator -Restart -Verbose *>&1

# ===================================================
# Step 3 -  Install 'File Services' and 'Fail Over Cluster' Roles
# ===================================================
# You can run the following commands from any domain joined server.
# For this example we will use YAHOO-WAC01 to run the commands.  
# YAHOO-WAC01 is domain joined to minecraftmoose.com

Invoke-Command -ComputerName ANC-Clus01, ANC-Clus02, ANC-Clus03 -ScriptBlock {
    Install-WindowsFeature -Name File-Services, Failover-Clustering -IncludeManagementTools -Confirm:$false -Verbose *>&1
} -Verbose *>&1

# Reboot all cluster 
Invoke-Command -ComputerName ANC-Clus01, ANC-Clus02, ANC-Clus03  -ScriptBlock {
    Restart-Computer -Force -Verbose *>&1
} -Verbose *>&1

Invoke-Command -ComputerName ANC-Clus01, ANC-Clus02, ANC-Clus03 -ScriptBlock {
    Get-WindowsFeature | ? -Property Name -Like "File-Services" | Select-Object PSComputerName, Name, Installed
    Get-WindowsFeature | ? -Property Name -Like "Failover-Clustering" | Select-Object PSComputerName, Name, Installed
} -Verbose *>&1

# NOTE: When using Invoke-Command like this, if the command executes successfully, it proves:
# WinRM is enabled on all three nodes
# Firewall rules allow WinRM (TCP 5985)
# Kerberos authentication works (domain‑joined hosts)
# You have administrator rights on all targets
# PowerShell Remoting is healthy
# Multinode fan‑out remoting works

# ===================================================
# Step 4 -  Create an fail-over cluster
#           Enable S2D
#           Configure cluster with 'Scale Out File Server' role
# ===================================================
#Install Management tools on WAC or MGMT Server
Install-WindowsFeature -Name RSAT-Clustering-MGMT -Verbose *>&1

# Test prerequisites
Test-Cluster -Node ANC-Clus01, ANC-Clus02, ANC-Clus03  -Include "Storage Spaces Direct", Inventory, Network, "System Configuration" -Verbose *>&1 

#Create the fail-over cluster
New-Cluster -Name S2DCluster01 -Node ANC-CLUS01, ANC-CLUS02, ANC-CLUS03 -NoStorage -StaticAddress 192.168.77.133 -Verbose *>&1

Get-Cluster -Name "S2DCluster01.minecraftmoose.com"

# The fail over cluster is now a computer in AD DS
Invoke-Command -ComputerName Anc-DC01 -ScriptBlock {
    Get-AdComputer -filter * | ? -Property Name -like *S2D* -Verbose *>&1
} -Verbose *>&1



# Enable S2D
# You do NOT run Enable-ClusterStorageSpacesDirect (or Enable-ClusterS2D) on every server.
# You run it exactly once, from any one node in the cluster.

# From any domain joined server run:
Invoke-Command -ComputerName ANC-Clus01 -ScriptBlock {
    Enable-ClusterS2D -CacheState Disabled -AutoConfig:0 -SkipEligibilityChecks -Confirm:$false -Verbose *>&1
} -Verbose *>&1

# Check Status
Invoke-Command -ComputerName ANC-Clus01 -ScriptBlock {
    Get-ClusterS2D -Verbose *>&1
} -Verbose *>&1

# After running 'Enable-ClusterS2D' you will see C:\ClusterStorage on each node in the cluster
# Note: The root of C:\ClusterStorage is read‑only by design
Invoke-Command -ComputerName ANC-Clus01, ANC-Clus02, ANC-Clus03  -ScriptBlock {
    HOSTNAME.EXE
    dir C:\
} -Verbose *>&1

#See available disks for S2D Cluster:
# NOTE:
# PowerShell Alias    .NET Type           Signed?     Range
# ================================================================================
# long                System.Int64        Signed      -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
# uint64              System.UInt64       Unsigned    0 to 18,446,744,073,709,551,615
# ================================================================================
# PowerShell Alias | .NET Type     | Signed?  | Max Value                  | Max Value / 1 GB
# -----------------|---------------|----------|----------------------------|-------------------
# uint64           | System.UInt64 | Unsigned | 18,446,744,073,709,551,615 | 17,179,869,184 GB

# The following shows how big each disk is
Invoke-Command -ComputerName ANC-Clus01 -ScriptBlock {
     $s2d_disks = (Get-StorageSubSystem -Name "s2dcluster01.minecraftmoose.com" | Get-PhysicalDisk).Size
     foreach($disk in $s2d_disks){
        $size = [uint64]$disk/1GB
        Write-Verbose -Message ("Disk size is $size" + "GB") -Verbose *>&1
     }

} -Verbose *>&1

# Make Stoarge Pool
# From any domain joined server run:
Invoke-Command -ComputerName ANC-Clus01 -ScriptBlock {
    $s2d_disks = Get-StorageSubSystem -Name "s2dcluster01.minecraftmoose.com" | Get-PhysicalDisk 
    New-StoragePool -StorageSubSystemName "s2dcluster01.minecraftmoose.com" -FriendlyName "s2d-StoragePool01" -ProvisioningTypeDefault Fixed -ResiliencySettingNameDefault Mirror -PhysicalDisks $s2d_disks -Verbose *>&1

} -Verbose *>&1


#if you need to reset
# Get-StoragePool -FriendlyName s2d-StoragePool01 | Remove-StoragePool -Verbose *>&1

# Create Volume from Storage pool 
Invoke-Command -ComputerName Anc-clus01 -ScriptBlock {
    New-Volume -StoragePoolFriendlyName "s2d-StoragePool01" -FriendlyName "CSV01" -FileSystem CSVFS_ReFS -Size 25GB -Verbose *>&1
    New-Volume -StoragePoolFriendlyName "s2d-StoragePool01" -FriendlyName "CSV02" -FileSystem CSVFS_ReFS -Size 25GB -Verbose *>&1
    New-Volume -StoragePoolFriendlyName "s2d-StoragePool01" -FriendlyName "CSV03" -FileSystem CSVFS_ReFS -Size 25GB -Verbose *>&1
} -Verbose *>&1

Invoke-Command -ComputerName ANC-Clus01, ANC-Clus02, ANC-Clus03  -ScriptBlock {
    HOSTNAME.EXE
    dir C:\ClusterStorage
} -Verbose *>&1

Invoke-Command -ComputerName ANC-Clus01  -ScriptBlock {
    Get-VirtualDisk
} -Verbose *>&1


# Invoke-Command -ComputerName ANC-Clus01  -ScriptBlock {
#     Get-VirtualDisk | Remove-VirtualDisk -Verbose *>&1
# } -Verbose *>&1


# Create Shares
Invoke-Command -ComputerName Anc-Clus01 -ScriptBlock {
    # Create folders
    mkdir "C:\ClusterStorage\CSV01\VM01000"
    mkdir "C:\ClusterStorage\CSV02\VM02000"
    mkdir "C:\ClusterStorage\CSV03\VM03000"
    # Create Shares
    New-SmbShare -Name "VM01000" -Path "C:\ClusterStorage\CSV01\VM01000" -FullAccess "minecraftmoose\Administrator" -Verbose *>&1
    New-SmbShare -Name "VM02000" -Path "C:\ClusterStorage\CSV02\VM02000" -FullAccess "minecraftmoose\Administrator" -Verbose *>&1
    New-SmbShare -Name "VM03000" -Path "C:\ClusterStorage\CSV03\VM03000" -FullAccess "minecraftmoose\Administrator" -Verbose *>&1
    Grant-SmbShareAccess -Name VM01000 -AccountName "minecraftmoose\Domain Users" -AccessRight Read -Force -Verbose *>&1
    Grant-SmbShareAccess -Name VM02000 -AccountName "minecraftmoose\Domain Users" -AccessRight Read -Force -Verbose *>&1
    Grant-SmbShareAccess -Name VM03000 -AccountName "minecraftmoose\Domain Users" -AccessRight Read -Force -Verbose *>&1

    # Fix underlying ACLs (best practice)
    Set-SmbPathAcl -ShareName "VM01000" -Verbose *>&1
    Set-SmbPathAcl -ShareName "VM02000" -Verbose *>&1
    Set-SmbPathAcl -ShareName "VM03000" -Verbose *>&1
} -Verbose *>&1

Invoke-Command -ComputerName Anc-Clus01 -ScriptBlock {
    Get-ClusterSharedVolume -Verbose *>&1
} -Verbose *>&1


# Enable scale out file server role (SOFS)
Invoke-Command -ComputerName Anc-Clus01 -ScriptBlock {
    New-StorageFileServer -StorageSubSystemName "s2dcluster01.minecraftmoose.com" -FriendlyName "S2D-SOFS01" -HostName "S2D-SOFS01" -Protocols SMB -Verbose *>&1
} -Verbose *>&1

# S2D-SOFS01 is now a computer in AD DS
Invoke-Command -ComputerName Anc-DC01 -ScriptBlock {
    Get-AdComputer -filter * | ? -Property Name -like *S2D* -Verbose *>&1
} -Verbose *>&1


# Check out the SOFS SMB PATH! <@:D
# In File Explorer navitage to \\S2D-SOFS01
Test-Path \\S2D-SOFS01\VM01


#Test HA
Invoke-Command -ComputerName ANC-Clus03  -ScriptBlock {
    Stop-Computer -Force -Verbose *>&1
}

# add disk to Storage pool
# Add-PhysicalDisk -StoragePoolFriendlyName "s2d-StoragePool01" -PhysicalDisks (Get-PhysicalDisk -SerialNumber ABC123...,DEF456...)

# ===================================================
# Step 5 - Add node to scale out file server
# ===================================================
# Add server node to SOFS cluster
New-Lab_VM -VMNames ANC-Clus04 -HyperVSwitch ANC-NET -nonOSdiskcount 5 -nonOSdiskSizeGB 700 -GeneralizedImageCore

# Change computer name to ANC-Clus03 and join to domain
# From the ANC-Clus04 VM run:
Rename-Computer -NewName ANC-Clus04 -Restart -Verbose *>&1

Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator -Restart -Verbose *>&1

# Install Roles
# From any domain joined server
Invoke-Command -ComputerName ANC-Clus04 -ScriptBlock {
    Install-WindowsFeature -Name File-Services, Failover-Clustering -IncludeManagementTools -Confirm:$false -Verbose *>&1
} -Verbose *>&1

# Reboot Server
Invoke-Command -ComputerName ANC-Clus04 -ScriptBlock {
    Restart-Computer -Force -Verbose *>&1
} -Verbose *>&1

# Test if ANC-Clus04 is ready to join cluster
Test-Cluster -Node ANC-Clus01, ANC-Clus02, ANC-Clus03, ANC-Clus04  -Include "Storage Spaces Direct", Inventory, Network, "System Configuration" -Verbose *>&1 

# add node to cluster
Invoke-Command -ComputerName ANC-Clus01 -ScriptBlock {
    Add-ClusterNode -Name ANC-Clus04 -Cluster S2DCluster01 -Verbose *>&1
} -Verbose *>&1

# Check ANC-Clus04 is now part of the cluster
Invoke-Command -ComputerName ANC-Clus04 -ScriptBlock {
    Get-ClusterNode
} -Verbose *>&1


#Check Allocation size before adding, watch it increase

# These are ANC-Clus04 disks.  These new drives can pool
Invoke-Command -ComputerName ANC-Clus04 -ScriptBlock {
    Get-StoragePool -FriendlyName "s2d-StoragePool01"
} -Verbose *>&1

# Add disks from ANC-Clus04
# Rebalance data across all 4 nodes -> This redistributes slabs so performance and capacity benefit from the new node.
Invoke-Command -ComputerName ANC-Clus04 -ScriptBlock {
    $disks = Get-StorageSubSystem -Name "s2dcluster01.minecraftmoose.com" | Get-PhysicalDisk -CanPool $true
    Get-StoragePool -FriendlyName "s2d-StoragePool01" | Add-PhysicalDisk -PhysicalDisks $disks -Verbose *>&1
    Optimize-StoragePool -FriendlyName "s2d-StoragePool01" -Verbose *>&1
} -Verbose *>&1

Invoke-Command -ComputerName ANC-Clus04 -ScriptBlock {
    Get-StoragePool -FriendlyName "s2d-StoragePool01"
} -Verbose *>&1





# NOTE

# The ClusterPerformanceHistory CSV is deliberately hidden from File Explorer (and from most GUI tools) so that administrators don’t accidentally browse it, put files in it, or delete the performance-history database files.
# Disable Performance History collection completely - Not recommeneded
# Stop-Service ClusPerfHist
# Set-Service ClusPerfHist -StartupType Disabled
# Remove-ClusterSharedVolume "ClusterPerformanceHistory"   # only after stopping the service
#######################################################
########################################################
########################################################
#########################
###
#9

########################################################
########################################################
########################################################
#########################
###
#10

########################################################
########################################################
########################################################
#########################
###
#11

########################################################
########################################################
########################################################
#########################
###
#12


########################################################
########################################################
########################################################
#########################
###
#13

########################################################
########################################################
########################################################
#########################
###
#14

########################################################
########################################################
########################################################
#########################
###
#15

########################################################
