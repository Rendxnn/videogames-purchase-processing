# Pub/Sub — creación de tópicos y subs

## Recursos
- Topic: **`events.raw`**
- Dead-letter Topic: **`events.raw.dlq`**
- Subs:
  - **`events.raw.df`** (para Dataflow)
  - **`events.raw.dlq-sub`** (para monitorear DLQ)

## Comandos (Cloud Shell)

```bash
PROJECT_ID="streaming-prod-475121"
gcloud config set project $PROJECT_ID

# Topic principal
gcloud pubsub topics create events.raw --project $PROJECT_ID || true

# DLQ
gcloud pubsub topics create events.raw.dlq --project $PROJECT_ID || true
gcloud pubsub subscriptions create events.raw.dlq-sub   --topic=events.raw.dlq --project $PROJECT_ID || true

# Sub para Dataflow (con DLQ)
gcloud pubsub subscriptions create events.raw.df   --topic=events.raw   --ack-deadline=60   --message-retention-duration=604800s   --dead-letter-topic=projects/$PROJECT_ID/topics/events.raw.dlq   --max-delivery-attempts=5   --project $PROJECT_ID || true
```

## Ver mensajes (debug temporal)
```bash
gcloud pubsub subscriptions create debug-events --topic=events.raw --project $PROJECT_ID
gcloud pubsub subscriptions pull debug-events --limit=5 --auto-ack
gcloud pubsub subscriptions delete debug-events --project $PROJECT_ID
```
