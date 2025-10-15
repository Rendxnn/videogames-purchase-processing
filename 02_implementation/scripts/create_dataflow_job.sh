#!/usr/bin/env bash
set -euo pipefail
PROJECT_ID="streaming-prod-475121"
REGION="us-central1"
STAGING_GCS="gs://streaming-prod-dl/tmp"
SA="dataflow-sa@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud dataflow jobs run "df-ps2bq-purchases-$(date +%Y%m%d-%H%M%S)"   --gcs-location="gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery"   --region=$REGION   --service-account-email="$SA"   --staging-location="$STAGING_GCS"   --parameters inputSubscription="projects/$PROJECT_ID/subscriptions/events.raw.df",outputTableSpec="$PROJECT_ID:analytics.purchases_events",useStorageWriteApi="true",writeDisposition="WRITE_APPEND",javascriptTextTransformGcsPath="gs://streaming-prod-dl/templates/transform.js",javascriptTextTransformFunctionName="transform"
