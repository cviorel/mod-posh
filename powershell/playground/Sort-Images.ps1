#
# condensing into a script
# checked out photo repo to c:\projects\photos
# repo is c:\repos\photos
#
# working with existing images.ps1 and code from http://nicholasarmstrong.com/2010/02/exif-quick-reference/
#
# Things I need in my object
# FileName
# FilePath
# TagType (IDF|EXIF)
# TagValue
#

. .\EXIFFunctions.ps1

[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") > $null
[System.Reflection.Assembly]::LoadWithPartialName("System.Text") > $null

$photos = Get-ChildItem -Path 'C:\Users\Jeff Patton\Pictures\2011-06-25' -Filter *.jpg -Recurse

$Rows = @()
foreach ($photo in $photos)
{
    $Row = New-Object -TypeName PSObject -Property @{
        File = $photo.FullName
        Hash = Get-BitmapHash -FileName $photo.FullName
        }
    $Rows += $Row
    }

$Rows = $Rows |Sort-Object -Property Hash -Unique
$Images = @()
foreach ($photo in $Rows)
{
    [System.Reflection.Assembly]::LoadWithPartialName("PresentationCore") > $null

    $filename = $photo.file
    $ImageFileName = ([System.IO.FileInfo]$filename).Name
    $ImageDirectoryName = ([System.IO.FileInfo]$filename).DirectoryName
    $ImageHash = $photo.Hash

    $stream = new-object System.IO.FileStream($filename, [System.IO.FileMode]::Open)
    $decoder = new-object System.Windows.Media.Imaging.JpegBitmapDecoder($stream,
        [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
        [System.Windows.Media.Imaging.BitmapCacheOption]::None)

    $metadata = $decoder.Frames[0].Metadata

    $Tags = @()
    foreach ($tag in $ifd)
    {
        if ($tag -ne "/{ushort=34665}")
        {
            $ThisTag = New-Object -TypeName PSObject -Property @{
                TagType = "ifd"
                TagName = $tag
                TagValue = $metadata.GetQuery("/app1/ifd$($tag)")
                }
            $Tags += $ThisTag
            }
        else
        {
            $exif = $metadata.GetQuery("/app1/ifd$($tag)")
            foreach ($eTag in $exif)
            {
                $ThisTag = New-Object -TypeName PSObject -Property @{
                    TagType = "exif"
                    TagName = $eTag
                    TagValue = $metadata.GetQuery("/app1/ifd/exif$($eTag)")
                    }
                $Tags += $ThisTag
                }
            }
    }
    #$Images += $Tags
    Foreach ($Tag in $Tags)
    {
        $myTag = ((($Tag.TagName).TrimStart("/{ushort=")).TrimEnd("}"))
        break
        Switch ($myTag)
        {
            271
            {
                # Make, the manufacturer of the equipment
                $TagMake = $Tag.TagValue
                }
            272
            {
                # Model, the model name or model number of the equipment
                $TagModel = $Tag.TagValue
                }
            274
            {
                # Orientation, the image orientation in terms of rows and columns
                $TagOrientation = $Tag.TagValue
                }
            33434
            {
                # ExposureTime
                $TagExposureTime = $Tag.TagValue
                }
            33437
            {
                # FNumber
                $TagFNumber = $Tag.TagValue
                }
            34855
            {
                # ISOSpeedRatings
                $TagISOSpeedRatings = $Tag.TagValue
                }
            36867
            {
                # DateTimeOriginal, Date and teim original image was generated
                $TagDateTimeOriginal = $Tag.TagValue
                }
            37385
            {
                # Flash
                $TagFlash = $Tag.TagValue
                }
            37386
            {
                # FocalLength, Lens focal length
                $TagFocalLength = $Tag.TagValue
                }
            40962
            {
                # PixelXDimension, valid image width
                $TagPixelXDimension = $Tag.TagValue
                }
            40963
            {
                # PixelYDimension, valid image height
                $TagPixelYDimension = $Tag.TagValue
                }
            4097
            {
                # RelatedImageWidth, image width
                $TagRelatedImageWidth = $Tag.TagValue
                }
            4098
            {
                # RelatedImageHeight, image height
                $TagRelatedImageHeight = $Tag.TagValue
                }
            41728
            {
                # FileSource, indicates the image source
                $TagFileSource = $Tag.TagValue
                }
            }
        }
    $ThisImage = New-Object -TypeName PSObject -Property @{
        ImageFileName = $ImageFileName
        ImageDirectoryName = $ImageDirectoryName
        Make = $TagMake
        Model = $TagModel
        Orientation = $TagOrientation
        ExposureTime = $TagExposureTime
        FNumber = $TagFNumber
        ISOSpeedRatings = $TagISOSpeedRatings
        DateTimeOriginal = $TagDateTimeOriginal
        Flash = $TagFlash
        FocalLength = $TagFocalLength
        PixelXDimension = $TagPixelXDimension
        PixelYDimension = $TagPixelYDimension
        RelatedImageWidth = $TagRelatedImageWidth
        RelatedImageHeight = $TagRelatedImageHeight
        FileSource = $TagFileSource
        Hash = $ImageHash
        }
    $Images += $ThisImage
    $stream.Dispose()
}