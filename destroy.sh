#!/bin/bash

#-------------------------------------------------------------------------------
# STEP 1: DESTROY ???
#-------------------------------------------------------------------------------

cd 01-postgres
terraform init  # Reinitialize infra directory
terraform destroy -auto-approve  # Nuke base resources (networking, firewalls, etc.)
cd ..
