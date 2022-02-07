Import-Module -Name 'C:\Users\Tech\OneDrive - Academy for Precision Learning\Documents\Powershell\Myfunctions.psm1'
Test-ExchangeOnlineConnectivity -testgroup "APL Families"
$email = Read-host -Prompt "Enter the email of the contact"

$contactexist = Get-MailContact -Identity $email | Measure-Object

if ($contactexist.Count -eq 0) {

Write-Host "Could not find email. Please create contact."
$name = Read-Host -Prompt "Enter the full name of the new contact"
New-MailContact -Name $name -ExternalEmailAddress $email

}

else {

Write-Host "Contact found."

}


Write-host "Checking if distribution group already contains contact..."
$memberexist = Get-DistributionGroupMember -Identity "APL Families" | Where-Object {$_.emailaddresses -like "*$email*"} | Measure-object

if ($memberexist.Count -eq 0) {

Write-host "Member not found. Adding to distribution group..."
Add-DistributionGroupMember -Identity "APL Families" -Member $email
Write-Host "Member added."

}

else {

Write-host "Found the following for that email address:"
$memberexist
Write-Host "Member is already in distribution group. Please check the office.com portal to investigate further. Terminating..."

}