# New-ShareFolders.ps1
# Creates the Lab 2 folder structure under C:\Shares.
# Safe to re-run: -Force does not error if a folder already exists.

$Root = "C:\Shares"

foreach ($Folder in "HR","Finance","IT","Company") {
    New-Item -Path "$Root\$Folder" -ItemType Directory -Force | Out-Null
}

Get-ChildItem $Root | Select-Object Name, FullName