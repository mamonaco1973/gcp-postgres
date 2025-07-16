try {
    Write-Host "Starting WinRM configuration script..." -ForegroundColor Cyan

    # Set Administrator password and ensure it doesn't expire
    net user Administrator "${password}"
    wmic useraccount where "name='Administrator'" set PasswordExpires=FALSE

    # Set execution policy and stop on all errors
    Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore
    $ErrorActionPreference = "Stop"

    # Remove existing WinRM listeners (ignore errors if none exist)
    Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse -ErrorAction SilentlyContinue

    # Create a self-signed certificate for HTTPS listener
    $Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"

    # Create new WinRM HTTPS listener
    New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

    # Configure WinRM settings
    winrm quickconfig -q
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/client '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"; CredSSP="true"; Negotiate="true"}'

    # Allow WinRM through the firewall
    New-NetFirewallRule -DisplayName "Allow WinRM HTTPS" -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow

    # Ensure WinRM service is running
    Stop-Service winrm
    Set-Service winrm -StartupType Automatic
    Start-Service winrm

    Write-Host "WinRM configuration completed successfully." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during WinRM setup: $_"
    exit 1
}


