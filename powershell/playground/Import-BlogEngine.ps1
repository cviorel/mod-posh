$DebugPreference=$VerbosePreference="Continue"

$Site = "http://dev.patton-tech.com"
$SitePath = "blog/lists/categories"
Write-Verbose "Pulling in the xml blog posts from the posts directory"
$blogPosts = Get-ChildItem -Path .\posts -Recurse
Write-Verbose "Pulling in the categories xml file."
[xml]$blogCategories = Get-Content -Path .\categories.xml
#
# Get the categories and tags into a PSObject
#
$blogEntries = @()
foreach ($blogPost in $blogPosts)
{
    $Categories = @()
    [xml]$blogEntry = Get-Content -Path $blogPost.FullName
    #
    # Skip empty categories
    #
    if ($blogEntry.post.categories.category -ne $null)
    {
        foreach ($Category in $blogEntry.post.categories.category)
        {
            foreach ($Entry in $blogCategories.categories.category)
            {
                if ($Entry.Id -eq $Category)
                {
                    Write-Verbose "Resolved category GUID to a category name"
                    $ThisCategory = New-Object -TypeName PSObject -Property @{
                        Name = $Entry.InnerText
                        }
                    }
                Write-Verbose "Adding $($ThisCategory.Name) to the Categories object"
                $Categories += $ThisCategory
                }
            }
        }
    #
    # Skip empty tags
    #
    if ($blogEntry.post.tags.tag -ne $null)
    {
        foreach ($category in $blogEntry.post.tags.tag)
        {
            $ThisCategory = New-Object -TypeName PSObject -Property @{
                Name = $Category
                }
            Write-Verbose "Adding $($ThisCategory.Name) tag to the Categories object"
            $Categories += $ThisCategory
            }
        }
    #
    # Remove duplicate categories
    #
    Write-Verbose "Removing duplicate categories and sorting in alphabetic order"
    $Categories = $Categories |Select-Object -Property Name -Unique |Sort-Object -Property Name
    Write-Verbose "Creating an object to hold this post."
    $ThisEntry = New-Object -TypeName PSObject -Property @{
        Title = $blogEntry.post.title
        Content = $blogEntry.post.content
        PubDate = [datetime]$blogEntry.post.pubDate
        Slug = $blogEntry.post.slug
        Categories = $Categories
        }
    Write-Verbose "Storing the blog post into an object"
    $blogEntries += $ThisEntry
    }
#
# Sort posts in ascending order by pubDate
#
Write-Verbose "Sorting blog entires in ascending order by published date"
$blogEntries = $blogEntries |Sort-Object -Property pubDate

#
# Add posts to blog
#
foreach($blogEntry in $blogEntries)
{
    Write-Verbose "Connecting to the sharepoint site"
    $SPWeb = Get-SPWeb -Identity http://dev.patton-tech.com
    Write-Verbose "Connecting to the post list"
    $SPPosts = $SPWeb.GetList("Blog/Lists/Posts/")
    Write-Verbose "Instantiating a new post"
    $SPPost = $SPPosts.AddItem()
    Write-Verbose "Creating a multichoice value field for the categories to be added to"
    $PostCategories = New-Object Microsoft.Sharepoint.SPFieldMultiChoiceValue($null)
    $SPBlogPath = "/Blog/SiteAssets"
    
    #
    # Get a list of available categories
    #
    Write-Verbose "Get a list of categoris from $($Site)/$($SitePath)"
    $SPCategories = Get-SPListIds -Site $Site -SitePath $SitePath
    foreach ($blogCategory in $blogEntry.Categories)
    {
        #
        # If the category isn't on the server add it
        #
        if ($blogCategory.Name)
        {
            if ((Get-SPListItem -Site $Site -SitePath $SitePath -LookupValue $blogCategory.Name) -eq $null)
            {
                Write-Verbose "$($blogCategory.Name) doesn't exist on the server adding it"
                $NewCategoryID = New-SPListItem -Site $Site -SitePath $SitePath -ItemValue $blogCategory.Name
                }
            Write-Verbose "Getting the ID of $($blogCategory.Name)"
            $WorkingCategory = Get-SPListItem -Site $Site -SitePath $SitePath -LookupValue $blogCategory.Name
            $postCategory = New-Object Microsoft.Sharepoint.SPFieldLookupValue($WorkingCategory.ID, $WorkingCategory.Title)
            Write-Verbose "Adding $($WorkingCategory.Title) to the list of post categories"
            $PostCategories.Add($postCategory)
            }
        }
    #
    # Pull the images from each post
    #
    Write-Verbose "Find all the links in the content of the blog"
    $blogLinks = Get-MarkupTag -tag a $blogEntry.Content
    If ($blogLinks -ne $null)
    {
        foreach ($blogLink in $blogLinks)
        {
            if($blogLink.tag.indexof("src") -ne -1)
            {
                Write-Verbose "Found an image link"
                $startHref = $blogLink.tag.indexof("href")
                $endHref = $blogLink.tag.indexof("`"",$startHref+6)
                $url = $blogLink.Tag.Substring($startHref+6,($endHref-$startHref)-6)
                if ($url.IndexOf("media") -ne -1)
                {
                    Write-Verbose "Found an image in the media folder"
                    $startFile = $url.IndexOf("media/")
                    $filename = $url.Substring($startFile+6,($url.Length-$startFile)-6)
                    Write-Verbose "Creating a new url to replace the old link"
                    $NewURL = "$($SPBlogPath)/$($blogEntry.Slug)/$($FileName)"
                    Write-Verbose "Replacing $($url) with $($NewURL)"
                    $blogEntry.Content = $blogEntry.Content.Replace($url, $NewURL)
                    }
                elseif($url.IndexOf("image.axd?picture=") -ne -1)
                {
                    Write-Verbose "Found a blogengine image link"
                    $startFile = $url.IndexOf("image.axd?picture=")
                    $filename = $url.Substring($startFile+18,($url.Length-$startFile)-18)
                    Write-Verbose "Creating a new url to replace the old link"
                    $NewURL = "$($SPBlogPath)/$($blogEntry.Slug)/$($FileName)"
                    Write-Verbose "Replacing $($url) with $($NewURL)"
                    $blogEntry.Content = $blogEntry.Content.Replace($url, $NewURL)
                    }
                elseif ($url.IndexOf("files") -ne -1)
                {
                    Write-Verbose "Found an image in the files directory"
                    $startFile = $url.IndexOf("files/")
                    $filename = $url.Substring($startFile+6,($url.Length-$startFile)-6)
                    Write-Verbose "Creating a new url to replace the old link"
                    $NewURL = "$($SPBlogPath)/$($blogEntry.Slug)/$($FileName)"
                    Write-Verbose "Replacing $($url) with $($NewURL)"
                    $blogEntry.Content = $blogEntry.Content.Replace($url, $NewURL)
                    }
                Write-Verbose "Creating $($blogEntry.Slug) folder to store image"
                New-Item -Name $blogEntry.slug -ItemType Directory -Force
                Write-Verbose "Creating $($blogEntry.Slug) folder on SharePoint"
                New-SPDocLibFolder -Site $Site -SitePath $SPBlogPath -Folder $blogEntry.Slug
                Write-Verbose "Download $($filename) from $($url)"
                Get-Web -url $url -toFile ".\$($blogEntry.slug)\$($filename)"
                Write-Verbose "Convert $($filename) into a System.IO.FileSystemInfo object"
                $FileName = Get-ChildItem ".\$($blogEntry.slug)\$($filename)"
                Write-Verbose "Adding the file to $($SPBlogPath)/$($blogEntry.Slug)"
                Add-SPFileToDocLib -Site $Site -SitePath "$($SPBlogPath)/$($blogEntry.Slug)" -FilePath $FileName
                $startSrc = $blogLink.Tag.indexof("src")
                $endSrc = $blogLink.Tag.indexof("`"",$startSrc+5)
                $url = $blogLink.Tag.Substring($startSrc+5,($endSrc-$startSrc)-5)
                if ($url.IndexOf("media") -ne -1)
                {
                    Write-Verbose "Found an image in the media folder"
                    $startFile = $url.IndexOf("media/")
                    $filename = $url.Substring($startFile+6,($url.Length-$startFile)-6)
                    Write-Verbose "Creating a new url to replace the old link"
                    $NewURL = "$($SPBlogPath)/$($blogEntry.Slug)/$($FileName)"
                    Write-Verbose "Replacing $($url) with $($NewURL)"
                    $blogEntry.Content = $blogEntry.Content.Replace($url, $NewURL)
                    }
                elseif($url.IndexOf("image.axd?picture=") -ne -1)
                {
                    $startFile = $url.IndexOf("image.axd?picture=")
                    $filename = $url.Substring($startFile+18,($url.Length-$startFile)-18)
                    Write-Verbose "Creating a new url to replace the old link"
                    $NewURL = "$($SPBlogPath)/$($blogEntry.Slug)/$($FileName)"
                    Write-Verbose "Replacing $($url) with $($NewURL)"
                    $blogEntry.Content = $blogEntry.Content.Replace($url, $NewURL)
                    }
                Write-Verbose "Creating $($blogEntry.Slug) folder to store image"
                New-Item -Name $blogEntry.slug -ItemType Directory -Force
                Write-Verbose "Creating $($blogEntry.Slug) folder on SharePoint"
                New-SPDocLibFolder -Site $Site -SitePath $SPBlogPath -Folder $blogEntry.Slug
                Write-Verbose "Download $($filename) from $($url)"
                Get-Web -url $url -toFile ".\$($blogEntry.slug)\$($filename)"
                Write-Verbose "Convert $($filename) into a System.IO.FileSystemInfo object"
                $FileName = Get-ChildItem ".\$($blogEntry.slug)\$($filename)"
                Write-Verbose "Adding file to $($SPBlogPath)/$($blogEntry.Slug)"
                Add-SPFileToDocLib -Site $Site -SitePath "$($SPBlogPath)/$($blogEntry.Slug)" -FilePath $FileName
                }
            }
        }
   $SPPost["Title"] = $blogEntry.Title
   $SPPost["Body"] = $blogEntry.Content
   $SPPost["Published"] = $blogEntry.PubDate
   $SPPost["Category"] = $PostCategories
   Write-Verbose "Store today's date for later"
   $CurrentDate = Get-Date
   #
   # Preserve the date the entry was posted to the server
   #
   Write-Verbose "Set the server date to the published date"
   Set-Date -Date $blogEntry.PubDate
   Write-Verbose "Update the post"
   $SPPost.Update()
   #
   # Reset to today's date
   #
   Write-Verbose "Change the date of the server back to today"
   Set-Date -Date $CurrentDate
   Write-Verbose "Closing the Sharepoint object"
   $SPWeb.Close()
    }

$DebugPreference=$VerbosePreference="SilentlyContinue"