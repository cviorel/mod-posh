Function Update-Repo
{
    <#
        .SYNOPSIS
            Update your repository
        .DESCRIPTION
            This function will update your working directory to the latest HEAD version of your repo.
        .PARAMETER WorkingPath
            The default is to use the current working directory, but you can specify an alternate
            location on the command-line
        .EXAMPLE
            Update-Repo
            At revision 378.
            True

            Description
            -----------
            This shows the basic usage with the default value for $WorkingPath
        .EXAMPLE
            Update-Repo -WorkingPath'C:\Users\Jeff Patton\My Repositories\scripts'
            At revision 378.
            True

            Description
            -----------
            This shows passing an alternate directory into the function.
        .NOTES
            This function checks to see what the value of $SubversionClient is before executing
            the update.
            Define $SubversionClient in your $profile, the two possible values I check are:
                svn, tortoise
        .LINK
    #>
    
    Param
    (
    [string]$WorkingPath = (Get-Location).Path
    )
    
    Begin
    {
        $TSvnCommand = "TortoiseProc.exe /command:update /path:`"$($WorkingPath)`""
        $SvnCommand = "svn update `"$($WorkingPath)`""
        }

    Process
    {
        Switch ($SubversionClient)
            {
                svn
                    {
                        Invoke-Expression $SvnCommand
                        }
                tortoise
                    {
                        Invoke-Expression $TSvnCommand
                        }
                }
        }

    End
    {
        Return $?
        }
}

Function New-Repo
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
        .LINK
    #>
    
    Param
    (
    )
    
    Begin
    {
        
        }

    Process
    {
        
        }

    End
    {
        
        }
}

Function Add-RepoItem
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
        .LINK
    #>
    
    Param
    (
    )
    
    Begin
    {
        
        }

    Process
    {
        
        }

    End
    {
        
        }
}

Function Set-RepoProps
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
        .LINK
    #>
    
    Param
    (
    )
    
    Begin
    {
        
        }

    Process
    {
        
        }

    End
    {
        
        }
}

Function New-RepoRevision
{
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
        .LINK
    #>
    
    Param
    (
    )
    
    Begin
    {
        
        }

    Process
    {
        
        }

    End
    {
        
        }
}