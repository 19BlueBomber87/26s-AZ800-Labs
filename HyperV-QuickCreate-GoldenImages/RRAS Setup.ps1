# =============================================================================
# Hyper-V Lab Creation & RRAS and DCHP Configuration
# =============================================================================
# Author:   Mark Kruse
# Purpose:  Prepare golden images via SysPrep
# Location: Anchorage, Alaska lab environment
# =============================================================================
# ===================================================
# Step 1 - Create RRAS Server with 5 network adapters
# ===================================================
New-Lab_VM -VMNames RRAS01 -HyperVSwitch ER-NET -RAM_GB 4GB -AdapterCount 5 -GeneralizedImageDE
# ===================================================
# Step 2 - Create Hyper-V Switches
# One external switch for path way to internet
# One private switch Per Local Area Network(LAN)
# ===================================================
New-VMSwitch -Name "EXT-INT"  -NetAdapterName "Wi-Fi" -AllowManagementOS $true
New-VMSwitch -Name ANC-NET -SwitchType Private -Verbose *>&1
New-VMSwitch -Name Nome-NET -SwitchType Private -Verbose *>&1
New-VMSwitch -Name JUN-NET -SwitchType Private -Verbose *>&1

# ========================================================
# Step 3 - Disable ipv6 and Change network adapter names
# ========================================================
$adapters = Get-NetAdapter
$NewAdapterNames = "EXT-INT", "ANC-NET", "Nome-NET", "JUN-NET", "ER-NET"
$index = 0
foreach($adapter in $adapters){
    Rename-NetAdapter -Name $adapter.Name -NewName $NewAdapterNames[$index]
    Disable-NetAdapterBinding -Name $NewAdapterNames[$index]-ComponentID ms_tcpip6 -Verbose *>&1
    $index++
}

# ========================================================
# Step 4 - Match Hyper-V Network Adapters to RRAS Server Network Adapters
# ========================================================

#on host
Get-VMNetworkAdapter -VMName "RRAS01" | Select-Object VMName, Name, SwitchName, MacAddress, Status
#EXAMPLE OUTPUT
# VMName     : RRAS01
# Name       : NetAdapter.1
# SwitchName : ER-NET
# MacAddress : 00155D0114D3
# Status     : {Ok}

# VMName     : RRAS01
# Name       : NetAdapter.2
# SwitchName : ER-NET
# MacAddress : 00155D0114D4
# Status     : {Ok}

# VMName     : RRAS01
# Name       : NetAdapter.3
# SwitchName : ER-NET
# MacAddress : 00155D0114D5
# Status     : {Ok}

# VMName     : RRAS01
# Name       : NetAdapter.4
# SwitchName : ER-NET
# MacAddress : 00155D0114D6
# Status     : {Ok}

# VMName     : RRAS01
# Name       : NetAdapter.5
# SwitchName : ER-NET
# MacAddress : 00155D0114D7
# Status     : {Ok}

#on RRAS
Get-NetAdapter | Select-Object Name, InterfaceDescription, MacAddress, Status, LinkSpeed
# EXAMPLE OUTPUT
# Name                 : EXT-INT
# InterfaceDescription : Microsoft Hyper-V Network Adapter #2
# MacAddress           : 00-15-5D-01-14-DA
# Status               : Up
# LinkSpeed            : 10 Gbps

# Name                 : ANC-NET
# InterfaceDescription : Microsoft Hyper-V Network Adapter
# MacAddress           : 00-15-5D-01-14-DB
# Status               : Up
# LinkSpeed            : 10 Gbps

# Name                 : Nome-NET
# InterfaceDescription : Microsoft Hyper-V Network Adapter #4
# MacAddress           : 00-15-5D-01-14-DC
# Status               : Up
# LinkSpeed            : 10 Gbps

# Name                 : JUN-NET
# InterfaceDescription : Microsoft Hyper-V Network Adapter #3
# MacAddress           : 00-15-5D-01-14-D8
# Status               : Up
# LinkSpeed            : 10 Gbps

# Name                 : ER-NET
# InterfaceDescription : Microsoft Hyper-V Network Adapter #5
# MacAddress           : 00-15-5D-01-14-D9
# Status               : Up
# LinkSpeed            : 10 Gbps

# ========================================================
# Step 5 - Set Default Gateway Addresses for LAN Networks
# ========================================================

#Set IP
New-NetIPAddress -InterfaceAlias ANC-NET -IPAddress 192.168.77.1 -PrefixLength 24 -Verbose *>&1
Set-DnsClientServerAddress -InterfaceAlias ANC-NET -ServerAddresses 8.8.8.8 -Verbose *>&1

New-NetIPAddress -InterfaceAlias Nome-NET -IPAddress 192.168.88.1 -PrefixLength 24 -Verbose *>&1
Set-DnsClientServerAddress -InterfaceAlias ANC-NET -ServerAddresses 8.8.8.8 -Verbose *>&1

New-NetIPAddress -InterfaceAlias JUN-NET -IPAddress 192.168.99.1 -PrefixLength 24 -Verbose *>&1
Set-DnsClientServerAddress -InterfaceAlias ANC-NET -ServerAddresses 8.8.8.8 -Verbose *>&1

New-NetIPAddress -InterfaceAlias ER-NET -IPAddress 192.168.100.1 -PrefixLength 24 -Verbose *>&1
Set-DnsClientServerAddress -InterfaceAlias ANC-NET -ServerAddresses 8.8.8.8 -Verbose *>&1


#Configure server to respond to ping
Get-NetFirewallRule -DisplayName "*Echo Request*" | Format-Table Name, Enabled, Direction, Action
New-NetFirewallRule -DisplayName "Allow ICMPv4 Ping (Echo Request)" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Action Allow

# ========================================================
# Step  6 -Install DHCP and Remote Access Roles
# ========================================================

Install-WindowsFeature -Name DHCP, RemoteAccess -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1 -Restart

# ========================================================
# Step  7 -Configure DHCP - Set DHCP Scopes - 1 DHCP Scope Per LAN
# ========================================================

$DhcpServer = $env:COMPUTERNAME
$ScopeName  = "Anchorage-NET-Scope"
$ScopeStart = "192.168.77.1"
$ScopeEnd   = "192.168.77.254"
$SubnetMask = "255.255.255.0"
$Gateway    = "192.168.77.1"
$DnsServer  = "192.168.77.7"   # adjust as needed
$DnsServerSecondary = "8.8.8.8"
$DomainName = "minecraftmoose.com" # adjust as needed
# Create DHCP scope
Add-DhcpServerv4Scope -Name $ScopeName -StartRange $ScopeStart -EndRange $ScopeEnd -SubnetMask $SubnetMask -Verbose *>&1
Add-DhcpServerv4ExclusionRange -ScopeId "192.168.77.0" -StartRange "192.168.77.1" -EndRange "192.168.77.9" -Verbose *>&1
# Configure scope options
Set-DhcpServerv4OptionValue -ScopeId "192.168.77.0" -Router $Gateway -Verbose *>&1
Set-DhcpServerv4OptionValue -ScopeId "192.168.77.0" -DnsServer $DnsServer, $DnsServerSecondary  -DnsDomain $DomainName -Force -Verbose *>&1
# Activate the scope
Set-DhcpServerv4Scope -ScopeId "192.168.77.0" -State Active  -Verbose *>&1

$DhcpServer = $env:COMPUTERNAME
$ScopeName  = "Nome-NET-Scope"
$ScopeStart = "192.168.88.1"
$ScopeEnd   = "192.168.88.254"
$SubnetMask = "255.255.255.0"
$Gateway    = "192.168.88.1"
$DnsServer  = "192.168.88.8"   # adjust as needed
$DnsServerSecondary = "8.8.8.8"
$DomainName = "moosewyre.fun" # adjust as needed
# Create DHCP scope
Add-DhcpServerv4Scope -Name $ScopeName -StartRange $ScopeStart -EndRange $ScopeEnd -SubnetMask $SubnetMask -Verbose *>&1
Add-DhcpServerv4ExclusionRange -ScopeId "192.168.88.0" -StartRange "192.168.88.1" -EndRange "192.168.88.9" -Verbose *>&1
# Configure scope options
Set-DhcpServerv4OptionValue -ScopeId "192.168.88.0" -Router $Gateway -Verbose *>&1
Set-DhcpServerv4OptionValue -ScopeId "192.168.88.0" -DnsServer $DnsServer, $DnsServerSecondary -Force -DnsDomain $DomainName -Verbose *>&1
# Activate the scope
Set-DhcpServerv4Scope -ScopeId "192.168.88.0" -State Active  -Verbose *>&1

$DhcpServer = $env:COMPUTERNAME
$ScopeName  = "Juneau-NET-Scope"
$ScopeStart = "192.168.99.1"
$ScopeEnd   = "192.168.99.254"
$SubnetMask = "255.255.255.0"
$Gateway    = "192.168.99.1"
$DnsServer  = "192.168.99.9"   # adjust as needed
$DnsServerSecondary = "8.8.8.8"
$DomainName = "megamooselabsfun.com" # adjust as needed
# Create DHCP scope
Add-DhcpServerv4Scope -Name $ScopeName -StartRange $ScopeStart -EndRange $ScopeEnd -SubnetMask $SubnetMask -Verbose *>&1
Add-DhcpServerv4ExclusionRange -ScopeId "192.168.99.0" -StartRange "192.168.99.1" -EndRange "192.168.99.9" -Verbose *>&1
# Configure scope options
Set-DhcpServerv4OptionValue -ScopeId "192.168.99.0" -Router $Gateway -Verbose *>&1
Set-DhcpServerv4OptionValue -ScopeId "192.168.99.0" -DnsServer $DnsServer, $DnsServerSecondary  -DnsDomain $DomainName -Force -Verbose *>&1
# Activate the scope
Set-DhcpServerv4Scope -ScopeId "192.168.99.0" -State Active  -Verbose *>&1

$DhcpServer = $env:COMPUTERNAME
$ScopeName  = "EagleRiver-NET-Scope"
$ScopeStart = "192.168.100.1"
$ScopeEnd   = "192.168.100.254"
$SubnetMask = "255.255.255.0"
$Gateway    = "192.168.100.1"
$DnsServer  = "192.168.100.9"   # adjust as needed
$DnsServerSecondary = "8.8.8.8"
$DomainName = "megamooseforge.com" # adjust as needed
# Create DHCP scope
Add-DhcpServerv4Scope -Name $ScopeName -StartRange $ScopeStart -EndRange $ScopeEnd -SubnetMask $SubnetMask -Verbose *>&1
Add-DhcpServerv4ExclusionRange -ScopeId "192.168.100.0" -StartRange "192.168.100.1" -EndRange "192.168.100.9" -Verbose *>&1
# Configure scope options
Set-DhcpServerv4OptionValue -ScopeId "192.168.100.0" -Router $Gateway -Verbose *>&1
Set-DhcpServerv4OptionValue -ScopeId "192.168.100.0" -DnsServer $DnsServer, $DnsServerSecondary  -DnsDomain $DomainName -Force -Verbose *>&1
# Activate the scope
Set-DhcpServerv4Scope -ScopeId "192.168.100.0" -State Active  -Verbose *>&1


# ========================================================
# Step  8 -Configure Routing - Use GUI or Powershell
# ========================================================
# After Install-RemoteAccess ...
# Start the RRAS service and set it to Automatic startup
Set-Service -Name RemoteAccess -StartupType Automatic -Verbose
Start-Service -Name RemoteAccess -Verbose
# Verify it's running
Get-Service -Name RemoteAccess | Format-List Name, Status, StartType

# NAT for ANC-NET (192.168.77.0/24)
New-NetNat -Name "NAT-ANC" -InternalIPInterfaceAddressPrefix "192.168.77.0/24" -Verbose

# NAT for second LAN (e.g., Nome-NET 192.168.88.0/24)
New-NetNat -Name "NAT-Nome" -InternalIPInterfaceAddressPrefix "192.168.88.0/24" -Verbose

# NAT for third LAN (e.g., JUN-NET 192.168.99.0/24)
New-NetNat -Name "NAT-JUN" -InternalIPInterfaceAddressPrefix "192.168.99.0/24" -Verbose

# NAT for fourth LAN (e.g., ER-NET 192.168.100.0/24)
New-NetNat -Name "NAT-Linux" -InternalIPInterfaceAddressPrefix "192.168.55.0/24" -Verbose

# 1. Install/enable the NAT protocol in RRAS
netsh routing ip nat install

# 2. Add your external (public/internet) interface as full NAT
netsh routing ip nat add interface "EXT-INT" full

# 3. Add each internal/private interface (repeat for all 4 LANs)
netsh routing ip nat add interface "ANC-NET" private
netsh routing ip nat add interface "Nome-NET" private
netsh routing ip nat add interface "JUN-NET" private
netsh routing ip nat add interface "ER-NET" private
# Add more if you have a 5th LAN, e.g.:
# netsh routing ip nat add interface "Linux-NET" private
# 4. Restart RRAS service to apply changes
Restart-Service RemoteAccess -Force -Verbose

# 5. Verify NAT is now installed and interfaces are listed

netsh routing ip nat show interface

