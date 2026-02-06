#!/bin/bash
# ===============================================================================
# FILE: api_setup.sh
# ===============================================================================
# Bootstraps Google Cloud APIs required for Terraform-based infrastructure builds.
#
# This script:
#   - Validates presence of a service account credentials file
#   - Authenticates gcloud using the service account
#   - Extracts the target project ID from credentials.json
#   - Enables all required Google Cloud APIs for the deployment
#   - Initializes a Firestore Native database (idempotent)
#
# NOTES:
#   - credentials.json must be a valid service account key file
#   - APIs are enabled at the project level and may take time to propagate
#   - Firestore creation is silenced to avoid noisy output on re-runs
# ===============================================================================

set -euo pipefail

# ===============================================================================
# VALIDATE SERVICE ACCOUNT CREDENTIALS FILE
# ===============================================================================
# - Ensures credentials.json exists before attempting authentication
# - Exits immediately if the file is missing
# ===============================================================================
#echo "NOTE: Validating credentials.json and testing gcloud authentication"

if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi


# ===============================================================================
# AUTHENTICATE GCLOUD USING SERVICE ACCOUNT
# ===============================================================================
# - Activates the service account for non-interactive usage
# - Required for API enablement and resource provisioning
# ===============================================================================
gcloud auth activate-service-account \
  --key-file="./credentials.json" > /dev/null 2> /dev/null


# ===============================================================================
# EXTRACT PROJECT ID FROM CREDENTIALS
# ===============================================================================
# - Uses jq to parse the service account JSON
# - Project ID is used to scope all subsequent gcloud operations
# ===============================================================================
project_id="$(jq -r '.project_id' "./credentials.json")"


# ===============================================================================
# SET ACTIVE GCLOUD PROJECT
# ===============================================================================
# - Ensures all API enablement targets the correct GCP project
# ===============================================================================
echo "NOTE: Enabling APIs needed for build"
gcloud config set project "${project_id}" > /dev/null

# ===============================================================================
# ENABLE REQUIRED GOOGLE CLOUD APIS
# ===============================================================================
# - Enables compute, networking, IAM, and managed service APIs
# - Required for Terraform resources and supporting services
# ===============================================================================
gcloud services enable compute.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable apigateway.googleapis.com
gcloud services enable servicemanagement.googleapis.com
gcloud services enable servicecontrol.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable servicenetworking.googleapis.com

