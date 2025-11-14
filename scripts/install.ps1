# set color theme
$Theme = @{
    Primary   = 'Cyan'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'White'
}

# Custom download/install locations for this fork
$DownloadDirectory = "C:\Users\Admin\Downloads"
$InstallDirectory = "D:\Program Files\Cursor Free Vip Activator"

# ASCII Logo
$Logo = @"
   ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗      ██████╗ ██████╗  ██████╗   
  ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗     ██╔══██╗██╔══██╗██╔═══██╗  
  ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝     ██████╔╝██████╔╝██║   ██║  
  ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗     ██╔═══╝ ██╔══██╗██║   ██║  
  ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║     ██║     ██║  ██║╚██████╔╝  
   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝     ╚═╝     ╚═╝  ╚═╝ ╚═════╝  
"@

# Beautiful Output Function
function Write-Styled {
    param (
        [string]$Message,
        [string]$Color = $Theme.Info,
        [string]$Prefix = "",
        [switch]$NoNewline
    )
    $symbol = switch ($Color) {
        $Theme.Success { "[OK]" }
        $Theme.Error   { "[X]" }
        $Theme.Warning { "[!]" }
        default        { "[*]" }
    }
    
    $output = if ($Prefix) { "$symbol $Prefix :: $Message" } else { "$symbol $Message" }
    if ($NoNewline) {
        Write-Host $output -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $output -ForegroundColor $Color
    }
}

# Get version number function
function Get-LatestVersion {
    try {
        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/Krystal0212/cursor-free-vip/releases/latest"
        return @{
            Version = $latestRelease.tag_name.TrimStart('v')
            Assets = $latestRelease.assets
        }
    } catch {
        Write-Styled $_.Exception.Message -Color $Theme.Error -Prefix "Error"
        throw "Cannot get latest version"
    }
}

# Show Logo
Write-Host $Logo -ForegroundColor $Theme.Primary
$releaseInfo = Get-LatestVersion
$version = $releaseInfo.Version
Write-Host "Version $version" -ForegroundColor $Theme.Info
Write-Host "Created by YeongPin`n" -ForegroundColor $Theme.Info

# Set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Launch helper that elevates when required
function Start-CursorFreeVipExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExecutablePath
    )

    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Styled "Requesting administrator privileges..." -Color $Theme.Warning -Prefix "Admin"

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $ExecutablePath
        $startInfo.UseShellExecute = $true
        $startInfo.Verb = "runas"

        try {
            [System.Diagnostics.Process]::Start($startInfo) | Out-Null
            Write-Styled "Program started with admin privileges" -Color $Theme.Success -Prefix "Launch"
            return
        }
        catch {
            Write-Styled "Failed to start with admin privileges. Starting normally..." -Color $Theme.Warning -Prefix "Warning"
            Start-Process $ExecutablePath
            return
        }
    }

    Start-Process $ExecutablePath
}

# Main installation function
function Install-CursorFreeVIP {
    Write-Styled "Start downloading Cursor Free VIP" -Color $Theme.Primary -Prefix "Download"
    
    try {
        # Get latest version
        Write-Styled "Checking latest version..." -Color $Theme.Primary -Prefix "Update"
        $releaseInfo = Get-LatestVersion
        $version = $releaseInfo.Version
        Write-Styled "Found latest version: $version" -Color $Theme.Success -Prefix "Version"
        
        # Find corresponding resources
        $asset = $releaseInfo.Assets | Where-Object { $_.name -eq "CursorFreeVIP_${version}_windows.exe" }
        if (!$asset) {
            Write-Styled "File not found: CursorFreeVIP_${version}_windows.exe" -Color $Theme.Error -Prefix "Error"
            Write-Styled "Available files:" -Color $Theme.Warning -Prefix "Info"
            $releaseInfo.Assets | ForEach-Object {
                Write-Styled "- $($_.name)" -Color $Theme.Info
            }
            throw "Cannot find target file"
        }
        
        # Ensure download/install directories exist
        if (!(Test-Path $DownloadDirectory)) {
            Write-Styled "Creating download directory: $DownloadDirectory" -Color $Theme.Warning -Prefix "Path"
            New-Item -ItemType Directory -Path $DownloadDirectory -Force | Out-Null
        }
        if (!(Test-Path $InstallDirectory)) {
            Write-Styled "Creating install directory: $InstallDirectory" -Color $Theme.Warning -Prefix "Path"
            New-Item -ItemType Directory -Path $InstallDirectory -Force | Out-Null
        }

        $installerName = "CursorFreeVIP_${version}_windows.exe"
        $downloadPath = Join-Path $DownloadDirectory $installerName
        $installedPath = Join-Path $InstallDirectory $installerName

        # Reuse any existing installer
        $existingPath = $null
        if (Test-Path $installedPath) {
            $existingPath = $installedPath
            Write-Styled "Found installer in install directory" -Color $Theme.Success -Prefix "Found"
        } elseif (Test-Path $downloadPath) {
            Write-Styled "Found installer in download directory; copying to install directory" -Color $Theme.Warning -Prefix "Copy"
            Copy-Item $downloadPath $installedPath -Force
            $existingPath = $installedPath
        }

        if ($existingPath) {
            Write-Styled "Location: $existingPath" -Color $Theme.Info -Prefix "Location"
            Start-CursorFreeVipExecutable -ExecutablePath $existingPath
            return
        }
        
        Write-Styled "No existing installation file found, starting download..." -Color $Theme.Primary -Prefix "Download"

        # Use HttpWebRequest for chunked download with real-time progress bar
        $url = $asset.browser_download_url
        $outputFile = $downloadPath
        Write-Styled "Downloading from: $url" -Color $Theme.Info -Prefix "URL"
        Write-Styled "Saving to: $outputFile" -Color $Theme.Info -Prefix "Path"

        $request = [System.Net.HttpWebRequest]::Create($url)
        $request.UserAgent = "PowerShell Script"
        $response = $request.GetResponse()
        $totalLength = $response.ContentLength
        $responseStream = $response.GetResponseStream()
        $fileStream = [System.IO.File]::OpenWrite($outputFile)
        $buffer = New-Object byte[] 8192
        $bytesRead = 0
        $totalRead = 0
        $lastProgress = -1
        $startTime = Get-Date
        try {
            do {
                $bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -gt 0) {
                    $fileStream.Write($buffer, 0, $bytesRead)
                    $totalRead += $bytesRead
                    $progress = [math]::Round(($totalRead / $totalLength) * 100, 1)
                    if ($progress -ne $lastProgress) {
                        $elapsed = (Get-Date) - $startTime
                        $speed = if ($elapsed.TotalSeconds -gt 0) { $totalRead / $elapsed.TotalSeconds } else { 0 }
                        $speedDisplay = if ($speed -gt 1MB) {
                            "{0:N2} MB/s" -f ($speed / 1MB)
                        } elseif ($speed -gt 1KB) {
                            "{0:N2} KB/s" -f ($speed / 1KB)
                        } else {
                            "{0:N2} B/s" -f $speed
                        }
                        $downloadedMB = [math]::Round($totalRead / 1MB, 2)
                        $totalMB = [math]::Round($totalLength / 1MB, 2)
                        Write-Progress -Activity "Downloading CursorFreeVIP" -Status "$downloadedMB MB / $totalMB MB ($progress%) - $speedDisplay" -PercentComplete $progress
                        $lastProgress = $progress
                    }
                }
            } while ($bytesRead -gt 0)
        } finally {
            $fileStream.Close()
            $responseStream.Close()
            $response.Close()
        }
        Write-Progress -Activity "Downloading CursorFreeVIP" -Completed
        # Check file exists and is not zero size
        if (!(Test-Path $outputFile) -or ((Get-Item $outputFile).Length -eq 0)) {
            throw "Download failed or file is empty."
        }
        Write-Styled "Download completed!" -Color $Theme.Success -Prefix "Complete"
        Write-Styled "File location: $outputFile" -Color $Theme.Info -Prefix "Location"

        # Copy installer into the install directory and launch from there
        Copy-Item $outputFile $installedPath -Force
        Write-Styled "Installer copied to: $installedPath" -Color $Theme.Info -Prefix "Install"
        Write-Styled "Starting program..." -Color $Theme.Primary -Prefix "Launch"
        Start-CursorFreeVipExecutable -ExecutablePath $installedPath
    }
    catch {
        Write-Styled $_.Exception.Message -Color $Theme.Error -Prefix "Error"
        throw
    }
}

# Execute installation
try {
    Install-CursorFreeVIP
}
catch {
    Write-Styled "Download failed" -Color $Theme.Error -Prefix "Error"
    Write-Styled $_.Exception.Message -Color $Theme.Error
}
finally {
    Write-Host "`nPress any key to exit..." -ForegroundColor $Theme.Info
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
