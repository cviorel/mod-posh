$LogName = "Microsoft-Windows-WLAN-AutoConfig/Operational"
$ComputerName = (& hostname)

#$Log = Get-WinEvent -LogName $LogName -ComputerName $ComputerName -Credential $Credentials `
$Log = Get-WinEvent -LogName $LogName -ComputerName $ComputerName `
        |Where-Object {$_.LevelDisplayName -ne "Information" `
        -AND $_.TimeCreated -gt (Get-Date).AddDays(-1).Date -AND $_.TimeCreated -le (Get-Date).Date}

#$Log = $Log |Select-Object -Property Id, ProviderName, LogName, ProcessID, ThreadID, UserID, TimeCreated, LevelDisplayName, TaskDisplayName, Message
$Log = $Log |Select-Object -Property Id, ProviderName, LogName, UserID, TimeCreated, LevelDisplayName, TaskDisplayName, Message

$Excel = New-Object -comobject Excel.Application
$Book = $Excel.Workbooks.Add()
$Sheet1 = $Excel.Worksheets.Item(1)

$col = 1
foreach ($Property in ($Log |Get-Member -MemberType NoteProperty))
    {
        $Sheet1.cells.item(1,$col) = $Property.Name
        $Prop += @($Item.Name)
        $col++
        }

Remove-Variable col

foreach ($entry in ($Log |Get-Member -MemberType NoteProperty)){$VarType += @($entry.definition.remove($entry.definition.indexof(" ")))}
Remove-Variable Entry

$row = 2
foreach($entry in $log)
    { # Need to define $col and increment it
        switch ($VarType[($col)-1])
            {
                System.Int32
                    {
                        $Sheet1.cells.item($row,$col) = [int]$Entry.($Prop[$Col])
                        }
                System.String
                    {
                        $Sheet1.cells.item($row,$col) = [string]$Entry.($Prop[$Col])
                        }
                System.DateTime
                    {
                        $Sheet1.cells.item($row,$col) = [datetime]$Entry.($Prop[$Col])
                        }
                System.Security.Principal.SecurityIdentifier
                    {
                        $Sheet1.cells.item($row,$col) = [string]$Entry.($Prop[$Col])
                        }
                    }        
        $row++
        }

$Sheet1.Name = ("DC - "+$entry.LogName.Replace("/","|")).Remove(30)
$Excel.Visible = $True