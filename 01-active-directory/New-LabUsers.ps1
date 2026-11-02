$Password = ConvertTo-SecureString "Password1!" -AsPlainText -Force
$OU       = "OU=_USERS,DC=kinglab,DC=local"
$Domain   = "kinglab.local"

$Names = @(
    "Maria Santos", "Juan Dela Cruz", "Ana Reyes", "Carlo Garcia", "Liza Mendoza",
    "Mark Villanueva", "Joy Ramos", "Paolo Cruz", "Grace Bautista", "Ben Aquino"
)

foreach ($Name in $Names) {
    $First, $Last = $Name -split " ", 2
    $Sam = ($First.Substring(0,1) + $Last).ToLower() -replace " ", ""

    New-ADUser -Name $Name `
        -GivenName $First -Surname $Last `
        -SamAccountName $Sam `
        -UserPrincipalName "$Sam@$Domain" `
        -Path $OU `
        -AccountPassword $Password `
        -Enabled $true `
        -PasswordNeverExpires $true

    Write-Host "Created $Name ($Sam)"
}
