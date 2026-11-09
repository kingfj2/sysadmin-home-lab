$Root = "C:\Shares"
$Map = @{
    "HR"      = "GG-HR"
    "Finance" = "GG-Finance"
    "IT"      = "GG-IT"
    "Company" = "Domain Users"
}

foreach ($Folder in $Map.Keys) {
    $Path = "$Root\$Folder"
    icacls $Path /inheritance:r `
        /grant "BUILTIN\Administrators:(OI)(CI)F" `
        /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" `
        /grant "KINGLAB\$($Map[$Folder]):(OI)(CI)M" | Out-Null

    if ($LASTEXITCODE -eq 0) { Write-Host "Set permissions on $Path" }
    else { Write-Host "FAILED on $Path (exit code $LASTEXITCODE)" -ForegroundColor Red }
}