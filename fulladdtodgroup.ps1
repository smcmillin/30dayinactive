## Create cred.xml with Export-clixml
function Test-ExchangeOnlineConnectivity {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[string] $Testgroup

)

$connected = Get-DistributionGroup -Identity "$Testgroup" -ErrorAction SilentlyContinue
if ($connected -eq $null -and $credential -eq $null) {
Write-Host -ForegroundColor Yellow "You are not connected to Exchange Online. Please enter your credentials."
Start-Sleep -Seconds 1

$global:credential = Import-CliXml -Path 'C:\cred.xml'
Connect-ExchangeOnline -Credential $credential
}
}

Test-ExchangeOnlineConnectivity -testgroup "[distribution group]"

## First, check if the contact exists before adding. If it exists, continue. If not, create contact.
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

## Get group name, and see if the group already contains the contact. If so, print found information. If not, add the contact.
$group = Read-host "Enter the distribution group you wish to edit"
Write-host "Checking if distribution group already contains contact..."
$memberexist = Get-DistributionGroupMember -Identity "$group" | Where-Object {$_.emailaddresses -like "*$email*"} | Measure-object

if ($memberexist.Count -eq 0) {

Write-host "Member not found. Adding to distribution group..."
Add-DistributionGroupMember -Identity "$group" -Member $email
Write-Host "Member added."

}

else {

Write-host "Found the following for that email address:"
$memberexist
Write-Host "Member is already in distribution group. Please check the office.com portal to investigate further. Terminating..."

}
