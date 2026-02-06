#!/bin/bash
# ===============================================================================
# FILE: apply.sh
# ===============================================================================
# Applies the PostgreSQL Cloud SQL infrastructure using Terraform.
#
# This script:
#   1) Validates the local environment and required tooling
#   2) Initializes and applies the PostgreSQL Terraform configuration
#   3) Runs post-deployment validation checks
#
# FAST-FAIL BEHAVIOR:
#   - Script exits immediately on any error
#   - Prevents partial or inconsistent deployments
# ===============================================================================

# Enable strict shell behavior:
#   -e  Exit immediately if a command exits non-zero
#   -u  Treat unset variables as an error
#   -o pipefail  Fail pipelines if any command fails
set -euo pipefail


# ===============================================================================
# VALIDATE ENVIRONMENT
# ===============================================================================
# - Ensures required commands, credentials, and permissions are present
# - check_env.sh is responsible for printing actionable errors
# ===============================================================================
./check_env.sh


# ===============================================================================
# DEPLOY POSTGRESQL INFRASTRUCTURE
# ===============================================================================
# - Initializes Terraform providers and backend
# - Applies the PostgreSQL Cloud SQL stack non-interactively
# ===============================================================================
cd 01-postgres
terraform init
terraform apply -auto-approve
cd ..


# ===============================================================================
# VALIDATE THE BUILD
# ===============================================================================
# - Confirms PostgreSQL and pgweb endpoints are reachable
# - Outputs final connection details
# ===============================================================================
echo ""
./validate.sh
