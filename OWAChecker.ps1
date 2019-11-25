function ConnectExchange($exchServer="EXCHANGESERVER.DOMAIN"){
        Write-Host "++ Connecting to $exchServer"
        try {
            $ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -Name "ExchangeSession" -ConnectionUri http://$exchServer/PowerShell/ -Credential "fs\andrewt"
            Import-PSSession $ExchangeSession
        } catch {
            Write-Host "`nFailed to make a connection to $exchServer`n"
            exit
     }
    }
#ConnectToExchange

$PioMailboxes = Get-CASMailbox -Identity * -DomainController "STUDENTEXCHANGE.DOMAINADRESS"  -ResultSize unlimited 

$EnabledCount = 0
$NotEnabledCount = 0

foreach ($mailbox in $PioMailboxes){
    if ($mailbox.OWAEnabled -eq $true){
        Write-Host $mailbox.Name"is OWA Enabled"
        $EnabledCount ++
        }
    if ($mailbox.OWAEnabled -eq $false){
        Write-Host $mailbox.Name"is not OWA Enabled"
        $NotEnabledCount ++

    if ($mailbox.OWAEnabled -eq $null){
        Write-Host $mailbox.Name"is not OWA Enabled"
        $NotEnabledCount ++
    }
    }
    }

Write-Host $EnabledCount ":number of users who are currently OWA Enabled"
Write-Host $NotEnabledCount ":number of users who are not currently OWA Enabled"
