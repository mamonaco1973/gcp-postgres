#!/bin/bash
# ===============================================================================
# FILE: validate.sh
# ===============================================================================
# Resolves and prints the pgweb endpoint and the internal PostgreSQL DNS name.
# Also waits for pgweb to become reachable before returning success.
#
# OUTPUT (SUMMARY):
#   - pgweb URL
#   - PostgreSQL internal hostname
# ===============================================================================

# Enable strict shell behavior:
#   -e  Exit immediately on error
#   -u  Treat unset variables as errors
#   -o pipefail  Fail pipelines if any command fails
set -euo pipefail


# ===============================================================================
# CONFIGURATION
# ===============================================================================
PGWEB_INSTANCE_NAME="pgweb-vm"
PGWEB_ZONE="us-central1-a"

POSTGRES_DNS_NAME="postgres.internal.db-zone.local"

MAX_ATTEMPTS=30
SLEEP_SECONDS=30


# ===============================================================================
# RESOLVE PGWEB PUBLIC IP
# ===============================================================================
PGWEB_IP="$(gcloud compute instances describe "${PGWEB_INSTANCE_NAME}" \
  --zone="${PGWEB_ZONE}" \
  --format="value(networkInterfaces[0].accessConfigs[0].natIP)")"

if [[ -z "${PGWEB_IP}" ]]; then
  echo "ERROR: Failed to resolve pgweb public IP address." >&2
  exit 1
fi

PGWEB_URL="http://${PGWEB_IP}"

echo "NOTE: pgweb running at ${PGWEB_URL}"


# ===============================================================================
# WAIT FOR PGWEB TO BECOME REACHABLE
# ===============================================================================
echo "NOTE: Waiting for pgweb to become available at ${PGWEB_URL}..."

ATTEMPT=1
until curl -s --fail "${PGWEB_URL}" >/dev/null; do
  if [[ "${ATTEMPT}" -ge "${MAX_ATTEMPTS}" ]]; then
    echo "ERROR: pgweb did not become available after ${MAX_ATTEMPTS} attempts." \
      >&2
    exit 1
  fi

  echo "WARNING: pgweb not reachable. Retrying in ${SLEEP_SECONDS}s..." >&2
  sleep "${SLEEP_SECONDS}"
  ATTEMPT=$((ATTEMPT + 1))
done


# ===============================================================================
# FINAL OUTPUT (CONSISTENT SUMMARY)
# ===============================================================================
echo ""
echo "===============================================================================" 
echo "BUILD RESULTS"
echo "===============================================================================" 
echo "pgweb URL             : ${PGWEB_URL}"
echo "Postgres Hostname DNS : ${POSTGRES_DNS_NAME}"
echo "===============================================================================" 
