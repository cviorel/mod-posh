<#
    .SYNOPSIS
        Remove the driver files from the spool drivers directory
    .DESCRIPTION
        This script stops the spooler service and then removes all files within the
        C:\Windows\System32\Spool\Drivers\W32X86 directory. It then starts the spool
        service and reboots the computer.
    .PARAMETER ComputerName
        The name of the computer process
    .PARAMETER DriverPath
        The path to where Windows stores driver files
        for printers, the default is the Windows default location.
    .EXAMPLE
        .\Remove-PrintDrivers.ps1 -ComputerName Desktop-PC01
        
        Description
        -----------
        This is the default syntax of the command
    .NOTES
        ScriptName : Remove-PrintDrivers.ps1
        Created By : jspatton
        Date Coded : 01/03/2012 15:17:40
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
 
        ErrorCodes
            100 = Success
            101 = Error
            102 = Warning
            104 = Information
    .LINK
        http://scripts.patton-tech.com/wiki/PowerShell/Production/Remove-PrintDrivers.ps1
#>
[cmdletbinding()]
Param
    (
    [Parameter(ValueFromPipeline=$true)]
    [string]$ComputerName = (&hostname),
    [string]$DriverPath = 'C:\Windows\System32\spool\drivers\w32x86'
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
        }
Process
    {
        foreach ($Workstation in $ComputerName)
        {
            try
            {
                Write-Verbose "Stop Spooler service"
                $Retval = (Get-WmiObject -ComputerName $Workstation -ErrorAction Stop -Class Win32_Service `
                    -Filter "Name='Spooler'").InvokeMethod("StopService",$null)
                if ($RetVal -eq 0)
                {
                    Write-Verbose "Spooler service Stopped"
                    }
                }
            catch
            {
                $Message = $Error[0].Exception
                Write-Verbose $Message
                Write-EventLog -LogName $LogName -Source $ScriptName -EventID "101" -EntryType "Error" -Message $Message
                }
            Write-Verbose "Delete all files and folders inside $($DriverPath)"
            if ($Workstation -eq (&hostname))
            {
                $FolderContents = Get-ChildItem $DriverPath
                }
            else
            {
                $FolderContents = Get-ChildItem "\\$($Workstation)\$($DriverPath.Replace(":","$"))"
                }
            foreach ($Item in $FolderContents)
            {
                if ($Item.PSIsContainer -eq $false)
                {
                    Remove-Item $Item.FullName -Force
                    }
                else
                {
                    Remove-Item $Item.FullName -Force -Recurse
                    }
                }
            try
            {
                Write-Verbose "Start Spooler service"
                $Retval = (Get-WmiObject -ComputerName $Workstation -ErrorAction Stop -Class Win32_Service `
                    -Filter "Name='Spooler'").InvokeMethod("StartService",$null)
                if ($RetVal -eq 0)
                {
                    Write-Verbose "Spooler service Started"
                    }
                }
            catch
            {
                $Message = $Error[0].Exception
                Write-Verbose $Message
                Write-EventLog -LogName $LogName -Source $ScriptName -EventID "101" -EntryType "Error" -Message $Message
                }
            try
            {
                Write-Verbose "Reboot $($Workstation)"
                $Retval = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Workstation -ErrorAction Stop).InvokeMethod("Win32Shutdown",0)
                }
            catch
            {
                $Message = $Error[0].Exception
                Write-Verbose $Message
                Write-EventLog -LogName $LogName -Source $ScriptName -EventID "101" -EntryType "Error" -Message $Message
                }
            }
        }
End
    {
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message	
        }
