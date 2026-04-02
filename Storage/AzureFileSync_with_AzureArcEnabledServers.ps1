# =============================================================================
# Hyper-V Lab Creation
# =====================
# Author:   Mark Kruse
# Purpose:  Configure Azure File Sync with 3 AD DS File Servers
# Location: Anchorage, Alaska lab environment
# ==========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-QuickCreate-GoldenImages/AZ-800Celebrate-HyperV%20Creation%20and%20Disk%20Functions.ps1
# ==========================================================================================================================================================
# ===================================================
# ===================================================
#  Prerequisites -> []
# ===================================================
# YAHOO-RRAS01 -> One RRAS server for routing
# ANC-DC01     -> One domain controller 
# ANC-PAW01    -> One server to be privileged access workstation(PAW) management server
az extension add --upgrade -n storagesync
# Variable index
$resourceGroupName = "az-FileSyncResourceGroup"
$location = "WestUS2"
$storageAccountName = "yahoostorageaccount"    
$resourceGroupName = "az-FileSyncResourceGroup" 
$storageAccountName = "yahoostorageaccount"
$shareName = "yahooazfileshare01"
$syncServiceName = "yahooFileSyncService"
$syncGroupName = "yahooSyncGroup"
$cloudEndPointName = "yahooCloudEndpoint"

# ===================================================
# Step 1 - Create storage account with Azure CLI
#          Grant Microsoft.StorageSync the Reader and Data Access Role on the storage account
# ===================================================
# Navigate to portal.azure.com and login and open the Cloud Shell
az group create -n $resourceGroupName -l $location

# === Create Storage Account for Azure Files (Provisioned v2) ===  
az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS --kind StorageV2 --access-tier Hot --min-tls-version TLS1_2 --allow-blob-public-access false --allow-shared-key-access true

# Automanage API Access = “Let Microsoft’s Automanage service manage resources on your behalf”
# We need to add the 
# Replace with your actual values
$storageAccountID = az storage account show --resource-group $resourceGroupName --name $storageAccountName --query id -o tsv

# We need to Grant Microsoft.StorageSync the Reader and Data Access Role on the storage account. 
# Microsoft.StorageSync is:
# The Azure service that implements Azure File Sync
# A first‑party Microsoft backend service
# Exposed in Azure as a resource provider and control plane

az ad sp list --display-name "Microsoft.StorageSync"  
az ad sp list --display-name "Microsoft.StorageSync" --query "[0].appDisplayName" -o tsv 


az role assignment create --assignee-object-id "$(az ad sp list --display-name "Microsoft.StorageSync" --query "[0].id" -o tsv)" --role "Reader and Data Access" --scope $storageAccountID

# ===================================================
# Step 2 - Create file share inside the storage account with Azure CLI
# ===================================================
# Workload type              | Choose
# ---------------------------|----------------------
# High transaction count     | Transaction optimized
# Large files, steady use    | Hot
# Rarely accessed data       | Cool
# Use Azure CLI to create and configure the File Share 
az storage share-rm create --resource-group $resourceGroupName --storage-account $storageAccountName --name $shareName --access-tier "TransactionOptimized" --quota 500

# Use Azure CLI to update access tier and quota
az storage share-rm update --resource-group $resourceGroupName --storage-account $storageAccountName --name $shareName --access-tier Hot --quota 1000

# ===================================================
# Step 3 - Create file sync service with Azure CLI and Powershell
# ===================================================

#First we need to add storagesync extension
az extension add --upgrade -n storagesync

# Create the Azure File Sync service object

az storagesync create --resource-group $resourceGroupName --name $syncServiceName --location $location

# Create a Sync Group inside the Azure File Sync service object

az storagesync sync-group create --resource-group $resourceGroupName --storage-sync-service $syncServiceName --name $syncGroupName

# Create Cloud End Point
az storagesync sync-group cloud-endpoint create --resource-group $resourceGroupName --storage-sync-service $syncServiceName --sync-group-name $syncGroupName --name $cloudEndPointName --storage-account $storageAccountName --azure-file-share-name $shareName

# ===================================================
# Step 4 - Create File Servers
# ===================================================

# From Host run:
New-Lab_VM -VMNames YAHOO-FILESYNC1 -HyperVSwitch ANC-NET -nonOSdiskcount 3 -nonOSdiskSizeGB 50 -GeneralizedImageCore
New-Lab_VM -VMNames YAHOO-FILESYNC2 -HyperVSwitch ANC-NET -nonOSdiskcount 3 -nonOSdiskSizeGB 50 -GeneralizedImageCore
New-Lab_VM -VMNames YAHOO-FILESYNC3 -HyperVSwitch ANC-NET -nonOSdiskcount 3 -nonOSdiskSizeGB 50 -GeneralizedImageCore


# From the YAHOO-FILESYNC1 VM run:
Rename-Computer -NewName YAHOO-FILESYNC1 -Restart -Verbose *>&1
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator  -Restart -Verbose *>&1


# From the YAHOO-FILESYNC2 VM run:
Rename-Computer -NewName YAHOO-FILESYNC2 -Restart -Verbose *>&1
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator  -Restart -Verbose *>&1


# From the YAHOO-FILESYNC1 VM run:
Rename-Computer -NewName YAHOO-FILESYNC3 -Restart -Verbose *>&1
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator  -Restart -Verbose *>&1

Invoke-Command -ComputerName YAHOO-FILESYNC1, YAHOO-FILESYNC2, YAHOO-FILESYNC3 -ScriptBlock {
    $disks = Get-Disk | 
        Where-Object -Property OperationalStatus -eq "Offline" | 
        Where-Object -Property PartitionStyle -eq "RAW"

    foreach($disk in $disks){
        Initialize-Disk -Number $disk.number -PartitionStyle GPT -Verbose *>&1
        $partition = New-Partition -DiskNumber $disk.number -UseMaximumSize -AssignDriveLetter -Verbose *>&1
        ($partition.DriveLetter).gettype()
        Format-Volume -DriveLetter $partition.DriveLetter -FileSystem NTFS -Verbose *>&1
        Clear-Variable partition -Verbose *>&1
    }
    # Enable RDP on YAHOO-FILESYNC1, YAHOO-FILESYNC2, YAHOO-FILESYNC1
    Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
    Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Set-Service TermService -StartupType Automatic
    Start-Service TermService

    # Allow ping on YAHOO-FILESYNC1, YAHOO-FILESYNC2, YAHOO-FILESYNC1
    New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
        -Direction Inbound `
        -Protocol ICMPv4 `
        -IcmpType 8 `
        -Action Allow
}

Invoke-Command -ComputerName YAHOO-FILESYNC1, YAHOO-FILESYNC2, YAHOO-FILESYNC3  -ScriptBlock{
    (Get-Volume  |Sort-Object DriveLetter )
    Where-Object -Property PartitionStyle -eq "RAW"
}

Invoke-Command -ComputerName YAHOO-FILESYNC1, YAHOO-FILESYNC2, YAHOO-FILESYNC3 -ScriptBlock{
    $volumes = (Get-Volume | ? -Property FileSystemType -Like "NTFS" | ? -Property DriveLetter -notlike *C* | ? -Property DriveLetter -ne $null  | Sort-Object DriveLetter ).DriveLetter
    $domainUsers  = "MINECRAFTMOOSE\Domain Users"
    $domainAdmins = "MINECRAFTMOOSE\Domain Admins"

    foreach($volume in $volumes){
        $shareName = $volume + " Share01"
        $path = $volume + ":\Share01"
        New-Item -ItemType Directory $Path -Verbose *>&1
        New-SmbShare -Name $shareName -Path $path -ReadAccess "Everyone" -FullAccess $domainAdmins -Verbose

    }
}


# ===================================================
# Step 5 - Onboard the file sync servers to Azure Arc to get "System -assigned Managed Identity"
#          Install and configure the 'Storage Sync Service' by using PowerShell remoting
# ===================================================
# https://learn.microsoft.com/en-us/azure/azure-arc/servers/onboard-powershell
Install-Module -Name Az.ConnectedMachine, Az.Accounts, Az.StorageSync -Repository PSGallery -Force -Verbose *>&1
Connect-AZAccount -DeviceCode
$resourceGroupName = "az-FileSyncResourceGroup"
$location = "WestUS2"
# From ANC-PAW01 run:
$sessions = New-PSSession -ComputerName YAHOO-FILESYNC1, YAHOO-FILESYNC2, YAHOO-FILESYNC3

#Test Powershell Remoting
Invoke-Command -Session $sessions -ScriptBlock {hostname;(gwmi win32_operatingsystem).caption}

# This will create a "System -assigned Managed Identity" for the Arc object in Azure
Connect-AzConnectedMachine -ResourceGroupName $resourceGroupName -Location $location -PSSession $sessions
# ===================================================
# Step 5 - Download and install Storage Sync Agent
#          Register Servers to 'File Sync Service' in Azure
# ===================================================
Invoke-Command -ComputerName YAHOO-FILESYNC1, YAHOO-FILESYNC2, YAHOO-FILESYNC3 -ScriptBlock {
    Install-Module -Name Az.StorageSync -Repository PSGallery -Force -Confirm:$false -Verbose *>&1
} -Verbose *>&1



Invoke-Command -ComputerName YAHOO-FILESYNC1, YAHOO-FILESYNC2, YAHOO-FILESYNC3 -ScriptBlock {
    # [Microsoft provides a nice script to download the StorageSyncAgent.msi]
# https://learn.microsoft.com/en-us/azure/storage/file-sync/file-sync-deployment-guide?tabs=azure-powershell%2Cproactive-portal
# Gather the OS version.
    $osver = [System.Environment]::OSVersion.Version

    # Download the appropriate version of the Azure File Sync agent for your OS.
    if ($osver.Equals([System.Version]::new(10, 0, 20348, 0))) {
        Invoke-WebRequest -Uri https://aka.ms/afs/agent/Server2022 -OutFile "StorageSyncAgent.msi" 
    } elseif ($osver.Equals([System.Version]::new(10, 0, 17763, 0))) {
        Invoke-WebRequest -Uri https://aka.ms/afs/agent/Server2019 -OutFile "StorageSyncAgent.msi" 
    } elseif ($osver.Equals([System.Version]::new(10, 0, 14393, 0))) {
        Invoke-WebRequest -Uri https://aka.ms/afs/agent/Server2016 -OutFile "StorageSyncAgent.msi" 
    } elseif ($osver.Equals([System.Version]::new(6, 3, 9600, 0))) {
        Invoke-WebRequest -Uri https://aka.ms/afs/agent/Server2012R2 -OutFile "StorageSyncAgent.msi" 
    } else {
        throw [System.PlatformNotSupportedException]::new("Azure File Sync is only supported on Windows Server 2012 R2, Windows Server 2016, Windows Server 2019 and Windows Server 2022")
    }

    # Install the .msi file. Start-Process is used for PowerShell blocks until the operation is complete.
    # Note that the installer currently forces all PowerShell sessions closed - this is a known issue.
    Start-Process -FilePath "StorageSyncAgent.msi" -ArgumentList "/quiet" -Wait
}

# Check Service
Invoke-Command -ComputerName YAHOO-FILESYNC1, YAHOO-FILESYNC2, YAHOO-FILESYNC3 -ScriptBlock {
    Get-Service "*Storage*"
    Get-Service "FileSyncSvc"
}

# Check Service
Invoke-Command -ComputerName YAHOO-FILESYNC1, YAHOO-FILESYNC2, YAHOO-FILESYNC3 -ScriptBlock {
    $resourceGroupName = "az-FileSyncResourceGroup"
    $syncServiceName = "yahooFileSyncService"
    # On Each YAHOO-FILESYNC Server
    Connect-AZAccount -DeviceCode
    Register-AzStorageSyncServer -ResourceGroupName $resourceGroupName -StorageSyncServiceName $syncServiceName 
}



#

# ===================================================
# Step 6 - Download and install Storage Sync Agent
#          Register Servers to 'File Sync Service' in Azure
# ===================================================
$resourceGroupName = "az-FileSyncResourceGroup"
$syncServiceName = "yahooFileSyncService"
$syncGroupName = "yahooSyncGroup"
az extension add --upgrade -n storagesync
# Get FriendlyName and ServerId
az storagesync registered-server list --resource-group $resourceGroupName  --storage-sync-service $syncServiceName --query "[].{Name:friendlyName, ServerId:serverId}"


$syncServersNamesAndIDs = az storagesync registered-server list --resource-group $resourceGroupName  --storage-sync-service $syncServiceName --query "[].{Name:friendlyName, ServerId:serverId}" | ConvertFrom-Json

$syncServersNamesAndIDs[0]
$syncServersNamesAndIDs[0].Name
$syncServersNamesAndIDs[0].ServerId


 

az storagesync sync-group server-endpoint create --resource-group $resourceGroupName  `
                                                 --storage-sync-service $syncServiceName `
                                                 --sync-group-name $syncGroupName `
                                                 --name $syncServersNamesAndIDs[0].Name `
                                                 --registered-server-id $syncServersNamesAndIDs[0].ServerId `
                                                 --server-local-path E:\Share01 `
                                                 --cloud-tiering on `
                                                 --volume-free-space-percent 85 `
                                                 --tier-files-older-than-days 15 

az storagesync sync-group server-endpoint create --resource-group $resourceGroupName  `
                                                 --storage-sync-service $syncServiceName `
                                                 --sync-group-name $syncGroupName `
                                                 --name $syncServersNamesAndIDs[1].Name `
                                                 --registered-server-id $syncServersNamesAndIDs[1].ServerId `
                                                 --server-local-path E:\Share01 `
                                                 --cloud-tiering on `
                                                 --volume-free-space-percent 85 `
                                                 --tier-files-older-than-days 15                                                  

az storagesync sync-group server-endpoint create --resource-group $resourceGroupName  `
                                                 --storage-sync-service $syncServiceName `
                                                 --sync-group-name $syncGroupName `
                                                 --name $syncServersNamesAndIDs[2].Name `
                                                 --registered-server-id $syncServersNamesAndIDs[2].ServerId `
                                                 --server-local-path E:\Share01 `
                                                 --cloud-tiering on `
                                                 --volume-free-space-percent 85 `
                                                 --tier-files-older-than-days 15 


# Add files to each E:\Share01 on any server and watch the syncing between servers and Azure File Share!
\\yahoo-filesync1\E Share01
\\yahoo-filesync2\E Share01
\\yahoo-filesync3\E Share01
