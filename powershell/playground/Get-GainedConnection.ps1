<#
    .SYNOPSIS
        Template script
    .DESCRIPTION
        This script sets up the basic framework that I use for all my scripts.
    .PARAMETER
    .EXAMPLE
    .NOTES
        ScriptName : Get-GainedConnection.ps1
        Created By : jspatton
        Date Coded : 10/27/2011 13:36:09
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
 
        ErrorCodes
            100 = Success
            101 = Error
            102 = Warning
            104 = Information
            
        OS Version Notes
        ----------------
        Windows Server 2003
            EventID = 4201
            LogName = System
        Windows Server 2008
            EventID = 4201
            LogName = System
        Windows Server 2008 R2
            EventID = 10000
            LogName = Microsoft-Windows-NetworkProfile/Operational
        
        Originally script was set to check EventID 11, but it seems that may be a Dell specific
        event code. I was unable to locate a definition of the Event Source l2nd, but all
        references point to Broadcom Network gear in Dell PowerEdge servers. After I realized
        this minor issue, I found the Networkprofile log, and should be able to use it, although
        that log doesn't actually exist in vanilla Windows Server 2008.
    .LINK
        http://scripts.patton-tech.com/wiki/PowerShell/Production/Get-GainedConnection.ps1
#>
Param
    (
        $EventID = 10000,
        $LogPath = 'C:\LogFiles',
        $EventLog = 'Microsoft-Windows-NetworkProfile/Operational'
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
        $OSVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version
        switch {$OSVersion}
        {
            '5.2.3790'
            {
                $EventID = 4202
                $EventLog = 'System'
                }
            '6.0.6002'
            {
                $EventID = 4202
                $EventLog = 'System'
                }
            '6.1.7600'
            {
                $EventID = 10000
                $EventLog = 'Microsoft-Windows-NetworkProfile/Operational'
                }
            Default
            {
                }
        $Events = Get-WinEvent -LogName $EventLog |Where-Object {$_.id -eq $EventID}
        }
Process
    {
        if ($Events.Count -eq $null)
        {
            }
        else
        {
            }
        $FileName = "Online-$((get-date -format "yyyMMdd-hhmmss")).xml"
        }
End
    {
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Messag
        if ((Test-Path -Path $LogPath) -eq $false)
        {
            New-Item $LogPath -ItemType Directory 
            }

        }