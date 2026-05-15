# ========================================================
# Entra Connect Setup
# ========================================================
# Author:   Mark Kruse
# Purpose:  Setup EntraConnect for AD DS domains minecraftmoose.com, moosewyre.fun, dev.moosewyure.fun and megamooselabsfun.com to sync to EntraID(minecraftmoose.com)
        #   Help understand Password Hash Synchronization.  
# Location: Anchorage, Alaska lab environment
# =====================

# ========================================================
# Prerequisite -You must own your AD DS domain names and have them connected to Azure\365 tenant before starting the lab. 
# https://learn.microsoft.com/en-us/microsoft-365/admin/setup/add-domain?view=o365-worldwide&tabs=domain-connect

# A domain registrar is a company accredited by ICANN (or relevant authorities) that lets you buy, register, and manage domain names like .com, .net, .org, etc.
# Examples: Network Solutions, Squarespace, GoDaddy, etc

# For these Labs I have added minecraftmoose.com, moosewyre.fun and megamooselabsfun.com to my Azure\365 tenant.  (You would replace with your domain name)
# ========================================================

New-Lab_VM MCMENTRACONNECT -HyperVSwitch Linux-Net -GeneralizedImageDE
Rename-Computer -NewName MCMENTRACONNECT -Restart -Verbose *>&1
Save-VM -VMName MCMENTRACONNECT -Verbose *>&1 

Set-DNSClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.77.7 
Add-Computer -DomainName minecraftmoose.com -DomainCredential minecraftmoose\megaman -Restart -Verbose *>&1
# ========================================================
# Step  1 -Log into entra.microsoft.com and download the install file for EntraConnect.(As of May 2026 the file name is -> "AzureADConnect.msi")
# ========================================================

# Note.  EntraConnect must be installed on a server with desktop experience.  

1. Start the .msi installe file
2. Select "Customize" to see install options (We will leave defaults)
3. Choose PHA and Single Sign .\OneDrive
4. Set Source Anchor to "mS-DS-ConsistencyGuid"
# Unlike objectGUID, which changes during cross-forest migrations, mS-DS-ConsistencyGuid remains constant, preventing synchronization errors



# EntraConnect design.  

# The Password Hashes are synced to Entra ID from AD DS
# If AD DS is down things still work.
# Micrsoft monitors password hashes

# https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/plan-connect-topologies
# https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/whatis-phs
# how it works
# https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-password-hash-synchronization

# The Active Directory domain service stores passwords in the form of a hash value representation, of the actual user password. 
# A hash value is a result of a one-way mathematical function (the hashing algorithm). 
# There's no method to revert the result of a one-way function to the plain text version of a password.

# File Hash Test illustrate how hashing works
"Yahoo" | Out-File .\yahoo.txt
Get-Content .\yahoo.txt
Get-FileHash .\yahoo.txt -Algorithm SHA256

# Format-Hex .\yahoo.txt

#            Path: C:\Users\A19mk\yahoo.txt

#            00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F

# 00000000   FF FE 59 00 61 00 68 00 6F 00 6F 00 0D 00 0A 00  .þY.a.h.o.o.....


# Moose in Hex
# 4D 00 6F 00 6F 00 73 00 65 00
"Moose" | Out-File .\yahoo.txt
Get-Content .\yahoo.txt
Get-FileHash .\yahoo.txt -Algorithm SHA256
Format-Hex .\yahoo.txt

#            Path: C:\Users\A19mk\yahoo.txt

#            00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F

# 00000000   FF FE 4D 00 6F 00 6F 00 73 00 65 00 0D 00 0A 00  .þM.o.o.s.e.....


# Explanation of Binary
# FF FE        → UTF‑16 Little Endian BOM
# 79 00        → y
# 61 00        → a
# 68 00        → h
# 6F 00        → o
# 6F 00        → o
# 0D 00        → carriage return
# 0A 00        → line feed


# Dec  Hex   Binary      Char  |  Dec  Hex   Binary      Char  |  Dec  Hex   Binary      Char  |  Dec  Hex   Binary      Char
# ---  ----  ----------  ----  |  ---  ----  ----------  ----  |  ---  ----  ----------  ----  |  ---  ----  ----------  ----
#   0  00   00000000         |   32  20   00100000    SP  |   64  40   01000000     @   |   96  60   01100000     `
#   1  01   00000001         |   33  21   00100001     !   |   65  41   01000001     A   |   97  61   01100001     a
#   2  02   00000010         |   34  22   00100010     "   |   66  42   01000010     B   |   98  62   01100010     b
#   3  03   00000011         |   35  23   00100011     #   |   67  43   01000011     C   |   99  63   01100011     c
#   4  04   00000100         |   36  24   00100100     $   |   68  44   01000100     D   |  100  64   01100100     d
#   5  05   00000101         |   37  25   00100101     %   |   69  45   01000101     E   |  101  65   01100101     e
#   6  06   00000110         |   38  26   00100110     &   |   70  46   01000110     F   |  102  66   01100110     f
#   7  07   00000111         |   39  27   00100111     '   |   71  47   01000111     G   |  103  67   01100111     g
#   8  08   00001000         |   40  28   00101000     (   |   72  48   01001000     H   |  104  68   01101000     h
#   9  09   00001001         |   41  29   00101001     )   |   73  49   01001001     I   |  105  69   01101001     i
#  10  0A   00001010         |   42  2A   00101010     *   |   74  4A   01001010     J   |  106  6A   01101010     j
#  11  0B   00001011         |   43  2B   00101011     +   |   75  4B   01001011     K   |  107  6B   01101011     k
#  12  0C   00001100         |   44  2C   00101100     ,   |   76  4C   01001100     L   |  108  6C   01101100     l
#  13  0D   00001101         |   45  2D   00101101     -   |   77  4D   01001101     M   |  109  6D   01101101     m
#  14  0E   00001110         |   46  2E   00101110     .   |   78  4E   01001110     N   |  110  6E   01101110     n
#  15  0F   00001111         |   47  2F   00101111     /   |   79  4F   01001111     O   |  111  6F   01101111     o
#  16  10   00010000         |   48  30   00110000     0   |   80  50   01010000     P   |  112  70   01110000     p
#  17  11   00010001         |   49  31   00110001     1   |   81  51   01010001     Q   |  113  71   01110001     q
#  18  12   00010010         |   50  32   00110010     2   |   82  52   01010010     R   |  114  72   01110010     r
#  19  13   00010011         |   51  33   00110011     3   |   83  53   01010011     S   |  115  73   01110011     s
#  20  14   00010100         |   52  34   00110100     4   |   84  54   01010100     T   |  116  74   01110100     t
#  21  15   00010101         |   53  35   00110101     5   |   85  55   01010101     U   |  117  75   01110101     u
#  22  16   00010110         |   54  36   00110110     6   |   86  56   01010110     V   |  118  76   01110110     v
#  23  17   00010111         |   55  37   00110111     7   |   87  57   01010111     W   |  119  77   01110111     w
#  24  18   00011000         |   56  38   00111000     8   |   88  58   01011000     X   |  120  78   01111000     x
#  25  19   00011001         |   57  39   00111001     9   |   89  59   01011001     Y   |  121  79   01111001     y
#  26  1A   00011010         |   58  3A   00111010     :   |   90  5A   01011010     Z   |  122  7A   01111010     z
#  27  1B   00011011         |   59  3B   00111011     ;   |   91  5B   01011011     [   |  123  7B   01111011     {
#  28  1C   00011100         |   60  3C   00111100     <   |   92  5C   01011100     \   |  124  7C   01111100     |
#  29  1D   00011101         |   61  3D   00111101     =   |   93  5D   01011101     ]   |  125  7D   01111101     }
#  30  1E   00011110         |   62  3E   00111110     >   |   94  5E   01011110     ^   |  126  7E   01111110     ~
#  31  1F   00011111         |   63  3F   00111111     ?   |   95  5F   01011111     _   |  127  7F   01111111   DEL
