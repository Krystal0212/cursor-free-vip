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

# Project metadata (used when release tags are non-version strings such as "release")
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$EnvFilePath = Join-Path $ProjectRoot ".env"

function Get-ProjectVersion {
    if (-not (Test-Path $EnvFilePath)) {
        return $null
    }

    foreach ($line in Get-Content $EnvFilePath) {
        if ($line -match '^\s*VERSION\s*=\s*(.+)\s*$') {
            $value = $Matches[1].Trim('"').Trim()
            if ($value) {
                return $value
            }
        }
    }
    return $null
}

$ProjectVersion = Get-ProjectVersion

function Get-ReleaseTag {
    param(
        [Parameter(Mandatory = $true)]
        $ReleaseInfo
    )

    if (-not $ReleaseInfo) {
        return $null
    }

    $tag = $null
    if ($ReleaseInfo.PSObject.Properties.Name -contains 'tag_name') {
        $tag = $ReleaseInfo.tag_name
    }
    if (-not $tag -and ($ReleaseInfo.PSObject.Properties.Name -contains 'name')) {
        $tag = $ReleaseInfo.name
    }

    if ([string]::IsNullOrWhiteSpace($tag)) {
        return $null
    }
    return $tag.Trim()
}

function Normalize-VersionTag {
    param(
        [string]$Tag
    )

    if ([string]::IsNullOrWhiteSpace($Tag)) {
        return $null
    }
    return $Tag.Trim().TrimStart('v')
}

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
    $repoBase = "https://api.github.com/repos/Krystal0212/cursor-free-vip/releases"
    try {
        $latestRelease = Invoke-RestMethod -Uri "$repoBase/latest"
        return $latestRelease
    } catch {
        Write-Styled "Standard release lookup failed: $($_.Exception.Message)" -Color $Theme.Warning -Prefix "Update"
        try {
            $allReleases = Invoke-RestMethod -Uri $repoBase
            if ($allReleases -and $allReleases.Count -gt 0) {
                Write-Styled "Using latest available release (including prereleases)." -Color $Theme.Warning -Prefix "Update"
                return $allReleases[0]
            }
        } catch {
            Write-Styled "Fallback release list lookup failed: $($_.Exception.Message)" -Color $Theme.Error -Prefix "Error"
        }
        throw "Cannot get latest version"
    }
}

# Show Logo
Write-Host $Logo -ForegroundColor $Theme.Primary
$releaseInfo = Get-LatestVersion
$releaseTag = Get-ReleaseTag -ReleaseInfo $releaseInfo
$version = Normalize-VersionTag -Tag $releaseTag
if (-not $version -and $ProjectVersion) {
    $version = $ProjectVersion
}
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
        $releaseTag = Get-ReleaseTag -ReleaseInfo $releaseInfo
        $version = Normalize-VersionTag -Tag $releaseTag
        if (-not $version -and $ProjectVersion) {
            $version = $ProjectVersion
        }
        $downloadTag = if ($releaseTag) { $releaseTag } elseif ($ProjectVersion) { "v$ProjectVersion" } else { "release" }
        Write-Styled "Found latest version: $version" -Color $Theme.Success -Prefix "Version"
        $effectiveVersion = if ($ProjectVersion -and ($version -eq 'release' -or -not $version)) {
            Write-Styled "Using project version $ProjectVersion for asset lookup" -Color $Theme.Info -Prefix "Version"
            $ProjectVersion
        } else {
            $version
        }
        
        # Find corresponding resources
        $expectedNames = @()
        if ($effectiveVersion) {
            $expectedNames += "CursorFreeVIP_${effectiveVersion}_windows.exe"
        }
        if ($version -and $version -ne $effectiveVersion) {
            $expectedNames += "CursorFreeVIP_${version}_windows.exe"
        }
        if (-not $expectedNames) {
            $expectedNames += "CursorFreeVIP_windows.exe"
        }

        $asset = $null
        foreach ($name in $expectedNames) {
            $asset = $releaseInfo.Assets | Where-Object { $_.name -eq $name } | Select-Object -First 1
            if ($asset) {
                break
            }
        }
        if (-not $asset) {
            $asset = $releaseInfo.Assets | Where-Object { $_.name -like "*windows*.exe" } | Select-Object -First 1
        }
        $manualDownloadUrl = $null
        $manualFileName = $null
        if (-not $asset) {
            Write-Styled "Matching asset not found in release payload" -Color $Theme.Warning -Prefix "Assets"
            if ($env:CURSOR_FREE_VIP_WINDOWS_URL) {
                $manualDownloadUrl = $env:CURSOR_FREE_VIP_WINDOWS_URL
                $manualFileName = Split-Path $manualDownloadUrl -Leaf
                Write-Styled "Using override download URL from CURSOR_FREE_VIP_WINDOWS_URL" -Color $Theme.Warning -Prefix "Override"
            } elseif ($effectiveVersion) {
                $manualFileName = "CursorFreeVIP_${effectiveVersion}_windows.exe"
                $manualDownloadUrl = "https://github.com/Krystal0212/cursor-free-vip/releases/download/$downloadTag/$manualFileName"
                Write-Styled "Falling back to direct download URL: $manualDownloadUrl" -Color $Theme.Warning -Prefix "Fallback"
            } else {
                Write-Styled "Available files:" -Color $Theme.Warning -Prefix "Info"
                $releaseInfo.Assets | ForEach-Object {
                    Write-Styled "- $($_.name)" -Color $Theme.Info
                }
                throw "Cannot find target file"
            }
        } else {
            $manualFileName = $asset.name
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

        $installerName = $manualFileName
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
        $url = if ($asset) { $asset.browser_download_url } else { $manualDownloadUrl }
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
