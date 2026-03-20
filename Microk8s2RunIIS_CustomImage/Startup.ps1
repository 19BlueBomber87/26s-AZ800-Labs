# startup.ps1 - Customize the IIS default page with real pod/container info

$ErrorActionPreference = 'Stop'

$htmlPath = "C:\inetpub\wwwroot\Default.htm"

# Read the base HTML
$html = Get-Content $htmlPath -Raw

# Gather dynamic info
$computerName = $env:COMPUTERNAME
$osVersion    = (Get-WmiObject -Class Win32_OperatingSystem).Caption
$today        = Get-Date -Format "MM-dd-yyyy HH:mm:ss zzz"

# CPU name (first one if multiple)
$cpu = (Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1 -ExpandProperty Name).Trim()

# Better pod IP detection (Kubernetes pod IP is usually on the "Ethernet" interface, non-loopback)
$podIP = (Get-NetIPAddress -AddressFamily IPv4 `
          | Where-Object { $_.IPAddress -notmatch '^127\.|^169\.254\.' -and $_.InterfaceAlias -notlike '*Loopback*' } `
          | Select-Object -First 1 -ExpandProperty IPAddress)

if (-not $podIP) {
    $podIP = "[Pod IP not detected - check networking]"
}

# Build the replacement string
$replacement = "Welcome to Azure<br>Computer Name: $computerName<br>OS Version: $osVersion<br>Date: $today<br>CPU: $cpu<br>IP: $podIP"

# Perform the replacement (case-sensitive; adjust if needed)
$updatedHtml = $html -replace 'Custom Heading Size and Font Type', $replacement

# Write the updated file back
$updatedHtml | Out-File -FilePath $htmlPath -Encoding utf8 -Force

Write-Host "Page customized successfully!"
Write-Host "Replaced with: $replacement"