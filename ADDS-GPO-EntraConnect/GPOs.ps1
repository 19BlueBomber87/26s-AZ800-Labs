# =============================================================================
# Hyper-V Lab Creation - User and Computer GPO Configuration
# =============================================================================
# Author:   Mark Kruse
# Purpose: GPO Applied Wall Paper and Add MCM-RDS-Users Group to local "Remote Desktop Users" Group
# =========================================================================================================================================================

# ========================================================
# Step  1 -Create User GPO to set Wall Paper.  Create and Confgiure GPO with PowerShell
# ========================================================

mkdir C:\Share01\WallPapers
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/ADDS-GPO-EntraConnect/WallPaper-GPO.png" -OutFile "C:\Share01\Wallpapers\RDP-WallPaper.png" -Verbose *>&1

# Share Wall Paper Location
$Path = "C:\Share01\WallPapers"
$ShareName = "Wallpapers"
New-SmbShare -Name $ShareName -Path $Path -Description "Wallpapers for Domain Users" -ChangeAccess "Everyone" -FullAccess "Domain Admins" -Verbose *>&1  

# Create GPO
$DomainDN = "DC=minecraftmoose,DC=com"   # <<< CHANGE IF YOUR DOMAIN IS DIFFERENT
$OUName   = "Entra Synced Users"
$OUPath   = "OU=$OUName,$DomainDN"
$GPOName  = "Set-Wallpaper"
$Comment  = "Corporate Wallpaper"
$WallpaperPath = "\\ANC-DC01\WallPapers\RDP-WallPaper.jpg"     # UNC path to image
$WallpaperStyle = "2"                               # 0=Centered, 2=Stretch, 3=Fit, 4=Fill, 5=Span
$PreventChange = $true                              # $false = allow users to change

Import-Module GroupPolicy -ErrorAction Stop
Import-Module ActiveDirectory -ErrorAction Stop
$gpo = New-GPO -Name $GPOName -Comment $Comment -ErrorAction Stop
Write-Verbose "GPO '$GPOName' created successfully." -Verbose *>&1


# === WALLPAPER SETTINGS (User Configuration) ===
Set-GPRegistryValue -Name $GPOName `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "Wallpaper" -Type String -Value $WallpaperPath

Set-GPRegistryValue -Name $GPOName `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "WallpaperStyle" -Type String -Value $WallpaperStyle

if ($PreventChange) {
    Set-GPRegistryValue -Name $GPOName `
        -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" `
        -ValueName "NoChangingWallPaper" -Type DWord -Value 1
}

# 3. LINK the GPO to the OU (This was missing!)
New-GPLink -Name $GPOName -Target $OUPath -LinkEnabled Yes -ErrorAction Stop
Write-Verbose "GPO '$GPOName' successfully linked to $OUPath" -Verbose *>&1

# Final Message
Write-Verbose "`n=== DONE! ==="  -Verbose *>&1
Write-Verbose "Run 'gpupdate /force' on test machines."  -Verbose *>&1
Write-Verbose "Check Group Policy Management Console to verify the link."  -Verbose *>&1

# on member servers use "gpupdate /force" to update group policy
gpupdate /force
# ========================================================
# Step  2 -Create Computer GPO to sAdd MCM-RDS-Users to Remote Desktop Users.  
# Create and Confgiure GUI
# ========================================================

# 1. Open Group Policy Management (gpmc.msc)

# 2. Right-click the OU that contains your computers or servers → 
#    Select "Create a GPO in this domain, and Link it here"

# 3. Name the GPO: RDS - Allow MCM-RDS-Users

# 4. Right-click the new GPO → Select "Edit"

# 5. In the Group Policy Editor go to:
#    Computer Configuration 
#    → Policies 
#    → Windows Settings 
#    → Security Settings 
#    → Restricted Groups

# 6. Right-click on "Restricted Groups" (left side) → Add Group

# 7. Type exactly: Remote Desktop Users → Click OK

# 8. Double-click the "Remote Desktop Users" entry that appears

# 9. In the bottom section "This group is a member of" → Click Add

# 10. Type: MCM-RDS-Users → Click "Check Names" → OK

# 11. Click OK to close the properties window

# 12. Close the Group Policy Editor

# 13. On a test computer run in Command Prompt (as admin):
#     gpupdate /force

# After this, members of MCM-RDS-Users should be able to RDP.

# ========================================================
# -Create User GPO to set Wall Paper.  Create and Confgiure GPO with GUI
# ========================================================

# GROUP POLICY - SET DESKTOP WALLPAPER (GUI Steps)

# 1. Open Group Policy Management
#    - Press Win + R, type gpmc.msc and press Enter

# 2. Create New GPO
#    - Expand your domain
#    - Right-click "Group Policy Objects" → New
#    - Name: Set-Company-Wallpaper
#    - Click OK

# 3. Edit the GPO
#    - Right-click the new GPO → Edit

# 4. Configure Wallpaper Policy
#    - Go to:
#      User Configuration → Policies → Administrative Templates → Desktop → Desktop
#    - Double-click "Desktop Wallpaper"

# 5. Set the Settings
#    - Select: Enabled
#    - Wallpaper Name: \\ANC-DC01\WallPapers\RDP-WallPaper.png     (or local path)
#    - Wallpaper Style: Fill (recommended) / Stretch / Fit
#    - Click Apply → OK

# 6. (Optional) Prevent Changing Wallpaper
#    - Go to:
#      User Configuration → Policies → Administrative Templates → Control Panel → Personalization
#    - Double-click "Prevent changing desktop background"
#    - Select: Enabled
#    - Click Apply → OK

# 7. Link the GPO
#    - Back in GPMC
#    - Right-click the target OU (Users OU) → Link an Existing GPO
#    - Select your GPO → OK

# 8. Apply on Client
#    - On client PC run Command Prompt as Administrator:
#      gpupdate /force
#    - Log off and log back on

# Notes:
# - Use UNC path for wallpaper file
# - File must be accessible to all users
# - This is User Configuration policy
