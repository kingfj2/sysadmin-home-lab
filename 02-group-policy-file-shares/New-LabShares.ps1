# New-LabShares.ps1
# Publishes each folder under C:\Shares as an SMB share.
# Share level: Authenticated Users get Change. The NTFS permissions
# set by Set-SharePermissions.ps1 do the real restricting.

$Root = "C:\Shares"

# Remove an old Company share if one exists (left over from a manual setup)
Get-SmbShare -Name "Company" -ErrorAction SilentlyContinue | Remove-SmbShare -Force

foreach ($Name in "HR","Finance","IT","Company") {
    try {
        New-SmbShare -Name $Name -Path "$Root\$Name" -ChangeAccess "Authenticated Users" -ErrorAction Stop | Out-Null
        Write-Host "Shared $Name"
    }
    catch {
        Write-Host "FAILED: $Name : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Verify
foreach ($N in "HR","Finance","IT","Company") {
    Write-Host "--- $N ---"
    Get-SmbShareAccess -Name $N | Select-Object Name, AccountName, AccessControlType, AccessRight | Format-Table | Out-String | Write-Host
}