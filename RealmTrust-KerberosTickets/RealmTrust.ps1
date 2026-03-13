
# =============================================================================
# Hyper-V Lab Creation 
# =============================================================================
# Author:   Mark Kruse
# Purpose:  Create a one way trust between an AD DS doamin and MIT KCD Kerberos Realm
# Location: Anchorage, Alaska lab environment
# =============================================================================

# ============================================
# Step 1 -  Create Hyper-V Switches
# ============================================ 

# CreateLabSwitches
# New-VMSwitch -Name "LINUX-NET"  -SwitchType Private -Verbose *>&1
# New-VMSwitch -Name "JUN-NET"  -SwitchType Private -Verbose *>&1
# New-VMSwitch -Name "EXT-INT"  -SwitchType Private -Verbose *>&1
# New-MMF_VM -VMNames YAHOO-DNS01 -HyperVSwitch linux-net -GeneralizedImage



# ===============================================================================
# Step 2 -  Create YAHOO-DNS01.
#            YAHOO-DNS01 will be a DNS server for YAHOOMOOSE.COM.
# ==============================================================================
New-Lab_VM -VMNames YAHOO-DNS01 -HyperVSwitch LINUX-NET -GeneralizedImageDE

#Configure server to respond to ping
Get-NetFirewallRule -DisplayName "*Echo Request*" | Format-Table Name, Enabled, Direction, Action
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow



New-NetIPAddress -InterfaceAlias "Ethernet" `
    -IPAddress 192.168.11.7 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.11.1 `
    -AddressFamily IPv4 `
    -Verbose *>&1

# Set DNS server(s)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
    -ServerAddresses 127.0.0.1, 8.8.8.8
    
    
Rename-Computer -NewName YAHOO-DNS01 -Restart -Verbose *>&1

# ===============================================================================
# Step 3 -  Install DNS Role for YAHOO-DNS01
#           Add DNS Records
#           Create DNS fowarder to megamooselabsfun.com
# ==============================================================================
Install-WindowsFeature -Name DNS -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1
Add-DnsServerPrimaryZone -Name "yahoomoose.com" -ZoneFile "yahoomoose.com.dns" -Verbose *>&1
Add-DnsServerResourceRecordA -Name "@" -ZoneName "yahoomoose.com" -IPv4Address "192.168.11.7"
Add-DnsServerResourceRecordA -Name "YAHOO-DNS01" -ZoneName "yahoomoose.com" -IPv4Address "192.168.11.7"
Add-DnsServerResourceRecordA -Name "linux01" -ZoneName "yahoomoose.com" -IPv4Address "192.168.11.10"
Get-DnsServerZone -Name "yahoomoose.com"
Get-DnsServerResourceRecord -ZoneName "yahoomoose.com"

# [Create DNS fowarder to megamooselabsfun.com]
Add-DnsServerConditionalForwarderZone -Name "megamooselabsfun.com" -MasterServers 192.168.99.9 -Verbose *>&1


# =============================================================
# Step 4 -  Add Kerberos SRV records for MIT KDC on YAHOO-DNS01
#           Realm/Zone: yahoomoose.com
#           KDC Host:   linux01.yahoomoose.com
#           DNS Server: 192.168.11.7 (YAHOO-DNS01)
# =============================================================

$ZoneName   = 'yahoomoose.com'
$Target     = 'linux01.yahoomoose.com'  # Must resolve to your MIT KDC
$DnsServer  = '192.168.11.7'
$TTL        = [TimeSpan]::FromMinutes(10)

Write-Verbose -Message "Adding SRV records to zone: $ZoneName on $DnsServer" -Verbose *>&1

# _kerberos._udp (Kerberos over UDP 88) - Primary / most common
Add-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -Srv `
    -Name '_kerberos._udp' `
    -DomainName $Target `
    -Priority 0 -Weight 0 -Port 88 -TimeToLive $TTL

# _kerberos._tcp (Kerberos over TCP 88) - Fallback for large packets / firewalls
Add-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -Srv `
    -Name '_kerberos._tcp' `
    -DomainName $Target `
    -Priority 0 -Weight 0 -Port 88 -TimeToLive $TTL

# _kpasswd._udp (Password change over UDP 464) - Important for resets/changes
Add-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -Srv `
    -Name '_kpasswd._udp' `
    -DomainName $Target `
    -Priority 0 -Weight 0 -Port 464 -TimeToLive $TTL

# Optional: _kerberos-adm._tcp (kadmind TCP 749) - Only for MIT admin tools like kadmin
# (Windows/AD trust does NOT need this)
Add-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -Srv `
    -Name '_kerberos-adm._tcp' `
    -DomainName $Target `
    -Priority 0 -Weight 0 -Port 749 -TimeToLive $TTL




# ===============================================================================
# Step 4 -  Create JUN-DC01. 
#            JUN-DC01 will be a AD DS, DNS and DHCP server for megamooselabsfun.com  
#            Configure AD DS domain megamooselabsfun.com
#            JUN-DC01 will hand out IPs for 192.168.99.0/24
#            Create DNS fowarder to yahoomoose.com
# ==============================================================================

New-Lab_VM -VMNames JUN-DC01 -HyperVSwitch JUN-NET -GeneralizedImageDE

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
-SafeModeAdministratorPassword  $DSRMPassword `
-Force:$true

# [Create DNS fowarder to yahoomoose.com]
Add-DnsServerConditionalForwarderZone -Name "yahoomoose.com" -MasterServers 192.168.11.7 -ReplicationScope Forest -Verbose *>&1

# -------------------------------
# AD DS will have SVR records for Kerberos
# Below are example SVR records you should see on JUN-DC01
# -------------------------------

# $ZoneName   = 'megamooselabsfun.com'
# $Target     = 'jun-dc01.megamooselabsfun.com'
# $DnsServer  = '192.168.99.9'    # Your Windows DNS Server IP
# $TTL        = [TimeSpan]::FromMinutes(10)

# # _kerberos._tcp
# Add-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -Srv `
#     -Name '_kerberos._tcp' `
#     -DomainName $Target `
#     -Priority 0 -Weight 0 -Port 88 -TimeToLive $TTL

# # _kerberos._udp
# Add-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -Srv `
#     -Name '_kerberos._udp' `
#     -DomainName $Target `
#     -Priority 0 -Weight 0 -Port 88 -TimeToLive $TTL

# # _kpasswd._tcp
# Add-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -Srv `
#     -Name '_kpasswd._tcp' `
#     -DomainName $Target `
#     -Priority 0 -Weight 0 -Port 464 -TimeToLive $TTL

# # _kpasswd._udp
# Add-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -Srv `
#     -Name '_kpasswd._udp' `
#     -DomainName $Target `
#     -Priority 0 -Weight 0 -Port 464 -TimeToLive $TTL




# ===============================================================================
# Step - Create jun-linux01 and connect
# ==============================================================================

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
# ===============================================================================
# Step 6 - Create KDC
# ==============================================================================
New-Lab_VM -VMNames linux01 -HyperVSwitch linux-net -RAM_GB 2GB -ISOPath C:\ISO\ubuntu-24.04.3-live-server-amd64.iso
# [Disable Secure boot to start OS installation]
Stop-VM -VMName linux01 -Force -Verbose *>&1
Set-VMFirmware -VMName linux01 -EnableSecureBoot off -Verbose *>&1
Start-VM -VMName linux01 -Verbose *>&1


# [General updates, Timezone, add user]
sudo apt update && sudo apt upgrade -y
sudo timedatectl set-timezone America/Anchorage
sudo timedatectl status
sudo timedatectl set-ntp true

#creat local user account
sudo useradd -m protoman && sudo passwd protoman
sudo usermod -aG sudo protoman

# Extra
resolvectl status
# Update DNS
sudo resolvectl dns eth0 192.168.11.7
#check for .local
host 192.168.11.10
resolvectl flush-caches
sudo hostnamectl set-hostname linux01.yahoomoose.com

#######################################################
# [Install Kerberos Packages and conifgure /etc/krb5.conf]
sudo apt install krb5-kdc krb5-user krb5-admin-server #CAPITAL -> YAHOOMOOSE.COM

sudo nano /etc/krb5.conf

[libdefaults]
    default_realm = YAHOOMOOSE.COM
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true

[realms]
    YAHOOMOOSE.COM = {
        kdc = linux01.yahoomoose.com:88
        admin_server = linux01.yahoomoose.com:749
        default_domain = yahoomoose.com
    }
    MEGAMOOSELABSFUN.COM = {
        kdc = jun-dc01.megamooselabsfun.com:88
        admin_server = jun-dc01.megamooselabsfun.com:749
        default_domain = megamooselabsfun.com
    }

[domain_realm]
    .yahoomoose.com = YAHOOMOOSE.COM
    yahoomoose.com = YAHOOMOOSE.COM
    .megamooselabsfun.com = MEGAMOOSELABSFUN.COM
    megamooselabsfun.com = MEGAMOOSELABSFUN.COM

[capaths]
    MEGAMOOSELABSFUN.COM = {
        YAHOOMOOSE.COM = .
    }
    YAHOOMOOSE.COM = {
        MEGAMOOSELABSFUN.COM = .
    }
###########################
sudo cat /etc/krb5.conf | head -n 50
#######################################################
#######################################################
# [Initialize Kerberos database]  
    sudo krb5_newrealm     #This creates the KDC database for `YAHOOMOOSE.COM` Use Captial letters YAHOOMOOSE.COM.
    
#WAIT A MOMENT
    sudo cat /etc/krb5kdc/stash
    # Check stash file
    sudo ls -l /etc/krb5kdc/stash

    # Check permissions
    sudo stat /etc/krb5kdc/stash

    # Check database files
    sudo ls -l /var/lib/krb5kdc/

    systemctl status krb5-kdc
    service krb5-kdc status
#######################################################
sudo systemctl restart krb5-kdc krb5-admin-server
sudo systemctl status krb5-kdc krb5-admin-server
#######################################################
#####
# [Add prinicipals -Firewall - Checks]  
# This does not create the Linux user — it only creates the Kerberos identity.
sudo kadmin.local -q 'addprinc -pw "Taz14Spaz!@#" admin01/admin@YAHOOMOOSE.COM'   # admin client principal
sudo kadmin.local -q 'addprinc -pw "Taz14Spaz!@#" protoman@YAHOOMOOSE.COM'         # test user
sudo kadmin.local -q 'addprinc -pw "Taz14Spaz!@#" host/linux01@YAHOOMOOSE.COM'     # short host (SSH GSSAPI)
sudo kadmin.local -q 'addprinc -pw "Taz14Spaz!@#" host/linux01.yahoomoose.com@YAHOOMOOSE.COM'  # FQDN host
sudo kadmin.local -q 'addprinc -pw "Taz14Spaz!@#" root/admin@YAHOOMOOSE.COM'       # for sudo kadmin
sudo kadmin.local -q "listprincs"                                                   # verify
# For example, this creates a Kerberos principal for the user protoman in the realm YAHOOMOOSE.COM.
# This means:
# - The Linux user protoman can now authenticate to Kerberos.
# - They can run kinit protoman and get a TGT.
# - They can access Kerberized services (SSH, NFS, HTTP, LDAP, etc.) if allowed and configured.


# Update `/etc/krb5kdc/kadm5.acl`: beset practice
# This file is the ACL (Access Control List) for the Kerberos admin server (kadmind).
# It controls who can do what with kadmin (remote admin tool) or kadmin.local (local admin tool).
# Without a proper ACL, kadmind may refuse connections or allow too much access (security risk).
sudo nano /etc/krb5kdc/kadm5.acl
  
*/admin@YAHOOMOOSE.COM  *
    
# Restart services:
sudo systemctl restart krb5-kdc krb5-admin-server
systemctl status krb5-kdc krb5-admin-server

#check Listener
sudo ss -tulpn | egrep ':88|:749'    
# udp   UNCONN 0      0                 0.0.0.0:88        0.0.0.0:*    users:(("krb5kdc",pid=6147,fd=11))                 
# udp   UNCONN 0      0                    [::]:88           [::]:*    users:(("krb5kdc",pid=6147,fd=12))                 
# tcp   LISTEN 0      5                 0.0.0.0:88        0.0.0.0:*    users:(("krb5kdc",pid=6147,fd=13))                 
# tcp   LISTEN 0      2                 0.0.0.0:749       0.0.0.0:*    users:(("kadmind",pid=6146,fd=13))                 
# tcp   LISTEN 0      5                    [::]:88           [::]:*    users:(("krb5kdc",pid=6147,fd=14))                 
# tcp   LISTEN 0      2                    [::]:749          [::]:*    users:(("kadmind",pid=6146,fd=14)) 

#Firewall is off by default
sudo ufw status verbose

#If you enable Firewall open these ports
sudo ufw allow ssh
sudo ufw allow 88
sudo ufw allow 464
sudo ufw allow 749

# Reload and check status
sudo ufw reload
sudo ufw status verbose
#See if you can get a kerbors ticket check
#on linux
kinit protoman@YAHOOMOOSE.COM
klist

kdestroy
kinit megaman@MEGAMOOSELABSFUN.COM
klist



# The test kinit megaman@MEGAMOOSELABSFUN.COM
# is an AD user authenticating to an AD resource — 
# This is not proving cross-realm trust; it's just local AD Kerberos.
sudo apt install samba smbclient cifs-utils 
kdestroy
kinit megaman@MEGAMOOSELABSFUN.COM
smbclient //JUN-DC01.megamooselabsfun.com/SYSVOL -k -c 'ls'
smbclient //JUN-DC01.megamooselabsfun.com/c$ -k -c 'ls'


# WARNING!
# A one-way trust is the only reliable and 
# fully supported configuration when connecting a MIT Kerberos KDC to an Active Directory domain.

# ┌────────────┐        one-way trust        ┌────────────┐
# │  Forest 1  │ <─────────────────────────  │  Forest 2  │
# │  AD DS     │                             │ MIT KDC    │
# └────────────┘                             └────────────┘
# AD DS is the trusted domain                 MIT is the trusting domain
# AD DS users can access MIT resources
#                 Direction of access: AD DS → MIT

# AD DS is trusting domain                    MIT is trusted Domain
# The Arrow in a one way trust represents "Who is trusting who"

# +------------------------------------------+-------------------------------------------------------+---------------------------------------------------------------+
# | Direction                                | What works                                            | What doesn't work                                             |
# +------------------------------------------+-------------------------------------------------------+---------------------------------------------------------------+
# | AD user → MIT service                    | Usually works (MIT KDC can resolve AD principals via  | Sometimes fails on decrypt if enctypes mismatch               |
# | (e.g. megaman SSH to linux01)            | explicit kdc entry)                                   |                                                               |
# +------------------------------------------+-------------------------------------------------------+---------------------------------------------------------------+
# | MIT user → AD service                    | TGT referral may work                                 | Service tickets (cifs/host) almost always fail (AD does not   |
# | (e.g. protoman smbclient -k to JUN-DC01) |                                                       | forward TGS requests)                                         |
# +------------------------------------------+-------------------------------------------------------+---------------------------------------------------------------+

#######################################################
#######################################################
#####
# [Step 5  Add prinicipals for trust]  

# sudo kadmin.local -q "delprinc krbtgt/YAHOOMOOSE.COM@MEGAMOOSELABSFUN.COM"
# sudo kadmin.local -q "delprinc krbtgt/MEGAMOOSELABSFUN.COM@YAHOOMOOSE.COM"
# krbtgt/YAHOOMOOSE.COM@MEGAMOOSELABSFUN.COM
# → This is the key AD uses when it wants to get tickets from the MIT realm.
# It's the "AD side of the bridge" for AD → MIT direction.
sudo kadmin.local -q "addprinc -pw 'NewTrustPass123ABCXYZ789' -e \"aes256-cts:normal aes128-cts:normal rc4-hmac:normal\" krbtgt/YAHOOMOOSE.COM@MEGAMOOSELABSFUN.COM"

sudo kadmin.local -q "getprinc krbtgt/YAHOOMOOSE.COM@MEGAMOOSELABSFUN.COM"

sudo systemctl restart krb5-kdc krb5-admin-server
systemctl status krb5-kdc krb5-admin-server



#SETUP WINDOWS TRUST ###################
netdom trust megamooselabsfun.com /Domain:YAHOOMOOSE.COM /Remove /Force
# you cannot use netdom from AD side to make MIT trust AD, buy you can use /twoway flag and remove the other one.
# Or create a "One-way outgoing" trust with GUI
# /usesaeskeys is NOT supported for /realm (MIT Kerberos) trusts.
netdom trust megamooselabsfun.com /Domain:YAHOOMOOSE.COM /add /realm /passwordt:NewTrustPass123ABCXYZ789 /twoway
netdom trust megamooselabsfun.com /Domain:YAHOOMOOSE.COM /Verify /Kerberos

#checks
Get-ADTrust -Identity YAHOOMOOSE.COM | fl UsesAESKeys,TrustType,Direction
Get-ADObject -Identity "CN=YAHOOMOOSE.COM,CN=System,DC=megamooselabsfun,DC=com" -Properties msDS-SupportedEncryptionTypes,trustType | fl

# The checkbox and AES attempts were blocked by 
# AD's read-only lock on msDS-SupportedEncryptionTypes for realm trusts.

#TRUST IS SETUP
# With pure realm trust in most cases:
# Cross-realm TGT auth (kinit to foreign realm) works.
# Cross-realm service auth (Kerberos ticket for host/cifs/ to foreign realm resources) does not work — it's not supported reliably in AD realm trusts without hacks or shortcut trust.
# smbclient -k and GSSAPI SSH to foreign-realm services will keep failing with SPNEGO/invalid parameter or decrypt errors.
############################
############################
#####

# [Testing the trust and kerberos]
klist -li 0x3e7
klist -li 0x3e7 purge

# PROVE FROM AD SIDE
kdestroy
kinit megaman@MEGAMOOSELABSFUN.COM
klist -e
kvno krbtgt/YAHOOMOOSE.COM@MEGAMOOSELABSFUN.COM
#output
# krbtgt/YAHOOMOOSE.COM@MEGAMOOSELABSFUN.COM: kvno = 0


