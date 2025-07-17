#!/bin/bash

#-------------------------------------------------------------------------------
# Output pgweb URL and postgres DNS name
#-------------------------------------------------------------------------------

PGWEB_IP=$(gcloud compute instances describe pgweb-vm \
  --zone=us-central1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

echo "NOTE: pgweb running at http://$PGWEB_IP"

PG_DNS="postgres.internal.db-zone.local"
echo "NOTE: Hostname for postgres server is \"$PG_DNS\""

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
