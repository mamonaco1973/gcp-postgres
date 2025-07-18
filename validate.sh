#!/bin/bash

#-------------------------------------------------------------------------------
# Output pgweb URL and postgres DNS name
#-------------------------------------------------------------------------------

PGWEB_IP=$(gcloud compute instances describe pgweb-vm \
  --zone=us-central1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

echo "NOTE: pgweb running at http://$PGWEB_IP"

# Wait until the pgweb URL is reachable (HTTP 200 or similar)
echo "NOTE: Waiting for pgweb to become available at http://$PGWEB_IP ..."

# Max attempts (optional)
MAX_ATTEMPTS=30
ATTEMPT=1

until curl -s --fail "http://$PGWEB_IP" > /dev/null; do
  if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
    echo "ERROR: pgweb did not become available after $MAX_ATTEMPTS attempts."
    exit 1
  fi
  echo "WARNING: pgweb not yet reachable. Retrying in 30 seconds..."
  sleep 30
  ATTEMPT=$((ATTEMPT+1))
done

PG_DNS="postgres.internal.db-zone.local"
echo "NOTE: Hostname for postgres server is \"$PG_DNS\""

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
