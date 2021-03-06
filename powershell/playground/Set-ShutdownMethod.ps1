Function Set-ShutdownMethod
{
    <#
        .SYNOPSIS
            Execute the Win32Shutdown method on a remote computer
        .DESCRIPTION
            This function executes the Win32Shutdown method on a remote computer. This
            can be either an IP, NetBIOS name or FQDN. Use the ShutdownMethod param to
            specify the type of shutdown.
        .PARAMETER ComputerName
            The IP, NetBIOS or FQDN of the remote computer.
        .PARAMETER ShutdownMethod
            Win32Shutdown accepts one of the following in32's
                0 = Logoff (Default)
                1 = Shutdown 
                2 = Reboot
                4 = Force Logoff (Doesn't work)
                8 = PowerOff
            
            For more information see the following MSDN article
            http://msdn.microsoft.com/en-us/library/aa376868(VS.85).aspx
        .EXAMPLE
            Set-ShutdownMethod -ComputerName Desktop-pc01
            
            Description
            -----------
            This is the default syntax for this command
        .EXAMPLE
            Set-ShutdownMethod -ComputerName Desktop-pc01 -ShutdownMethod 0
            
            Description
            -----------
            This is the only syntax for this command
        .EXAMPLE
            Get-WmiObject -Class Win32_ServerSession -ComputerName $ComputerName | Set-ShutdownMethod
            
            Description
            -----------
            An example showing how to pipe information into the function.
        .NOTES
        .LINK
    #>
    
    PARAM
    (
    [parameter(Mandatory=$True,ValueFromPipeline=$True)]
    [string]$ComputerName,
    $Credentials = (Get-Credential),
    [int32]$ShutdownMethod = 0
    )
    
    Begin
    {
    }
    
    Process
    {
        Try
        {
            $ReturnValue = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -Credential $Credentials).InvokeMethod("Win32Shutdown",0)
            }
        Catch
        {
            $ReturnValue = $Error[0]
            }
        }
    
    End
    {
        if ($ReturnValue -ne 0)
        {
            Return "An error occurred, most likely there is nobody logged into $($ComputerName)"
            }
        else
        {
            Return "Success"
            }
        }
}