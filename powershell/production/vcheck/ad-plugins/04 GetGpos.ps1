$Title = "Active Directory: GPOs"
$Header ="Group Policy Objects"
$Comments = "Get a listing of Group Policy Objects"
$Display = "List"
$Author = "Jeff Patton"
$PluginVersion = 1
$PluginCategory = "AD"

$GPOs = Get-GPO 
$UnlinkedGPOs = Get-UnlinkedGPO

$Report = New-Object -TypeName PSObject -Property @{
    "Total GPO's" = $GPOs.Count
    "Total Unlinked GPO's" = $UnlinkedGPOs.Count
    }

$Report