Write-Verbose "An LDAP Url for where you want to search"
$AdsPath = 'LDAP://OU=1132,OU=Learned,OU=People,DC=soecs,DC=ku,DC=edu'
Write-Verbose "Pull out the root from the path"
$Root = $AdsPath.Substring(($AdsPath.ToLower().IndexOf('dc=')),$AdsPath.Length-($AdsPath.ToLower().IndexOf('dc=')))
Write-Verbose "Cast the modified root, pointing at the Domain Controllers OU to get the first DC listed"
$DC = (([adsi]"LDAP://OU=Domain Controllers,$($Root)").Children |ForEach-Object {$_.Name})[0]
Write-Verbose "Modified DirectoryEntry that contains a newly formated adspath and passes in stored credentials"
$directoryEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($DC)/$($AdsPath.Replace('LDAP://',''))",$Credentials.UserName,$Credentials.GetNetworkCredential().Password)