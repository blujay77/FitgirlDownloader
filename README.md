# FitgirlDownloader
This is a simple script to automate some of the download process from www.fitgirl-repacks.site. I am not affiliated with the site itself.

### Requirements
Successfully running the script requires three things:
- Windows Powershell
- A working installation of IDM (www.internetdownloadmanager.com), optimally in "C:\Program Files (x86)\"
- The game's files being hosted on www.fuckingfast.co

### Usage
Open Powershell and run the following command:
```ps1
Invoke-Expression "& { $(Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/blujay77/FitgirlDownloader/refs/heads/main/app.ps1') }"
```
