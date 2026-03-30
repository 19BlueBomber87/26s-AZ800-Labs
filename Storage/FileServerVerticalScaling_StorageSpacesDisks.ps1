# =============================================================================
# Hyper-V Lab Creation
# =====================
# Author:   Mark Kruse
# Purpose:  Create a File Server with 4 non-OS disks fromated as ReFs
#           Add 16 diks to the file server fromated as ReFs
#           Example of Vertical scaling
# Location: Anchorage, Alaska lab environment
# ==========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-QuickCreate-GoldenImages/AZ-800Celebrate-HyperV%20Creation%20and%20Disk%20Functions.ps1
# ==========================================================================================================================================================
# ===================================================
#  Prerequisites
# ===================================================
# YAHOO-RRAS01 -> One RRAS server for routing
# ANC-DC01     -> One domain controller 
# ANC-PAW01    -> One server to be privileged access workstation(PAW) management server

 
# ===================================================
# Step 1 - Create File Server
#          Create Server to be privileged access workstation(PAW) management server
# ===================================================

# From Host run:
New-Lab_VM -VMNames YAHOO-FILE01 -HyperVSwitch ANC-NET -nonOSdiskcount 4 -nonOSdiskSizeGB 250 -GeneralizedImageCore
New-Lab_VM -VMNames YAHOO-PAW01 -HyperVSwitch ANC-NET -GeneralizedImageDE

# Change computer name to ANC-Clus01 and join to domain
# From the YAHOO-FILE01 VM run:
Rename-Computer -NewName YAHOO-FILE01 -Restart -Verbose *>&1
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator  -Restart -Verbose *>&1


# Change computer name to ANC-Clus01 and join to domain
# From the YAHOO-PAW01 VM run:
Rename-Computer -NewName YAHOO-PAW01 -Restart -Verbose *>&1
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\administrator  -Restart -Verbose *>&1
# ===============================================================
#  Step 2 - Initialize any Raw Offline Disks on YAHOO-FILE01 - RUN AS ADMIN
# ==============================================================
function Initialize-RawOfflineDisks {
    <#
    .SYNOPSIS
        Initializes all offline RAW disks, creates a single maximum-size GPT partition 
        with an assigned drive letter, and formats the volume using ReFS.

    .DESCRIPTION
        This function targets disks that are both Offline and have RAW partition style.
        It performs the exact sequence:
          - Initialize-Disk (GPT)
          - New-Partition (max size + assign drive letter)
          - Format-Volume (ReFS)
        
        Typically run inside a lab VM after attaching additional data disks.

        WARNING: Destructive to any matching disks — no safety checks added.

    .EXAMPLE
        # Run inside the VM to prepare all new data disks
        Initialize-RawOfflineDisks

    .EXAMPLE
        # Pipe to see verbose output
        Initialize-RawOfflineDisks -Verbose

    .NOTES
        Original logic preserved exactly, including debug line ($partition.DriveLetter).gettype()
    #>

    [CmdletBinding()]
    param()

    $disks = Get-Disk | 
        Where-Object -Property OperationalStatus -eq "Offline" | 
        Where-Object -Property PartitionStyle -eq "RAW"

    foreach($disk in $disks){
        Initialize-Disk -Number $disk.number -PartitionStyle GPT -Verbose *>&1
        $partition = New-Partition -DiskNumber $disk.number -UseMaximumSize -AssignDriveLetter -Verbose *>&1
        ($partition.DriveLetter).gettype()
        Format-Volume -DriveLetter $partition.DriveLetter -FileSystem ReFS -Verbose *>&1
        Clear-Variable partition -Verbose *>&1
    }
}




# On YAHOO-FILE01 Run the function:
Initialize-RawOfflineDisks
Get-PSDrive

# On YAHOO-PAW01, test visability
Test-Path \\YAHOO-FILE01\E$
Test-Path \\YAHOO-FILE01\F$
Test-Path \\YAHOO-FILE01\G$
Test-Path \\YAHOO-FILE01\H$

# Test from File explore on ANC-PAW01 the 
# ADD YAHOO-File01 to Server Manger to see and manage disks

Invoke-Command -ComputerName YAHOO-FILE01 -ScriptBlock {
    Get-Disk | Format-Table;
    Get-Volume | Sort-Object DriveLetter | Format-Table;
    Get-Volume | ? -Property FileSystemType -Like "ReFS" | Sort-Object DriveLetter | Format-Table
}


# ===============================================================
# Step 3 Add extra 17 data disks to existing VM - RUN AS ADMIN from host- This is vertical scaling
# ===============================================================

function Add-Disks2VM{
    <#
    .SYNOPSIS
        Creates and attaches multiple identically-sized VHDX data disks to an existing VM

    .PARAMETER VMName
        Name of the virtual machine to add disks to

    .PARAMETER DiskSetName
        Prefix/name for the disk set (e.g. "Data", "Archive", "Logs")

    .PARAMETER DiskCount
        How many disks to create (default: 1)

    .PARAMETER DiskSize
        Size in GB for each disk (default: 128)

    .EXAMPLE
        Add-Disks2VM -VMName "FS01" -DiskSetName "Storage" -DiskCount 4 -DiskSize 500

    .EXAMPLE
        Add-Disks2VM -VMName "SQL01" -DiskSetName "DB" -DiskCount 2 -DiskSize 200
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='Set1')]
        [string] $VMName,

        [Parameter(Mandatory=$true, Position=1, ParameterSetName='Set1')]
        [string] $DiskSetName,
        
        [Parameter(Mandatory=$false, ParameterSetName='Set1')]
        [int] $DiskCount = 1,

        [Parameter(Mandatory=$false, ParameterSetName='Set1')]
        [int] $DiskSize = 128
    )

    foreach($x in 1..$DiskCount){
        New-VHD -Path "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\$VMName.$DiskSetName.Disk$x.vhdx" -SizeBytes ($DiskSize * 1GB) -Verbose *>&1
    }
    foreach($y in 1..$DiskCount){
    [array]$disks +=  Get-VHD -Path "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\$VMName.$DiskSetName.Disk$y.vhdx"
    }            
    $disks

    foreach($disk in $disks){
        Add-VMHardDiskDrive -VMName $VMName -Path $disk.path -Verbose *>&1
    }
}




Add-Disks2VM -VMName "Yahoo-File01" -DiskSetName "Expand" -DiskCount 17 -DiskSize 350

# ===============================================================
#  Step 4 - Initialize the new Raw Offline Disks that were just added on YAHOO-FILE01 - RUN AS ADMIN
# ==============================================================
# On YAHOO-FILE01 Run the function:
Initialize-RawOfflineDisks



# On YAHOO-PAW01, test visability
Get-PSDrive
Test-Path \\YAHOO-FILE01\X$
Test-Path \\YAHOO-FILE01\Y$
Test-Path \\YAHOO-FILE01\Z$

# Test from File explore on ANC-PAW01 the 
# ADD YAHOO-File01 to Server Manger to see and manage disks

Invoke-Command -ComputerName YAHOO-FILE01 -ScriptBlock {
    Get-Disk | Format-Table;
    Get-Volume | Sort-Object DriveLetter | Format-Table;
    Get-Volume | ? -Property FileSystemType -Like "ReFS" | Sort-Object DriveLetter | Format-Table
}


# ===============================================================
#  Step 5 - Create File Shares
# ==============================================================

# Create one folder per volume to share

$volumes = (Get-Volume | ? -Property FileSystemType -Like "ReFS" | Sort-Object DriveLetter ).DriveLetter
$domainUsers  = "MINECRAFTMOOSE\Domain Users"
$domainAdmins = "MINECRAFTMOOSE\Domain Admins"

foreach($volume in $volumes){
    $shareName = $volume + " Share01"
    $path = $volume + ":\Share01"
    New-Item -ItemType Directory $Path -Verbose *>&1
    New-SmbShare -Name $shareName -Path $path -ReadAccess "Everyone" -FullAccess $domainAdmins -Verbose

}



# ===============================================================
#  Ste5  -  Create Storage Spaces Drives - Use Gui or Powershell
# ==============================================================

# Reset disks - 
$volumes = (Get-Volume | ? -Property FileSystemType -Like "ReFS" | Sort-Object DriveLetter ).DriveLetter

foreach($volume in $volumes){
    Get-Partition -DriveLetter $volume | Remove-Partition -Confirm:$false -Verbose *>&1

}


# PowerShell
# Create Storage pool.  
Invoke-Command -ComputerName YAHOO-FILE01 -ScriptBlock {
    $poolName = "MegaPool01"
    $subsystem = (Get-StorageSubSystem).FriendlyName
    $disks = Get-PhysicalDisk -CanPool $true
    New-StoragePool -FriendlyName $poolName -StorageSubSystemFriendlyName $subsystem -PhysicalDisks $disks -ResiliencySettingNameDefault Parity -ProvisioningTypeDefault Thin -Verbose *>&1
    
} -Verbose *>&1

# Check Storage Pool
Invoke-Command -ComputerName YAHOO-FILE01 -ScriptBlock {
    Get-StoragePool
} -Verbose *>&1


# Create large virtual disk from storage pool
Invoke-Command -ComputerName YAHOO-FILE01 -ScriptBlock {

    $vdName   = "MegaDisk01"
    $poolName = "MegaPool01"

    New-VirtualDisk -FriendlyName $vdName -StoragePoolFriendlyName $poolName -Size 1TB -ResiliencySettingName Parity -ProvisioningType Thin -Verbose *>&1

} -Verbose *>&1

Invoke-Command -ComputerName YAHOO-FILE01 -ScriptBlock {
    Get-Disk | Format-Table
}

# Use custom function to format disk volume
Initialize-RawOfflineDisks

Invoke-Command -ComputerName YAHOO-FILE01 -ScriptBlock {
    Get-Volume | ? -Property FileSystemType -Like "ReFS" | Sort-Object DriveLetter | Format-Table
}

Invoke-Command -ComputerName YAHOO-FILE01 -ScriptBlock {
    New-Item -ItemType Directory "E:\MegaShare01" -Verbose *>&1
    New-SmbShare -Name "MegaShare01" -Path "E:\MegaShare01" -ReadAccess "Everyone" -FullAccess "Minecraftmoose\Domain Admins" -Verbose

}


# GUI 
# 1 - Add Yahoo-File01 to Server manager on YAHOO-PAW01
# 2 - Click on Storage Pools -> Tasks -> New Storage Pool -> The Wizard Starts -> Name Pool -> Select available Disks -> Create
# 3 - Click on the new Storage Pool -> From the 'VIRTUAL DISKS' pane click on Tasks -> New Virtual Disk -> Name The disk -> We have no enclousers, click next -> For Storage Layout pick Parity -> Thin Provisioning -> 1TB -> Create
# 4 - New Volume Wizard -> YAHOO-FILE01 and pick the 1TB disk -> Volume Size: 1024 GB -> Pick Drive Letter -> Use ReFS for File System and Name Volume -> Create
# 5 - Share out the Volume

Invoke-Command -ComputerName YAHOO-FILE01 -ScriptBlock {
    New-Item -ItemType Directory "E:\GUI-Share01" -Verbose *>&1
    New-SmbShare -Name "GUI-Share01" -Path "E:\GUI-Share01" -ReadAccess "Everyone" -FullAccess "Minecraftmoose\Domain Admins" -Verbose

}