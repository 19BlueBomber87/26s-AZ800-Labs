# =============================================================================
# Hyper-V Lab - Prepare Golden Image with SysPrep
# =============================================================================
# Author:   Mark Kruse
# Purpose:  Prepare golden images via SysPrep
# Location: Anchorage, Alaska lab environment
# =============================================================================
# =========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/HyperV%20Lab%20Creation%20and%20Disk%20Functions.ps1
# =========================================================================================================================================================
# Use 2GB or higher if possible
New-Lab_VM -VMNames GoldenImage-ServerCore -HyperVSwitch EXT-INT -Ram 2GB -ISOPath C:\ISO\2025_26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso
New-Lab_VM -VMNames GoldenImage-DesktopExperience -HyperVSwitch EXT-INT -RAM 2GB -ISOPath 2025_26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso

#enter Audit Mode - At the very first OOBE screen CTRL + SHIFT + F3
#intsall Updates
#install Apps
#Set wall paper background

# =========================
# Step 1 - Install Python 
# =========================
$pythonUrl = "https://www.python.org/ftp/python/3.12.6/python-3.12.6-amd64.exe"
$installerPath = "$env:TEMP\python-installer.exe"

# Download installer
Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath

# Install silently with default options
Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait

shutdown /r /f /t 0
# Verify installation
python --version

# Use notepad to create yahoo.py
notepad yahoo.py
#Paste the text below into yahoo.py and save to desktop
import textwrap
with open("unicodeAlphabet-Py.txt", "w",encoding="UTF-8") as unicodeAlphabet:
    for i in range(55295):
        uniCharacter = chr(i)
        print(uniCharacter,end='',file = unicodeAlphabet)
    for i in range(57900,65994):
        uniCharacter = chr(i)
        print(uniCharacter,end='',file = unicodeAlphabet)
    # for i in range(65537):
    #     uniCharacter = chr(i)
    #     print(uniCharacter,end='',file = unicodeAlphabet)
    # for i in range(129):
    #     uniCharacter = chr(i)
    #     print(uniCharacter,end='',file = unicodeAlphabet)
    unicodeAlphabet.close()
    
with open("unicodeAlphabet-Py.txt", "r",encoding="UTF-8") as unicodeAlphabet:
    x = unicodeAlphabet.read()
    with open("unicodeAlphabet-Py-wrapped.txt","w",encoding="UTF-8") as unicodeWrap:
        print("\n".join(textwrap.wrap(x,100)),file=unicodeWrap)
    unicodeWrap.close()
    unicodeAlphabet.close()
#end of python file
# ============================================
# Step 2- Custom Background Image            
# Skip this step if making Server Core Image 
# ============================================

mkdir C:\Windows\Web\Wallpaper\Custom
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/main/Main.JPG" -OutFile "C:\Windows\Web\Wallpaper\Custom\MegaMan.jpg"

#USE GUI TO SET BACKGROUND!

# =============================================
# Step 3 - Pull unattend.xml file for Sysprep 
# =============================================
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/19BlueBomber87/Hyper-V-GoldenImages/refs/heads/main/Apps/unattend.xml" -OutFile C:\Windows\System32\Sysprep\unattend.xml

# ===================
# Step 4 - Sysprerp 
# ===================
C:\windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\unattend.xml

# ======================
# Step 4 - Post Sysprerp 
# ======================
# Move the .vhdx file to C:\GoldenImages
# Now New-Lab VM can use GeneralizedImageDE.
New-Lab_VM -VMNames yahoo -HyperVSwitch ext-int -GeneralizedImageDE -RAM_GB 2GB

# ============================================
# Step 5                                     
# Repeat steps 1-4 using a Server Core Image 
# ============================================
# Now New-Lab VM can use GeneralizedImageCore
New-Lab_VM -VMNames yahoo -HyperVSwitch ext-int -GeneralizedImageCore -RAM_GB 2GB

# ============================================
# GUI                                    
# You can copy and rename the golden image with the GUI.  
# ============================================

