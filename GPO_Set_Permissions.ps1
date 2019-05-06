#Set GPO Permissions to $group. Permission level determined in -PermissionLevel. Better to start low. 
#Can do batches of similar GPO names, or alter | where filter as needed

$GPOList = get-gpo –all | where{$_.displayname –like “GPO TYPE1*”}
$group = $(get-adgroup “GPO_Management_Group1”).sAMAccountName
$gpolist | foreach{set-gppermissions -guid $_.id -targetname $group -targettype Group -PermissionLevel GpoEdit}
