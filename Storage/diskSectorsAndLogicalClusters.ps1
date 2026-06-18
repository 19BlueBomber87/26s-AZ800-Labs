# =============================================================================
# Storage Labs
# =====================
# Author:   Mark Kruse
# Purpose:  Configuring Drives, Volumes, Allocation Size and Shares
# Location: Anchorage, Alaska lab environment
# ====================================================================================

# 1 KB = 1024 bytes
# 4 KB = 4096 bytes
# 1KB  # 1024 bytes
# 1MB  # 1024 * 1024 = 1,048,576 bytes
# 1GB  # 1024 * 1024 * 1024 = 1,073,741,824 bytes
# 1TB / 1000GB = 1.024
# 1GB / 1000MB = 1.024
# 1024KB / 1MB = 1
# 1024MB / 1GB = 1
# 1024TB / 1PB = 1
$(1TB).gettype()
Write-Verbose -Message "1024TB / 1PB =  $(1024TB / 1PB)PB" -Verbose *>&1
# For powershell commands you can use 1KB to represent 1024 bytes or 4KB to represent 4096
# Term                  Meaning
# --------------------  -----------------------------------------------
# Sector                Smallest unit the disk hardware reads/writes
# Cluster               Smallest unit the filesystem allocates

# File Size             Space Used on Disk
# --------------------  ----------------------
# 1 byte                4 KB (1 Cluster)(Waste: 4095 Bytes)
# 2 KB                  4 KB (1 Cluster)(Waste: 2 KB)
# 4 KB                  4 KB (1 Cluster)(Waste: 0 KB)
# 5 KB                  8 KB (2 clusters)(Waste: 3 KB)
# 1600 KB(1.6 MB)       1600 KB (40 Clusters)(Waste: 0 KB)
# 1601 KB(1.601 MB)     1604 KB (41 Clusters)(Waste 3 KB)

# FAT32 Works on almost everything (cameras, consoles, BIOS tools, etc.)

# The maximum volume size for exFAT is 128 petabytes (PB)
# Bytes Per Sector : 512 → This is the Logical Sector Size
# Bytes Per Physical Sector : 4096 → This is the Physical Sector Size
fsutil fsinfo ntfsinfo d:\


# Disk
Get-PhysicalDisk
Get-PhysicalDisk -DeviceNumber 2 | fl *

Get-PhysicalDisk | 
    Select-Object FriendlyName, 
                  LogicalSectorSize, 
                  PhysicalSectorSize, 
                  @{Name='SizeGB'; Expression={[math]::Round($_.Size / 1GB, 2)}} | 
    Format-Table -AutoSize


# Volume
Get-Volume C | fl *
Get-Volume D | fl *

Get-Volume | Where-Object DriveLetter | 
    Select-Object DriveLetter, FileSystemType, FriendlyName, 
           @{Name='Size GB'; Expression={[math]::Round($_.Size/1GB,2)}},
           @{Name='Cluster Size'; Expression={"$([math]::Round($_.AllocationUnitSize / 1KB)) KB"}} | 
    Format-Table -AutoSize

#  “allocation unit size” is another name for a cluster size.
# Format D: with 1KB allocation unit size
# 1 KB = 1024 bytes
# 4 KB = 4096 bytes
# For powershell commands you can use 1KB to represent 1024 bytes or 4KB to represent 4096
Format-Volume -DriveLetter D -FileSystem NTFS -AllocationUnitSize 1KB -NewFileSystemLabel "Data" -Confirm:$false -Verbose *>&1
Format-Volume -DriveLetter D -FileSystem NTFS -AllocationUnitSize 4KB -NewFileSystemLabel "Data" -Confirm:$false -Verbose *>&1
Format-Volume -DriveLetter D -FileSystem NTFS -AllocationUnitSize 1024 -NewFileSystemLabel "Data" -Confirm:$false -Verbose *>&1
Format-Volume -DriveLetter D -FileSystem NTFS -AllocationUnitSize 4096 -NewFileSystemLabel "Data" -Confirm:$false -Verbose *>&1
Format-Volume -DriveLetter D -FileSystem NTFS -AllocationUnitSize 64KB -NewFileSystemLabel "Data" -Confirm:$false -Verbose *>&1
Format-Volume -DriveLetter D -FileSystem NTFS -AllocationUnitSize 256KB -NewFileSystemLabel "Data" -Confirm:$false -Verbose *>&1

# Clear Partitions and Volumes
Get-Partition -DiskNumber 2 
Get-Partition -DiskNumber 2 | Remove-Partition -Confirm:$false -Verbose *>&1

# The 'New-Partition' command creates both the Partition and the Volume
New-Partition -DiskNumber 2 -Size 4GB -AssignDriveLetter -Verbose *>&1
New-Partition -DiskNumber 2 -UseMaximumSize -AssignDriveLetter -Verbose *>&1
Get-Partition
Format-Volume -DriveLetter D -FileSystem NTFS -AllocationUnitSize 1024 -NewFileSystemLabel "Data" -Confirm:$false -Verbose *>&1
Format-Volume -DriveLetter F -FileSystem FAT32 -AllocationUnitSize 2048 -NewFileSystemLabel "Data" -Confirm:$false -Verbose *>&1


