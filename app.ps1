Write-Host ""

$fitgirlUrl = ""
$idmLocation = ""
$targetLocation = ""


### GET USER INPUTS


# get link to game
while ($true) {
    # prompt user to input link to game's page
    $fitgirlUrl = Read-Host "Enter the URL to the game you want to download! (https://fitgirl-repacks.site/...) `n"
    Write-Host ""

    # reject input, if not a link to fitgirl-repacks
    if (!$fitgirlUrl.StartsWith("https://fitgirl-repacks.site/")) {
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

    Write-Output ""
    break
}


# check IDM default path
if (Test-Path -Path "C:\Program Files (x86)\Internet Download Manager\IDMan.exe") {
    $idmLocation = "C:\Program Files (x86)\Internet Download Manager\IDMan.exe"
}
# if not in default path, get path from user
else {
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

#start idm
#Start-Process -FilePath $idmLocation

$pathExists = $false
# get target path from user
do {
    $targetLocation = Read-Host "Enter the path you want to download the files to! `n"
    Write-Host ""

    # reject if empty
    if ($targetLocation -eq "") {
        Write-Output "Invalid path!`n`n"
        continue
    }

    # if path doesn't exist, ask if user wants to create it
    if (-not (Test-Path $targetLocation)) {
        while ($true) {
            $createNewPath = Read-Host "This path does not exist. Would you like to create it? (y/n)"

            # if they answer no, stop asking and prompt for new path again
            if ($createNewPath -in ("n", "N")) {
                Write-Host ""
                break
            }

            # if they answer yes, try to create path
            if ($createNewPath -in ("y", "Y")) {
                Write-Host ""
                # if the newly created path exists
                if ((New-Item -ItemType Directory -Path $targetLocation).Exists) {
                    Write-Output "Path created. `n`n"
                    $pathExists = $true
                }
                else {
                    Write-Output "Path could not be created. `n`n"
                }
                break
            }
        }
    }
    else {
        $pathExists = $true
    }
} while ($pathExists -eq $false)


### PROCESS USER INPUTS

# list that holds 1. name and 2. link to fuckingfast page
$fitgirlLinkInfo = @()

# get all the fuckingfast links from fitgirl-repacks page
$fitgirlLinks = ($fitgirlResponse.Links | Where-Object href -like "*fuckingfast.co*").href
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

# exit if no links were found
if ($fitgirlLinkInfo.length -eq 0) {
    Write-Output "No `"fuckingfast.co`" links found!"
    exit
}

# iterate over fitgirlLinkInfo
foreach ($linkInfo in $fitgirlLinkInfo) {
    # get content of fuckingfast page
    $fuckingfastResponse = (Invoke-WebRequest -UseBasicParsing -Uri $linkInfo.Link).toString()
    $downloadLink = ""
    # download link is everything from https://fuckingfast.co/dl/ to "
    $i = $fuckingfastResponse.IndexOf("https://fuckingfast.co/dl/")
    while ($fuckingfastResponse[$i] -ne "`"") {
        $downloadLink += $fuckingfastResponse[$i]
        $i++
    }
    
    # add file download to queue
    Start-Process -FilePath $idmLocation -ArgumentList "/a /n /d $downloadLink /p `"$targetLocation`" /f `"$($linkInfo.Name)`""
}

#start queue
Start-Process -FilePath $idmLocation -ArgumentList "/s"
Write-Output "Finished. Check your IDM queue to see the download progress.`n"