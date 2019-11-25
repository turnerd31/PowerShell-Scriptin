function Write-Color([String[]]$Text, [ConsoleColor[]]$Color, [switch]$nnl) {
    for ($i = 0; $i -lt $Text.Length; $i++) {
        if (-Not $Color[$i]) { $Color = $Color += "White" }
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    if ($nnl -eq $true) { } else { Write-Host }
}

function callDBATools($userName, $newName, $displayName, $mode='test') {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if($userName -eq '' -or $newName -eq '' -or $displayName -eq '') { exit }

    $Parameters = @{
        #Default param
        inst = "all"
        #detail or yn
        opt = "detail"
        #Current User Name
        pname = "$userName"
        #New User Name
        newname = "$newName"
        #First and Last name
        desc = "$displayName"
        #test or doit
        mode = "$mode"
    }

    Write-Host "Using the $mode mode to rename $userName to $newName with a Display Name of $displayName"

    #$response = (Invoke-WebRequest -Uri 'dbatools.cgi' -Body $Parameters -Method Get).Content
    $response = (Invoke-WebRequest -Uri "dbatools.cgiwebcall" -Method Get).Content
    return $response
}

function FindNextName ($baseName) {
    $userArray = @()
    $regex1 = $baseName + "*"
    $regex2 = "^" + $baseName + "($|\d)"
    $userArray += Get-ADUser -Server domain.controller-Filter {samAccountName -like $regex1} | select samAccountName
    $userArray += Get-ADUser -Server domain.controller -Filter {samAccountName -like $regex1} | select samAccountName
    $userArray = $userArray | ? {$_.samaccountname -match $regex2} | select samAccountName

    if (@($userArray).Count -eq 0) {
        return "$baseName"
    }

    [int[]]$numArray = @()
    foreach ($sAName in $userArray) {
	    $numArray += $($sAName.samAccountName -Split "$baseName")[1]
    }

    $nextNum = $($numArray | sort)[-1]+1
    return "$baseName" + "$nextNum"

}
#FindNextName -baseName "KROMAN"
function GetCurrentUsername {
    Write-Color "Enter the user's current username: " -Color Cyan -nnl
    Read-Host
}

function GetSamaccountname {
    Write-Color "Enter the user's desired username !WARNING! Do not include number or digits: " -Color Cyan -nnl
    Read-Host
}

function GetLastName {
    Write-Color "Enter the user's desired Last Name (Might be the same as their current last name): " -Color Cyan -nnl
    Read-Host
}

function GetFirstName {
    Write-Color "Enter the user's desired First Name (Might be the same as their current first name): " -Color Cyan -nnl
    Read-Host
}

function FindUsersDomain{    
     try{Get-ADUser $currentUsername -Properties CanonicalName | Select @{N='Domain';E={($_.CanonicalName -split '/')[0]}}
     }
     catch{Get-ADUser -Server "domain.controller" $currentUsername -Properties CanonicalName | Select @{N='Domain';E={($_.CanonicalName -split '/')[0]}}
     }
}

function ExchangeNameChange($Samaccountname,$NewUserName,$UserPrincipalName,$DisplayName,$UsersDomain){

    function DisconnectExchange(){
    Remove-PSSession -Name ExchangeSession
                                    } 
  
if ($usersdomain -match 'Domain=domain'){
#Connect to Exch
    function ConnectExchange($exchServer="exchange.domain.server"){
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

Set-Mailbox -Identity $Samaccountname -SamAccountName $NewUserName -Alias $NewUserName -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -PrimarySmtpAddress $UserPrincipalName -WindowsEmailAddress $UserPrincipalName -Name $DisplayName -EmailAddressPolicyEnabled $false

Write-Host "Success! The relevant properties for the mailbox formerly known as $Samaccountname have been changed, this should be the last name in the Name Change process, well done!"

#Send informative email to TLT

Send-MailMessage -From 'email@security' -To 'tlt@email.com' -Subject 'User Name Change' -Body "User $DisplayName with the username $Samaccountname has been changed to $NewUserName " -SmtpServer 'smtp.server.edu'

DisconnectExchange       

}

if ($usersdomain -match 'Domain=domain.controller'){

 function ConnectExchange($exchServer="exchange.domain.server"){
        Write-Host "++ Connecting to $exchServer"
        try {
            $ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -Name "ExchangeSession" -ConnectionUri http://$exchServer/PowerShell/ -Credential "pioneer\andrewt"
            Import-PSSession $ExchangeSession
        } catch {
            Write-Host "`nFailed to make a connection to $exchServer`n"
            exit
     }
    }

ConnectExchange

Set-Mailbox -Identity $Samaccountname -SamAccountName $NewUserName -Alias $NewUserName -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -PrimarySmtpAddress $UserPrincipalName -WindowsEmailAddress $UserPrincipalName -Name $DisplayName -EmailAddressPolicyEnabled $false

Write-Host "Success! The relevant properties for the mailbox formerly known as $Samaccountname have been changed, this should be the last name in the Name Change process, well done!"

#Send informative email to TLT

Send-MailMessage -From 'infosec@email.com' -To 'tlt@email.com' -Subject 'User Name Change' -Body "User $DisplayName with the username $Samaccountname has been changed to $NewUserName " -SmtpServer 'smtp@email.com'

DisconnectExchange 

}

}

$currentUsername = GetCurrentUsername

try{
    $current_DistinguishedName = Get-ADUser -Server domain.controller $currentUsername -Properties DistinguishedName

}catch{
    try{
        $current_DistinguishedName = Get-ADUser -Server domain.controller $currentUsername -Properties DistinguishedName
    }catch{ 
        Write-Color "!!! Exception !!! That current user was not found in FS or Pioneer" -Color Red
        exit
    }
}

function usercheck{
    Write-Color "Is the current username the same as the desired username? Y(y) or N(n)" -Color Cyan -nnl
    Read-Host
}

DO { $usercheck = usercheck } While ([string]::IsNullOrWhiteSpace($usercheck))

#Takes all of the input parameters and sets them, ignoring Samaccount/username since it is hasn't changed

if ($usercheck -ieq 'Y'){
    $Samaccountname = $currentUsername
    $UsersDomain = FindUsersDomain
    $FirstName = GetFirstName
    $LastName = GetLastName
    $DisplayName = $FirstName+' '+$LastName
    $UserPrincipalName = $Samaccountname+"@email.edu"

    #Strip samAccountName update from this section
    if ($UsersDomain -match 'Domain=domain.edu'){
        Set-ADUser -Server "domain.controller" -Identity $current_DistinguishedName <#>-UserPrincipalName $UserPrincipalName</#> -DisplayName $DisplayName -GivenName $FirstName -Surname $LastName <#>-SamAccountName $Samaccountname</#> -PassThru | Rename-ADObject -NewName $DisplayName -PassThru 
    }if($UsersDomain -match 'Domain=domain.controller'){
        Set-ADUser -Server "domain.controller" -Identity $current_DistinguishedName <#>-UserPrincipalName $UserPrincipalName</#> -DisplayName $DisplayName -GivenName $FirstName -Surname $LastName <#>-SamAccountName $Samaccountname</#> -PassThru | Rename-ADObject -NewName $DisplayName -PassThru     
    }  
    Write-Color -Color Yellow "Sucess on the AD end. $FirstName's information has been changed! First Name:$FirstName Last Name:$LastName Display Name:$DisplayName"
    Write-Color -Color Yellow "Attempting to call DBA Tools with new information...running on test mode"

    callDBATools -userName "$Samaccountname" -newName "$Samaccountname" -displayName "$FirstName+$LastName" -mode "test"
    $dbaToolsRunConfirm = Read-Host -Prompt (Write-Color -Color Magenta "Do the results look good? Do you want to actually run it for real? Y(y) or N(n)")
    if ($dbaToolsRunConfirm -ieq "y"){
    Write-Color -Color Yellow "Attempting to call DBA Tools with new information...running on commit mode this time"
    callDBATools -userName "$Samaccountname" -newName "$Samaccountname" -displayName "$FirstName+$LastName" -mode "doit"

                                     } else{Write-Color -color Red "!!!ABORTING!!!" 
                                            exit}

ExchangeNameChange -Samaccountname $Samaccountname -NewUserName $Samaccountname -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -UsersDomain $UsersDomain

}

#Finds new Username and sets new the parameters for user in AD

if ($usercheck -ieq 'N'){
    $Samaccountname = GetSamaccountname
    $UsersDomain = FindUsersDomain
    Write-Color -Color Yellow "User is in $UsersDomain"
    if ($Samaccountname -match ".*\d+.*"){ 
        Write-Color "!!! Error desired username is not allowed to contain numbers/digits !!!" -Color Red
        exit
    }
    $NewUserName = FindNextName -baseName $Samaccountname
    $FirstName = GetFirstName
    $LastName = GetLastName
    $DisplayName = $FirstName+' '+$LastName
    $UserPrincipalName = $NewUserName+"@email.edu"
    $fixfiltervariable = "*$currentUsername*"
    
    Write-Color -Color Yellow "Attempting to change user's information. New username will be $NewUserName"

    if ($UsersDomain -match 'Domain=domain.edu'){
        Set-ADUser -Server "domain.controller" -Identity $current_DistinguishedName -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -GivenName $FirstName -Surname $LastName -SamAccountName $NewUserName -PassThru | Rename-ADObject -NewName $DisplayName -PassThru 
    }if($UsersDomain -match 'Domain=domain.controller'){
        Set-ADUser -Server "domain.controller" -Identity $current_DistinguishedName -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -GivenName $FirstName -Surname $LastName -SamAccountName $NewUserName -PassThru | Rename-ADObject -NewName $DisplayName -PassThru     
    }
    Write-Color -Color Green "Sucess on the AD end.$NewUserName's information has changed! Old User Name:$currentUsername New User Name: $NewUserName First Name: $FirstName Last Name: $LastName Display Name: $DisplayName User Principal Name: $UserPrincipalName"
    Write-Color -Color Magenta "Attempting to call DBA Tools with new information...running on test mode"
    
    callDBATools -userName "$currentUsername" -newName "$NewUserName" -displayName "$FirstName+$LastName" -mode "test"
    
    $dbaToolsRunConfirm = Read-Host -Prompt (Write-Color -Color Magenta "Do the results look good? Do you want to actually run it for real? Y(y) or N(n)")

    if ($dbaToolsRunConfirm -ieq "y"){
    Write-Color -Color Magenta "Attempting to call DBA Tools with new information...running on commit mode this time"
    callDBATools -userName "$currentUsername" -newName "$NewUserName" -displayName "$FirstName+$LastName" -mode "doit"

                                     } else{Write-Color -color Red "!!!ABORTING!!!" 
                                            exit}

ExchangeNameChange -Samaccountname $currentUsername -NewUserName $NewUserName -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -UsersDomain $UsersDomain

#Rename GAPPS Contact Card in AD
if ($UsersDomain -match 'Domain=domain.edu'){
Write-Color -Color Yellow "Renaming GAPPS Contact Card in AD......" 
Get-ADObject -Server "domain.controller" -Filter {(objectClass -eq "contact") -and (cn -like $fixfiltervariable)} -Properties * | Set-ADObject -Replace @{givenName=$FirstName;sn=$LastName;DisplayName="$LastName, $FirstName";CN="$NewUserName@googlecontact"}
Write-Color -Color Yellow "DONE"}if($UsersDomain -match 'Domain=domain.controller){
Get-ADObject -Server "domain.controller" -Filter {(objectClass -eq "contact") -and (cn -like $fixfiltervariable)} -Properties * | Set-ADObject -Replace @{givenName=$FirstName;sn=$LastName;DisplayName="$LastName, $FirstName";CN="$NewUserName@googlecontact"}
}
}  
             


#Set-ADUser -Server "domain.controller" -Identity (Get-ADUser $Samaccountname -Properties DistinguishedName) -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -GivenName $FirstName -Surname $LastName -SamAccountName "sectest223" -PassThru | Rename-ADObject -NewName $DisplayName -PassThru
