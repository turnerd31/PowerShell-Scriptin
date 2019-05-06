#Set GPO Permissions to $group. Permission level determined in -PermissionLevel. Better to start low. 
#Can do batches of similar GPO names, or alter | where filter as needed

function Write-Color([String[]]$Text, [ConsoleColor[]]$Color, [switch]$nnl) {
    for ($i = 0; $i -lt $Text.Length; $i++) {
        if (-Not $Color[$i]) { $Color = $Color += "White" }
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    if ($nnl -eq $true) { } else { Write-Host }
}

function GetPermissionLevel{
    Write-Color "What Permission Level would you like for the Security Group to have? (Read/Edit/Modify/None)" -Color Magenta -nnl
    Read-Host
}


$GPOList = get-gpo –all | where{$_.displayname –like “GPO TYPE1*”}
$group = $(get-adgroup “GPO_Management_Group1”).sAMAccountName


DO { $PermissionLevel = GetPermissionLevel } While ([string]::IsNullOrWhiteSpace($PermissionLevel))

If ($PermissionLevel -ne 'Read' -or 'Edit' -or 'Modify' -or 'None'){ 
Write-Color "You have entered an invalid permission. Exiting script..." -Color Yellow -nnl
    Exit}


If ($PermissionLevel -eq 'Read'){ $PermissionLevel = 'GpoRead'}
If ($PermissionLevel -eq 'Edit'){ $PermissionLevel = 'GpoEdit'}
If ($PermissionLevel -eq 'Modify'){ $PermissionLevel = 'GpoEditDeleteModifySecurity'}
If ($PermissionLevel -eq 'None'){ $PermissionLevel = 'None'}


$GPOList | foreach{set-gppermissions -guid $_.id -targetname $group -targettype Group -PermissionLevel $PermissionLevel}
