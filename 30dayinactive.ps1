## In order for the two below functions to work you will need to use Export-clixml to generate the encrypted credentials. 
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

function Test-AzureADConnectivity {

try{
$connected = Get-AzureADTenantDetail
}

catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException]

{
Write-Host -ForegroundColor Red "You're not connected to Azure AD, please enter your credentials"

## Get the credential, connect to Azure AD
if ($credential -eq $null) 
{
$credential = Import-CliXml -Path 'C:\cred.xml'
}

connect-azuread -Credential $credential


}
}

Test-AzureADConnectivity
Test-ExchangeOnlineConnectivity -Testgroup "[group]"


## Create an arraylist and add accounts from a csv with a header of "mail." Use this arraylist to exclude testing certain accounts that are known to be over 30days without use but are needed for whatever reason.
$exclusionlist = New-Object -TypeName "System.Collections.ArrayList"
foreach ($exclusion in $inactiveexclude) {
$exclusionlist.Add($exclusion.mail)
}

## Get all users that aren't guests, are not in the exclude list, and are enabled
$users = Get-AzureADUser -All $true | Where-Object {($_.usertype -ne "Guest") -and ($_.AccountEnabled -eq $true) -and ($exclusionlist -notcontains $_.mail)}

## Set up counter for progress bar
$usercount = $users.Count
$i = 0

## Create arraylist to add inactive users to for export
$inactiveuserlist = New-Object -TypeName "System.Collections.ArrayList"

## Establish date to test against
$monthago = (Get-date).AddDays(-30)

## Loop through user list and use Get-mailbox statistics to test user activity against $monthago. If the account has been inactive longer than $monthago, add to $inactiveuserlist.
foreach ($user in $users) {

$identity = $user.userprincipalname
$mailbox = Get-MailboxStatistics -identity $identity -erroraction ignore
$lastactiontime = $mailbox.lastuseractiontime

if ($lastactiontime -lt $monthago) {

$inactiveuserlist.Add($user)

}
 
$i++
Write-Progress -Activity "Testing user accounts..." -Status "User $i of $($usercount)" -PercentComplete (($i / $usercount) * 100) 

}

## Export all that work
$inactiveuserlist | export-csv "[path]" -NoTypeInformation
