# Events from yesterday

# Get firewall logs from yesterday
$fwlogs = Get-FileLogs -LogFile C:\Windows\System32\LogFiles\Firewall\pfirewall.log -LogType wfw
$fwlogs |Where-Object {$_.Date -gt (Get-Date((Get-Date).AddDays(-1)) -Format "yyyy-MM-d") -AND $_.Date -le (Get-Date -Format "yyyy-MM-dd")} |Format-Table

# Get a list of recent logs
$RecentLogs = Get-WinEvent -ListLog * |Where-Object {$_.RecordCount -gt 0 -AND (Get-Date($_.LastWriteTime).Month) -eq (Get-Date).Month}
$Logs = @()

Foreach ($log in $RecentLogs)
{
    
    $evt = Get-WinEvent -LogName $log.LogName |Where-Object {$_.LevelDisplayName -ne "Information" -AND $_.TimeCreated -gt (Get-Date).AddDays(-1).Date -AND $_.TimeCreated -le (Get-Date).Date}
    $evt = $evt |Select-Object -Property Id, ProviderName, LogName, UserID, TimeCreated, LevelDisplayName, TaskDisplayName, Message
    Foreach ($Event in $evt)
    {
        $ThisLog = New-Object -TypeName PSObject -Property @{
                Id = $Event.Id
                ProviderName = $Event.ProviderName
                LogName = $Event.LogName
                UserID = $Event.UserID
                TimeCreated = $Event.TimeCreated
                LevelDisplayName = $Event.LevelDisplayName
                TaskDisplayName = $Event.TaskDisplayName
                Message = $Event.Message
            }
        $Logs += $ThisLog
    }
}
$logs |Format-Table -AutoSize

# Get netstat
$NetStat = Get-NetstatReport
$NetStat |Format-Table -AutoSize

# Get updates
$PendingUpdates = Get-PendingUpdates -ComputerName (& hostname)
$PendingUpdates |Format-Table -Property Title, Description, LastDeploymentChangeTime, SupportUrl, RebootRequired