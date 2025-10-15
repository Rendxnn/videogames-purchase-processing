# Fuente viva en VM — `emitter-vm/`

Esta carpeta contiene el **emisor** que corre en una **VM de Compute Engine** y publica eventos en **Pub/Sub**.

## Qué hace
- Descarga el dataset de juegos desde **GCS** (`gs://streaming-prod-dl/curated/games_march2025_cleaned.csv`).
- Genera **compras aleatorias** (JSON) cada `INTERVAL_S` segundos.
- Publica a **Pub/Sub** tópico **`events.raw`**.

## Variables (service unit)
Configura en `purchases-emitter.service`:
- `PROJECT_ID=streaming-prod-475121`
- `TOPIC_ID=events.raw`
- `DATASET_URI=gs://streaming-prod-dl/curated/games_march2025_cleaned.csv`
- `INTERVAL_S=0.25` (cadencia)
- `LIMIT_ROWS=5000` (opcional: máximo filas leídas del CSV)

## Crear Service Account e IAM mínimos
```bash
PROJECT_ID="streaming-prod-475121"
SA_NAME="vm-emitter-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create "$SA_NAME" --display-name="VM Emitter SA"
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:${SA_EMAIL}" --role="roles/storage.objectViewer"
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:${SA_EMAIL}" --role="roles/pubsub.publisher"
```

## Crear la VM (zona `us-central1-a`)
```bash
ZONE="us-central1-a"
gcloud compute instances create vm-purchases-emitter   --zone="$ZONE"   --machine-type=e2-small   --service-account="$SA_EMAIL"   --scopes=https://www.googleapis.com/auth/cloud-platform   --metadata-from-file startup-script=./startup.sh
```

> El script de arranque instala Python, dependencias, copia `emitter.py`, crea el **servicio systemd** y lo inicia.

## Operación (en la VM via SSH)

```bash
# Estado / control del servicio
sudo systemctl status purchases-emitter
sudo systemctl restart purchases-emitter
sudo systemctl stop purchases-emitter
sudo systemctl start purchases-emitter

# Logs
sudo journalctl -u purchases-emitter -n 100 --no-pager
sudo tail -n 50 /var/log/purchases-emitter/emitter.log
sudo tail -n 50 /var/log/purchases-emitter/emitter.err
```

## Verificar mensajes en Pub/Sub (desde Cloud Shell)
```bash
gcloud pubsub subscriptions create debug-events --topic=events.raw
gcloud pubsub subscriptions pull debug-events --limit=5 --auto-ack
gcloud pubsub subscriptions delete debug-events
```
