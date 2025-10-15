# Dataflow — Pub/Sub → BigQuery

## Objetivo
Consumir `events.raw.df` y escribir en `analytics.purchases_events` en BigQuery.

## Requisitos
- Service Account: `dataflow-sa@streaming-prod-475121.iam.gserviceaccount.com` con roles:
  - `roles/dataflow.admin`, `roles/dataflow.worker`
  - `roles/pubsub.subscriber`
  - `roles/bigquery.dataEditor`, `roles/bigquery.jobUser`
  - `roles/storage.objectAdmin` (para staging)
  - `roles/logging.logWriter`, `roles/monitoring.metricWriter`
- Bucket de staging: `gs://streaming-prod-dl/tmp`

## Opción A — Lanzar desde la **Consola** (UI)
1. Dataflow → *Create job from template*.
2. Template: **Pub/Sub Subscription to BigQuery**.
3. Job name: `df-ps2bq-purchases-<fecha>`.
4. Region: `us-central1`.
5. *Input subscription*: `projects/streaming-prod-475121/subscriptions/events.raw.df`.
6. *Output table*: `streaming-prod-475121:analytics.purchases_events`.
7. (Opcional) *User-defined function (JavaScript)*:
   - `UDF GCS path`: `gs://streaming-prod-dl/templates/transform.js`
   - `Function name`: `transform`
8. *Service account*: `dataflow-sa@streaming-prod-475121.iam.gserviceaccount.com`.
9. *Temporary location*: `gs://streaming-prod-dl/tmp`.
10. Create.

## Opción B — CLI
```bash
PROJECT_ID="streaming-prod-475121"
REGION="us-central1"
STAGING_GCS="gs://streaming-prod-dl/tmp"
SA="dataflow-sa@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud dataflow jobs run "df-ps2bq-purchases-$(date +%Y%m%d-%H%M%S)"   --gcs-location="gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery"   --region=$REGION   --service-account-email="$SA"   --staging-location="$STAGING_GCS"   --parameters inputSubscription="projects/$PROJECT_ID/subscriptions/events.raw.df",outputTableSpec="$PROJECT_ID:analytics.purchases_events",useStorageWriteApi="true",writeDisposition="WRITE_APPEND",javascriptTextTransformGcsPath="gs://streaming-prod-dl/templates/transform.js",javascriptTextTransformFunctionName="transform"
```

## Validación en BigQuery
```sql
SELECT event_id, source, payload.game_name, payload.total_price, event_ts, event_date
FROM `streaming-prod-475121.analytics.purchases_events`
ORDER BY event_ts DESC
LIMIT 20;
```
