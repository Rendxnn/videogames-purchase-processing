#!/bin/bash
set -euo pipefail

PROJECT_ID="streaming-prod-475121"
TOPIC_ID="events.raw"
DATASET_URI="gs://streaming-prod-dl/curated/games_march2025_cleaned.csv"
APP_DIR="/opt/purchases-emitter"
VENV_DIR="${APP_DIR}/venv"
LOG_DIR="/var/log/purchases-emitter"
PY="${VENV_DIR}/bin/python"

mkdir -p "$APP_DIR" "$LOG_DIR"
apt-get update -y
apt-get install -y python3 python3-venv python3-pip

python3 -m venv "$VENV_DIR"
${PY} -m pip install --upgrade pip

cat > "${APP_DIR}/emitter.py" <<'PY'
#!/usr/bin/env python3
import os, sys, csv, json, time, uuid, random, traceback
from datetime import datetime, timezone
from typing import List, Tuple, Dict
from urllib.parse import urlparse
from google.cloud import pubsub_v1, storage

PROJECT_ID = os.getenv("PROJECT_ID", "streaming-prod-475121")
TOPIC_ID   = os.getenv("TOPIC_ID", "events.raw")
DATASET_URI= os.getenv("DATASET_URI", "gs://streaming-prod-dl/curated/games_march2025_cleaned.csv")
INTERVAL_S = float(os.getenv("INTERVAL_S", "0.25"))
LIMIT_ROWS = os.getenv("LIMIT_ROWS")

def log(m): print(m, flush=True)
def loge(m): print(m, file=sys.stderr, flush=True)
def iso_utc(): return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def download_if_gcs(path: str) -> str:
    if path.startswith("gs://"):
        u = urlparse(path, allow_fragments=False)
        local = "/tmp/dataset.csv"
        client = storage.Client()
        b = client.bucket(u.netloc).blob(u.path.lstrip("/"))
        if not b.exists(): raise FileNotFoundError(f"No existe el objeto: {path}")
        b.download_to_filename(local)
        return local
    return path

def to_float(v, default):
    try: return float(v)
    except: return default

def load_games(csv_path: str, limit: int|None) -> Tuple[list[dict], list[float]]:
    games, weights = [], []
    with open(csv_path, newline="", encoding="utf-8") as f:
        r = csv.DictReader(f)
        for row in r:
            price = to_float(row.get("price"), round(random.uniform(5,70),2))
            game = {
                "game_id":  row.get("game_id") or row.get("id") or str(uuid.uuid4()),
                "game_name":row.get("game_name") or row.get("name") or "Unknown Game",
                "platform": row.get("platform") or "PC",
                "price":    price,
                "currency": row.get("currency") or "USD",
                "genre":    row.get("genre"),
                "publisher":row.get("publisher"),
            }
            w = to_float(row.get("weight"), 1.0)
            games.append(game); weights.append(w if w>0 else 1.0)
            if limit and len(games) >= limit: break
    if not games: raise RuntimeError("No se cargaron juegos")
    return games, weights

def rand_user(): return f"user-{random.randint(1,500000):06d}"
def rand_region(): return random.choice(["NA","SA","EU","AS","AF","OC"])
def rand_qty(): return 1 if random.random()<0.95 else random.randint(2,5)

def build_event(game: dict) -> dict:
    qty = rand_qty()
    total = round(game["price"]*qty,2)
    return {
        "event_id": str(uuid.uuid4()),
        "source": "games_synth_vm",
        "event_ts": iso_utc(),
        "entity_id": rand_user(),
        "payload": {
            "type": "purchase",
            "game_id": game["game_id"],
            "game_name": game["game_name"],
            "platform": game["platform"],
            "genre": game.get("genre"),
            "publisher": game.get("publisher"),
            "unit_price": game["price"],
            "quantity": qty,
            "total_price": total,
            "currency": game["currency"],
            "region": rand_region(),
        }
    }

def main():
    log(f"[boot] PROJ={PROJECT_ID} TOPIC={TOPIC_ID} DATASET={DATASET_URI}")
    path = download_if_gcs(DATASET_URI)
    lim = int(LIMIT_ROWS) if LIMIT_ROWS else None
    games, weights = load_games(path, lim)
    log(f"[boot] Juegos cargados: {len(games)}")
    pub = pubsub_v1.PublisherClient()
    topic_path = pub.topic_path(PROJECT_ID, TOPIC_ID)
    pub.publish(topic_path, b'{"healthcheck":true}').result(10)
    log("[boot] Pub/Sub OK")
    while True:
        game = random.choices(games, weights=weights, k=1)[0]
        evt = build_event(game)
        pub.publish(topic_path, json.dumps(evt).encode("utf-8"))
        time.sleep(INTERVAL_S)

if __name__ == "__main__":
    try: main()
    except Exception as e:
        loge("[FATAL] " + repr(e)); traceback.print_exc(); sys.exit(1)

PY
chmod +x "${APP_DIR}/emitter.py"

cat > "${APP_DIR}/requirements.txt" <<'REQ'
google-cloud-pubsub==2.21.5
google-cloud-storage==2.18.2

REQ

${PY} -m pip install -r "${APP_DIR}/requirements.txt"

cat > /etc/systemd/system/purchases-emitter.service <<'UNIT'
[Unit]
Description=Purchases Emitter (Pub/Sub)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/purchases-emitter
Environment=PROJECT_ID=streaming-prod-475121
Environment=TOPIC_ID=events.raw
Environment=DATASET_URI=gs://streaming-prod-dl/curated/games_march2025_cleaned.csv
Environment=INTERVAL_S=0.25
Environment=LIMIT_ROWS=5000
ExecStart=/opt/purchases-emitter/venv/bin/python /opt/purchases-emitter/emitter.py
Restart=always
RestartSec=5
StandardOutput=append:/var/log/purchases-emitter/emitter.log
StandardError=append:/var/log/purchases-emitter/emitter.err

[Install]
WantedBy=multi-user.target

UNIT

systemctl daemon-reload
systemctl enable purchases-emitter
systemctl start purchases-emitter
