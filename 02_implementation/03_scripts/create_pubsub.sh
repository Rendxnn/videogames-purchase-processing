#!/usr/bin/env bash
set -euo pipefail
PROJECT_ID="streaming-prod-475121"
gcloud config set project $PROJECT_ID
gcloud pubsub topics create events.raw --project $PROJECT_ID || true
gcloud pubsub topics create events.raw.dlq --project $PROJECT_ID || true
gcloud pubsub subscriptions create events.raw.dlq-sub --topic=events.raw.dlq --project $PROJECT_ID || true
gcloud pubsub subscriptions create events.raw.df   --topic=events.raw   --ack-deadline=60   --message-retention-duration=604800s   --dead-letter-topic=projects/$PROJECT_ID/topics/events.raw.dlq   --max-delivery-attempts=5   --project $PROJECT_ID || true
