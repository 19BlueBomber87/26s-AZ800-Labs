# =============================================================================
# Hyper-V Lab Creation - Install AD DS and Promote DCs
# =============================================================================
# Author:   Mark Kruse
# Purpose: Install AD DS role and promote server(s) to domain controller(s) via PowerShell.
# =========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/HyperV%20Lab%20Creation%20and%20Disk%20Functions.ps1
# =========================================================================================================================================================
# How to create Hyper-V Windows Server Router
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/ADDS-GPO-EntraConnect-LinuxADJoin/RRAS%20Setup.ps1
# ========================================================
# Golden Images were used to create VMs
# https://github.com/19BlueBomber87/26s-AZ800-Labs/tree/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions
# Note: If you sign in with MegaMan Or Rush as a local user on a server, if you sign into the same server after its domain joined, you need to recreate the profile.


# ========================================================
# Step  1 -Create Lab Servers - One DC per Domain - Install AD DS on DCs and 
# ========================================================
# Note:
# Memory Management Note: Use 2GB for DC config.  Reduce to 1GB after inital DC config.  
# Save VMs or resize memory to help manage memory

# 1 - minecraftmoose.com domain controller
New-Lab_VM ANC-DC01 -HyperVSwitch ANC-Net -RAM 2GB -GeneralizedImageCore
Rename-Computer -NewName ANC-DC01 -Restart -Verbose *>&1
Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Restart-Computer -Verbose *>&1
Save-VM -VMName ANC-DC01 -Verbose *>&1 

# 2 - minecraftmoose.com member server
New-Lab_VM ANC-SVR01 -HyperVSwitch ANC-Net -GeneralizedImageDE
Rename-Computer -NewName ANC-SVR01 -Restart -Verbose *>&1
Save-VM -VMName ANC-SVR01 -Verbose *>&1 

# 3 - minecraftmoose.com privileged access workstation(Management Server)
New-Lab_VM ANC-Paw01 -HyperVSwitch Linux-Net -GeneralizedImageDE
Rename-Computer -NewName ANC-PAW01 -Restart -Verbose *>&1
Install-WindowsFeature -Name RSAT-AD-PowerShell -IncludeAllSubFeature -Confirm:$false -Verbose *>&1
Install-WindowsFeature -Name RSAT-AD-Tools -IncludeAllSubFeature -Confirm:$false -Verbose *>&1
Install-WindowsFeature -Name RSAT-DNS-Server -Confirm:$false -Verbose *>&1
Install-WindowsFeature -Name GPMC -Confirm:$false -Verbose *>&1
Set-Item WSMan:\localhost\Client\TrustedHosts -Value * # Paw in a different LAN
Restart-Service WinRM -Verbose *>&1
Restart-Computer -Verbose *>&1
Save-VM -VMName ANC-PAW01 -Verbose *>&1 

# 4 - Windows Admin Center
New-Lab_VM ANC-WAC01 -HyperVSwitch ANC-Net -GeneralizedImageCore
Rename-Computer -NewName ANC-WAC01 -Restart -Verbose *>&1
Save-VM -VMName ANC-WAC01  -Verbose *>&1 

# 5 - moosewyre.fun domain controller
New-Lab_VM Nome-DC01 -HyperVSwitch Nome-Net -RAM 2GB -GeneralizedImageCore
Rename-Computer -NewName Nome-DC01 -Restart -Verbose *>&1
Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Restart-Computer -Verbose *>&1
Save-VM -VMName Nome-DC01  -Verbose *>&1 

# 6 - dev.moosewyre.fun domain controller
New-Lab_VM ER-DC01 -HyperVSwitch ER-Net -RAM 2GB -GeneralizedImageCore
Rename-Computer -NewName ER-DC01 -Restart -Verbose *>&1
Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Restart-Computer -Verbose *>&1
Save-VM -VMName ER-DC01  -Verbose *>&1 

# 7 - dev.moosewyre.fun member server
New-Lab_VM ER-SVR01 -HyperVSwitch ER-Net -GeneralizedImageDE
Rename-Computer -NewName ER-SVR01 -Restart -Verbose *>&1
Save-VM -VMName ER-SVR01  -Verbose *>&1 

# 8 - megamooselabsfun.com domain controller
New-Lab_VM JUN-DC01 -HyperVSwitch Jun-Net -RAM 2GB -GeneralizedImageCore
Rename-Computer -NewName JUN-DC01 -Restart -Verbose *>&1
Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Restart-Computer -Verbose *>&1
Save-VM -VMName JUN-DC01  -Verbose *>&1 

# 9 - megamooselabsfun.com member server
New-Lab_VM JUN-SVR01 -HyperVSwitch Jun-Net -GeneralizedImageDE
Rename-Computer -NewName JUN-SVR01 -Restart -Verbose *>&1
Save-VM -VMName JUN-SVR01  -Verbose *>&1 

# 10 - Entra Connect Server
New-Lab_VM MCMENTRACONNECT -HyperVSwitch Linux-Net -GeneralizedImageDE
Rename-Computer -NewName MCMENTRACONNECT -Restart -Verbose *>&1
Save-VM -VMName MCMENTRACONNECT -Verbose *>&1 

# Power Shell Direct Example.  Use the -VMName parameter. (Run command from the hyper-V host to any VM)
Enter-PSSession -VMName ANC-DC01 -Credential ANC-DC01\administrator


#On Each DC, Install AD DS
# Get-WindowsFeature | Where-Object -Property name -like *AD*
# Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1

# ====================================================
# Step 2 - Install AD DS and Promote ANC-DC01 to DC.  
#        - Add ANC-SVR01 to domain
# Root Domain - minecraftmoose.com
# ====================================================
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

# Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Get-WindowsFeature AD-Domain-Services

#Promote DC
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
-SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssword1!" -AsPlainText -Force) `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true


New-ADReplicationSite -Name Nome -Description "Nome Office AD DS Site" -Verbose *>&1
New-ADReplicationSite -Name EagleRiver -Description "Nome Office AD DS Site" -Verbose *>&1
New-ADReplicationSubnet -Name "192.168.88.0/24" -Site Nome -Location "Nome Office" -Verbose *>&1
New-ADReplicationSubnet -Name "192.168.100.0/24" -Site EagleRiver -Location "Eagle River Office" -Verbose *>&1
Set-ADReplicationSiteLink -Identity "DEFAULTIPSITELINK" -SitesIncluded @{Add="Nome","EagleRiver"} -Verbose *>&1

Add-DnsServerConditionalForwarderZone -Name "moosewyre.fun" -MasterServers 192.168.88.8 -Verbose *>&1 
# Note: A tree domain (new domain with a non-contiguous namespace, e.g., moosewyre.fun in a forest whose root is something like corp.local) creates a separate DNS namespace inside the same forest.
# Domain controllers in different trees need reliable name resolution for each other (for Kerberos, replication, trusts, GC lookups, etc.).
# Unlike a child domain (contiguous namespace), a tree domain does not automatically get proper delegation in the parent/root DNS zone.

# Set permissions for administrators, in this case the user megaman@minecraftmoose.com and rush@minecraftmoose.com
# Disable default administrator account for the domain
$newAdmins = "megaman","Rush"
$adminPermissions = (Get-ADUser administrator -Properties memberof).memberof
foreach($admin in $newAdmins){
    foreach($perm in $adminPermissions){
        Add-ADGroupMember -Identity "$perm" -Members $admin -Verbose *>&1
    }
}
Disable-ADAccount Administrator -Verbose *>&1
(Get-ADUser megaman -Properties memberof).memberof
(Get-ADUser rush -Properties memberof).memberof

# This is an OU for a GPO later in the lab
New-ADOrganizationalUnit -Name CrossDomain01 -Path "DC=minecraftmoose,DC=com"-ProtectedFromAccidentalDeletion $true
# Permission List
# CN=Group Policy Creator Owners,CN=Users,DC=minecraftmoose,DC=com
# CN=Domain Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Enterprise Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Schema Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Administrators,CN=Builtin,DC=minecraftmoose,DC=com

##############################################
# Important -> Build default users with GUI or Powershell.  (Link to a .ps1 file that builds users quickly -> https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/ADDS-GPO-EntraConnect/ADUserPoolQuickCreate.ps1
##############################################

# Test GPO Config
# Test RDP with GUI
# Test new Wallpaper GUI

# ANC-DC01(minecraftmoose.com), NOME-DC01(moosewyre.fun) and ER-DC01(dev.moosewyre.fun) share a Schema
# #AD Partitions
# ntdsutil.exe
# activate instance ntds
# partition management
# connections
# connect to server ANC-DC01
# quit
# list
# Join ANC-SVR01 and ANC-WAC01 to minecraftmoose.com
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\megaman -Restart -Verbose *>&1

# Install AD DS management tools
# Join ANC-PAW to minecraftmoose.com
# ANC-PAW01 is on Linux-Net(192.168.11.0/24).  Set DNS 192.168.77.7(ANC-DC01)
# Install-WindowsFeature -Name RSAT-AD-PowerShell -IncludeAllSubFeature -Confirm:$false -Verbose *>&1
# Install-WindowsFeature -Name RSAT-AD-Tools -IncludeAllSubFeature -Confirm:$false -Verbose *>&1

Get-WindowsFeature -Name RSAT-AD-PowerShell
Get-WindowsFeature -Name RSAT-AD-Tools
Get-WindowsFeature -Name RSAT-DNS-Server
Set-DNSClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.77.7 
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\megaman -Restart -Verbose *>&1


Get-ADComputer "ANC-WAC01","ANC-SVR01", "ANC-PAW01" | Move-ADObject -TargetPath "OU=CrossDomain01,DC=minecraftmoose,DC=com" -Verbose *>&1

##############################################
# Important -> Design Group Policies -> Create and Test GPOs.  (Link to instructions for creating GPOs-> https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/ADDS-GPO-EntraConnect/GPOs.ps1)
##############################################
# Test GPO Config



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

# Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Get-WindowsFeature AD-Domain-Services

Import-Module ADDSDeployment
Install-ADDSDomain `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$false `
-Credential (Get-Credential -Credential megaman@minecraftmoose.com) `
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
-SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssword1!" -AsPlainText -Force) `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true

Add-DnsServerConditionalForwarderZone -Name "minecraftmoose.com" -MasterServers 192.168.77.7 -Verbose *>&1 



# Set permissions for administrators, in this case the user megaman@moosewyre.fun and rush@moosewyre.fun
# Disable default administrator account for the domain
$newAdmins = "megaman","Rush"
$adminPermissions = (Get-ADUser administrator -Properties memberof).memberof
foreach($admin in $newAdmins){
    foreach($perm in $adminPermissions){
        Add-ADGroupMember -Identity "$perm" -Members $admin -Verbose *>&1
    }
}
Disable-ADAccount administrator -Verbose *>&1
(Get-ADUser megaman -Properties memberof).memberof
(Get-ADUser rush -Properties memberof).memberof
# Permission List
# CN=Group Policy Creator Owners,CN=Users,DC=minecraftmoose,DC=com
# CN=Domain Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Enterprise Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Schema Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Administrators,CN=Builtin,DC=minecraftmoose,DC=com

##############################################
# Important -> Build default users with GUI or Powershell.  (Link to a .ps1 file that builds users quickly -> https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/ADDS-GPO-EntraConnect/ADUserPoolQuickCreate.ps1
##############################################

#On ANC-DC01 make sure initial sync has completed to Nome-DC01
repadmin /replsummary
repadmin /syncall anc-dc01.minecraftmoose.com /AeD
repadmin /syncall nome-dc01.moosewyre.fun /AeD
repadmin /replsummary

# ANC-DC01(minecraftmoose.com), NOME-DC01(moosewyre.fun) and ER-DC01(dev.moosewyre.fun) share a Schema
# #AD Partitions
# ntdsutil.exe
# activate instance ntds
# partition management
# connections
# connect to server ANC-DC01
# quit
# list

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

# Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Get-WindowsFeature AD-Domain-Services

#MAKE SURE repadmin /replsummary LOOKS GOOD!!
Import-Module ADDSDeployment
Install-ADDSDomain `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$true `
-Credential (Get-Credential -Credential megaman@minecraftmoose.com) `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainType "ChildDomain" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NewDomainName "dev" `
-NewDomainNetbiosName "DEV" `
-ParentDomainName "moosewyre.fun" `
-NoRebootOnCompletion:$false `
-SiteName "EagleRiver" `
-SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssword1!" -AsPlainText -Force) `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true
# Set permissions for administrators, in this case the user megaman@dev.moosewyre.fun and rush@dev.moosewyre.fun
# Disable default administrator account for the domain
$newAdmins = "megaman","Rush"
$adminPermissions = (Get-ADUser administrator -Properties memberof).memberof
foreach($admin in $newAdmins){
    foreach($perm in $adminPermissions){
        Add-ADGroupMember -Identity "$perm" -Members $admin -Verbose *>&1
    }
}
Disable-ADAccount Administrator -Verbose *>&1
(Get-ADUser megaman -Properties memberof).memberof
(Get-ADUser rush -Properties memberof).memberof
# Permission List
# CN=Group Policy Creator Owners,CN=Users,DC=minecraftmoose,DC=com
# CN=Domain Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Enterprise Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Schema Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Administrators,CN=Builtin,DC=minecraftmoose,DC=com

##############################################
# Important -> Build default users with GUI or Powershell.  (Link to a .ps1 file that builds users quickly -> https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/ADDS-GPO-EntraConnect/ADUserPoolQuickCreate.ps1
##############################################

#On ANC-DC01 make sure initial sync has completed to ER-DC01
repadmin /replsummary
repadmin /syncall ER-dc01.dev.moosewyre.fun /AeD
repadmin /replsummary

# ANC-DC01(minecraftmoose.com), NOME-DC01(moosewyre.fun) and ER-DC01(dev.moosewyre.fun) share a Schema
# #AD Partitions
# ntdsutil.exe
# activate instance ntds
# partition management
# connections
# connect to server ANC-DC01
# quit
# list

# Join ER-SVR01 to domain
Add-Computer -DomainName dev.moosewyre.fun -DomainCredential dev.moosewyre\megaman -Restart -Verbose *>&1


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

# Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Get-WindowsFeature AD-Domain-Services

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
-SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssword1!" -AsPlainText -Force) `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true

# Set permissions for administrators, in this case the user megaman@megamooselabsfun.com and rush@megamooselabsfun.com
# Disable default administrator account for the domain
$newAdmins = "megaman","Rush"
$adminPermissions = (Get-ADUser administrator -Properties memberof).memberof
foreach($admin in $newAdmins){
    foreach($perm in $adminPermissions){
        Add-ADGroupMember -Identity "$perm" -Members $admin -Verbose *>&1
    }
}
Disable-ADAccount Administrator -Verbose *>&1
(Get-ADUser megaman -Properties memberof).memberof
(Get-ADUser rush -Properties memberof).memberof
# Permission List
# CN=Group Policy Creator Owners,CN=Users,DC=minecraftmoose,DC=com
# CN=Domain Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Enterprise Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Schema Admins,CN=Users,DC=minecraftmoose,DC=com
# CN=Administrators,CN=Builtin,DC=minecraftmoose,DC=com

##############################################
# Important -> Build default users with GUI or Powershell.  (Link to a .ps1 file that builds users quickly -> https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/ADDS-GPO-EntraConnect/ADUserPoolQuickCreate.ps1
##############################################

# ANC-DC01(minecraftmoose.com), NOME-DC01(moosewyre.fun) and ER-DC01(dev.moosewyre.fun) share a Schema
# #AD Partitions
# ntdsutil.exe
# activate instance ntds
# partition management
# connections
# connect to server ANC-DC01
# quit
# list

# Join JUN-SVR01 to domain
Add-Computer -DomainName megamooselabsfun.com -DomainCredential megamooselabsfu\megaman -Restart -Verbose *>&1 # megamooselabsfun.com NETBIOS = MEGAMOOSELABSFU



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

repadmin /syncall anc-dc01.minecraftmoose.com /AeD
repadmin /syncall nome-dc01.moosewyre.fun /AeD

# You will see the Conditional Forwarder Zone on Nome-DC01 and ER-DC01

# You need Enterprise Admin privileges in both forests.

# The netdom trust command can't be used to create a forest trust between two AD DS forests. To create a cross-forest trust between two AD DS forests, use the Active Directory Domains and Trusts snap-in to create and manage forest trusts. Scripting solution such as using PowerShell is also an option for managing these types of trusts if you need to automate the process.

# Jun-DC01 (run in local forest)
$strRemoteForest = "minecraftmoose.com"
$strRemoteAdmin  = "administrator@minecraftmoose.com"
$strRemoteAdminPassword = "P@ssword2026!"

$remoteContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext(
    "Forest",
    $strRemoteForest,
    $strRemoteAdmin,
    $strRemoteAdminPassword
)

# Get remote forest
$remoteForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($remoteContext)
Write-Verbose "Connected to Remote forest: $($remoteForest.Name)" -Verbose

# Get local forest
$localForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
Write-Verbose "Connected to Local forest: $($localForest.Name)" -Verbose

# Create TWO-WAY trust
try {
    $localForest.CreateTrustRelationship($remoteForest, "Bidirectional")
    Write-Verbose "Two-way forest trust created successfully." -Verbose
}
catch {
    Write-Verbose "CreateTrustRelationship failed:`n$($_.Exception.Message)" -Verbose
}


# ========================================================
# Step 6  - ANC-DC01 -> Grant access to Resources in minecraftmoose.com
# Allow users from the megamooselabsfun.com forest to RDP to servers in minecraftmoose.com forest
# minecraftmoose.com and megamooselabsfun.com are seperate forests
# ========================================================
#  Domain Local groups can contain users (and groups) from other forests, but only when a trust exists between the forests.

# Only members of the Domain Admins, Enterprise Admins, Administrators (built-in local group on the DC), or sometimes Server Operators can RDP to a DC.

New-ADGroup -Name "megamooselabs-DL-RDP-CrossForest" `
            -SamAccountName "megamooselabs-DL-RDP-CrossForest" `
            -GroupScope DomainLocal `
            -GroupCategory Security `
            -Path "OU=Entra Synced Users,DC=minecraftmoose,DC=com" `
            -Description "Allows users from minecraftmoose.com to RDP" `
            -Verbose *>&1

$RemoteUser01 = Get-ADUser -Identity "megaman" -Server "megamooselabsfun.com"
$RemoteUser02 = Get-ADUser -Identity "rush" -Server "megamooselabsfun.com"
$RemoteUser03 = Get-ADUser -Identity "topman" -Server "megamooselabsfun.com"

Add-ADGroupMember -Identity "megamooselabs-DL-RDP-CrossForest" -Members $RemoteUser01,$RemoteUser02,$RemoteUser03 -Verbose *>&1

# Add megamooselabs-DL-RDP-CrossForest to remote desktop users group on member servers
