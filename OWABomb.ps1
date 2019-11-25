function ConnectExchange($exchServer="EXchangeSERVER.domain"){
        Write-Host "++ Connecting to $exchServer"
        try {
            $ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -Name "ExchangeSession" -ConnectionUri http://$exchServer/PowerShell/ -Credential "fs\andrewt"
            Import-PSSession $ExchangeSession
        } catch {
            Write-Host "`nFailed to make a connection to $exchServer`n"
            exit
     }
    }
ConnectExchange
#ConnectToExchange

$PioneerUsers = Get-ADUser -Properties MemberOf -SearchBase "DC=STUDENTS,DC=dew,DC=twu" -Server "STUDENTS.server.domain" -LDAPFilter "(MemberOf=*)"
#Gather Students who are members of anything
$PioCount = 0
$StudentACount = 0
$HadAlreadyBeenDeactivatedCount = 0

foreach ($user in $PioneerUsers){ 
 if ($user.MemberOf -notcontains "CN=Student Assistant Group,OU=Faculty and Staff,DC=fs,DC=dew,DC=twu"){
    #If they are not a member of Student assistant group
    if((Get-CASMailbox -Identity $user.UserPrincipalName -DomainController "Student.domain.controller").OWAEnabled -eq $true) {
       #if they have OWA enabled on mailbox set it to false, write ouput, add to count
    Set-CasMailbox -Identity $user.UserPrincipalName -DomainController "dione.pioneer.dew.twu"  -OwaEnabled $false -PopEnabled $false -ImapEnabled $false
    Write-Host $user.Name"is a not in Student Assistants group, removing their OWA/IMAP/POP access"$user.UserPrincipalName
    $PioCount ++

    }
    if((Get-CASMailbox -Identity $user.UserPrincipalName -DomainController "Student.domain.controller").OWAEnabled -eq $false){
      #if they have OWA disabled already do nothing, but write output, and add to count
    Write-Host $user.Name"is in PIO and not in Student Assistants AD Group, but already has OWA disabled, so nothing is happening" 
    $HadAlreadyBeenDeactivatedCount ++
    }
    if((Get-CASMailbox -Identity $user.UserPrincipalName -DomainController "Student.domain.controller").OWAEnabled -eq $null){
      #if owa flas is set to null do nothing, but write output, and add to count
    Write-Host $user.Name"is in PIO and not in Student Assistants AD Group, but already has OWA disabled, so nothing is happening" 
    $HadAlreadyBeenDeactivatedCount ++
    }
    }
 if ($user.MemberOf -contains "CN=Student Assistant Group,OU=Faculty and Staff,DC=fs,DC=dew,DC=twu"){
    #if user is part of student assistant group, do nothing, but write output, and add to count
    Write-Host $user.Name"is in Student Assistants group, their OWA access was not touched"$user.UserPrincipalName
    $StudentACount++
}
}

#Display results
Write-Host "There are $PioCount users had their OWA access removed just now"
Write-Host "There are $StudentACount users not having their OWA access touched becuase they are in the Student Assistants group"
Write-Host "There are $HadAlreadyBeenDeactivatedCount users who are on PIO, not in Student Assistant Group in AD, but already had their OWA access removed"
