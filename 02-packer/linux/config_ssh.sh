#!/bin/bash

# ------------------ Sanity Check: Ensure PACKER_PASSWORD is set ------------------

# Exit immediately if PACKER_PASSWORD is empty or unset
if [[ -z "${PACKER_PASSWORD}" ]]; then
  echo "ERROR: PACKER_PASSWORD is not set. Aborting user creation." >&2
  exit 1
fi

# ------------------ User Creation: 'packer' Setup ------------------

# Create the 'packer' user with:
# -m : create a home directory under /home/packer
# -s : set default shell to /bin/bash
# If the user already exists, this will fail — no retry logic included
sudo useradd -m -s /bin/bash packer

# ------------------ Password Assignment: Secure Access ------------------

# Use chpasswd to set the user's password securely
# Injecting the password via stdin (secure and script-friendly)
# Note: PACKER_PASSWORD is assumed to be set in the environment (e.g., via export or passed in)
echo "packer:$PACKER_PASSWORD" | sudo chpasswd

# ------------------ Sudo Privileges: Grant Passwordless Access ------------------

# Append sudoer config line to a dedicated file for the user
# This enables 'packer' to run ANY command as ANY user WITHOUT a password prompt
echo "packer ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/packer

# Secure the sudoers file with strict permissions
# Must be 0440 or sudo will reject it (and potentially break sudo access)
sudo chmod 440 /etc/sudoers.d/packer
