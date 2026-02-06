#!/bin/bash
# ===============================================================================
# FILE: destroy.sh
# ===============================================================================
# Tears down the PostgreSQL Cloud SQL infrastructure.
#
# This script:
#   1) Validates the local environment and required tooling
#   2) Deletes the Cloud SQL PostgreSQL instance via gcloud
#   3) Destroys all remaining Terraform-managed infrastructure
#
# FAST-FAIL BEHAVIOR:
#   - Script exits immediately on any error
#   - Prevents partial or inconsistent teardown
#
# WARNING:
#   - This operation is destructive and irreversible
#   - All database data will be permanently deleted
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
# DELETE CLOUD SQL POSTGRESQL INSTANCE
# ===============================================================================
# - Explicitly deletes the Cloud SQL instance first
# - Avoids Terraform waiting on long-running managed-service deletion
# ===============================================================================
gcloud sql instances delete postgres-instance --quiet


# ===============================================================================
# DESTROY TERRAFORM MANAGED INFRASTRUCTURE
# ===============================================================================
# - Destroys networking, DNS, VM, and supporting resources
# - Runs non-interactively for automation and repeatability
# ===============================================================================
cd 01-postgres
terraform init
terraform destroy -auto-approve
cd ..
