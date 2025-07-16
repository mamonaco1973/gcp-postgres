# Ensure the script stops on all errors
$ErrorActionPreference = "Stop"

try {
    Write-Host "Starting local user creation and group assignment..." -ForegroundColor Cyan

    # Read the password from the PACKER_PASSWORD environment variable
    $envPassword = [Environment]::GetEnvironmentVariable("PACKER_PASSWORD")

    # Exit with error if PACKER_PASSWORD is not set or empty
    if ([string]::IsNullOrWhiteSpace($envPassword)) {
        Write-Error "Environment variable 'PACKER_PASSWORD' is not set or empty."
        exit 1
    }

    # Convert plain text password to secure string
    $securePassword = ConvertTo-SecureString $envPassword -AsPlainText -Force

    # Create the local user 'packer' with the password, if it doesn't already exist
    if (-Not (Get-LocalUser -Name "packer" -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name "packer" `
                      -Password $securePassword `
                      -FullName "Packer User" `
                      -Description "Local user for Packer builds" `
                      -PasswordNeverExpires
        Write-Host "User 'packer' created successfully."
    } else {
        Write-Host "User 'packer' already exists. Skipping creation."
    }

    # Add the user to the Administrators group
    Add-LocalGroupMember -Group "Administrators" -Member "packer"
    Write-Host "User 'packer' added to Administrators group."

    # Add the user to the Remote Desktop Users group
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member "packer"
    Write-Host "User 'packer' added to Remote Desktop Users group."

    Write-Host "User setup completed successfully." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred while setting up the 'packer' user: $_"
    exit 1
}
