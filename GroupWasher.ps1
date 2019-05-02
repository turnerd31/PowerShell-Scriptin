#This script checks to see if each of the members of group 1 are members on in the list $ComparisonGroups. If true, user is removed from Group 1
#Created by Drew Turner
#5/2/2019

$AdminCredentials = Get-Credential "adminusername"
$Group1 = "NAMEOFGROUPONE"
$ComparisonGroups = Get-Content C:\LOCATION OF YOUR LIST OF COMPARISON GROUPS


ForEach ($user in (Get-ADGroupMember -Identity $Group1)) {
      ForEach ($group in $ComparisonGroups){   
       Write-Host "Checking" $user.samaccountname "for" "$group"
       if ((Get-ADPrincipalGroupMembership -Identity $user).name -contains $group ){

            Remove-ADGroupMember -identity $Group1 -Confirm: $false -Member $user -AuthType Basic -Credential $AdminCredentials
            Write-Host "$user Removed" $Group1    
            }
            }
}
