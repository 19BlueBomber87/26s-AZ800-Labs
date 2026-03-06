# =============================================================================
# Hyper-V Lab Creation - Quick user Pool Creation
# =============================================================================
# Author:   Mark Kruse
# Purpose: Quickly Create Test user pool in custom OU
# =========================================================================================================================================================

# ========================================================
# Step  1 -Create DCs - Create Test User pool 
# ========================================================
################## #loop1 -> minecraftmoose.com ###############

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
    $pass = "Taz14Spaz!@#"
    $secureString = ConvertTo-SecureString "Taz14Spaz!@#" -AsPlainText -Force
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


# ========================================================
# Step  2 -Create DCs - Create Test User pool 
# ========================================================
###################loop2 -> moosewyre.fun ###############

$megaman2 = "Bubble Man", "Air Man", "Crash Man", "Quick Man", "Heat Man", "Wood Man", "Metal Man", "Flash Man"


#choose domain

$domain = "moosewyre.fun"
$manager = "megaman"
$OUName = "Entra Synced Users"
$DC_Value = $domain.TrimEnd(".fun")
$OUPath = "DC=$DC_Value,DC=fun"   # Replace with your domain DN

# Create the OU
New-ADOrganizationalUnit -Name $OUName -Path $OUPath -ProtectedFromAccidentalDeletion $true
#start
foreach($boss in $megaman2){
    $distinguishedName = $domain.TrimEnd(".fun")
    $office = "Nome"
    $city = $office
    $zip = 99762
    $pass = "Taz14Spaz!@#"
    $secureString = ConvertTo-SecureString "Taz14Spaz!@#" -AsPlainText -Force
    $firstName = ($boss.Split(" "))[0]
    $lastName = ($boss.Split(" "))[1]
    $SAM =($FirstName + $LastName).ToLower()
    $userName = $Sam + "@" + $domain
    $OU = "OU=Entra Synced Users,DC=$distinguishedName,DC=fun"


    New-ADUser -Name $boss -SamAccountName $SAM -UserPrincipalName $userName -GivenName $firstName -Surname $lastName -Path $OU -AccountPassword $secureString -Enabled $true -Verbose *>&1
    Set-ADUser $SAM `
        -DisplayName $boss `
        -Description $($Office + " Programmer") `
        -Office $Office `
        -EmailAddress $userName `
        -Enabled $True `
        -Homepage $domain `
        -StreetAddress "456 Front Street" `
        -POBOX 1818 `
        -City $city `
        -State "AK" `
        -PostalCode $zip `
        -Title "Programmer" `
        -Department "Programming" `
        -Company "MooseWyre.fun" `
        -Manager $manager -ErrorAction STOP -Verbose *>&1 #username of Manager
    }

# ========================================================
# Step  3 -Create DCs - Create Test User pool 
# ========================================================
################## #loop 3 -> megamooselabsfun.com ###############

$megaman3 = "Hard Man", "Top Man", "Shadow Man", "Spark Man", "Snake Man", "Gemini Man", "Needle Man", "Magnet Man"

#choose domain

$domain = "megamooselabsfun.com"
$manager = "megaman"
$OUName = "Entra Synced Users"
$DC_Value = $domain.TrimEnd(".com")
$OUPath = "DC=$DC_Value,DC=com"   # Replace with your domain DN
# Create the OU
New-ADOrganizationalUnit -Name $OUName -Path $OUPath -ProtectedFromAccidentalDeletion $true
#start
foreach($boss in $megaman3){
    $distinguishedName = $domain.TrimEnd(".com")
    $office = "Juneau"
    $city = $office
    $zip = 99824
    $pass = "Taz14Spaz!@#"
    $secureString = ConvertTo-SecureString "Taz14Spaz!@#" -AsPlainText -Force
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
        -StreetAddress "789 Moose Way" `
        -POBOX 7777 `
        -City $city `
        -State "AK" `
        -PostalCode $zip `
        -Title "Programmer" `
        -Department "Programming" `
        -Company "MegaMooseLabsFun.com" `
        -Manager $manager -ErrorAction STOP -Verbose *>&1 #username of Manager
    }

    
# ========================================================
# Step  4 -Create DCs - Create Test User pool 
# ========================================================
################## #loop 4 -> dev.moosewyre.fun ###############

$megaman4 = "Toad Man", "Bright Man", "Pharaoh Man", "Ring Man", "Dust Man", "Skull Man", "Dive Man", "Drill Man"

$domain = "dev.moosewyre.fun"
$manager = "megaman"
$OUName = "Entra Synced Users"
$DC_Value = ($domain.TrimEnd(".fun")).split(".")
$DC_Value1 = $DC_Value[1]
$DC_Value2 = $DC_Value[0]
$OUPath = "DC=$DC_Value2, DC=$DC_Value1,DC=fun"   # Replace with your domain DN
# Create the OU
New-ADOrganizationalUnit -Name $OUName -Path $OUPath -ProtectedFromAccidentalDeletion $true
#start
foreach($boss in $megaman4){
    $office = "Eagle River"
    $city = $office
    $zip = 99577
    $pass = "Taz14Spaz!@#"
    $secureString = ConvertTo-SecureString "Taz14Spaz!@#" -AsPlainText -Force
    $firstName = ($boss.Split(" "))[0]
    $lastName = ($boss.Split(" "))[1]
    $SAM =($FirstName + $LastName).ToLower()
    $userName = $Sam + "@" + $domain
    $OU = "OU=Entra Synced Users,DC=$DC_Value2,DC=$DC_Value1,DC=fun"


    New-ADUser -Name $boss -SamAccountName $SAM -UserPrincipalName $userName -GivenName $firstName -Surname $lastName -Path $OU -AccountPassword $secureString -Enabled $true -Verbose *>&1
    Set-ADUser $SAM `
        -DisplayName $boss `
        -Description $($Office + " Programmer") `
        -Office $Office `
        -EmailAddress $userName `
        -Enabled $True `
        -Homepage $domain `
        -StreetAddress "777 Eagle River Road" `
        -POBOX 1987 `
        -City $city `
        -State "AK" `
        -PostalCode $zip `
        -Title "Programmer" `
        -Department "Programming" `
        -Company "Minecraftmoose.com" `
        -Manager $manager -ErrorAction STOP -Verbose *>&1 #username of Manager
    }

    

    # #prtotype
# $domain = "minecraftmoose.com"
# $office = "Anchorage"
# $city = $office
# $zip = 99504
# $pass = "Taz14Spaz!@#"
# $secureString = ConvertTo-SecureString "Taz14Spaz!@#" -AsPlainText -Force
# $displayName = "Proto Man3"
# $firstName = ($Displayname.Split(" "))[0]
# $lastName = ($Displayname.Split(" "))[1]
# $SAM =($FirstName + $LastName).ToLower()
# $userName = $Sam + "@" + $domain
# $OU = "OU=AAD Synced Users,DC=minecraftmoose,DC=com"


# New-ADUser -Name $displayName -SamAccountName $SAM -UserPrincipalName $userName -GivenName $firstName -Surname $lastName -Path $OU -AccountPassword $secureString -Enabled $true -Verbose *>&1
# Set-ADUser $SAM `
#     -Description $($Office + " Programmer") `
#     -Office $Office `
#     -EmailAddress $userName `
#     -Enabled $True `
#     -Homepage $domain `
#     -StreetAddress "3021 Brookridge Circle" `
#     -POBOX 7777 `
#     -City $city `
#     -State "AK" `
#     -PostalCode $zip `
#     -Title "Programmer" `
#     -Department "Programming" `
#     -Company "RockTech" `
#     -Manager "MegaMan" -ErrorAction STOP -Verbose *>&1 #username of Manager
