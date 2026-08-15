function CreateLabSwitches {
    <#
    .SYNOPSIS
        Creates the standard lab private virtual switches (ANC-Net, Nome-Net, JUN-Net, ER-Net)
        and one external switch (EXT-INT) bound to the Wi-Fi adapter with host management allowed.
        Skips creation if a switch with the same name already exists.
        Extremely non-destructive — safe to run multiple times.
    .DESCRIPTION
        Builds the networking foundation for the lab environment.
        Uses private switches for isolated lab segments and one external switch for internet/host access.
        No parameters required — just run it.
    .EXAMPLE
        CreateLabSwitches
    .EXAMPLE
        CreateLabSwitches -Confirm    # (Confirm has no real effect here)
    #>

    # Private lab switches (isolated networks)
    $privateSwitches = @(
        "ANC-Net",
        "Nome-Net",
        "JUN-Net",
        "ER-Net",
        "LINUX-Net"
    )

    foreach ($name in $privateSwitches) {
        if (-not (Get-VMSwitch -Name $name -ErrorAction SilentlyContinue)) {
            Write-Verbose "Creating private switch: $name" -Verbose
            New-VMSwitch -Name $name -SwitchType Private -Verbose *>&1
        } else {
            Write-Verbose "Switch $name already exists — skipping" -Verbose
        }
    }

    # External switch (bound to Wi-Fi adapter, host can share connection)
    $extName = "EXT-INT"
    $adapterName = "Wi-Fi"   # ← change this if your Wi-Fi adapter has a different name

    if (-not (Get-VMSwitch -Name $extName -ErrorAction SilentlyContinue)) {
        Write-Verbose "Creating external switch: $extName (using adapter: $adapterName)" -Verbose
        New-VMSwitch -Name $extName -NetAdapterName $adapterName -AllowManagementOS $true -Verbose *>&1
    } else {
        Write-Verbose "External switch $extName already exists — skipping" -Verbose
    }

    Write-Host "Lab switches creation complete." -ForegroundColor Green
}
