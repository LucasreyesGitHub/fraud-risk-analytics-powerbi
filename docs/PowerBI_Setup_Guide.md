# VaultSentinel Corp — Guía de Construcción del Dashboard en Power BI

> **Fraud Risk Analytics Platform | Power BI Setup & Analysis Guide**
> Lucas Reyes · 2024

---

## Contenido del Repositorio

### Datos disponibles (`/data`)

| Archivo | Contenido |
|---------|-----------|
| `transactions_2024.csv` | 100 transacciones con canal, monto, fraud_flag, risk_score, ml_model_score |
| `customer_risk_profiles.csv` | 50 clientes con tier de riesgo (MINIMAL → CRITICAL), PEP flags |
| `fraud_cases_2024.csv` | 40 casos de investigación con estado, analista asignado, monto recuperado |
| `monthly_channel_summary.csv` | KPIs mensuales pre-agregados por canal (12 meses × 8 canales) |
| `fraud_scenarios_2024.csv` | 10 campañas de fraude narradas (GOLDENWIRE, CREDSTORM, etc.) |

### Medidas DAX disponibles (`/dax`)

| Archivo | Contenido |
|---------|-----------|
| `VaultSentinel_FraudMeasures.dax` | 40+ medidas core: pérdidas, tasas, time intelligence MTD/YTD/YoY |
| `Advanced_DAX_Measures.dax` | 60+ medidas avanzadas: cohortes, anomalías, What-If, F1 Score, scorecard ejecutivo |

---

## Pasos para construir el análisis en Power BI

### Paso 1 — Importar los datos

1. Abrí **Power BI Desktop**
2. Clic en **Obtener datos → Texto/CSV**
3. Importá estos 4 archivos desde la carpeta `/data`:
   - `transactions_2024.csv`
   - `customer_risk_profiles.csv`
   - `fraud_cases_2024.csv`
   - `monthly_channel_summary.csv`
4. Verificá que los tipos de columna sean correctos (fechas como Date, montos como Decimal)

> `fraud_scenarios_2024.csv` es narrativo — no se importa al modelo, es solo referencia.

---

### Paso 2 — Construir el modelo (Star Schema)

En la vista **Modelo**, creá las siguientes relaciones:

```
transactions_2024  ──(customer_id)──▶  customer_risk_profiles
transactions_2024  ──(transaction_id = linked_transaction_id)──▶  fraud_cases_2024
monthly_channel_summary  [tabla independiente — KPIs pre-agregados]
```

**Tabla de fechas:** Creá una dimensión de calendario con nueva tabla DAX:

```dax
Dim_Date =
CALENDAR(DATE(2024,1,1), DATE(2024,12,31))
```

Luego marcala como **Tabla de fechas** (clic derecho → Marcar como tabla de fechas → columna Date).

**Configuración del modelo:**
- Dirección del filtro: **unidireccional** (de dimensiones hacia hechos)
- Cardinalidad: muchos a uno (`*` → `1`) en todas las relaciones

---

### Paso 3 — Importar las medidas DAX

**Opción A — DAX Studio (recomendado):**
1. Descargá DAX Studio desde [daxstudio.org](https://daxstudio.org)
2. Conectate al archivo PBIX abierto
3. Abrí `dax/VaultSentinel_FraudMeasures.dax` y ejecutalo

**Opción B — Pegado manual:**
1. En Power BI, clic en **Nueva medida**
2. Copiá cada medida del archivo `.dax` y pegala una por una

---

### Paso 4 — Aplicar el tema oscuro

1. En la pestaña **Vista**, clic en **Temas → Examinar temas**
2. El JSON del tema está documentado en `docs/Dashboard_Design_Spec.md`
3. Paleta principal:

| Elemento | Color |
|----------|-------|
| Fondo principal | `#0D1117` |
| Fondo de tarjetas | `#161B22` |
| Borde | `#30363D` |
| P0 Crítico | `#FF2D55` |
| P1 Alto | `#FF6B35` |
| P2 Advertencia | `#FFB800` |
| P3 Medio | `#58A6FF` |
| P4 Seguro | `#3FB950` |
| Texto principal | `#F0F6FC` |

---

### Paso 5 — Construir los 6 dashboards

#### Página 1 — Executive Risk Command Center
**Objetivo:** Vista ejecutiva para C-Suite — situational awareness en 30 segundos.

| Visual | Configuración |
|--------|--------------|
| KPI Cards (4) | Net Fraud Loss, Fraud Loss Rate (bps), Detection Rate (%), False Positive Rate (%) |
| Waterfall chart | Desglose de pérdida bruta → recuperación → pérdida neta |
| Heat map de canales | Canal vs. mes, color = fraud_rate_pct |
| Gauge de alertas | Alertas abiertas vs. capacidad del equipo |

**Medidas clave:** `Net Fraud Loss ($)`, `Fraud Loss Rate (bps)`, `Detection Rate (%)`, `YoY Fraud Loss Change (%)`

---

#### Página 2 — Multi-Channel Fraud Intelligence
**Objetivo:** Vista operativa por canal de pago.

| Visual | Configuración |
|--------|--------------|
| Barras agrupadas | Fraud loss por canal y mes |
| Área apilada | Volumen total vs. volumen fraudulento por mes |
| Matriz de canales | Canal × KPI (fraud_rate, loss_usd, alert_count) |
| Líneas de tendencia | Fraud rate % por canal — últimos 12 meses |

**Canales disponibles:** CARD_POS, CARD_CNP, ACH_CREDIT, ACH_DEBIT, WIRE_DOMESTIC, WIRE_INTERNATIONAL, DIGITAL_WALLET, DIGITAL_TRANSFER

---

#### Página 3 — ML Model Performance Monitor
**Objetivo:** Monitoreo técnico del modelo de detección.

| Visual | Configuración |
|--------|--------------|
| Línea de tendencia | F1 Score, Precision, Recall por mes |
| Matriz de confusión | True Positives, False Positives, True Negatives, False Negatives |
| Scatter plot | ml_model_score vs. fraud_flag (distribución de scores) |
| Slicer de umbral | What-If parameter para simular threshold 0.0 → 1.0 |

**Medidas clave:** `Model Precision (%)`, `Model Recall (%)`, `Model F1 Score`, `False Positive Rate (%)`

---

#### Página 4 — Fraud Case Operations Pipeline
**Objetivo:** Gestión de cola de casos para investigadores.

| Visual | Configuración |
|--------|--------------|
| Funnel chart | Casos por estado: OPEN → UNDER_INVESTIGATION → RESOLVED |
| Tabla de casos | case_id, priority, amount_at_risk, days_open, SLA_status |
| Barras de aging | Distribución de casos por antigüedad (0-7, 8-14, 15-30, 30+ días) |
| Heatmap de analistas | Analista × mes, color = casos resueltos |

**Lógica de SLA:**
- P0: ≤ 1 hora | P1: ≤ 1 hora | P2: ≤ 4 horas | P3: ≤ 8 horas | P4: ≤ 24 horas

---

#### Página 5 — Customer & Account Risk Segmentation
**Objetivo:** Vista de portfolio de riesgo para el Risk Officer.

| Visual | Configuración |
|--------|--------------|
| Treemap | Clientes agrupados por risk_tier, tamaño = transaction_volume |
| Scatter plot | risk_score (eje X) vs. total_amount_usd (eje Y), color = risk_tier |
| Tabla de watchlist | Clientes con watchlist_flag = TRUE o pep_flag = TRUE |
| KPI cards | Clientes por tier, exposición total por tier |

**Tiers disponibles:** MINIMAL, LOW, MEDIUM, HIGH, CRITICAL

---

#### Página 6 — Geospatial Fraud Intelligence
**Objetivo:** Patrones geográficos para compliance y AML.

| Visual | Configuración |
|--------|--------------|
| Mapa coroplético | País de destino, color = fraud_rate o fraud_loss_usd |
| Tabla de jurisdicciones | País × fraud_count, fraud_loss, % del total |
| Barras | Top 10 países de destino por pérdida |
| KPI cards | Transacciones cross-border, pérdida internacional |

**Países de alto riesgo en los datos:** Nigeria (NG), Romania (RO), Moldova (MD)

---

## Conclusiones del análisis

### 1. Tendencia general — mejora sostenida en FY2024
> La plataforma demostró ROI medible: el fraud loss rate cayó de **21.2 bps a 12.4 bps** en 12 meses, una reducción del 41.5%.

### 2. Canal de mayor riesgo — WIRE_INTERNATIONAL
> Concentra la mayor pérdida absoluta. El pico de Q3 2024 corresponde a la campaña **GOLDENWIRE** (BEC wire fraud, $850K sin recuperar hacia Nigeria). Requiere controles adicionales de callback y verificación SWIFT.

### 3. Modelo ML — mejora de precisión consistente
> La precisión del modelo pasó de **87.4% → 94.3%** en el año. La reducción de falsos positivos en **0.9 pp** equivale a un ahorro estimado de **~$340K/año** en horas de revisión de analistas.

### 4. Gestión de casos — cuello de botella en casos P0
> El caso **CASE-2024-0004** (GOLDENWIRE, $850K, P0) permanece abierto con exposición sin recuperar. Los casos P0 tienen SLA de respuesta inmediata — este caso excede el umbral de escalación al CRO y potencialmente al Board.

### 5. Segmentación de clientes — concentración de riesgo
> **4 clientes en tier CRITICAL** concentran desproporcionada exposición. Dos están marcados como PEP (Politically Exposed Person) y requieren **Enhanced Due Diligence (EDD)**. Uno es una entidad anónima (LLC) sin KYC completado.

### 6. Riesgo geográfico — patrones cross-border
> Nigeria, Romania y Moldova aparecen como destinos recurrentes en transacciones fraudulentas. Alineado con el **GOLDENWIRE** y **CROSSBORDER** campaigns. Base para filing de SARs ante FinCEN.

---

## Recomendaciones estratégicas (para incluir en el dashboard)

| # | Recomendación | Inversión estimada | ROI proyectado |
|---|--------------|-------------------|----------------|
| 1 | Implementar callback obligatorio en WIRE_INTERNATIONAL > $50K | $45K (proceso) | Previene ~$850K/evento |
| 2 | Bajar umbral del modelo ML en canales de alto riesgo | $0 (configuración) | -15% falsos negativos |
| 3 | Iniciar EDD para los 4 clientes CRITICAL | $20K (horas analista) | Mitiga $2.1M exposición |
| 4 | Automatizar enriquecimiento de alertas con threat intelligence | $120K/año | -0.5 días resolución |
| 5 | Implementar autenticación FIDO2 en DIGITAL_WALLET | $80K (IT) | Elimina vector SIM swap |

---

## Referencias del repositorio

| Recurso | Ubicación |
|---------|-----------|
| Wireframes detallados de dashboards | `docs/Dashboard_Design_Spec.md` |
| Diccionario de datos (todas las columnas) | `docs/Data_Dictionary.md` |
| Metodología de detección | `docs/Fraud_Detection_Methodology.md` |
| Brief ejecutivo Q4 2024 | `docs/Executive_Intelligence_Brief_Q4_2024.md` |
| Playbook de alertas SOC | `docs/SOC_Alert_Playbook.md` |
| Framework de detección de anomalías | `docs/Anomaly_Detection_Framework.md` |
| Medidas DAX core | `dax/VaultSentinel_FraudMeasures.dax` |
| Medidas DAX avanzadas | `dax/Advanced_DAX_Measures.dax` |

---

*VaultSentinel Corp es una empresa ficticia. Todos los datos son 100% sintéticos.*
*Portfolio project · Lucas Reyes · Fraud Risk & Business Intelligence Analytics · 2024*
*GitHub: https://github.com/LucasreyesGitHub/fraud-risk-analytics-powerbi*
*LinkedIn: https://www.linkedin.com/in/lucasreyes2003/*
