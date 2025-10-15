
# Visualización en tiempo real con Looker Studio (sobre BigQuery)

[Ver dashboard](https://lookerstudio.google.com/reporting/548afb3d-cc7b-4616-ae30-b4152dd53015) 

> Proyecto: **streaming-prod-475121**  
> Dataset de BigQuery: **`analytics`**  
> Vistas de análisis en tiempo real:  
> - `analytics.vw_purchases_curated`  
> - `analytics.vw_rt_timeseries_1m`  
> - `analytics.vw_rt_top_games`  
> - `analytics.vw_rt_platform_mix`  
> - `analytics.vw_rt_region_mix`  

---

## 1) Objetivo

Publicar eventos de compras (videojuegos) en **Pub/Sub**, ingerirlos con **Dataflow** hacia **BigQuery**, y **visualizarlos en tiempo casi real** con **Looker Studio**, usando vistas optimizadas para dashboards.

---

## 2) Prerrequisitos verificados

- Pipeline en ejecución (**VM → Pub/Sub → Dataflow → BigQuery**).  
- Tabla de aterrizaje: `analytics.purchases_events` con esquema RECORD para `payload`.  
- Vistas (SQL de referencia):

```sql
-- Vista base curada
CREATE OR REPLACE VIEW `streaming-prod-475121.analytics.vw_purchases_curated` AS
SELECT
  event_id, source, event_ts, DATE(event_ts) AS event_date,
  entity_id AS buyer_id,
  payload.game_id, payload.game_name, payload.platform, payload.genre, payload.publisher,
  CAST(payload.unit_price AS FLOAT64)  AS unit_price,
  CAST(payload.quantity   AS INT64)    AS quantity,
  CAST(payload.total_price AS FLOAT64) AS total_price,
  payload.currency, payload.region
FROM `streaming-prod-475121.analytics.purchases_events`;

-- Serie temporal por minuto (últimos 60 minutos)
CREATE OR REPLACE VIEW `streaming-prod-475121.analytics.vw_rt_timeseries_1m` AS
SELECT TIMESTAMP_TRUNC(event_ts, MINUTE) AS minute,
       COUNT(*) AS purchases,
       SUM(total_price) AS revenue
FROM `streaming-prod-475121.analytics.vw_purchases_curated`
WHERE event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 60 MINUTE)
GROUP BY minute;

-- Top juegos (última hora)
CREATE OR REPLACE VIEW `streaming-prod-475121.analytics.vw_rt_top_games` AS
SELECT game_name, COUNT(*) purchases, SUM(total_price) revenue
FROM `streaming-prod-475121.analytics.vw_purchases_curated`
WHERE event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 60 MINUTE)
GROUP BY game_name
ORDER BY revenue DESC;

-- Mix por plataforma (última hora)
CREATE OR REPLACE VIEW `streaming-prod-475121.analytics.vw_rt_platform_mix` AS
SELECT platform, COUNT(*) purchases, SUM(total_price) revenue
FROM `streaming-prod-475121.analytics.vw_purchases_curated`
WHERE event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 60 MINUTE)
GROUP BY platform
ORDER BY revenue DESC;

-- Mix por región (última hora)
CREATE OR REPLACE VIEW `streaming-prod-475121.analytics.vw_rt_region_mix` AS
SELECT region, COUNT(*) purchases, SUM(total_price) revenue
FROM `streaming-prod-475121.analytics.vw_purchases_curated`
WHERE event_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 60 MINUTE)
GROUP BY region
ORDER BY revenue DESC;
```

> Estas vistas limitan la ventana a la **última hora** para que el dashboard sea ágil y económico. Ajustar el intervalo si se requiere más historia.

---

## 3) Crear el reporte en Looker Studio

1. Abrir **Looker Studio** → **Create → Report** → conector **BigQuery**.  
2. Seleccionar el proyecto **streaming-prod-475121** y el dataset **analytics**.  
3. Añadir como fuentes de datos las vistas:
   - `vw_rt_timeseries_1m`
   - `vw_rt_top_games`
   - `vw_rt_platform_mix`
   - `vw_rt_region_mix`

> **Importante:** En cada **fuente de datos**, establecer la **Dimensión de rango de fechas** en **`event_ts`** (o `minute` en el caso de la serie temporal). Si se deja una fecha NULL (p. ej. `event_date`), los gráficos aparecerán vacíos.

---

## 4) Construir las páginas y gráficos

**Página 1 – Tiempo real (últimos 60 min)**  
- **Gráfico de serie temporal**  
  - Fuente: `vw_rt_timeseries_1m`  
  - Dimensión: **`minute`**  
  - Métricas: **`purchases`**, **`revenue`**  
- **Indicadores** (scorecards): compras totales y revenue total (últimos 60 min).

**Página 2 – Top juegos (última hora)**  
- **Tabla**  
  - Fuente: `vw_rt_top_games`  
  - Columnas: `game_name`, `purchases`, `revenue`  
  - Orden: `revenue` desc.

**Página 3 – Mix por plataforma / región (última hora)**  
- **Barras apiladas o pastel** con `platform` y `region`.  
  - Fuente: `vw_rt_platform_mix`, `vw_rt_region_mix`  
  - Métricas: `purchases`, `revenue`.

**Filtros y controles**  
- Agregar **control de periodo** (Date range control) con valor predeterminado **“Última hora”**.  
- Opcional: filtros por `platform`, `region`, `game_name`.

**Auto-refresh**  
- **Archivo → Configuración del reporte → Auto refresh:** cada **1 minuto**.

---

## 5) Optimización y costos

- Activar **BigQuery BI Engine** (2–4 GB) para mejorar la latencia de consulta.  
- Mantener ventanas de tiempo razonables (1–24 h).  
- Considerar **materialized views** si se requieren agregaciones sobre grandes volúmenes históricos.

---

## 6) Gobierno y calidad

- Controlar el **esquema** de `purchases_events` y validar nulos en `payload`.  
- Versionar SQL de vistas y documentar cambios.  
- (Opcional) Añadir **DLQ** en Pub/Sub y **tabla de errores** en Dataflow para auditoría.

---

## 7) Solución de problemas (FAQ)

- **El gráfico sale vacío:** revisa que la **dimensión de rango de fechas** use `event_ts`/`minute` y que el **periodo** del reporte incluya **HOY** (o **última hora**).  
- **No se actualiza:** habilitar **Auto refresh** y verificar que el **job de Dataflow** esté **Running**.  
- **Errores de escritura en BQ:** revisar **Dataflow → Logs/Métricas**; típicamente son por esquema incompatible.

---

## 8) Enlaces y multimedia

- **Enlace al reporte de Looker Studio:** *[PEGA AQUÍ EL LINK DEL REPORTE]*

### Capturas (espacios reservados)
> Inserta las imágenes para tu entrega final reemplazando los paths:

<img width="966" height="677" alt="image" src="https://github.com/user-attachments/assets/be84942c-c043-437e-85d9-79c48a0c2b94" />


<img width="854" height="339" alt="image" src="https://github.com/user-attachments/assets/c38b306a-155e-44d4-a4ba-ed5cc9ed3251" />

<img width="440" height="268" alt="image" src="https://github.com/user-attachments/assets/9e22ae68-722f-44e0-98e2-0061896a257c" />


<img width="643" height="340" alt="image" src="https://github.com/user-attachments/assets/edd1b4c0-2023-4bf5-bd5a-dd1b41a13812" />


---

## 9) Estructura de artefactos del proyecto

```
streaming-prod-475121/
├── pubsub: topic events.raw, subs events.raw.df (+ opcional debug-events, DLQ)
├── dataflow: job Pub/Sub → BigQuery (streaming)
├── gcs: gs://streaming-prod-dl/{curated/, tmp/, templates/}
├── bigquery:
│   ├── analytics.purchases_events (landing)
│   └── analytics.vw_* (vistas para dashboard)
└── looker-studio: reporte conectado a vistas vw_rt_*
```
