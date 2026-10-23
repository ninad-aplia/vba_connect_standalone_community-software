#!/usr/bin/env bash
# Provision GCP resources from your LOCAL machine (or Cloud Shell).
# Prereq: gcloud CLI installed & authenticated: gcloud auth login
#
# Usage:
#   export PROJECT_ID=your-gcp-project
#   export REGION=us-central1          # or asia-south1
#   export ZONE=us-central1-a
#   export VM_NAME=loop-meetnote-vm
#   export DOMAIN=example.com          # your base domain
#   bash deploy/gcp-provision.sh
set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID}"
: "${REGION:=us-central1}"
: "${ZONE:=${REGION}-a}"
: "${VM_NAME:=loop-meetnote-vm}"
: "${MACHINE_TYPE:=e2-medium}"
: "${BOOT_DISK_GB:=30}"
: "${DATA_DISK_GB:=30}"

gcloud config set project "$PROJECT_ID"

echo "Creating reserved static IP..."
gcloud compute addresses create "${VM_NAME}-ip" --region="$REGION" --quiet 2>/dev/null || true
STATIC_IP=$(gcloud compute addresses describe "${VM_NAME}-ip" --region="$REGION" --format='value(address)')
echo "Static IP: $STATIC_IP"

echo "Creating firewall rules..."
for rule in \
  "allow-http-https:tcp:80,443" \
  "allow-livekit-sig:tcp:7880,7881" \
  "allow-livekit-media:udp:50000-50020"; do
  IFS=: read -r name proto ports <<< "$rule"
  gcloud compute firewall-rules create "$name" \
    --allow="$proto:$ports" --source-ranges=0.0.0.0/0 --quiet 2>/dev/null || true
done

echo "Creating data disk..."
gcloud compute disks create "${VM_NAME}-data" \
  --size="${DATA_DISK_GB}GB" --type=pd-standard --zone="$ZONE" --quiet 2>/dev/null || true

echo "Creating VM..."
gcloud compute instances create "$VM_NAME" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud \
  --boot-disk-size="${BOOT_DISK_GB}GB" --boot-disk-type=pd-balanced \
  --address="$STATIC_IP" \
  --disk="name=${VM_NAME}-data,auto-delete=no" \
  --tags=http-server,https-server,livekit \
  --quiet

echo ""
echo "=== PROVISIONED ==="
echo "VM:        $VM_NAME ($ZONE)"
echo "Static IP: $STATIC_IP"
echo ""
echo "Next steps:"
echo "  1. Point DNS A records (loop, meetnote, meetnote-api, livekit) -> $STATIC_IP"
echo "  2. SSH: gcloud compute ssh $VM_NAME --zone=$ZONE"
echo "  3. On the VM run: sudo bash /opt/loop/deploy/gcp-vm-bootstrap.sh"
EOF
echo "Done"
