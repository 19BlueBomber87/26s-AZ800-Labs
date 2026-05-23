# ===============================================================================
# Step - Create jun-linux01 and join to AD DS domain
# ==============================================================================
# Author:   Mark Kruse
# Purpose:  Join Linux server to AD DS Domain
# Location: Anchorage, Alaska lab environment
# =============================================================================
# =========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-QuickCreate-GoldenImages/AZ-800Celebrate-HyperV%20Creation%20and%20Disk%20Functions.ps1
# =========================================================================================================================================================

# ===============================================================================
# Step 1 -  Create linux server(jun-linux01) to join to megamooselabsfun.com
#           Add DNS record for jun-linux01
#           Create Test File Share
#           Configure sudo(admin) username and server name
#           Add dns record for jun-linux01
#           Confirm SSH is working
# ==============================================================================


# [Create Linux Box on jun-net.  Linux box gets IP via DHCP]
$iso = "C:\ISO\ubuntu-26.04-live-server-amd64.iso"
New-Lab_VM -VMNames jun-linux01 -HyperVSwitch jun-net -RAM 2GB -ISOPath $iso
# [Disable Secure boot to start OS installation]
Stop-VM -VMName jun-linux01 -Force -Verbose *>&1
Set-VMFirmware -VMName jun-linux01 -EnableSecureBoot off -Verbose *>&1
Start-VM -VMName jun-linux01 -Verbose *>&1

# Linux OS Install Wizard
#   1. Linux Server Name   -> "jun-linux01"
#   2. sudo(admin) account -> "admin01"


# JUN-DC01
# Add DNS record for linux box(or just use ip address)
# Find the ip of your linux server
$Linux_ipv4 = "192.168.99.29"
Add-DnsServerResourceRecordA -Name "jun-linux01" -ZoneName "megamooselabsfun.com" -IPv4Address $Linux_ipv4
Get-DnsServerResourceRecord -ZoneName "megamooselabsfun.com" | ? -Property hostname -Like *linux*
Get-DnsServerResourceRecord -ZoneName "megamooselabsfun.com" 

# Create Test File Share
mkdir "C:\Share01\Yahoo"
$Path = "C:\Share01\Yahoo"
"<@:D" | Out-File $Path\yahoo.txt -Verbose *>&1
$ShareName = "Yahoo"
New-SmbShare -Name $ShareName -Path $Path -Description "Test File Share" -ChangeAccess "Everyone" -FullAccess "Domain Admins" -Verbose *>&1  
Get-ChildItem "\\jun-dc01\Yahoo"
Get-Content "\\jun-dc01\Yahoo\yahoo.txt"
notepad "\\jun-dc01\Yahoo\yahoo.txt"


# ==============================================================================
# Step 2 -  Configure jun-linux01 to join megamooselabsfun.com
#           Join jun-linux01 to the domain
# ==============================================================================
ssh admin01@jun-linux01.megamooselabsfun.com

sudo apt update && sudo apt upgrade -y
sudo timedatectl set-timezone America/Anchorage
sudo timedatectl set-ntp true


# ________________________________________________
# Install realmd + join packages without krb5-user first (to avoid debconf):
sudo apt install realmd sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit -y
sudo nano /etc/krb5.conf
[libdefaults]
    default_realm = MEGAMOOSELABSFUN.COM
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true

[realms]
    MEGAMOOSELABSFUN.COM = {
        kdc = jun-dc01.megamooselabsfun.com:88
        default_domain = megamooselabsfun.com
    }
    YAHOOMOOSE.COM = {
        kdc = linux01.yahoomoose.com:88
        admin_server = linux01.yahoomoose.com:749
        default_domain = yahoomoose.com
    }

[domain_realm]
    .megamooselabsfun.com = MEGAMOOSELABSFUN.COM
    megamooselabsfun.com = MEGAMOOSELABSFUN.COM
    .yahoomoose.com = YAHOOMOOSE.COM
    yahoomoose.com = YAHOOMOOSE.COM
[capaths]
    MEGAMOOSELABSFUN.COM = {
        YAHOOMOOSE.COM = .
    }
    YAHOOMOOSE.COM = {
        MEGAMOOSELABSFUN.COM = .
    }

# Install krb5-user, smaba, smbclient and cifs-util packages
sudo apt install krb5-user # 
sudo apt install samba smbclient cifs-utils 

# #check config
# sudo cat /etc/sssd/sssd.conf

# ssh admin01@jun-linux01.megamooselabsfun.com
# Test SMB with Kerberos ticket
smbclient //JUN-DC01.megamooselabsfun.com/c$ -k -c 'ls'
kdestroy
kinit megaman@MEGAMOOSELABSFUN.COM
smbclient //JUN-DC01.megamooselabsfun.com/c$ -k -c 'ls'
smbclient //JUN-DC01.megamooselabsfun.com/yahoo -k -c 'ls'
kdestroy
smbclient //JUN-DC01.megamooselabsfun.com/yahoo -k -c 'ls'

# Join linux box to megamooselabsfun.com
sudo realm join -U megaman MEGAMOOSELABSFUN.COM


# ==============================================================================
# Step 3 -  Give non-admin AD DS account sudo right on jun-linux01
#           Test Kerberos ticket with SMB
# ==============================================================================

# Connect to jun-linux01.megamooselabsfun.com.  
# Test SMB with Kerberos ticket
# Note that megaman(enterprise admin) won't have sudo(admin) rights on linux box, only admin01 currently has sudo rights.  
ssh megaman@megamooselabsfun.com@jun-linux01.megamooselabsfun.com
smbclient //JUN-DC01.megamooselabsfun.com/c$ -k -c 'ls'
smbclient //JUN-DC01.megamooselabsfun.com/yahoo -k -c 'ls'
sudo su

# Give Normal AD DS user sudo rights on jun-linux01
# Add rush to that group in AD (not Linux).
# On JUN-DC01
New-ADUser `
    -Name "beat" `
    -SamAccountName "beat" `
    -UserPrincipalName "beat@megamooselabsfun.com" `
    -AccountPassword (ConvertTo-SecureString "P@ssword2026!" -AsPlainText -Force) `
    -Enabled $true `
    -Path "CN=Users,DC=megamooselabsfun,DC=com" `
    -Verbose *>&1

# Use a domain local group to add users from other forests.
New-ADGroup -Name "linux-sudo-admins" -GroupScope DomainLocal -GroupCategory Security -Path "CN=Users,DC=megamooselabsfun,DC=com" -Verbose *>&1
Add-ADGroupMember -Identity "linux-sudo-admins" -Members "beat" -Verbose *>&1
(Get-ADUser beat -Properties memberof).memberof

# Domain local groups can have users from other other forests <@:D
$cred = Get-Credential -Credential minecraftmoose\megaman 
$RemoteUser01 = Get-ADUser -Identity "megaman" -Server "minecraftmoose.com" -Credential $cred
$RemoteUser02 = Get-ADUser -Identity "rush" -Server "minecraftmoose.com" -Credential $cred
Add-ADGroupMember -Identity "linux-sudo-admins" -Members $RemoteUser01,$RemoteUser02 -Verbose *>&1

ssh admin01@jun-linux01.megamooselabsfun.com
# Add AD DS group that will have SuperUser (superuser do)(linux version of the "administrator" account in Windows)
sudo nano /etc/sudoers.d/ad-linux-adminsd-linux-admins
%linux-sudo-admins@megamooselabsfun.com ALL=(ALL) ALL
#passwordless SSH
%linux-sudo-admins@megamooselabsfun.com ALL=(ALL) NOPASSWD: ALL

sudo cat /etc/sudoers.d/ad-linux-adminsd-linux-admins

# Connect to jun-linux01.megamooselabsfun.com with standard AD DS account, in this case "beat" 
ssh beat@megamooselabsfun.com@jun-linux01.megamooselabsfun.com

#Test sudo rights
sudo su 
sudo sss_cache -E
sudo systemctl restart sssd

# Test File Share rights.  Beat is not an admin and cannot access smbclient //JUN-DC01.megamooselabsfun.com/c$ -k -c 'ls'
smbclient //JUN-DC01.megamooselabsfun.com/SYSVOL -k -c 'ls'
smbclient //JUN-DC01.megamooselabsfun.com/yahoo -k -c 'ls'
#beat does not have access to C:\ on JUN-DC01
smbclient //JUN-DC01.megamooselabsfun.com/c$ -k -c 'ls'
# Get Kerberos ticket for enterprise admin and it will work
kinit megaman@MEGAMOOSELABSFUN.COM
smbclient //JUN-DC01.megamooselabsfun.com/c$ -k -c 'ls'
kdestroy
