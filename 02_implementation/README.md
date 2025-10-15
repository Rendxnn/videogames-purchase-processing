# Streaming Data Project — `streaming-prod-475121`

Este repositorio documenta y contiene los artefactos para un **pipeline de streaming** con **Google Cloud**:

- **Fuente viva**: una **VM de Compute Engine** que genera **compras de videojuegos** a partir de un dataset en GCS.
- **Transporte**: **Pub/Sub** (`events.raw`).
- **Atterrizaje/Analítica**: **Dataflow** (template gestionada) que escribe en **BigQuery** (`analytics.purchases_events`).

> Proyecto: `streaming-prod-475121` · Región: `us-central1` · Zona VM: `us-central1-a` · Bucket datalake: `gs://streaming-prod-dl`

## Estructura

```
.
├─ README.md                                # Este documento
├─ emitter-vm/                              # Fuente viva en VM (código y servicio)
│  ├─ README.md
│  ├─ emitter.py
│  ├─ requirements.txt
│  ├─ purchases-emitter.service
│  └─ startup.sh
├─ infra/
│  ├─ pubsub_setup.md                       # Creación de topics/subs + IAM
│  ├─ bigquery_setup.sql                    # Dataset + tabla particionada
│  └─ dataflow/
│     ├─ README.md                          # Lanzar Dataflow (UI/CLI)
│     └─ transform.js                       # (opcional) UDF JS para derivar event_date
└─ scripts/
   ├─ create_pubsub.sh
   ├─ create_dataflow_job.sh
   └─ verify_pubsub.sh
```

## Flujo de alto nivel

1. **VM** (servicio `purchases-emitter`) lee `gs://streaming-prod-dl/curated/games_march2025_cleaned.csv`, genera compras y **publica** JSON a `events.raw`.
2. **Pub/Sub** enruta mensajes. `events.raw.df` es la sub consumida por Dataflow.
3. **Dataflow** (template) **inserta** en **BigQuery** (`analytics.purchases_events`, particionada por `event_date`).
4. (Opcional) Vista `analytics.vw_purchases_curated` para dashboards.

## Prerrequisitos (GCP)

- Facturación activa en el proyecto `streaming-prod-475121`.
- APIs habilitadas: Artifact Registry, Cloud Build (si se usa), Pub/Sub, Dataflow, BigQuery, Compute Engine.
- Datalake: Bucket **`gs://streaming-prod-dl`** con dataset en **`curated/games_march2025_cleaned.csv`**.

## Pasos resumidos

1) **Pub/Sub**: crear `events.raw`, `events.raw.df` y DLQ (`events.raw.dlq`).  
2) **BigQuery**: crear dataset `analytics` y tabla `purchases_events`.  
3) **VM**: crear SA `vm-emitter-sa`, crear VM `vm-purchases-emitter` y arrancar servicio.  
4) **Dataflow**: lanzar **Pub/Sub → BigQuery** leyendo `events.raw.df`.  
5) **Verificación**: ver mensajes (Pub/Sub), filas (BQ), logs (VM).

> Detalles completos en los README específicos de cada carpeta.
