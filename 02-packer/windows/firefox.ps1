# Set script to stop on all errors
$ErrorActionPreference = "Stop"

# https://www.snel.com/support/install-firefox-in-windows-server/

try {
    # Define working directory
    $workdir = "C:\installer"

    # Create directory if it doesn't exist
    if (Test-Path -Path $workdir -PathType Container) {
        Write-Host "$workdir already exists" -ForegroundColor Red
    } else {
        New-Item -Path $workdir -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $workdir" -ForegroundColor Green
    }

    # Define source URL and destination path
    $source = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
    $destination = "$workdir\firefox.exe"

    # Download Firefox using Invoke-WebRequest if available
    if (Get-Command 'Invoke-WebRequest' -ErrorAction SilentlyContinue) {
        Write-Host "Downloading Firefox using Invoke-WebRequest..."
        Invoke-WebRequest $source -OutFile $destination
    } else {
        Write-Host "Downloading Firefox using WebClient fallback..."
        $webclient = New-Object System.Net.WebClient
        $webclient.DownloadFile($source, $destination)
    }

    # Install Firefox silently
    Write-Host "Launching Firefox installer silently..."
    Start-Process -FilePath $destination -ArgumentList "/S" -Wait

    # Remove installer
    Write-Host "Cleaning up installer files..."
    Remove-Item -Force "$workdir\firefox*" -ErrorAction SilentlyContinue

    Write-Host "Firefox installation completed successfully." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during the Firefox installation: $_"
    exit 1
}
