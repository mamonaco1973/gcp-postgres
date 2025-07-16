#!/bin/bash

################################################################################
# FULL DEPLOYMENT SCRIPT: GCP INFRASTRUCTURE + IMAGE BUILD + VM DEPLOYMENT
# Automates:
#   - Terraform infrastructure provisioning
#   - Packer image builds (Linux + Windows)
#   - Image discovery for latest builds
#   - Terraform deployment using those images
################################################################################

#-------------------------------------------------------------------------------
# STEP 0: VALIDATE ENVIRONMENT BEFORE EXECUTION
#-------------------------------------------------------------------------------

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

#-------------------------------------------------------------------------------
# STEP 1: PROVISION CORE INFRASTRUCTURE USING TERRAFORM
#-------------------------------------------------------------------------------

cd 01-infrastructure
terraform init
terraform apply -auto-approve
cd ..

#-------------------------------------------------------------------------------
# STEP 2: EXTRACT PROJECT AND AUTHENTICATE TO GCP
#-------------------------------------------------------------------------------

project_id=$(jq -r '.project_id' "./credentials.json")

gcloud auth activate-service-account --key-file="./credentials.json" > /dev/null 2> /dev/null
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/credentials.json"

#-------------------------------------------------------------------------------
# STEP 3: RETRIEVE SECRET FOR PACKER USER PASSWORD FROM SECRET MANAGER
#-------------------------------------------------------------------------------

password=$(gcloud secrets versions access latest --secret="packer-credentials" | jq -r '.password')

#-------------------------------------------------------------------------------
# STEP 4: BUILD LINUX IMAGE USING PACKER
#-------------------------------------------------------------------------------

cd 02-packer/linux
packer init .

packer build \
  -var="project_id=$project_id" \
  -var="password=$password" \
  linux_image.pkr.hcl

cd ../windows
packer build \
  -var="project_id=$project_id" \
  -var="password=$password" \
  windows_image.pkr.hcl

cd ../..

#-------------------------------------------------------------------------------
# STEP 5: LOOKUP LATEST PACKER IMAGES FROM GCP BY FAMILY
#-------------------------------------------------------------------------------

games_image=$(gcloud compute images list \
  --filter="name~'^games-image' AND family=games-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")

if [[ -z "$games_image" ]]; then
  echo "ERROR: No latest image found for 'games-image' in family 'games-images'."
  exit 1
fi

echo "NOTE: Games image is $games_image"

desktop_image=$(gcloud compute images list \
  --filter="name~'^desktop-image' AND family=desktop-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")

if [[ -z "$desktop_image" ]]; then
  echo "ERROR: No latest image found for 'desktop-image' in family 'desktop-images'."
  exit 1
fi

echo "NOTE: Desktop image is $desktop_image"

#-------------------------------------------------------------------------------
# STEP 6: DEPLOY VM RESOURCES USING LATEST IMAGES
#-------------------------------------------------------------------------------

cd 03-deploy

# Apply Terraform deployment with dynamic image names and no manual prompt
terraform init
terraform apply \
  -var="games_image_name=$games_image" \
  -var="desktop_image_name=$desktop_image" \
  -auto-approve

cd ..
