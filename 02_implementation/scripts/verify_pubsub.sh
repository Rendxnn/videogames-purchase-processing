#!/usr/bin/env bash
set -euo pipefail
PROJECT_ID="streaming-prod-475121"
gcloud config set project $PROJECT_ID
gcloud pubsub subscriptions create debug-events --topic=events.raw --project $PROJECT_ID || true
gcloud pubsub subscriptions pull debug-events --limit=5 --auto-ack
gcloud pubsub subscriptions delete debug-events --project $PROJECT_ID || true
