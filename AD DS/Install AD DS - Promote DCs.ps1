# =============================================================================
# Hyper-V Lab Creation - Install AD DS and Promote DCs
# =============================================================================
# Author:   Mark Kruse
# Purpose: Install AD DS role and promote server(s) to domain controller(s) via PowerShell.
# =========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-QuickCreate-GoldenImages/AZ-800Celebrate-HyperV%20Creation%20and%20Disk%20Functions.ps1
# =========================================================================================================================================================

# ========================================================
# Step  1 -Create DCs - One per Domain - Install AD DS
# ========================================================
#Create DCs
New-Lab_VM ANC-DC01 -HyperVSwitch ANC-Net -GeneralizedImageDE
New-Lab_VM Nome-DC01 -HyperVSwitch Nome-Net -GeneralizedImageDE
New-Lab_VM JUN-DC01 -HyperVSwitch Jun-Net -GeneralizedImageDE
New-Lab_VM ER-DC01 -HyperVSwitch ER-Net -GeneralizedImageDE

#On Each DC, Install AD DS
# Get-WindowsFeature | Where-Object -Property name -like *AD*
# Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1

# ====================================================
# Step 2 - Install AD DS and Promote ANC-DC01 to DC.  
# Root Domain - minecraftmoose.com
# ====================================================
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow

Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Rename-Computer -NewName ANC-DC01 -Restart -Verbose *>&1

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
$DSRMPassword = Read-Host "Enter DSRM Password" -AsSecure
Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "minecraftmoose.com" `
-DomainNetbiosName "MINECRAFTMOOSE" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SafeModeAdministratorPassword  $DSRMPassword `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true

New-ADReplicationSite -Name Nome -Description "Nome Office AD DS Site" -Verbose *>&1
New-ADReplicationSite -Name Juneau -Description "Nome Office AD DS Site" -Verbose *>&1
New-ADReplicationSite -Name EagleRiver -Description "Nome Office AD DS Site" -Verbose *>&1
New-ADReplicationSubnet -Name "192.168.88.0/24" -Site Nome -Location "Nome Office"
New-ADReplicationSubnet -Name "192.168.99.0/24" -Site Nome -Location "Juneau Office"
New-ADReplicationSubnet -Name "192.168.100.0/24" -Site Nome -Location "Eagle River Office"

Set-ADReplicationSiteLink -Identity "DEFAULTIPSITELINK" -SitesIncluded @{Add="Nome","Juneau","EagleRiver"}
# ====================================================
# Step 3 - Install AD DS and Promote Nome-DC01 to DC.  
# Tree Domain. moosewyre.fun This will be the second tree in the Forest.  
# ====================================================
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow

# Set static IP + subnet + default gateway in one command
New-NetIPAddress -InterfaceAlias "Ethernet" `
    -IPAddress 192.168.88.8 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.88.1 `
    -AddressFamily IPv4 `
    -Verbose *>&1

# Set DNS server(s)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
    -ServerAddresses 192.168.77.7, 8.8.8.8 `  # When setting up a Tree Domain, use the DNS server of the root domain.  

Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Rename-Computer -NewName Nome-DC01 -Restart -Verbose *>&1

$DSRMPassword = Read-Host "Enter DSRM Password" -AsSecure
Import-Module ADDSDeployment
Install-ADDSDomain `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$false `
-Credential (Get-Credential -Credential administrator@minecraftmoose.com) `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainType "TreeDomain" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NewDomainName "moosewyre.fun" `
-NewDomainNetbiosName "MOOSEWYRE" `
-ParentDomainName "minecraftmoose.com" `
-NoRebootOnCompletion:$false `
-SiteName "Nome" `
-SafeModeAdministratorPassword  $DSRMPassword `
-SysvolPath "C:\Windows\SYSVOL" -Force:$true


# ========================================================
# Step 3  - Install AD DS and Promote ER-DC01 to DC.  
# This is a Child Forest - dev.moosewyre.fun
# ========================================================
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow

# Set static IP + subnet + default gateway in one command
New-NetIPAddress -InterfaceAlias "Ethernet" `
    -IPAddress 192.168.100.9 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.100.1 `
    -AddressFamily IPv4 `
    -Verbose *>&1

# Set DNS server(s)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
    -ServerAddresses 192.168.88.8, 8.8.8.8

Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Rename-Computer -NewName ER-DC01 -Restart -Verbose *>&1

$DSRMPassword = Read-Host "Enter DSRM Password" -AsSecure
Import-Module ADDSDeployment
Install-ADDSDomain `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$true `
-Credential (Get-Credential -Credential administrator@minecraftmoose.com) `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainType "ChildDomain" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NewDomainName "dev" `
-NewDomainNetbiosName "DEV" `
-ParentDomainName "moosewyre.fun" `
-NoRebootOnCompletion:$false `
-SiteName "Nome" `
-SysvolPath "C:\Windows\SYSVOL" `
-SafeModeAdministratorPassword  $DSRMPassword -Force:$true


Move-ADDirectoryServer -Identity "ER-DC01" -Site "EagleRiver" -Confirm:$false
# ========================================================
# Step 4  - Install AD DS and Promote JUN-DC01 to DC.  
# This is a New Forset - megamooselabsfun.com
# ========================================================
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow

# Set static IP + subnet + default gateway in one command
New-NetIPAddress -InterfaceAlias "Ethernet" `
    -IPAddress 192.168.99.9 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.99.1 `
    -AddressFamily IPv4 `
    -Verbose *>&1

# Set DNS server(s)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
    -ServerAddresses 127.0.0.1, 8.8.8.8

Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Rename-Computer -NewName Jun-DC01 -Restart -Verbose *>&1

$DSRMPassword = Read-Host "Enter DSRM Password" -AsSecure
Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "megamooselabsfun.com" `
-DomainNetbiosName "MEGAMOOSELABSFU" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-SafeModeAdministratorPassword  $DSRMPassword -Force

# ANC-DC01, NOME-DC01 and ER-DC01 share a Schema
# #AD Partitions
# ntdsutil.exe
# activate instance ntds
# partition management
# connections
# connect to server ANC-DC01
# quit
# list

# ========================================================
# Step 5  - Create a two way forest trust between megamooselabsfun.com and moosewyre.fun
# ========================================================
# +-----------------+------------------------+------------+------------------------+-----------------------+
# | Trust Type      | Scope                  | Transitive | Direction              | Created Automatically |
# +-----------------+------------------------+------------+------------------------+-----------------------+
# | Parent-Child    | Same tree              | Yes        | Two-way                | Yes                   |
# +-----------------+------------------------+------------+------------------------+-----------------------+
# | Tree Root       | Same forest            | Yes        | Two-way                | Yes                   |
# +-----------------+------------------------+------------+------------------------+-----------------------+
# | Shortcut        | Same forest            | Yes        | One or Two-way         | No                    |
# +-----------------+------------------------+------------+------------------------+-----------------------+
# | External        | Domain-to-domain       | No         | One or Two-way         | No                    |
# +-----------------+------------------------+------------+------------------------+-----------------------+
# | Forest          | Forest-to-forest       | Yes        | One or Two-way         | No                    |
# +-----------------+------------------------+------------+------------------------+-----------------------+
# | Realm           | AD ↔ Kerberos realm    | Optional   | One or Two-way         | No                    |
# +-----------------+------------------------+------------+------------------------+-----------------------+
# Ensure the Active Directory module is loaded
Import-Module ActiveDirectory -ErrorAction Stop

# Jun-DC01
    Add-DnsServerConditionalForwarderZone `
    -Name "minecraftmoose.com" `
    -MasterServers "192.168.77.7" `
    -ReplicationScope Forest                    # Replicates to all DCs in the forest

# ANC-DC01
Add-DnsServerConditionalForwarderZone `
    -Name "megamooselabsfun.com" `
    -MasterServers "192.168.99.9" `
    -ReplicationScope Forest                     # Replicates to all DCs in the forest

# You need Enterprise Admin privileges in both forests.

# The netdom trust command can't be used to create a forest trust between two AD DS forests. To create a cross-forest trust between two AD DS forests, use the Active Directory Domains and Trusts snap-in to create and manage forest trusts. Scripting solution such as using PowerShell is also an option for managing these types of trusts if you need to automate the process.

# Jun-DC01
$strRemoteForest = "minecraftmoose.com" 
$strRemoteAdmin = "administrator@minecraftmoose.com" 
$strRemoteAdminPassword = "Password123!" 
$remoteContext = New-Object -TypeName "System.DirectoryServices.ActiveDirectory.DirectoryContext" -ArgumentList @( "Forest",$strRemoteForest, $strRemoteAdmin, $strRemoteAdminPassword) 
try { 
$remoteForest =[System.DirectoryServices.ActiveDirectory.Forest]::getForest($remoteContext) 
#Write-Host "GetRemoteForest: Succeeded for domain $($remoteForest)" 
}catch { 
Write-Verbose "GetRemoteForest: Failed:`n`tError: $($($_.Exception).Message)" -Verbose *>&1
} 

Write-Verbose "Connected to Remote forest: $($remoteForest.Name)" -Verbose *>&1
$localforest=[System.DirectoryServices.ActiveDirectory.Forest]::getCurrentForest() 
Write-Verbose "Connected to Local forest: $($localforest.Name)" -Verbose *>&1

try { 
$localForest.CreateTrustRelationship($remoteForest,"Inbound") 
Write-Verbose "CreateTrustRelationship: Succeeded for domain $($remoteForest)" -Verbose *>&1 

}catch { 
Write-Verbose "CreateTrustRelationship: Failed for domain$($remoteForest)`n`tError: $($($_.Exception).Message)" -Verbose *>&1
}

# ========================================================
# Step 6  - Allow users from other forest to RDP to DC and member servers.  
# This is a New Forset - megamooselabsfun.com
# ========================================================
#  Domain Local groups can contain users (and groups) from other forests, but only when a trust exists between the forests.

# Only members of the Domain Admins, Enterprise Admins, Administrators (built-in local group on the DC), or sometimes Server Operators can RDP to a DC.

# Get the remote user object (requires connectivity to minecraftmoose.com DCs and trust validation)
$remoteUser = Get-ADUser -Identity "Administrator" -Server "minecraftmoose.com"  # or specific DC like "ANC-DC01.minecraftmoose.com"
# Now add it to the group
Add-ADGroupMember -Identity "forest2DL" -Members $remoteUser -Verbose
Add-ADGroupMember -Identity "Administrators" -Members $remoteUser -Verbose

$remoteUser = Get-ADUser -Identity "Megaman" -Server "minecraftmoose.com"  # or specific DC like "ANC-DC01.minecraftmoose.com"
# Now add it to the group
Add-ADGroupMember -Identity "forest2DL" -Members $remoteUser -Verbose
Add-ADGroupMember -Identity "Administrators" -Members $remoteUser -Verbose

