## Splash screen
Write-Host -ForegroundColor Yellow `
"Azure AD Password Reset Tool v. 1.1
************************************

"

Import-Module -Name "C:\Users\Tech\OneDrive - Academy for Precision Learning\Documents\Powershell\Myfunctions.psm1"

## Check to see if already connected to Azure AD
Test-azureadconnectivity

## Search for account to reset password for
$search = Read-host "Enter the name of the person whose password you want to change"
Do {
$search = $search -replace ".$"
$searchexist = get-azureaduser -SearchString "$search"
}
While ($searchexist -eq $null)

## Display a gridview of all the options the search found. Pass selection to variable
$account = Get-AzureADUser -SearchString "$search" | Out-GridView -PassThru

## Confirm selection
$confirmation = Read-Host "You have selected $($account.userprincipalname) as the account to reset the password for. Is this correct? [y/n]"
if ($confirmation -eq "y") {

## Enter password
$password = New-RandomPassword -Base "APLRocks" -Length 4
} Else {
Write-Host -ForegroundColor Yellow "Restart the script and select the desired user."
break
}

## Attempt to reset the password
try {
Set-AzureADUserPassword -ObjectID "$($account.userprincipalname)" -Password (ConvertTo-SecureString -String "$password" -Force -AsPlainText) -ForceChangePasswordNextLogin $true
}
catch {
Write-Host "Either the email address you entered was not valid or the password you entered was not complex enough. Check the email address and try again."
break
}

## Confirm if user wants to send password in email
$answer = Read-Host "Do you want to send this information in an email? [y/n]"
if ($answer -eq "y"){
Write-Host "Before I can send the temporary password to the user, I need some information."
}
else {
Write-Host -ForegroundColor Yellow "Exiting, password is $password"
break
}

## Get email of sender and recipient
$sender = "sam.m@aplschool.org"
$recipient = Read-Host "Enter the PERSONAL email address of the user"

## Define the Send-MailMessage parameters
$mailParams = @{
    SmtpServer                 = 'smtp.office365.com'
    Port                       = '587' # or '25' if not using TLS
    UseSSL                     = $true ## or not if using non-TLS
    Credential                 = $credential
    From                       = $sender
    To                         = $recipient
    Subject                    = "Your APL account password has been reset - $(Get-Date -Format g)"
    Body                       = "Your APL password has been reset. Your account information is below:
	
	Username: $($account.userprincipalname)
	Password: $password 
	
	You will be asked to change your password the next time you log in.
	
	Samuel McMillin
	IT Support Associate
	sam.m@aplschool.org"
    DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
}

## Send the message
Send-MailMessage @mailParams

Write-Host -ForegroundColor Yellow "Password reset successful."