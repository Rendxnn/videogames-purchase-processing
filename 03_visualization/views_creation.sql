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
