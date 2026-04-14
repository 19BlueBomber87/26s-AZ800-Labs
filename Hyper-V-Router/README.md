# RRAS & DHCP Multi-Network Setup

**File:** `RRAS Setup.ps1`

This script builds the core networking infrastructure for the entire Hyper-V lab environment.

It creates a multi-homed **RRAS server** that acts as a router, DHCP server, and NAT gateway for five separate isolated lab networks.

---

## Purpose

- Create and configure the central **YAHOO-RRAS01** server
- Set up multiple private Hyper-V virtual switches (one per LAN)
- Configure DHCP scopes for each network
- Enable routing and NAT so all lab VMs can access the internet
- Prepare the foundation for domain controllers and other servers in each subnet

---

## Lab Networks Created

| Network Name     | Subnet             | Default Gateway | DHCP Scope              | Associated Domain              |
|------------------|--------------------|-----------------|-------------------------|--------------------------------|
| ANC-NET         | 192.168.77.0/24   | 192.168.77.1   | Anchorage-NET-Scope    | minecraftmoose.com            |
| Nome-NET        | 192.168.88.0/24   | 192.168.88.1   | Nome-NET-Scope         | moosewyre.fun                 |
| JUN-NET         | 192.168.99.0/24   | 192.168.99.1   | Juneau-NET-Scope       | megamooselabsfun.com          |
| ER-NET          | 192.168.100.0/24  | 192.168.100.1  | EagleRiver-NET-Scope   | megamooseforge.com            |
| LINUX-NET       | 192.168.11.0/24   | 192.168.11.1   | yahoomoose.com-NET-Scope | yahoomoose.com              |

**External Interface:** `EXT-INT` (connected to host Wi-Fi for internet access)

---

## Prerequisites

- Hyper-V enabled on the host
- The `New-Lab_VM` function loaded (from the HyperV-QuickCreate-GoldenImages folder)
- A generalized Windows Server Desktop Experience golden image
- Sufficient RAM and storage on the host
- Internet access on the Hyper-V host

---

## Execution Steps (in order)

1. **Create the RRAS VM** with 6 network adapters
2. **Create Hyper-V Switches** (uses `CreateLabSwitches` function or manual creation)
3. **Rename computer** and configure network adapter names + disable IPv6
4. **Match virtual adapters** (verify MAC addresses between host and guest)
5. **Assign static IPs** and DNS on RRAS interfaces
6. **Install DHCP + Remote Access** roles
7. **Configure 5 DHCP scopes** with proper options and exclusions
8. **Configure Routing & NAT** (using both `New-NetNat` and `netsh`)
9. **Create test VMs** in each network to validate DHCP and internet connectivity

---

## Key Features

- Automatic adapter renaming and IPv6 disabling
- Detailed MAC address matching section for troubleshooting
- DHCP exclusions (.1 – .9) reserved for static servers
- Full NAT configuration for internet access from all internal networks
- ICMP ping allowed on RRAS for easy testing
- Comprehensive verbose output for troubleshooting

---

## Important Notes

- The script assumes the RRAS VM is created on the `ER-NET` switch initially.
- After running, verify NAT with `Get-NetNat` and `netsh routing ip nat show interface`
- DNS servers in DHCP scopes point to the future domain controllers (adjust if needed)
- Run this script **after** the root domain controller (`minecraftmoose.com`) is online if possible

---

## Author
Mark Kruse  
Anchorage, Alaska

---

**Part of the AZ-800 Hyper-V Lab Series**

---

✅ **Next:** Proceed to deploy domain controllers and other servers in each network.