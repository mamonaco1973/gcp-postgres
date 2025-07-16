
#!/bin/bash
#-------------------------------------------------------------------------------
# STEP 0: VALIDATE ENVIRONMENT BEFORE EXECUTION
#-------------------------------------------------------------------------------

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

#-------------------------------------------------------------------------------
# STEP 1:???
#-------------------------------------------------------------------------------

cd 01-postgres
terraform init
terraform apply -auto-approve
cd ..

#-------------------------------------------------------------------------------
# STEP 2: EXTRACT PROJECT AND AUTHENTICATE TO GCP
#-------------------------------------------------------------------------------

project_id=$(jq -r '.project_id' "./credentials.json")
gcloud auth activate-service-account --key-file="./credentials.json" > /dev/null 2> /dev/null
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/credentials.json"


