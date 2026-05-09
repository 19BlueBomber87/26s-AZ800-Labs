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

# [Create Linux Box on jun-net.  Linux box gets IP via DHCP]
New-Lab_VM -VMNames jun-linux01 -HyperVSwitch jun-net -RAM_GB 2GB -ISOPath C:\ISO\ubuntu-24.04.3-live-server-amd64.iso
# [Disable Secure boot to start OS installation]
Stop-VM -VMName jun-linux01 -Force -Verbose *>&1
Set-VMFirmware -VMName jun-linux01 -EnableSecureBoot off -Verbose *>&1
Start-VM -VMName jun-linux01 -Verbose *>&1

# https://linuxvox.com/blog/connect-ubuntu-to-windows-domain/
# [Linux Box Config] Use IP address or Create DNS record on JUN-DC01 for linux01.megamooselabsfun.com
ssh admin02@jun-linux01.megamooselabsfun.com

#[Configure jun-linux01]

sudo apt update && sudo apt upgrade -y
sudo timedatectl set-timezone America/Anchorage
sudo timedatectl set-ntp true
sudo resolvectl dns eth0 192.168.11.7

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


sudo realm join -U Administrator MEGAMOOSELABSFUN.COM

sudo cat /etc/sssd/sssd.conf

# Give Normal AD DS user sudo rights on jun-linux01
# Add rush to that group in AD (not Linux).
# On JUN-DC01
New-ADUser `
    -Name "rush" `
    -SamAccountName "rush" `
    -UserPrincipalName "rush@megamooselabsfun.com" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd2026!" -AsPlainText -Force) `
    -Enabled $true `
    -Path "CN=Users,DC=megamooselabsfun,DC=com" `
    -Verbose *>&1

New-ADGroup -Name "linux-sudo-admins" -GroupScope Global -GroupCategory Security -Path "CN=Users,DC=megamooselabsfun,DC=com" -Verbose *>&1
Add-ADGroupMember -Identity "linux-sudo-admins" -Members "rush" -Verbose *>&1

ssh rush@megamooselabsfun.com@jun-linux01.megamooselabsfun.com

sudo nano /etc/sudoers.d/ad-linux-adminsd-linux-admins
%linux-sudo-admins@megamooselabsfun.com ALL=(ALL) ALL
#passwordless SSH
%linux-sudo-admins@megamooselabsfun.com ALL=(ALL) NOPASSWD: ALL
sudo cat /etc/sudoers.d/ad-linux-adminsd-linux-admins

sudo sss_cache -E
sudo systemctl restart sssd

#Test Kerbors
sudo apt install krb5-user # to install 
kinit rush@MEGAMOOSELABSFUN.COM
kdestroy
sudo apt install samba smbclient cifs-utils 