# =============================================================================
# Hyper-V Lab Creation 
# =============================================================================
# Author:   Mark Kruse
# Purpose:  Quick Create Tools- Create VMs from ISO or golden images,
#           add extra network adapters and data disks.  Also a tool to Initialize Raw Offline Disks quickly
# Location: Anchorage, Alaska lab environment
# =============================================================================

# -----------------------------------------------------------------------------
#  Preparation Steps – Golden Image Creation (manual / one-time commands)
# -----------------------------------------------------------------------------
# Sysprep the reference machine
# C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown

# After shutdown → Copy .vhdx → rename to GoldenImage-*.vhdx
#>

# -----------------------------------------------------------------------------
#  Virtual Switch Creation (one-time setup – run once)
# -----------------------------------------------------------------------------

<#
New-VMSwitch -Name "ANC-Net"  -SwitchType Private -Verbose *>&1
New-VMSwitch -Name "Nome-Net" -SwitchType Private -Verbose *>&1
New-VMSwitch -Name "JUN-Net"  -SwitchType Private -Verbose *>&1
New-VMSwitch -Name "Linux-Net" -SwitchType Private -Verbose *>&1
New-VMSwitch -Name "EXT-INT"  -NetAdapterName "Wi-Fi" -AllowManagementOS $true
#>
# ALL FUNCTIONS NEED TO BE RUN AS ADMIN
# -----------------------------------------------------------------------------
#  Main VM Creation Function - RUN AS ADMIN
# -----------------------------------------------------------------------------

function New-Lab_VM
{
    <#
    .SYNOPSIS
        Creates one or more Hyper-V Generation 2 virtual machines from either:

        • Windows Server ISO (clean install)
        • Generalized Desktop Experience golden image
        • Generalized Server Core golden image

    .DESCRIPTION
        Supports multiple VMs at once, custom RAM, multiple NICs, extra data disks,
        dynamic memory option, and automatic start.

    .PARAMETER VMNames
        One or more names for the virtual machines to create

    .PARAMETER HyperVSwitch
        Name of the virtual switch for the primary network adapter

    .PARAMETER RAM_GB
        Startup RAM in GB (default: 1)

    .PARAMETER AdapterCount
        Total number of network adapters (default: 1)

    .PARAMETER nonOSdiskcount
        Number of additional data disks to attach (default: 0)

    .PARAMETER nonOSdisksize
        Size in GB for each additional data disk (default: 128)

    .PARAMETER DynamicMemory
        Enable Dynamic Memory (default: $false – fixed memory)

    .PARAMETER ISOPath
        Full path to Windows Server evaluation ISO (ISO mode only)

    .PARAMETER GeneralizedImageDE
        Use Desktop Experience golden image (mutually exclusive)

    .PARAMETER GeneralizedImageCore
        Use Server Core golden image (mutually exclusive)

    .EXAMPLE
        # Create single VM from ISO
        New-Lab_VM -VMNames "ANC-RRAS01" -HyperVSwitch "EXT-INT" -AdapterCount 4 -ISOPath $vmiso_path

    .EXAMPLE
        # Create two DCs from Server Core golden image
        New-Lab_VM -VMNames "DC01","DC02" -HyperVSwitch "ANC-Net" -RAM_GB 4 -GeneralizedImageCore

    .EXAMPLE
        # File server with 6 data disks and dynamic memory
        New- Lab_VM -VMNames "FS01" -HyperVSwitch "JUN-Net" -RAM_GB 6 -nonOSdiskcount 6 -nonOSdisksize 200 -DynamicMemory -GeneralizedImageDE
    #>

    [CmdletBinding(DefaultParameterSetName = 'ISOPath')]
    Param(
        # VMNames appears in all sets, same position
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ISOPath')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'GeneralizedImageDE')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'GeneralizedImageCore')]
        [string[]] $VMNames,

        # HyperVSwitch appears in all sets
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ISOPath')]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'GeneralizedImageDE')]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'GeneralizedImageCore')]
        [string] $HyperVSwitch,

        # Shared optional parameters
        [Parameter(ParameterSetName = 'ISOPath')]
        [Parameter(ParameterSetName = 'GeneralizedImageDE')]
        [Parameter(ParameterSetName = 'GeneralizedImageCore')]
        [Int64] $RAM_GB = 1GB,

        [Parameter(ParameterSetName = 'ISOPath')]
        [Parameter(ParameterSetName = 'GeneralizedImageDE')]
        [Parameter(ParameterSetName = 'GeneralizedImageCore')]
        [int] $AdapterCount = 1,

        [Parameter(ParameterSetName = 'ISOPath')]
        [Parameter(ParameterSetName = 'GeneralizedImageDE')]
        [Parameter(ParameterSetName = 'GeneralizedImageCore')]
        [int] $nonOSdiskcount = 0,

        [Parameter(ParameterSetName = 'ISOPath')] 
        [Parameter(ParameterSetName = 'GeneralizedImageDE')]
        [Parameter(ParameterSetName = 'GeneralizedImageCore')]
        [int] $nonOSdisksize = 128,

        # Set-specific switches
        [Parameter(Mandatory = $false, ParameterSetName = 'ISOPath')]
        [Parameter(Mandatory = $false, ParameterSetName = 'GeneralizedImageDE')]
        [Parameter(ParameterSetName = 'GeneralizedImageCore')]
        [switch] $DynamicMemory,

        [Parameter(Mandatory = $true, ParameterSetName = 'ISOPath')]
        [string] $ISOPath = "C:\iso\SERVER_EVAL_x64FRE_en-us.iso",

        [Parameter(Mandatory = $true, ParameterSetName = 'GeneralizedImageDE')]
        [switch] $GeneralizedImageDE,

        [Parameter(Mandatory = $true, ParameterSetName = 'GeneralizedImageCore')]
        [switch] $GeneralizedImageCore
    )

    try{
        Get-VMSwitch -Name $HyperVSwitch -Verbose *>&1 -ErrorAction Stop
    }
    catch{
        Write-Verbose "Invalid Hyper-V Switch Name" -Verbose *>&1
        break
    }

    foreach($VMName in $VMNames){

        $VMPath = "C:\Hyper-V\VMs"           # Folder to store VM configuration files
        $HostVHDPath = (Get-VMHost).VirtualHardDiskPath
        $newVHDPath = $HostVHDPath + "\" + "$VMName.vhdx"  # Path for the virtual hard disk
        $GeneralizedImagePathDE = "C:\GoldenImages\GoldenImage-DesktopExperience.vhdx"
        $GeneralizedImagePathCore = "C:\GoldenImages\GoldenImage-ServerCore.vhdx"
        $VHDSize = 128GB 
        $MemoryStartup = $RAM_GB                      # Size of the new VHDX             # Memory
        $ProcessorCount = ((Get-WmiObject -Class Win32_Processor).NumberOfLogicalProcessors / 2)      # Number of vCPUs
        # Create the VM with a new dynamic VHDX
        if($GeneralizedImageDE){
        Copy-Item -Path $GeneralizedImagePathDE -Destination $newVHDPath -Verbose *>&1
        New-VM -Name $VMName `
                -Path $VMPath `
                -Generation 2 `
                -MemoryStartupBytes $MemoryStartup`
                -SwitchName $HyperVSwitch `
                -Verbose *>&1
                
        Add-VMHardDiskDrive -VMName $VMName -Path $newVHDPath
        Add-VMDvdDrive -VMName $VMName -Verbose *>&1
        }
        elseif($GeneralizedImageCore){
        Copy-Item -Path $GeneralizedImagePathCore -Destination $newVHDPath -Verbose *>&1
        New-VM -Name $VMName `
                -Path $VMPath `
                -Generation 2 `
                -MemoryStartupBytes $MemoryStartup`
                -SwitchName $HyperVSwitch `
                -Verbose *>&1
                
        Add-VMHardDiskDrive -VMName $VMName -Path $newVHDPath
        Add-VMDvdDrive -VMName $VMName -Verbose *>&1
        }
        else{
        try{
            Get-ChildItem $ISOPath -ErrorAction STOP | Out-Null
        }
        catch{
            Write-Verbose "The ISO Path [$ISOPath] is invalid.  `nPlease move ISO to correct path or use ISO Parameter to specify ISO path <@:D`nStopping Function Call" -Verbose *>&1
            Break            
        }
  
            New-VM -Name $VMName `
                    -Path $VMPath `
                    -NewVHDPath $newVHDPath `
                    -NewVHDSizeBytes $VHDSize `
                    -Generation 2 `
                    -MemoryStartupBytes $MemoryStartup `
                    -SwitchName $HyperVSwitch `
                    -Verbose *>&1
                
            try{
                Add-VMDvdDrive -VMName $VMName -Path $ISOPath -ErrorAction Stop -Verbose *>&1
            }
            catch{
                Add-VMDvdDrive -VMName $VMName -Verbose *>&1
            }           
    }###################################
        # Configure processor and disable dynamic memory
        Set-VM -Name $VMName `
            -ProcessorCount $ProcessorCount `
            -AutomaticCheckpointsEnabled $False `
            -CheckpointType "Production" `
            -Verbose *>&1
        Set-VMMemory $VMName -DynamicMemoryEnabled $false -Verbose *>&1

        if($dynamicMemory){
            Set-VMMemory $VMName -DynamicMemoryEnabled $true -Verbose *>&1
            Set-VM -Name $VMName `
                -MemoryMinimumBytes 1GB `
                -MemoryMaximumBytes 8GB
            

        }

        # Add and Attach the ISO to a DVD drive
        # Optional: Enable Secure Boot (recommended for Windows 11+)JI
        Set-VMFirmware -VMName $VMName -EnableSecureBoot On -Verbose *>&1

        $DvdDrive = Get-VMDvdDrive -VMName $VMName
        $HardDrive = Get-VMHardDiskDrive -VMName $VMName

        #Set First boot device
        Set-VMFirmware -VMName $VMName -FirstBootDevice $DvdDrive -Verbose *>&1
        # Set boot order: DVD first, then hard disk, then network
        Set-VMFirmware -VMName $VMName -BootOrder $DvdDrive, $HardDrive -Verbose *>&1



        Write-Verbose -Message "VM '$VMName' created successfully! Check Hyper-V Manager." -Verbose *>&1

        ###################################_FILE SERVERS_#########################################
        if($nonOSdiskcount){
            foreach($x in 1..$nonOSdiskcount){
                New-VHD -Path "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\$VMName.Disk$X.vhdx" -SizeBytes ($nonOSdisksize * 1GB) -Verbose *>&1
            }
            foreach($x in 1..$nonOSdiskcount){
               [array]$disks +=  Get-VHD -Path "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\$VMName.Disk$x.vhdx"
            }            

            foreach($disk in $disks){
                Add-VMHardDiskDrive -VMName $VMName -Path $disk.path -Verbose *>&1
            }
        }
        $disks = @() #reset Array




        
        if($adaptercount -lt 1){
            throw "Can't have Zero or negative number of Network Adapters"
        }
        elseif($AdapterCount -eq 1){
            "skip"
        }
        else{
            Rename-VMNetworkAdapter -VMName $VMName -Name "Network Adapter" -NewName "NetAdapter.1"
            foreach($adapater in 2..($adaptercount)){
                Add-VMNetworkAdapter -VMName $VMName -SwitchName $HyperVSwitch -Name "NetAdapter.$adapater" -Verbose *>&1
            }
        }

        Write-Output "$VMName Starting "
        Start-VM $VMName -Verbose *>&1
    }

    # if($isFileServer -eq $true) {
    #     Write-Verbose -Message "$Name `n $numberOfVMs `n $ISOPath `n $isFileServer" -Verbose *>&1
    # }
    
}

# Example call (commented)
# New-AZLab_VM -VMNames "ANC-RRAS01" -HyperVSwitch EXT-INT -AdapterCount 4 -ISOPath $vmiso_path

# -----------------------------------------------------------------------------
#  Add extra data disks to existing VM - RUN AS ADMIN
# -----------------------------------------------------------------------------

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
        Add-Disks2VM "SQL01" "DB" 2 200
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




# -----------------------------------------------------------------------------
#  Initialize any Raw Offline Disks - RUN AS ADMIN
# -----------------------------------------------------------------------------
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


# -----------------------------------------------------------------------------
#  Reset Lab – Destructive – Removes everything - RUN AS ADMIN
# -----------------------------------------------------------------------------

function _ResetLabNow {
    <#
    .SYNOPSIS
        Force-stop and completely delete ALL virtual machines and ALL .vhdx files 
        in the default Virtual Hard Disks folder.

    .DESCRIPTION
        Extremely destructive function — use only when you want to start from scratch.
        No confirmation is asked when called without -Confirm.

    .EXAMPLE
        _ResetLabNow

    .EXAMPLE
        _ResetLabNow -Confirm
    #>

    Get-VM | Stop-VM -Confirm:$false -Force -Verbose *>&1
    
    # Delete VHDs  
    $disks2delete = (Get-ChildItem 'C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\').fullname
    foreach($disk in $disks2delete){
        Remove-Item $disk -Verbose *>&1
    }

    # Delete VMs
    Get-VM | Remove-VM -Confirm:$false -Force -Verbose *>&1

}
