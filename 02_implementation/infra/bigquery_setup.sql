-- Dataset
-- Ejecutar en Cloud Shell o UI de BigQuery con location=US
-- Crea dataset si no existe:
-- bq --location=US mk -d streaming-prod-475121:analytics

-- Tabla landing particionada por day
CREATE TABLE IF NOT EXISTS `streaming-prod-475121.analytics.purchases_events` (
  event_id   STRING,
  source     STRING,
  event_ts   TIMESTAMP,
  entity_id  STRING,
  event_date DATE,
  payload    JSON
)
PARTITION BY event_date;

-- Vista curada (opcional)
CREATE OR REPLACE VIEW `streaming-prod-475121.analytics.vw_purchases_curated` AS
SELECT
  event_id,
  source,
  event_ts,
  event_date,
  entity_id AS buyer_id,
  payload.game_id,
  payload.game_name,
  payload.platform,
  payload.genre,
  payload.publisher,
  CAST(payload.unit_price  AS FLOAT64) AS unit_price,
  CAST(payload.quantity    AS INT64)   AS quantity,
  CAST(payload.total_price AS FLOAT64) AS total_price,
  payload.currency,
  payload.region
FROM `streaming-prod-475121.analytics.purchases_events`;
