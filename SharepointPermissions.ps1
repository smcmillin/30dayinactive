Write-Host "Sharepoint Permissions tool v1.0
*********************************"

## Adding necessary components
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -AssemblyName System.Windows.Forms
   
## Site Information
$SiteUrl = "[site url]"
$ListName="[list name]"

## Credentials
$username = Read-host -Prompt "Enter your username: "
$password = Read-host -Prompt "Enter your password: " -AsSecureString
  
#Setup Credentials to connect. Maybe there is an easier way to do this with get-credential.
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username,$password)
  
## Create Context
Write-host "Creating Sharepoint context..."
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
$ctx.Credentials = $Credentials
$List = $ctx.web.Lists.GetByTitle($ListName)
$ListItems = $List.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()) 
$ctx.Load($ListItems)
$ctx.ExecuteQuery()
Write-host "Context created."

## open dialog box for path
Read-Host -Prompt "A window will pop-up where you can browse to the .csv which contains the email addresses you want to assign to individual items. Browse to the file and click 'open'. Press any key to continue"
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
$null = $FileBrowser.ShowDialog()
$permissionslist = Import-csv -Path "$($FileBrowser.filename)"
Write-host "Loaded csv."

## Begin loop through csv
foreach ($item in $permissionslist) {

## Parse csv
$name = $item.name
$username = $item.username
Write-host "Now adding $username to $name..."

## Search name from Sharepoint list
$title = $ListItems | where {$_["Title"] -eq "$name"}

## Powershell won't assign roles if there are inherited roles. This next part breaks those inherited permissions
$title.BreakRoleInheritance($false, $false) 
$ctx.ExecuteQuery()

##The permission stuff
$UserID = $item.username
$PermissionLevel = "Read"

$User = $ctx.Web.EnsureUser($UserID)
$ctx.load($User)
$ctx.ExecuteQuery()

$Role = $ctx.web.RoleDefinitions.GetByName($PermissionLevel)
$RoleDB = New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($ctx)
$RoleDB.Add($Role)

$UserPermissions = $learner.RoleAssignments.Add($User,$RoleDB)
$title.Update()
$ctx.ExecuteQuery()

Write-host "$username added to $name."
}
