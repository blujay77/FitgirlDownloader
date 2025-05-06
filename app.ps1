Write-Host ""

### GET USER INPUTS


# get link to game
while ($true) {
    # prompt user to input link to game's page
    $fitgirlUrl = Read-Host "Enter the URL of the game you want to download! (https://fitgirl-repacks.site/...) `n"
    Write-Host ""

    # reject input, if not a link to fitgirl-repacks
    if (-not $fitgirlUrl.Contains("fitgirl-repacks.site/") -or $fitgirlUrl.Contains("paste.fitgirl-repacks.site/")) {
    #if (!$fitgirlUrl.StartsWith("https://fitgirl-repacks.site/")) {
        Write-Output "Invalid URL! `n`n"
        continue
    }

    # check if link leads to valid page, else reject
    try {
        $fitgirlResponse = Invoke-WebRequest -UseBasicParsing -Uri $fitgirlUrl
    }
    catch {
        Write-Output "Invalid URL! `n`n"
        continue
    }

    Write-Host ""
    break
}


# save folder name from site title
$title = ""
$titleIndex = $fitgirlResponse.Content.IndexOf("<title>") + "<title>".Length

do {
    $title += $fitgirlResponse.Content[$titleIndex]
    $titleIndex++
} while ($fitgirlResponse.Content[$titleIndex] -ne "<")


# check IDM default path
$idmLocation = "C:\Program Files (x86)\Internet Download Manager\IDMan.exe"
if (-not (Test-Path -Path $idmLocation)) {
    while ($true) {
        $idmLocation = Read-Host "Enter the path to your IDM installation! (e.g.: C:\Program Files (x86)\Internet Download Manager) `n"
        Write-Host ""

        # reject if empty
        if ($idmLocation -eq "") {
            Write-Output "Invalid path!`n`n"
            continue
        }

        # remove any spaces and backslashes from start and end
        $idmLocation.Trim(" ", "\")
        # add exe to directory
        $idmLocation += "\IDMan.exe"

        # reject if program not in given path
        if (-not (Test-Path -Path $idmLocation)) {
            Write-Output "Invalid path!`n`n"
            continue
        }

        Write-Host ""
        break
    }
}

# load dialog
Add-Type -AssemblyName System.Windows.Forms

# get target path from user
$targetLocation = $null
Write-Output "Choose a download folder!"

$folderSelection = New-Object System.Windows.Forms.FolderBrowserDialog 
$folderSelection.SelectedPath = Get-Location
$folderSelection.Description = "Choose a download folder"

Write-Host ""
Write-Host ""

# show dialog, exit if user cancels
if ($folderSelection.ShowDialog() -eq "Cancel") {
    exit
}

# create new folder in selected location with title
$i = 0
while ($true) {
    try {
        # create folder without number if its the folder does not yet exist
        if ($i -eq 0) {
        $targetLocation = New-Item -Path ($folderSelection.SelectedPath + "\" + $title) -ItemType Directory -ErrorAction Stop
        }
        # append number to folder if it does
        else {
            $targetLocation = New-Item -Path ($folderSelection.SelectedPath + "\" + $title + " ($i)") -ItemType Directory -ErrorAction Stop
        }

        # break out of loop, once folder was successfully created
        break
    } catch {
        # increase number until an available one is found
        $i++
    }
}

### PROCESS USER INPUTS


Write-Output "Thinking...`n"

# start idm
Start-Process -FilePath $idmLocation
# wait for idm to open
Start-Sleep 3

# list that holds 1. name and 2. link to fuckingfast page
$fitgirlLinkInfo = @()

# get all the fuckingfast links from fitgirl-repacks page
$fitgirlLinks = ($fitgirlResponse.Links | Where-Object href -like "*fuckingfast.co*").href

# exit if no links were found
if ($fitgirlLinks.length -eq 0) {
    Write-Output "No `"fuckingfast.co`" links found!"
    exit
}

# extract file name from each link
foreach ($link in $fitgirlLinks) {
    $name = ""

    $i = $link.IndexOf("#") + 1
    # name is string between # and "
    while (($link[$i] -ne "`"") -and ($i -lt $link.length)) {
        $name = $name + $link[$i]
        $i++
    }

    # add (name,link)-object to array
    $fitgirlLinkInfo += [PSCustomObject]@{
        Name = $name
        Link = $link
    }
}


# iterate over fitgirlLinkInfo
foreach ($linkInfo in $fitgirlLinkInfo) {
    
    # wait one second
    Start-Sleep 1

    # get content of fuckingfast page
    $fuckingfastResponse = (Invoke-WebRequest -UseBasicParsing -Uri $linkInfo.Link).toString()
    $downloadLink = ""
    # download link is everything from https://fuckingfast.co/dl/ to "
    $i = $fuckingfastResponse.IndexOf("https://fuckingfast.co/dl/")
    while ($fuckingfastResponse[$i] -ne "`"") {
        $downloadLink += $fuckingfastResponse[$i]
        $i++
    }

    # add file download queue
    Start-Process -FilePath $idmLocation -ArgumentList "/a /n /d $downloadLink /p `"$targetLocation`" /f `"$($linkInfo.Name)`""
    # start queue if not yet started
    Start-Process -FilePath $idmLocation -ArgumentList "/s"

}

Write-Output "Finished. Check your IDM queue to see the download progress.`n"