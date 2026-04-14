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


# ====================================================
# Step 2 - Install AD DS and Promote ANC-DC01 to DC.  
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

Install-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Rename-Computer -NewName ANC-DC01 -Restart -Verbose *>&1

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

# ====================================================
# Step 3 - Create User pool
# ====================================================
$megaman1 = "Guts Man", "Cuts Man", "Elec Man", "Ice Man", "Fire Man", "Bomb Man"

$domain = "minecraftmoose.com"
$manager = "megaman"
$OUName = "Entra Synced Users"
$DC_Value = $domain.TrimEnd(".com")
$OUPath = "DC=$DC_Value,DC=com"   # Replace with your domain DN

# Create the OU
New-ADOrganizationalUnit -Name $OUName -Path $OUPath -ProtectedFromAccidentalDeletion $true
#start
foreach($boss in $megaman1){
    $distinguishedName = $domain.TrimEnd(".com")
    $office = "Anchorage"
    $city = $office
    $zip = 99504
    $pass = "Password123!"
    $secureString = ConvertTo-SecureString "Password123!" -AsPlainText -Force
    $firstName = ($boss.Split(" "))[0]
    $lastName = ($boss.Split(" "))[1]
    $SAM =($FirstName + $LastName).ToLower()
    $userName = $Sam + "@" + $domain
    $OU = "OU=Entra Synced Users,DC=$distinguishedName,DC=com"


    New-ADUser -Name $boss -SamAccountName $SAM -UserPrincipalName $userName -GivenName $firstName -Surname $lastName -Path $OU -AccountPassword $secureString -Enabled $true -Verbose *>&1
    Set-ADUser $SAM `
        -DisplayName $boss `
        -Description $($Office + " Programmer") `
        -Office $Office `
        -EmailAddress $userName `
        -Enabled $True `
        -Homepage $domain `
        -StreetAddress "123 Yahoo Drive" `
        -POBOX 1717 `
        -City $city `
        -State "AK" `
        -PostalCode $zip `
        -Title "Programmer" `
        -Department "Programming" `
        -Company "Minecraftmoose.com" `
        -Manager $manager -ErrorAction STOP -Verbose *>&1 #username of Manager
    }
