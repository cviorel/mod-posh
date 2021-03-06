<#
    .SYNOPSIS
        Returns the output of netstat -anop TCP|UDP
    .DESCRIPTION
        Returns the output of netstat -anop TCP|UDP in a format that can be processed by the built-in
            PowerShell commands.
    .EXAMPLE
            .\Get-NetstatReport.ps1 |Format-Table

            PID       ProcessNa LocalAddr State     User      ProcessPa RemoteAdd LocalPort Protocol  RemotePor
                        me        ess                           th        ress                          t
            ---       --------- --------- -----     ----      --------- --------- --------- --------  ---------
            792       svchost   0.0.0.0   LISTENING                     0.0.0.0   135       TCP       0
            4         System    0.0.0.0   LISTENING                     0.0.0.0   445       TCP       0
            2324      vmware... 0.0.0.0   LISTENING                     0.0.0.0   912       TCP       0
            2992      svchost   0.0.0.0   LISTENING                     0.0.0.0   990       TCP       0
            468       wininit   0.0.0.0   LISTENING                     0.0.0.0   1025      TCP       0
            976       svchost   0.0.0.0   LISTENING                     0.0.0.0   1026      TCP       0

            Description
            -----------
            Sample output of the function after being piped into Format-Table

    .NOTES
        ScriptName : Get-NetstatReport.ps1
        Created By : jspatton
        Date Coded : 04/24/2012 16:06:25
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
 
        ErrorCodes
            100 = Success
            101 = Error
            102 = Warning
            104 = Information

        Functionized the get-netstat code found on http://poshcode.org/get/592. The version on poshcode 
        objectified each line and returned that line. This version creates an object above the for and adds the 
        noteproperties inside the loop.

        Copied over from my net stat function.
    .LINK
        https://code.google.com/p/mod-posh/wiki/Production/Get-NetstatReport.ps1
#>
[CmdletBinding()]
Param
    (
 
    )
Begin
    {
        $ScriptName = $MyInvocation.MyCommand.ToString()
        $LogName = "Application"
        $ScriptPath = $MyInvocation.MyCommand.Path
        $Username = $env:USERDOMAIN + "\" + $env:USERNAME
 
        New-EventLog -Source $ScriptName -LogName $LogName -ErrorAction SilentlyContinue
 
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message
 
        #	Dotsource in the functions you need.
        $netstat = netstat -a -n -o | where-object { $_ -match "(UDP|TCP)" }
        [regex]$regexTCP = '(?<Protocol>\S+)\s+((?<LAddress>(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?))|(?<LAddress>\[?[0-9a-fA-f]{0,4}(\:([0-9a-fA-f]{0,4})){1,7}\%?\d?\]))\:(?<Lport>\d+)\s+((?<Raddress>(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?))|(?<RAddress>\[?[0-9a-fA-f]{0,4}(\:([0-9a-fA-f]{0,4})){1,7}\%?\d?\]))\:(?<RPort>\d+)\s+(?<State>\w+)\s+(?<PID>\d+$)'

        [regex]$regexUDP = '(?<Protocol>\S+)\s+((?<LAddress>(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?)\.(2[0-4]\d|25[0-5]|[01]?\d\d?))|(?<LAddress>\[?[0-9a-fA-f]{0,4}(\:([0-9a-fA-f]{0,4})){1,7}\%?\d?\]))\:(?<Lport>\d+)\s+(?<RAddress>\*)\:(?<RPort>\*)\s+(?<PID>\d+)'
        $Report = @()
        }
Process
    {
        foreach ($Line in $Netstat)
        {
            switch -regex ($Line.Trim())
            {
                $RegexTCP
                {
                    $MyProtocol = $Matches.Protocol
                    $MyLocalAddress = $Matches.LAddress
                    $MyLocalPort = $Matches.LPort
                    $MyRemoteAddress = $Matches.Raddress
                    $MyRemotePort = $Matches.RPort
                    $MyState = $Matches.State
                    $MyPID = $Matches.PID
                    $MyProcessName = (Get-Process -Id $Matches.PID -ErrorAction SilentlyContinue).ProcessName
                    $MyProcessPath = (Get-Process -Id $Matches.PID -ErrorAction SilentlyContinue).Path
                    $MyUser = (Get-WmiObject -Class Win32_Process -Filter ("ProcessId = "+$Matches.PID)).GetOwner().User
                    }
                $RegexUDP
                {
                    $MyProtocol = $Matches.Protocol
                    $MyLocalAddress = $Matches.LAddress
                    $MyLocalPort = $Matches.LPort
                    $MyRemoteAddress = $Matches.Raddress
                    $MyRemotePort = $Matches.RPort
                    $MyState = $Matches.State
                    $MyPID = $Matches.PID
                    $MyProcessName = (Get-Process -Id $Matches.PID -ErrorAction SilentlyContinue).ProcessName
                    $MyProcessPath = (Get-Process -Id $Matches.PID -ErrorAction SilentlyContinue).Path
                    $MyUser = (Get-WmiObject -Class Win32_Process -Filter ("ProcessId = "+$Matches.PID)).GetOwner().User
                    }
                }
            $LineItem = New-Object -TypeName PSobject -Property @{
                Protocol = $MyProtocol
                LocalAddress = $MyLocalAddress
                LocalPort = $MyLocalPort
                RemoteAddress = $MyRemoteAddress
                RemotePort = $MyRemotePort
                State = $MyState
                PID = $MyPID
                ProcessName = $MyProcessName
                ProcessPath = $MyProcessPath
                User = $MyUser
                }
            $Report += $LineItem
            }
        }
End
    {
        Return $Report
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message	
        }