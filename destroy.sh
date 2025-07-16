#!/bin/bash

# =================================================================================
# VALIDATE ENVIRONMENT
# - Ensures prerequisites are in place before proceeding
# =================================================================================

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# =================================================================================
# DESTROY POSTGRESQL INFRASTRUCTURE
# - Step-by-step teardown of Cloud SQL resources
# - Partial destroy first (user + instance), then full cleanup
# =================================================================================

cd 01-postgres || { echo "ERROR: Directory '01-postgres' not found."; exit 1; }

#echo "STEP 1: Destroy Cloud SQL user and instance..."
#terraform destroy \
#  -target=google_sql_user.postgres_user \
#  -target=google_sql_database_instance.postgres \
#  -auto-approve

#echo "STEP 2: Wait 15 minutes for backend cleanup (Cloud SQL teardown takes time)..."
#sleep 900  # 900 seconds = 15 minutes

echo "STEP 3: Destroy remaining infrastructure..."
terraform destroy -auto-approve

cd ..
