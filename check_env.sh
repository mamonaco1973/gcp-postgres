#!/bin/bash
# ===============================================================================
# FILE: check_env.sh
# ===============================================================================
# Validates local environment prerequisites before running GCP automation.
#
# This script:
#   - Enforces strict shell error handling (fail fast)
#   - Verifies required CLI tools are present in PATH
#   - Validates existence of the service account credentials file
#   - Authenticates gcloud using the service account
#   - Invokes API bootstrap script on successful validation
#
# FAIL FAST:
#   - Any missing dependency or failed command causes immediate exit
# ===============================================================================

# ------------------------------------------------------------------------------
# STRICT SHELL BEHAVIOR
# ------------------------------------------------------------------------------
#  -e  Exit immediately on any command failure
#  -u  Treat unset variables as errors
#  -o pipefail  Fail pipelines if any command fails
# ------------------------------------------------------------------------------
set -euo pipefail


# ===============================================================================
# VALIDATE REQUIRED COMMANDS
# ===============================================================================
# - Ensures all required CLI tools are installed and accessible
# - Script exits immediately if any dependency is missing
# ===============================================================================
echo "NOTE: Validating required commands in PATH"

REQUIRED_COMMANDS=(
  "gcloud"
  "terraform"
  "jq"
)

for cmd in "${REQUIRED_COMMANDS[@]}"; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: Required command '${cmd}' not found in PATH." >&2
    exit 1
  fi

  echo "NOTE: Found required command: ${cmd}"
done

echo "NOTE: All required commands are available"


# ===============================================================================
# VALIDATE SERVICE ACCOUNT CREDENTIALS FILE
# ===============================================================================
# - Ensures credentials.json exists before authentication
# - Prevents accidental interactive gcloud usage
# ===============================================================================
echo "NOTE: Validating service account credentials file"

if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi


# ===============================================================================
# AUTHENTICATE GCLOUD USING SERVICE ACCOUNT
# ===============================================================================
# - Activates the service account for non-interactive automation
# - Required before enabling APIs or provisioning resources
# ===============================================================================
gcloud auth activate-service-account \
  --key-file="./credentials.json"


# ===============================================================================
# RUN API BOOTSTRAP SCRIPT
# ===============================================================================
# - Enables all required Google Cloud APIs for the deployment
# - Script is expected to be idempotent
# ===============================================================================
./api_setup.sh
