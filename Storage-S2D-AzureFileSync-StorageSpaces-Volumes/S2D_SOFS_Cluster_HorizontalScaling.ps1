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
Vertical scaling (scaling up): You increase the resources (CPU, RAM, storage, etc.) of a single server.
Adding more drives (HDDs/SSDs) to a Storage Spaces pool on one server is a classic example of vertical scaling for storage capacity and/or performance.
Horizontal scaling (scaling out): You add more servers/nodes to distribute the load, improve redundancy, and increase overall capacity.
Adding servers to a Windows Failover Cluster (especially with Storage Spaces Direct / S2D) is horizontal scaling. In S2D/hyper-converged setups, new nodes autom
# ===================================================
#  Prerequisites
# ===================================================
# One RRAS server for routing
# One domain controller 
# One Windows Admin Center instYAHOO-e
# One server to be privileged access workstation(PAW) management server


# ===================================================
# Step 1 - Create YAHOO-DC01
#                 Promote DC for minecraftmoose.com domain
# ===================================================
New-Lab_VM YAHOO-DC01 -HyperVSwitch ANC-NET -GeneralizedImageCore
# 
Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Rename-Computer -NewName YAHOO-DC01 -Restart -Verbose *>&1

#
Get-WindowsFeature -Name AD-Domain-Services
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow

# Set static IP + subnet + default gateway in one command
New-NetIPAddress -InterfaceAlias "Ethernet" `
    -IPAddress 192.168.77.7 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.77.1 `
    -AddressFamily IPv4 `
    -Verbose *>&1

# Set DNS server(s)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
    -ServerAddresses 127.0.0.1, 8.8.8.8 `
    -Verbose *>&1


#Promote DC
Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "minecraftmoose.com" `
-DomainNetbiosName "minecraftmoose" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssword1!" -AsPlainText -Force) `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true

# My golden images has two users accounts along with default administrator account.  
# If you have local computer accounts on the DC that is promoted, they are added to the domain.
# Add accounts to enterprise admin group
$newAdmins = "megaman","Rush"
$adminPermissions = (Get-ADUser administrator -Properties memberof).memberof
foreach($admin in $newAdmins){
    foreach($perm in $adminPermissions){
        Add-ADGroupMember -Identity "$perm" -Members $admin -Verbose *>&1
    }
}
(Get-ADUser megaman -Properties memberof).memberof
(Get-ADUser rush -Properties memberof).memberof


    # 3 - minecraftmoose.com privileged access workstation(Management Server)
New-Lab_VM YAHOO-NestedHost-PAW01 -HyperVSwitch ANC-NET -RAM 2GB -GeneralizedImageDE
Install-WindowsFeature -Name RSAT-Clustering-MGMT -Confirm:$false -Verbose *>&1
Install-WindowsFeature -Name RSAT-AD-Tools -IncludeAllSubFeature -Confirm:$false -Verbose *>&1
Install-WindowsFeature -Name RSAT-DNS-Server -Confirm:$false -Verbose *>&1
Install-WindowsFeature -Name GPMC -Confirm:$false -Verbose *>&1
Rename-Computer -NewName YAHOO-NestedHost-PAW01 -Restart -Verbose *>&1
#
$computerName = "YAHOO-NestedHost-PAW01"
Stop-VM -VMName $computerName -Force -Verbose *>&1 
Set-VMProcessor -VMName $computerName  -ExposeVirtualizationExtensions $true -Verbose *>&1
Start-VM -VMName $computerName  -Verbose *>&1
Get-VMProcessor -VMName $computerName  | Select-Object VMName, ExposeVirtualizationExtensions

Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1 -Restart

Get-WindowsFeature RSAT-Clustering*, RSAT-AD-*, RSAT-DNS-Server, GPMC | Select-Object DisplayName, Name, Installed
Get-Module -ListAvailable *cluster*, ActiveDirectory, Hyper-V
#
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow
#
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator  -Restart -Verbose *>&1


# ===================================================
# Step 1 - Create 3 Server Core VMs for Storage Spaces Direct Cluster
# ===================================================
New-Lab_VM -VMNames YAHOO-Clus01 -HyperVSwitch ANC-NET -nonOSdiskcount 5 -nonOSdiskSizeGB 200 -GeneralizedImageCore
New-Lab_VM -VMNames YAHOO-Clus02 -HyperVSwitch ANC-NET -nonOSdiskcount 5 -nonOSdiskSizeGB 200 -GeneralizedImageCore
New-Lab_VM -VMNames YAHOO-Clus03 -HyperVSwitch ANC-NET -nonOSdiskcount 5 -nonOSdiskSizeGB 200 -GeneralizedImageCore

#NOTE: Cluster Servers get IP via DCHP from RRAS Server.  

# ===================================================
# Step 2 - Rename cluster servers and join to minecraftmoose.com
# ===================================================
# Change computer name to YAHOO-Clus01 and join to domain
# From the YAHOO-Clus01 VM run:
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow
Rename-Computer -NewName YAHOO-Clus01 -Restart -Verbose *>&1
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator  -Restart -Verbose *>&1

# Change computer name to YAHOO-Clus02 and join to domain
# From the YAHOO-Clus02 VM run:
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow
Rename-Computer -NewName YAHOO-Clus02 -Restart -Verbose *>&1
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator -Restart  -Verbose *>&1

# Change computer name to YAHOO-Clus03 and join to domain
# From the YAHOO-Clus03 VM run:
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow
Rename-Computer -NewName YAHOO-Clus03 -Restart -Verbose *>&1
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator -Restart -Verbose *>&1


# Now we can leverage Invoke-Command
# Test via PowerShell Direct - Run from host
$cred = Get-Credential minecraftmoose\megaman
Invoke-Command -VMName YAHOO-Clus01, YAHOO-Clus02, YAHOO-Clus03 -ScriptBlock {
    $ENV:COMPUTERNAME
} -Credential $cred -Verbose *>&1
# ===================================================
# Step 3 -  Install 'File Services' and 'Fail Over Cluster' Roles
# ===================================================
# You can run the following commands from any domain joined server.
# For this example we will use YAHOO-WAC01 to run the commands.  
# YAHOO-WAC01 is domain joined to minecraftmoose.com


Invoke-Command -ComputerName YAHOO-Clus01, YAHOO-Clus02, YAHOO-Clus03 -ScriptBlock {
    Install-WindowsFeature -Name File-Services, Failover-Clustering -IncludeManagementTools -Confirm:$false -Verbose *>&1
} -Verbose *>&1

# Reboot all cluster 
Invoke-Command -ComputerName YAHOO-Clus01, YAHOO-Clus02, YAHOO-Clus03 -ScriptBlock {
    Restart-Computer -Force -Verbose *>&1
} -Verbose *>&1

Invoke-Command -ComputerName YAHOO-Clus01, YAHOO-Clus02, YAHOO-Clus03 -ScriptBlock {
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
# 
# The YAHOO-PAW01 server is domain joined and has powershell commands to test and Create Cluster
# You can run commands from YAHOO-PAW01 or any of the YAHOO-CLUS0X servers.  
# 

Test-Cluster -Node YAHOO-Clus01, YAHOO-Clus02, YAHOO-Clus03  -Include "Storage Spaces Direct", Inventory, Network, "System Configuration" -Verbose *>&1 


#Create the fail-over cluster
New-Cluster -Name S2DCluster01 -Node YAHOO-CLUS01, YAHOO-CLUS02, YAHOO-CLUS03 -NoStorage -StaticAddress 192.168.77.133 -Verbose *>&1

# We can now connect to S2DCluster01.minecraftmoose.com in fail-over cluster manager
Get-Cluster -Name "S2DCluster01.minecraftmoose.com"


# The fail over cluster is now a computer in AD DS
Invoke-Command -ComputerName YAHOO-DC01 -ScriptBlock {
    Get-AdComputer -filter * | ? -Property Name -like *S2D* -Verbose *>&1
} -Verbose *>&1



# Enable S2D
# You do NOT run Enable-ClusterStorageSpacesDirect (or Enable-ClusterS2D) on every server.
# You run it exactly once, from any one node in the cluster.

# From any domain joined server run:
Invoke-Command -ComputerName YAHOO-Clus01 -ScriptBlock {
    Enable-ClusterS2D -CacheState Disabled -AutoConfig:0 -SkipEligibilityChecks -Confirm:$false -Verbose *>&1
} -Verbose *>&1

# Check Status
Invoke-Command -ComputerName YAHOO-Clus01, YAHOO-Clus02, YAHOO-Clus03 -ScriptBlock {
    Get-ClusterS2D -Verbose *>&1
} -Verbose *>&1

# After running 'Enable-ClusterS2D' you will see C:\ClusterStorage on each node in the cluster
# Note: The root of C:\ClusterStorage is read‑only by design
Invoke-Command -ComputerName YAHOO-Clus01, YAHOO-Clus02, YAHOO-Clus03  -ScriptBlock {
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
# ---------|--------|-----|--------------|----------
# uint64           | System.UInt64 | Unsigned | 18,446,744,073,709,551,615 | 17,179,869,184 GB

# The following shows how big each disk is
Invoke-Command -ComputerName YAHOO-Clus01 -ScriptBlock {
     $s2d_disks = (Get-StorageSubSystem -Name "s2dcluster01.minecraftmoose.com" | Get-PhysicalDisk).Size
     foreach($disk in $s2d_disks){
        $size = [uint64]$disk/1GB
        Write-Verbose -Message ("Disk size is $size" + "GB") -Verbose *>&1
     }

} -Verbose *>&1

# Make Stoarge Pool
# From any domain joined server run:
Invoke-Command -ComputerName YAHOO-Clus01 -ScriptBlock {
    $s2d_disks = Get-StorageSubSystem -Name "s2dcluster01.minecraftmoose.com" | Get-PhysicalDisk 
    New-StoragePool -StorageSubSystemName "s2dcluster01.minecraftmoose.com" -FriendlyName "s2d-StoragePool01" -ProvisioningTypeDefault Fixed -ResiliencySettingNameDefault Mirror -PhysicalDisks $s2d_disks -Verbose *>&1

} -Verbose *>&1


#if you need to reset
# Get-StoragePool -FriendlyName s2d-StoragePool01 | Remove-StoragePool -Verbose *>&1

# Create Clusterd Shared Volumes from a Storage pool 
Invoke-Command -ComputerName YAHOO-clus01 -ScriptBlock {
    New-Volume -StoragePoolFriendlyName "s2d-StoragePool01" -FriendlyName "CSV01" -FileSystem CSVFS_ReFS -Size 25GB -Verbose *>&1
    New-Volume -StoragePoolFriendlyName "s2d-StoragePool01" -FriendlyName "CSV02" -FileSystem CSVFS_ReFS -Size 25GB -Verbose *>&1
    New-Volume -StoragePoolFriendlyName "s2d-StoragePool01" -FriendlyName "CSV03" -FileSystem CSVFS_ReFS -Size 25GB -Verbose *>&1
} -Verbose *>&1

Invoke-Command -ComputerName YAHOO-Clus01 -ScriptBlock {
    Get-ClusterSharedVolume | Select Name, OwnerNode
} -Verbose *>&1

Invoke-Command -ComputerName YAHOO-Clus01, YAHOO-Clus02, YAHOO-Clus03  -ScriptBlock {
    HOSTNAME.EXE
    dir C:\ClusterStorage
} -Verbose *>&1

Invoke-Command -ComputerName YAHOO-Clus01  -ScriptBlock {
    Get-VirtualDisk
} -Verbose *>&1


# Invoke-Command -ComputerName YAHOO-Clus01  -ScriptBlock {
#     Get-VirtualDisk | Remove-VirtualDisk -Verbose *>&1
# } -Verbose *>&1



# Enable scale out file server role (SOFS)
Invoke-Command -ComputerName YAHOO-Clus01 -ScriptBlock {
    New-StorageFileServer -StorageSubSystemName "s2dcluster01.minecraftmoose.com" -FriendlyName "S2D-SOFS01" -HostName "S2D-SOFS01" -Protocols SMB -Verbose *>&1
} -Verbose *>&1

# S2D-SOFS01 is now a computer in AD DS
Invoke-Command -ComputerName YAHOO-DC01 -ScriptBlock {
    Get-AdComputer -filter * | ? -Property Name -like *S2D* -Verbose *>&1
} -Verbose *>&1


# Create Shares to be used in SOFS
Invoke-Command -ComputerName YAHOO-Clus01 -ScriptBlock {
    # Create folders
    mkdir "C:\ClusterStorage\CSV01\SQL1000"
    mkdir "C:\ClusterStorage\CSV02\SQL2000"
    mkdir "C:\ClusterStorage\CSV03\SQL3000"
    mkdir "C:\ClusterStorage\CSV01\VM1000"
    mkdir "C:\ClusterStorage\CSV02\VM2000"
    mkdir "C:\ClusterStorage\CSV03\VM3000"
    # Create Shares
    New-SmbShare -Name "SQL1000" -Path "C:\ClusterStorage\CSV01\SQL1000" -FullAccess "minecraftmoose\megaman" -Verbose *>&1
    New-SmbShare -Name "SQL2000" -Path "C:\ClusterStorage\CSV02\SQL2000" -FullAccess "minecraftmoose\megaman" -Verbose *>&1
    New-SmbShare -Name "SQL3000" -Path "C:\ClusterStorage\CSV03\SQL3000" -FullAccess "minecraftmoose\megaman" -Verbose *>&1
    New-SmbShare -Name "VM1000" -Path "C:\ClusterStorage\CSV01\VM1000" -FullAccess "minecraftmoose\megaman" -Verbose *>&1
    New-SmbShare -Name "VM2000" -Path "C:\ClusterStorage\CSV02\VM2000" -FullAccess "minecraftmoose\megaman" -Verbose *>&1
    New-SmbShare -Name "VM3000" -Path "C:\ClusterStorage\CSV03\VM3000" -FullAccess "minecraftmoose\megaman" -Verbose *>&1
    Grant-SmbShareAccess -Name SQL1000 -AccountName "minecraftmoose.com\Domain Users" -AccessRight Read -Force -Verbose *>&1
    Grant-SmbShareAccess -Name SQL2000 -AccountName "minecraftmoose.com\Domain Users" -AccessRight Read -Force -Verbose *>&1
    Grant-SmbShareAccess -Name SQL3000 -AccountName "minecraftmoose.com\Domain Users" -AccessRight Read -Force -Verbose *>&1
    Grant-SmbShareAccess -Name VM1000 -AccountName "minecraftmoose.com\Domain Users" -AccessRight Read -Force -Verbose *>&1
    Grant-SmbShareAccess -Name VM2000 -AccountName "minecraftmoose.com\Domain Users" -AccessRight Read -Force -Verbose *>&1
    Grant-SmbShareAccess -Name VM3000 -AccountName "minecraftmoose.com\Domain Users" -AccessRight Read -Force -Verbose *>&1

    # Fix underlying ACLs (best practice)
    Set-SmbPathAcl -ShareName "SQL1000" -Verbose *>&1
    Set-SmbPathAcl -ShareName "SQL2000" -Verbose *>&1
    Set-SmbPathAcl -ShareName "SQL3000" -Verbose *>&1
    Set-SmbPathAcl -ShareName "VM1000" -Verbose *>&1
    Set-SmbPathAcl -ShareName "VM2000" -Verbose *>&1
    Set-SmbPathAcl -ShareName "VM3000" -Verbose *>&1
} -Verbose *>&1

Invoke-Command -ComputerName YAHOO-Clus01 -ScriptBlock {
    Get-ClusterSharedVolume -Verbose *>&1
} -Verbose *>&1


# Check out the SOFS SMB PATH! <@:D
# In File Explorer navitage to \\S2D-SOFS01
Test-Path \\S2D-SOFS01\Share1000



#Test HA
Invoke-Command -ComputerName YAHOO-Clus03  -ScriptBlock {
    Stop-Computer -Force -Verbose *>&1
}

# add disk to Storage pool
# Add-PhysicalDisk -StoragePoolFriendlyName "s2d-StoragePool01" -PhysicalDisks (Get-PhysicalDisk -SerialNumber ABC123...,DEF456...)

# ===================================================
# Step 5 - Add node to scale out file server
# ===================================================
# Add server node to SOFS cluster
New-Lab_VM -VMNames YAHOO-Clus04 -HyperVSwitch ANC-NET -nonOSdiskcount 5 -nonOSdiskSizeGB 700 -GeneralizedImageCore

# Change computer name to YAHOO-Clus03 and join to domain
# From the YAHOO-Clus04 VM run:
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow
Rename-Computer -NewName YAHOO-Clus04 -Restart -Verbose *>&1
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator -Restart -Verbose *>&1

# Install Roles
# From any domain joined server
Invoke-Command -ComputerName YAHOO-Clus04 -ScriptBlock {
    Install-WindowsFeature -Name File-Services, Failover-Clustering -IncludeManagementTools -Confirm:$false -Verbose *>&1
} -Verbose *>&1

# Reboot Server
Invoke-Command -ComputerName YAHOO-Clus04 -ScriptBlock {
    Restart-Computer -Force -Verbose *>&1
} -Verbose *>&1

# Test if YAHOO-Clus04 is ready to join cluster
Test-Cluster -Node YAHOO-Clus01, YAHOO-Clus02, YAHOO-Clus03, YAHOO-Clus04  -Include "Storage Spaces Direct", Inventory, Network, "System Configuration" -Verbose *>&1 


# Some failover clustering cmdlets do not work remotely
# Access YAHOO-CLUS04 from Hyper-V Manager and run this
Add-ClusterNode -Name YAHOO-Clus04 -Cluster S2DCluster01 -Verbose *>&1

# Check YAHOO-Clus04 is now part of the cluster
Invoke-Command -ComputerName YAHOO-Clus01 -ScriptBlock {
    Get-ClusterNode | Select-Object PSComputerName, Cluster, State
} -Verbose *>&1


# Check Allocation size Before adding, watch it increase
Invoke-Command -ComputerName YAHOO-Clus04 -ScriptBlock {
    Get-StoragePool -FriendlyName "s2d-StoragePool01"
} -Verbose *>&1

# These are YAHOO-Clus04 disks.  These new drives can pool
Get-StorageSubSystem -Name "s2dcluster01.minecraftmoose.com" | Get-PhysicalDisk -CanPool $true

# Add disks from YAHOO-Clus04
# Rebalance data across all 4 nodes
# → This redistributes storage pool slabs so performance and capacity are evenly utilized after adding the n
Invoke-Command -ComputerName YAHOO-Clus04 -ScriptBlock {
    $disks = Get-StorageSubSystem -Name "s2dcluster01.minecraftmoose.com" | Get-PhysicalDisk -CanPool $true
    Get-StoragePool -FriendlyName "s2d-StoragePool01" | Add-PhysicalDisk -PhysicalDisks $disks -Verbose *>&1
    Optimize-StoragePool -FriendlyName "s2d-StoragePool01" -Verbose *>&1
} -Verbose *>&1

# Check Allocation size AFTER adding, watch it increase
Invoke-Command -ComputerName YAHOO-Clus04 -ScriptBlock {
    Get-StoragePool -FriendlyName "s2d-StoragePool01"
} -Verbose *>&1


# NOTE

# The ClusterPerformYAHOO-eHistory CSV is deliberately hidden from File Explorer (and from most GUI tools) so that administrators don’t accidentally browse it, put files in it, or delete the performYAHOO-e-history database files.
# Disable PerformYAHOO-e History collection completely - Not recommeneded
# Stop-Service ClusPerfHist
# Set-Service ClusPerfHist -StartupType Disabled
# Remove-ClusterSharedVolume "ClusterPerformYAHOO-eHistory"   # only after stopping the service
#######################################################
########################################################
########################################################
#########################
###
# #9                  ┌──────────────────────────────┐
#                     │        CLIENTS / USERS       │
#                     │ (Apps, VMs, SQL, File Share)│
#                     └──────────────┬───────────────┘
#                                    │
#                      Management / Production Network
#                                    │
#         ┌──────────────────────────┼──────────────────────────┐
#         │                          │                          │
# ┌───────────────┐        ┌───────────────┐        ┌───────────────┐
# │   NODE 1      │        │   NODE 2      │        │   NODE 3      │
# │ (Server)      │        │ (Server)      │        │ (Server)      │
# │               │        │               │        │               │
# │  VMs / Roles  │        │  VMs / Roles  │        │  VMs / Roles  │
# │               │        │               │        │               │
# └──────┬────────┘        └──────┬────────┘        └──────┬────────┘
#        │                        │                        │
#        └──────────────┬─────────┴─────────┬──────────────┘
#                       │                   │
#              Heartbeat / Cluster Network
#          (Health checks & node communication)

#                       │
#          ┌────────────┴────────────┐
#          │   Cluster Shared Volume │
#          │        (CSV Storage)    │
#          │  Accessible by ALL nodes│
#          └────────────┬────────────┘
#                       │
#                 ┌─────┴─────┐
#                 │  QUORUM    │
#                 │ (Witness)  │
#                 │ File / Disk│

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
