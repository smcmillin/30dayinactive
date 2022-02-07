Import-Module -name 'C:\Users\Tech\OneDrive - Academy for Precision Learning\Documents\Powershell\Myfunctions.psm1' 
Test-AzureADConnectivity
Test-ExchangeOnlineConnectivity -Testgroup "APL Families"

## SKU for student licenses, needed for filter
$studentlicense = "e82ae690-a2d5-4d76-8d30-7c6e01e6022e"
$inactiveexclude = Import-csv -Path "C:\Users\Tech\OneDrive - Academy for Precision Learning\Documents\30dayinactiveexclude.csv"

$exclusionlist = New-Object -TypeName "System.Collections.ArrayList"
foreach ($exclusion in $inactiveexclude) {
$exclusionlist.Add($exclusion.mail)
}



## Get all users that aren't guests, that do not have student licenses, and are enabled
$users = Get-AzureADUser -All $true | Where-Object {($_.usertype -ne "Guest") -and ($_.AssignedLicenses.skuid -ne $studentlicense) -and ($_.AccountEnabled -eq $true) -and ($exclusionlist -notcontains $_.mail)}

$usercount = $users.Count
$i = 0

$inactiveuserlist = New-Object -TypeName "System.Collections.ArrayList"
$monthago = (Get-date).AddDays(-30)

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

$inactiveuserlist | export-csv "C:\Users\Tech\OneDrive - Academy for Precision Learning\Documents\InactiveUserList.csv" -NoTypeInformation