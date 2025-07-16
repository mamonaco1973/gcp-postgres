#!/bin/bash

################################################################################
# FULL CLEANUP SCRIPT: DESTROYS INFRASTRUCTURE AND DELETES PACKER IMAGES
# Safely destroys:
#   - Deployed VM infrastructure
#   - All custom Packer images starting with "games" or "desktop"
################################################################################

#-------------------------------------------------------------------------------
# STEP 1: FETCH LATEST "games" IMAGE FROM GCP
#-------------------------------------------------------------------------------

games_image=$(gcloud compute images list \
  --filter="name~'^games-image' AND family=games-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")  # Grabs most recently created image from 'games-images' family

if [[ -z "$games_image" ]]; then
  echo "ERROR: No latest image found for 'games-image' in family 'games-images'."
  exit 1  # Hard fail if no image found — we can't safely destroy without this input
fi

echo "NOTE: Games image is $games_image"

#-------------------------------------------------------------------------------
# STEP 2: FETCH LATEST "desktop" IMAGE FROM GCP
#-------------------------------------------------------------------------------

desktop_image=$(gcloud compute images list \
  --filter="name~'^desktop-image' AND family=desktop-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")  # Fetch most recent image from 'desktop-images' family

if [[ -z "$desktop_image" ]]; then
  echo "ERROR: No latest image found for 'desktop-image' in family 'desktop-images'."
  exit 1  # Exit hard if image not found — prevents undefined destroy variables
fi

echo "NOTE: Desktop image is $desktop_image"

#-------------------------------------------------------------------------------
# STEP 3: DESTROY DEPLOYED INFRASTRUCTURE
#-------------------------------------------------------------------------------

cd 03-deploy
terraform init  # Reinitialize providers and backend in case it's stale

# Destroy VMs and associated infrastructure using the latest image names
terraform destroy \
  -var="games_image_name=$games_image" \
  -var="desktop_image_name=$desktop_image" \
  -auto-approve  # Skip confirmation for full wipe (only safe in scripted/CI envs)

cd ..

#-------------------------------------------------------------------------------
# STEP 4: DELETE PACKER-BUILT IMAGES (GAMES & DESKTOP PREFIX)
#-------------------------------------------------------------------------------

echo "NOTE: Fetching images starting with 'games' or 'desktop'..."

# List all custom images that match known prefixes
image_list=$(gcloud compute images list \
  --format="value(name)" \
  --filter="name~'^(games|desktop)'")  # Regex match for names starting with 'games' or 'desktop'

# Check if any were found
if [ -z "$image_list" ]; then
  echo "NOTE: No images found starting with 'games' or 'desktop'. Continuing..."
else
  echo "NOTE: Deleting images..."
  for image in $image_list; do
    echo "NOTE: Deleting image: $image"
    gcloud compute images delete "$image" --quiet || echo "WARNING: Failed to delete image: $image"  # Continue even if deletion fails
  done
fi

#-------------------------------------------------------------------------------
# STEP 5: DESTROY BASE INFRASTRUCTURE (VPC, FIREWALL, ETC.)
#-------------------------------------------------------------------------------

cd 01-infrastructure
terraform init  # Reinitialize infra directory
terraform destroy -auto-approve  # Nuke base resources (networking, firewalls, etc.)
cd ..
