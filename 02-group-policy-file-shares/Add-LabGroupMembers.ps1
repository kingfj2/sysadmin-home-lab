ADD users to group

$Groups = @{
    GG-HR      = @(msantos, areyes, lmendoza)
    GG-Finance = @(jdelacruz, cgarcia, jramos)
    GG-IT      = @(mvillanueva, gbautista, baquino)
}

foreach ($Group in $Groups.Keys) {
    foreach ($User in $Groups[$Group]) {
        try {
            Add-ADGroupMember -Identity $Group -Members $User -ErrorAction Stop
            Write-Host Added $User to $Group
        }
        catch {
            Write-Host FAILED $User - $Group  $($_.Exception.Message) -ForegroundColor Red
        }
    }
}


Verify the users to group

foreach ($G in "GG-HR","GG-Finance","GG-IT") {
    Write-Host "--- $G ---"
    Get-ADGroupMember -Identity $G | Select-Object Name, SamAccountName | Format-Table | Out-String | Write-Host
}