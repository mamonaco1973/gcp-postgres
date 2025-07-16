# Set strict error handling
$ErrorActionPreference = "Stop"

# https://www.snel.com/support/install-chrome-in-windows-server/

try {

    # Set variables
    $LocalTempDir = $env:TEMP
    $ChromeInstaller = "ChromeInstaller.exe"
    $InstallerPath = Join-Path $LocalTempDir $ChromeInstaller

    Write-Host "Starting Chrome installation process..." -ForegroundColor Cyan

    # Step 1: Download Chrome installer
    Write-Host "Downloading Chrome installer to: $InstallerPath" -ForegroundColor Yellow
    try {
    (New-Object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', $InstallerPath)
        Write-Host "Download complete." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to download Chrome installer: $_" -ForegroundColor Red
        exit 1
    }

    # Step 2: Run installer silently
    Write-Host "Launching Chrome installer in silent mode..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath $InstallerPath -ArgumentList "/silent", "/install" -Wait
        Write-Host "Chrome installation completed." -ForegroundColor Green
    }
    catch {
        Write-Host "Chrome installation failed: $_" -ForegroundColor Red
        exit 1
    }

    # Step 3: Clean up installer
    Write-Host "Cleaning up temporary installer file..." -ForegroundColor Yellow
    try {
        Remove-Item $InstallerPath -ErrorAction Stop
        Write-Host "Cleanup complete." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove installer. Continuing anyway." -ForegroundColor DarkYellow
    }

    Write-Host "Chrome installation script completed." -ForegroundColor Cyan
}
catch {
    Write-Error "An error occurred during Chrome installation: $_"
    exit 1
}
