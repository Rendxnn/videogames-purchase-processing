# Videogames Purchase Real-Time Processing

---

**Universidad EAFIT**  
**Curso:** ST1630 – Sistemas Intensivos en Datos (2025-2)  
**Profesor:** Edwin Montoya  
**Proyecto Final + Reto 4 (Nivel 3 MLOps)**  

---

## Integrantes
   
- Alejando Arango Mejía – aarangom1@eafit.edu.co  
- Samuel Rendón Trujillo – srendont@eafit.edu.co  
- Thomas Rivera Fernandez – triveraf@eafit.edu.co  

---

## Descripción del caso

### Caso de negocio  
Este proyecto busca implementar un **sistema de procesamiento en tiempo real de compras de videojuegos** utilizando datos del dataset de [Steam Games Dataset de Kaggle](https://www.kaggle.com/datasets/artermiloff/steam-games-dataset).

El objetivo es **analizar el comportamiento de compra** en diferentes categorías y géneros, para **detectar tendencias emergentes, patrones de consumo, y estimar ventas en tiempo real**.  
Los resultados se presentarán en **dashboards de visualización interactiva**, y se incluirá un modelo predictivo de **tendencia de ventas** automatizado con **MLOps Nivel 3 (monitorización + reentrenamiento)**.

### Caso tecnológico  
El sistema será desplegado en **Google Cloud Platform (GCP)** y empleará una **arquitectura de procesamiento de datos en streaming (Kappa Architecture)**.  
El reto principal consiste en **diseñar e implementar una solución escalable y reproducible** que integre:

- Ingesta continua de datos simulados de compras.  
- Procesamiento en streaming para agregación y detección de eventos.  
- Almacenamiento en datalake (batch) y bases NoSQL (real-time).  
- Entrenamiento y despliegue automatizado de un modelo de predicción de demanda.  
- Visualización de métricas de negocio y de modelo en **Grafana / Looker Studio**.  
- Monitoreo del modelo y **reentrenamiento automático** mediante Vertex AI Pipelines.

---

## Metodología Analítica: TDSP (Team Data Science Process)

Se empleará la metodología **TDSP** de Microsoft para estructurar el desarrollo del proyecto:

| Etapa | Descripción | Entregable |
|-------|--------------|------------|
| **1. Business Understanding** | Definición del problema, hipótesis, KPIs y métricas de éxito. | Documento de requerimientos analíticos. |
| **2. Data Acquisition & Understanding** | Exploración del dataset de Steam (géneros, precios, reseñas, compras), simulación de flujo de compras en tiempo real. | Scripts de ingestión batch y streaming. |
| **3. Modeling** | Diseño y entrenamiento del modelo de predicción (ej. ARIMA/XGBoost). | Notebook + pipeline de entrenamiento Vertex AI. |
| **4. Deployment** | Despliegue del modelo como servicio (Cloud Run o Vertex AI Endpoint). | API REST + dashboard de monitoreo. |
| **5. Customer Acceptance & Feedback Loop** | Validación del modelo en producción, monitoreo, métricas y retraining automático. | Reporte de rendimiento + evidencias Grafana. |

---

## Arquitectura de referencia en GCP

### Mapeo de componentes

| Componente | Servicio GCP | Función principal |
|-------------|--------------|-------------------|
| **Fuente de datos (Batch/Streaming)** | Cloud Function + Pub/Sub | Simulación y publicación de eventos de compra. |
| **Ingesta y procesamiento** | Dataflow (Apache Beam) | Limpieza, enriquecimiento y agregación de eventos. |
| **Datalake** | Cloud Storage | Almacenamiento histórico (Parquet). |
| **Base de datos NoSQL** | Bigtable / Firestore | Acceso en tiempo real a compras y métricas. |
| **Almacenamiento analítico** | BigQuery | Análisis y consultas agregadas. |
| **Model Training / Reentrenamiento** | Vertex AI Pipelines | Entrenamiento automatizado + registro de modelos. |
| **Model Serving (inferencias)** | Vertex AI Endpoint / Cloud Run | Servicio de predicción en línea. |
| **Monitoreo del modelo** | Vertex Model Monitoring / Grafana | Detección de drift, calidad y rendimiento. |
| **Visualización** | Looker Studio / Grafana | Dashboards de KPIs de ventas y métricas del modelo. |
| **Orquestación** | Cloud Composer / Cloud Scheduler | Coordinación de pipelines y tareas periódicas. |
| **Infraestructura como código** | Terraform / gcloud CLI | Despliegue reproducible de la solución. |

![Arquitectura Videogames Purchases (2)](https://github.com/user-attachments/assets/e9c8dd48-a493-4f5f-bd88-b0cbf2e83808)


---

## Implementación del caso

1. **Identificación de fuentes batch y streaming:**  
   Dataset de Steam + simulador de compras en Pub/Sub.

2. **Adquisición e ingesta:**  
   Dataflow transforma y almacena en BigQuery y GCS.

3. **Desarrollo analítico:**  
   EDA sobre dataset batch; modelo predictivo entrenado con Vertex AI.

4. **Sistema de almacenamiento y visualización:**  
   BigQuery (consulta), Grafana/Looker Studio (visualización en tiempo real).

5. **Arquitectura Kappa:**  
   Flujo unificado streaming-first, sin caminos separados batch/stream.

---

## Documentación y Reproducibilidad

- Guía de configuración paso a paso (GCP, servicios, permisos, despliegue).  
- Código fuente en repositorio GitHub (simulador, pipelines, notebooks, Terraform).  
- Video de sustentación con demo en tiempo real.  
- Evidencias de dashboards y monitoreo del modelo.
