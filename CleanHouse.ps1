<#
.Synopsis
    Clean House the script formerly known as SpamRipper
    Simplified Search, Count, and Delete for exchange mailboxes using Search-Mailbox.

    Author: Drew Turner
    Required Dependencies: Exchange Management Tools (Specifically the Get-Mailbox powershell cmdlet.)
    Updated: November 2018

.DESCRIPTION
    This script provides a simplified way to search, count, and remove e-mail from an exchange environment.

.EXAMPLE
    CleanHouse -mailbox username
    Searches specified mailbox for items matching input criteria. 

.EXAMPLE
    CleanHouse.ps1 -all
    Searches all mailboxes in the exchange environment. (Takes some time)

.INPUTS
    -mailbox
        ex: Single mailbox.
            CleanHouse.ps1 -mailbox UserName
            
        ex: Multiple specified mailboxes.
            CleanHouse.ps1 -mailbox UserA,UserB,UserC
    -all  
        ex: All mailboxes.
            CleanHouse.ps1 -all
            
    -deleteforce
        Note: Default behavior is to prompt user to delete findings after running a search.
        ex: Perform delete action without estimating results first.
            CleanHouse.ps1 -mailbox UserName -deleteforce
            
    -estimate
        ex: Override default behavior and run a search without prompting to delete findings. 
            CleanHouse.ps1 -mailbox UserName -estimate

.OUTPUTS
   Outputs mailbox/user name and number of found items matching input criteria. 
   
.NOTES
   Requires administrative/elevated access to an exchange server/environment to execute correctly.
   Logs are automatically created and emailed.

#>

# Paramaters to call from the command line. 
[CmdletBinding(DefaultParameterSetName = "setMailbox" )]
param(
    [Parameter(Mandatory = $true,position=0,ParameterSetName = "setMailbox")][string[]]$mailbox,
    [Parameter(Mandatory = $true,position=0,ParameterSetName = "setAll")][switch]$all,
    [Parameter(Mandatory = $false)][switch]$log,
    [Parameter(Mandatory = $false)][string]$logfile,
    [Parameter(Mandatory = $false)][switch]$deleteforce,
    [Parameter(Mandatory = $false)][switch]$estimate,
    [Parameter(Mandatory = $false)][string]$pull
)

#Globals
$mailboxArray = @() #Array to hold mailbox names to decrease re-processing time for delete.


#Functions:
#Helper function for colored output.
function Write-Color([String[]]$Text, [ConsoleColor[]]$Color, [switch]$nnl) {
    for ($i = 0; $i -lt $Text.Length; $i++) {
        if (-Not $Color[$i]) { $Color = $Color += "White" }
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    if ($nnl -eq $true) { } else { Write-Host }
}

#Helper functions for building the search query. 
function GetSubject{
    Write-Color "(REQUIRED) "," Mail Subject: " -Color Red -nnl
    Read-Host
}

function GetBody{
    Write-Color "----------     Mail Body: " -Color White -nnl
    Read-Host
}

function GetAttachment{
    Write-Color "----------    Attachment: " -Color White -nnl
    Read-Host
}

function GetRecDate{
    Write-Color "(REQUIRED) ","Received Date: " -Color Red,White -nnl
    Read-Host
}

function GetDeleteConfirm{
    Write-Color "Would you like to delete the results from these mailboxes? (Y/N)" -Color Magenta -nnl
    Read-Host
}


#Set delete or estimate flags. 
if ($deleteforce){
    $doprocess = "-deleteforce"
} elseif ($estimate) {
    $doprocess = "-EstimateResultOnly"
} else {
    $doprocess = ""
}

#Build email search query.
DO { $mailsubject = GetSubject } While ([string]::IsNullOrWhiteSpace($mailsubject))
$mailbody =  GetBody
$mailattachment = GetAttachment
DO { $mailrecdate = GetRecDate } While ([string]::IsNullOrWhiteSpace($mailrecdate))

$mailsubjectset = "Subject:`"$mailsubject`""
if($mailbody) { $mailbodyset = "body:`"$mailbody`"," }
if($mailattachment) { $mailattachmentset = "attachment:`"$mailattachment`"," }
$mailrecdateset = "received:`"$mailrecdate`""

## Build command to be run.

if ($all){$mailbox = Get-Mailbox -resultsize unlimited}

ForEach ($box in $mailbox) {
    try { 
       Write-Host $box                     
       $a = Search-Mailbox -Identity "$box" -SearchQuery "$mailsubjectset$mailrecdateset $doprocess" -TargetMailbox "aturner19@twu.edu" -TargetFolder "CleanHouse" -LogLevel Full | Where-Object ResultItemsCount -NE "0" 
       
       if ($a){
        Write-Host $a.Identity,"has"$a.ResultItemsCount"results"
        $mailboxArray = $mailboxArray + "$box"        
        }

        } catch{

        }
}

Write-Host "The following users all have at least one result from your search: $mailboxArray"

if ($doprocess -ne "-deleteforce"){

DO { $deleteconfirm = GetDeleteConfirm } While ([string]::IsNullOrWhiteSpace($deleteconfirm))
 
    if ($deleteconfirm -eq 'Y'){

    ForEach ($box in $mailboxArray){
                Search-Mailbox -Identity "$box" -SearchQuery "$mailsubjectset$mailrecdateset" -TargetMailbox "aturner19@twu.edu" -TargetFolder "CleanHouse" -LogLevel Full -DeleteContent -Force                             
                                   }

                                 }
    else {Write-Host "Mail not deleted"
           }
}
