function Convert-SIDToUser($ObjectSID) {
    return $ObjectSID.Translate([System.Security.Principal.NTAccount])
}

function Convert-ObjectSID($ObjectSID) {
	$sid = New-Object System.Security.Principal.SecurityIdentifier($ObjectSID)
	return 	$sid
}

function Get-GroupMembers([ADSI]$group) {
	$from = 0
	$script:all = $false;
	$members = @()
	while (! $all) { 
		trap [Exception] {
			$script:all = $True;
			continue
		}
		$to = $from + 999
		$DS = New-Object DirectoryServices.DirectorySearcher($group,"(objectClass=*)","member;range=$from-$to",'Base')
		$members += $ds.findall() | foreach {$_.properties | foreach {$_.item($_.PropertyNames -like 'member;*')}}
		$from += 1000
	}
	return $members
}

Function Get-UsersToMigrate
{
    <#
        .SYNOPSIS
            Return a collection of user objects for migration
        .DESCRIPTION
            This function returns a list of user objects that are passed to a seperate function to aid in the migration
            of users from a monolithic user drive, to a distributed collection of user drives.
        .PARAMETER ADSPath
            The LDAP URL that contains the group of user accounts to migrate
        .PARAMETER RemoteDomain
            The domain where the user objects actually live, this is used as a property that will be accessed later to set
            permissions.
        .PARAMETER LocalDomain
            The local domain of any user objects that might exist in the migration group. This is used as a property that 
            will be accessed later to set permissions.
        .EXAMPLE
            Get-UsersToMigrate

            Domain UserName         DistinguishedName                                                                                  
            ------ --------         -----------------                                                                                  
            SOECS  schricks.admin   CN=Steve Schrick,CN=Users,DC=soecs,DC=ku,DC=edu                                                    
            HOME   schricks         CN=S-1-5-21-57989841-1078081533-682003330-27373,CN=ForeignSecurityPrincipals,DC=soecs,DC=ku,DC=edu 
            HOME   mriggs           CN=S-1-5-21-57989841-1078081533-682003330-157560,CN=ForeignSecurityPrincipals,DC=soecs,DC=ku,DC=edu
            SOECS  mat.admin        CN=Matt Riggs,CN=Users,DC=soecs,DC=ku,DC=edu                                                       
            ...

            Description
            -----------
            This example shows using the default parameters, which is our normal use case.
        .EXAMPLE
            Get-UsersToMigrate -ADSPath "LDAP://CN=UndergraduateStaffProfessionals,OU=Undergraduate,OU=Security Groups,DC=soecs,DC=ku,DC=edu"

            Domain UserName    DistinguishedName                                                                                  
            ------ --------    -----------------                                                                                  
            HOME   c881a797    CN=S-1-5-21-57989841-1078081533-682003330-180943,CN=ForeignSecurityPrincipals,DC=soecs,DC=ku,DC=edu
            HOME   a574f243    CN=S-1-5-21-57989841-1078081533-682003330-183327,CN=ForeignSecurityPrincipals,DC=soecs,DC=ku,DC=edu
            HOME   jayjack     CN=S-1-5-21-57989841-1078081533-682003330-131039,CN=ForeignSecurityPrincipals,DC=soecs,DC=ku,DC=edu
            HOME   ctalley     CN=S-1-5-21-57989841-1078081533-682003330-159010,CN=ForeignSecurityPrincipals,DC=soecs,DC=ku,DC=edu

            Description
            -----------
            This example shows the output from passing an alternate LDAP URl.
        .NOTES
            This function assumes that C:\Users\jspatton\My Repositories\KU\PowerShell\Private\lib\adutillib.ps1 is
            dot-sourced in, as it relies on two functions Convert-ObjectSID and Convert-SIDToUser
        .LINK
            Convert-ObjectSID
        .LINK
            Convert-SIDToUser
        .LINK
            http://trac.soecs.ku.edu/powershell/browser/Private/lib/MigrationFunctions.ps1
    #>
    Param
        (
            #$ADSPath = "LDAP://CN=ECSStaffProfessionals,OU=ECS,OU=Security Groups,DC=soecs,DC=ku,DC=edu",
            $ADSPath = "LDAP://CN=PGFSAECarStudents,OU=FSAE,OU=Project Groups,OU=Security Groups,DC=soecs,DC=ku,DC=edu",
            $RemoteDomain = "HOME",
            $LocalDomain = "SOECS"
        )

    Begin
        {
            #$ds = New-Object DirectoryServices.DirectorySearcher($ADSPath, "(objectClass=*)", "member", "Base")
            #$ds.PageSize = 1000
            $members = Get-GroupMembers -group $ADSPath
        }

    Process
        {
            $UserAccounts = @()

            foreach ($user in $members)
            {
                If ($user.Contains("S-1-5-21") -eq $false)
                {
                    [ADSI]$user = "LDAP://" + $user
                    $ThisUser = New-Object -TypeName PSObject -Property @{
                        UserName = ($user.sAMAccountName).ToString()
                        Domain = $LocalDomain
                        DistinguishedName = $user.distinguishedName.ToString()
                        }
                    $UserAccounts += $ThisUser
                }
                Else
                {
                    $Sid = $user.Substring(3,($user.IndexOf(",")-3))
                    $ThisUser = New-Object -TypeName PSObject -Property @{
                        UserName = ((Convert-SIDToUser -ObjectSID (Convert-ObjectSID -ObjectSID $Sid)).Value).Replace($RemoteDomain +"\", $null)
                        Domain = $RemoteDomain
                        DistinguishedName = $user
                        }
                    $UserAccounts += $ThisUser
                }
            }
        }

    End
        {
            Return $UserAccounts
        }
}