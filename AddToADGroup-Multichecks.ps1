<#
    .SYNOPSIS
        script created for automation purposes to add users from a text file to a group of choice. Includes a multiple checks: see if the user is already in the group, creates group if it doesn't already exist, and a check to see if the user doesn't exist or is already in the group. Prints all results to screen.
    .DESCRIPTION
       
    .EXAMPLE
      
        
    .NOTES
        Author: Drew Turner
        Date :Summer 2018
#>

$AdminCredentials = Get-Credential "USERNAME"
$GroupToAdd = 'NAMEOFADGROUP'
$textfile = (Get-Content C:\LOCATION OF TEXT FILE)
#The following is a check on the group. If it doesn't exist, it creates it.
    try{
        $DomainGroupDN = (Get-ADGroup -Identity "$GroupToAdd" -Server DOMAINONE).name
        }
    catch{ 
    
    New-ADGroup -Name "$GroupToAdd" -SamAccountName $GroupToAdd -GroupCategory Security -GroupScope Universal -DisplayName "$GroupToAdd" -Path "OU=OnBase,OU=Special,DC=fs,DC=dew,DC=twu" -Credential $AdminCredentials
    $DomainGroupDN = (Get-ADGroup -Identity "$GroupToAdd" -Server DOMAINONE).name
    Write-Output "$GroupToAdd has been created because it didn't previously exist"
        }
$nfarray = @()

#The following function loops through all usernames in the file, and adds them to the group. Prints a notifcation is user is already in the group, or their username doesn't exist.
function AddUsers{ 
ForEach ($user in $textfile) {

    if ( (Get-ADGroupMember -Identity $DomainGroupDN ).samaccountname -contains "$user" ){
        Write-Output "$user is already a member of $DomainGroupDN"
    }
    else { 

        try {
            Add-ADGroupMember $DomainGroupDN -Server "DOMAINONE" -Member $user -AuthType Basic -Credential $AdminCredentials
            Write-Output "Added FS User: $user to $DomainGroupDN"
        } catch {
            try {
                $userPio = Get-ADUser -Identity "$user" -Server "DOMAINTWO"
                Add-ADGroupMember $DomainGroupDN -Server "DOMAINONE" -Member $userPio -AuthType Basic -Credential $AdminCredentials 
                Write-Output "Added PIO User: $user to $DomainGroupDN"
            } catch {
                $nfarray = $nfarray + $user
            }
        }
    }
}
}

#Get MasterList deletion approval or denial
function MasterListCheck{
    Write-Host "Is this list the master list? Should users not in the list be removed from the group? Y(y) or N(n)"
    Read-Host
}

DO { $masterlistcheck = MasterListCheck } While ([string]::IsNullOrWhiteSpace($masterlistcheck))

if ($masterlistcheck -ieq 'Y'){
ForEach ($user in (Get-ADGroupMember -Identity $DomainGroupDN )){
$username = $user.SamAccountName
    try {        
	Remove-ADGroupMember -identity $DomainGroupDN -Confirm: $false -Member $username -AuthType Basic -Credential $AdminCredentials -ErrorAction Stop
    Write-Host "FS User: $username Removed" 
    }catch {
            $username = (Get-ADUser $username -Server "DOMAINTWO")
            Remove-ADGroupMember -identity $DomainGroupDN -Server "DOMAINONE" -Confirm: $false -Member $username -AuthType Basic -Credential $AdminCredentials
            $usernameSAM = $username.samaccountname
            Write-Host "PIO User: $usernameSAM Removed"
            }
    }
AddUsers

}

if ($masterlistcheck -ieq 'N'){
AddUsers
}

if ($nfarray.Count -gt 0) {
    Write-Output "-- List of users not found. --"
    foreach ($user in $nfarray) {
        Write-Output "$user"
    }
}
