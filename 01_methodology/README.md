# 01 · Metodología y Planeación

Este documento resume la metodología y la planeación del proyecto “Videogames Purchase Real‑Time Processing”. Seguimos TDSP (Team Data Science Process) como marco liviano, con énfasis especial en Business Understanding. La implementación técnica se alinea con la arquitectura propuesta en el README principal (GCP + streaming/Kappa).

---

## 1. Business Understanding (más importante)

- Objetivo de negocio: analizar el comportamiento de compra de videojuegos en tiempo real para detectar tendencias, entender patrones por género/categoría y estimar ventas, habilitando decisiones rápidas (promociones, inventario digital, featured lists).
- Preguntas clave:
  - ¿Qué géneros y categorías muestran mayor tracción por ventana temporal (hora/día/semana)?
  - ¿Qué juegos muestran “picos” de interés (p. ej., `peak_ccu`) que anteceden compras?
  - ¿Cómo impactan descuentos (`discount`) y reseñas/score en la demanda?
  - ¿Qué señales tempranas ayudan a proyectar ventas a corto plazo?
- KPIs de negocio:
  - Ventas estimadas y tasa de crecimiento por género/categoría.
  - Ingresos estimados y precio promedio ponderado (`price`).
  - Conversión proxy: relación entre señales de interés (reseñas recientes, `peak_ccu`) y compras simuladas.
  - Efecto de descuento en demanda (uplift vs. baseline).
- Métricas de modelo:
  - MAE/MAPE de predicción de demanda a corto plazo por juego/género.
  - F1/ROC-AUC para clasificación de “tendencia” (spike/no spike), si aplica.
- Supuestos y alcance:
  - Eventos de compra se simulan y se enriquecen con catálogos estáticos del dataset de Steam (archivo cleaned de marzo 2025).
  - El archivo contiene campos como `appid`, `name`, `price`, `genres`, `categories`, `estimated_owners`, `peak_ccu`, `discount`, reseñas y metadatos de plataforma; estos alimentan features.
  - El sistema es streaming-first (Kappa) y prioriza latencia baja y escalabilidad.

---

## 2. Data Acquisition & Understanding

- Fuentes:
  - Catálogo batch: `archive/games_march2025_cleaned.csv` (columnas ejemplo: `appid,name,release_date,price,genres,categories,estimated_owners,peak_ccu,discount,user_score,pct_pos_recent,num_reviews_recent,…`).
  - Flujo streaming: simulador de compras (Pub/Sub) que emite eventos mínimos: `event_time, appid, price, discount, platform, region, quantity` y que se enriquece con el catálogo (género, publisher, tags).
- Calidad y perfilamiento:
  - Validar unicidad de `appid`, rangos de `price` y `discount`, consistencia de `genres/categories` y cobertura de `peak_ccu`.
  - Manejo de texto largo (`detailed_description`) solo como fuente secundaria de features si se usa más adelante.
- Esquemas (propuesta):
  - Catalog (BigQuery/Parquet): clave `appid`, campos descriptivos, métricas históricas.
  - Purchases (stream): clave compuesta (`event_time`, `appid`), atributos de transacción + enriquecimiento.

---

## 3. Modeling

- Problemas a resolver:
  - Predicción de demanda a corto plazo (por juego/género). Baseline: agregación por ventanas + modelo de regresión (XGBoost/ElasticNet). Alternativa: series temporales (ARIMA/Prophet) por clústeres de juegos.
  - Detección de tendencias/spikes: clasificación binaria usando features de ventana (picos de `peak_ccu`, cambios en `discount`, reseñas recientes).
- Features iniciales:
  - Ventanas móviles (1h/6h/24h) de conteos y montos, `discount` actual y delta, `peak_ccu`, señales recientes de reseñas (`pct_pos_recent`, `num_reviews_recent`), género/categoría one‑hot o embeddings simples.
- Evaluación:
  - Backtesting en ventanas recientes con separación temporal. Métricas MAE/MAPE para regresión; F1/ROC-AUC para clasificación.

---

## 4. Deployment

- Ingesta y streaming: Cloud Functions (simulador) -> Pub/Sub -> Dataflow (Apache Beam) para limpieza, enriquecimiento y agregación por ventanas.
- Almacenamiento:
  - Datalake: Cloud Storage (Parquet) para histórico batch del catálogo y compras.
  - Analítico: BigQuery para consultas y features offline.
  - Real-time: Bigtable/Firestore para métricas recientes expuestas a dashboards.
- Serving de modelo: Vertex AI Endpoint o Cloud Run; inferencia online sobre agregados recientes.
- Visualización: Grafana/Looker Studio con KPIs de negocio y métricas de modelo.

---

## 5. Customer Acceptance & MLOps (Nivel 3)

- Monitorización:
  - Data drift y performance del modelo (Vertex Model Monitoring + métricas custom).
  - SLA de latencia del pipeline de streaming y tasa de error.
- Retraining automático:
  - Triggers por degradación de MAPE/F1 o drift significativo.
  - Pipelines en Vertex AI orquestados (Composer/Scheduler) con versionado de modelos y rollback.
- Evidencia de aceptación:
  - Reporte con KPIs de negocio antes/después de cambios (ej. promociones por `discount`).
  - Dashboards con vistas por género/categoría y ranking de tendencia.

---

## Plan de Trabajo (alto nivel)

1) Preparación de datos (catálogo + validaciones)
- Definir esquema del catálogo y diccionario de datos.
- Validar columnas clave del CSV cleaned (muestras y tipos).

2) Simulador e ingesta streaming
- Diseñar evento mínimo de compra y mapa de enriquecimiento con el catálogo.
- Publicación en Pub/Sub + Dataflow para ETL y agregaciones por ventanas.

3) Persistencia y consultas
- Escribir histórico en GCS (Parquet) y métricas en BigQuery.
- Exponer métricas recientes en Bigtable/Firestore para dashboards.

4) Modelado y evaluación
- Entrenar baseline (regresión o serie temporal) y medir MAE/MAPE.
- Opcional: clasificador de tendencias con ventanas recientes.

5) Despliegue + MLOps
- Empaquetar modelo (CI/CD), servir en Vertex/Cloud Run.
- Configurar monitoreo, alertas y retraining automatizado.

6) Visualización y aceptación
- Construir dashboards con KPIs prioritarios.
- Validación con stakeholders y criterios de éxito.

---

## Entregables

- Pipelines de streaming (Dataflow/Beam) y simulador de eventos.
- Esquemas y almacenamiento (GCS Parquet, BigQuery, Bigtable/Firestore).
- Modelos entrenados + endpoints de inferencia.
- Dashboards (Grafana/Looker) y reporte de aceptación.
- Guía de despliegue y reproducibilidad (GCP/Infra como código).

---

## Riesgos y mitigaciones

- Calidad/ruido en señales públicas (reseñas, `peak_ccu`): suavizar con ventanas y robustez.
- Sparsity por juego: agrupar por género/categoría y/o buckets de popularidad.
- Costos en nube: muestrear simulaciones y usar cuotas/alertas.
- Deriva del comportamiento: monitoreo y retraining programado.

---

## Supuestos de datos (del CSV cleaned)

- Columnas relevantes observadas: `appid, name, release_date, price, genres, categories, estimated_owners, peak_ccu, discount, user_score, pct_pos_recent, num_reviews_recent, …`.
- Se usará `appid` como llave para enriquecer eventos de compra y construir features.
- `discount` y `peak_ccu` se consideran señales de impulso de demanda; reseñas recientes como contexto adicional.

---

## Criterios de éxito

- Dashboards en tiempo real con KPIs accionables por género/categoría.
- MAE/MAPE dentro de umbrales acordados para proyecciones de corto plazo.
- Pipeline estable con latencia y disponibilidad dentro de SLA.
- Evidencia de impacto de descuentos en la demanda (uplift medible).

