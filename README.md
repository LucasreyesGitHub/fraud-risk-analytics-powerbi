# VaultSentinel Corp — Fraud Risk Analytics Platform

> **Enterprise Multi-Channel Fraud Intelligence | Power BI Dashboard Suite**

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![DAX](https://img.shields.io/badge/DAX-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=for-the-badge)
![Domain](https://img.shields.io/badge/Domain-Fraud%20Analytics-red?style=for-the-badge)
![Theme](https://img.shields.io/badge/Theme-Dark%20Enterprise-0D1117?style=for-the-badge)
![Measures](https://img.shields.io/badge/DAX%20Measures-60%2B-0078D4?style=for-the-badge)
![Severity](https://img.shields.io/badge/Severity-P0--P4%20Framework-FF2D55?style=for-the-badge)

---

## Overview

**VaultSentinel Corp** is a fictional enterprise fintech firm specializing in real-time fraud risk intelligence for financial institutions. This Power BI solution monitors card, ACH, wire, and digital payment channels — enabling fraud operations teams to detect, investigate, and resolve suspicious activity with precision and speed.

This portfolio project demonstrates end-to-end BI development for a fraud operations context: from raw transaction data through star-schema data modeling, advanced DAX analytics, and executive dashboard design.

**Built for roles in:** Fraud Analyst · Risk Operations Analyst · BI Developer · Data Analyst · Financial Crime Analyst

---

## Dashboard Pages

### 1. Executive Risk Command Center
The top-level KPI hub for C-suite and VP-level stakeholders. Displays real-time fraud loss rate, net exposure, detection performance, and channel heat map. Designed for 30-second situational awareness without drilling down.

**Visuals:** KPI cards, sparklines, fraud loss waterfall, channel risk matrix, alert queue gauge

### 2. Multi-Channel Fraud Intelligence
Operational view for fraud strategy teams. Breaks down fraud volume, loss, and rate by payment channel (CARD_POS, CARD_CNP, ACH, WIRE_DOMESTIC, WIRE_INTERNATIONAL, DIGITAL_WALLET, DIGITAL_TRANSFER) with cross-channel pattern overlays.

**Visuals:** Clustered bar, stacked area, channel comparison matrix, fraud rate trend lines, YoY delta

### 3. ML Model Performance Monitor
Technical dashboard for quantitative risk and model validation teams. Tracks model precision, recall, and F1 score over time, score threshold sensitivity, false positive decomposition, and model drift indicators across segments.

**Visuals:** Precision-Recall curve simulation, confusion matrix, threshold slider slicer, segment breakdown

### 4. Fraud Case Operations Pipeline
Investigator and team-lead focused view showing open case queue, case age distribution, workload by analyst, and resolution rate. Drives SLA compliance monitoring and escalation triage.

**Visuals:** Funnel chart, case aging bins, investigator heatmap, resolution vs. target gauge

### 5. Customer & Account Risk Segmentation
Risk officer view for portfolio-level exposure management. Segments customers by composite risk tier (MINIMAL → CRITICAL), surfaces watchlist and PEP-flagged accounts, tracks behavioral anomaly indicators, and supports EDD workflow prioritization.

**Visuals:** Treemap by risk tier, scatter plot (risk score vs. transaction volume), watchlist table

### 6. Geospatial Fraud Intelligence
Compliance and AML-adjacent view showing transaction origin/destination mapping, high-risk jurisdiction flagging, cross-border fraud flows, and IP reputation clustering. Supports SAR filing context and geographic pattern analysis.

**Visuals:** Filled map, origin-destination flow, jurisdiction risk table, country-level fraud rate

---

## Key Metrics Delivered

| KPI | Current Value | YoY Trend |
|-----|--------------|-----------|
| Fraud Detection Rate | **94.3%** | ↑ +2.1 pp |
| Net Fraud Loss | **$2.84M** | ↓ -8.7% |
| Fraud Loss Rate | **12.4 bps** | ↓ -1.8 bps |
| False Positive Rate | **5.2%** | ↓ -0.9 pp |
| Avg Case Resolution Time | **3.2 days** | ↓ -0.5 days |
| ML Model F1 Score | **0.912** | ↑ +0.03 |
| Chargeback Recovery Rate | **78.4%** | ↑ +4.1 pp |
| High-Risk Account Count | **12** | ↑ +3 |

---

## Data Architecture

```
┌──────────────────────────────────────────────────────────────┐
│              VAULTSENTINEL CORP — STAR SCHEMA                │
│                                                              │
│   ┌─────────────┐         ┌──────────────────────────────┐  │
│   │  Dim_Date   │────────▶│     Fact_Transactions        │  │
│   └─────────────┘         │  ─────────────────────────── │  │
│   ┌─────────────┐         │  transaction_id (PK)         │  │
│   │ Dim_Channel │────────▶│  transaction_date (FK)       │  │
│   └─────────────┘         │  channel (FK)                │  │
│   ┌─────────────┐         │  customer_id (FK)            │  │
│   │Dim_Customer │────────▶│  amount_usd                  │  │
│   └─────────────┘         │  risk_score                  │  │
│   ┌─────────────┐         │  fraud_flag                  │  │
│   │Dim_FraudType│────────▶│  fraud_type (FK)             │  │
│   └─────────────┘         │  ml_model_score              │  │
│                           └──────────────────────────────┘  │
│                                        │                     │
│                                        ▼                     │
│   ┌─────────────┐         ┌──────────────────────────────┐  │
│   │Dim_RiskTier │────────▶│      Fact_FraudCases         │  │
│   └─────────────┘         │  case_id (PK)                │  │
│                           │  amount_at_risk_usd          │  │
│                           │  recovered_amount_usd        │  │
│                           │  resolution_days             │  │
│                           └──────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

**Relationships:** All fact-to-dimension joins on surrogate or natural keys. Single-direction filter flow. Dim_Date marked as date table for time intelligence functions.

---

## Technical Stack

| Layer | Technology |
|-------|-----------|
| Visualization | Power BI Desktop (PBIX) |
| Data Modeling | Star Schema — 2 fact tables, 5 dimension tables |
| Analytics Engine | DAX (Data Analysis Expressions) |
| Data Prep | Power Query (M language) |
| Source System | Azure SQL / SQL Server (simulated via CSV) |
| Scheduling | Power BI Service + Incremental Refresh |
| Version Control | Git / GitHub |

---

## DAX Measures Overview

The `dax/VaultSentinel_FraudMeasures.dax` file contains **40+ production-grade DAX measures** across these categories:

| Category | Measures |
|----------|---------|
| Volume & Transaction Metrics | 5 measures |
| Financial Loss Analytics | 7 measures |
| ML Model Performance | 6 measures (Precision, Recall, F1) |
| Time Intelligence | 8 measures (MTD, QTD, YTD, MoM, YoY) |
| Alert & Case Management | 6 measures |
| Channel Segmentation | 5 measures |
| Customer Risk Scoring | 5 measures |

Selected highlights:

```dax
-- Net Fraud Loss with dynamic time context
Net Fraud Loss ($) =
    CALCULATE(
        SUMX(
            FILTER(Transactions, Transactions[fraud_flag] = 1),
            Transactions[amount_usd]
        )
    ) - [Chargeback Recovered ($)]

-- Model F1 Score
Model F1 Score =
    VAR Precision = [Model Precision (%)]
    VAR Recall    = [Model Recall (%)]
    RETURN
        IF(
            Precision + Recall = 0, 0,
            2 * DIVIDE(Precision * Recall, Precision + Recall)
        )

-- YoY Fraud Loss Change
YoY Fraud Loss Change (%) =
    DIVIDE(
        [Net Fraud Loss ($)] - [Prior Year Fraud Loss ($)],
        [Prior Year Fraud Loss ($)],
        BLANK()
    )
```

---

## Repository Structure

```
fraud-risk-analytics-powerbi/
│
├── README.md                                   ← You are here
├── PORTFOLIO.md                                ← LinkedIn copy, resume bullets, ATS keywords
├── CHANGELOG.md                                ← Version history
├── requirements.txt                            ← Python dependencies for scripts
│
├── data/
│   ├── transactions_2024.csv                   ← 100 transaction records across 8 channels
│   ├── customer_risk_profiles.csv              ← 50 customers across 5 risk tiers
│   ├── fraud_cases_2024.csv                    ← 40 fraud investigation cases
│   ├── monthly_channel_summary.csv             ← 96-row aggregated channel KPIs
│   └── fraud_scenarios_2024.csv               ← 10 detailed multi-step fraud campaigns
│
├── dax/
│   ├── VaultSentinel_FraudMeasures.dax         ← Core 40+ DAX measures library
│   └── Advanced_DAX_Measures.dax              ← 60+ advanced measures (cohorts, anomaly, WhatIf)
│
├── sql/
│   ├── 01_create_schema.sql                    ← Star schema DDL — 8 tables, 10 indexes, seed data
│   ├── 02_sample_queries.sql                   ← 8 analytical queries with CTEs & window functions
│   └── 03_stored_procedures.sql               ← 3 stored procedures for data refresh & KPI feeds
│
├── scripts/
│   └── validate_data.py                        ← Automated CSV data quality validation
│
├── screenshots/
│   └── README.md                               ← Dashboard capture guide (screenshots pending PBIX build)
│
└── docs/
    ├── Data_Dictionary.md                      ← Column-level documentation for all tables
    ├── Fraud_Detection_Methodology.md          ← 4-layer detection architecture & scoring
    ├── Business_Context.md                     ← Use case, stakeholders, 5 personas, KPI framework
    ├── Executive_Intelligence_Brief_Q4_2024.md ← Board-level fraud brief, P0-P4 severity, recommendations
    ├── SOC_Alert_Playbook.md                   ← 5 alert tickets, playbooks, escalation matrix, TTPs
    ├── Dashboard_Design_Spec.md               ← 6 ASCII wireframes, dark theme, drillthrough specs
    └── Anomaly_Detection_Framework.md         ← Z-score, IQR, Isolation Forest, LSTM, PSI monitoring
```

---

## Business Impact Narrative

> This dashboard suite was designed to address VaultSentinel Corp's FY2024 fraud operations modernization initiative — replacing legacy Excel-based reporting with a real-time, interactive intelligence platform.

**Quantified outcomes:**

- Reduced fraud loss rate from **21.2 bps → 12.4 bps** over 12 months through improved detection coverage
- Improved ML model precision from **87.4% → 94.3%** following rule refinement and threshold tuning
- Decreased false positive rate by **0.9 pp**, reducing analyst review burden by an estimated **~$340K/year**
- Cut average case resolution time by **0.5 days** through automated alert enrichment and case routing
- Identified and blocked a **$1.2M wire fraud campaign** in Q3 2024 via geospatial pattern detection
- Enabled **SAR filing** for 6 high-value cases totaling **$2.1M** in exposure through integrated AML flagging

---

## How to Use This Project

### Option A — Load Sample Data into Power BI
1. Clone this repository
2. Open Power BI Desktop
3. Import CSV files from `/data` via **Get Data → Text/CSV**
4. Build the star schema relationships per the data architecture diagram above
5. Import DAX measures from `/dax/VaultSentinel_FraudMeasures.dax` via DAX Studio or paste into Power BI
6. Apply the dark enterprise theme from [`docs/Dashboard_Design_Spec.md`](docs/Dashboard_Design_Spec.md)

### Option B — Deploy on SQL Server / Azure SQL
```sql
-- Execute in order:
-- 1. Run sql/01_create_schema.sql   → creates tables, indexes, and seed data
-- 2. Run sql/02_sample_queries.sql  → validates analytical queries
-- 3. Run sql/03_stored_procedures.sql → deploys stored procedures
```
Then connect Power BI to the database via **Get Data → SQL Server**.

### Option C — Validate Sample Data
```bash
pip install -r requirements.txt
python scripts/validate_data.py --data-dir data/ --verbose
```
Runs schema, null, uniqueness, range, and referential integrity checks across all 5 CSV files.

### Option D — Review for Methodology
Browse `docs/` for business context, data dictionary, and detection methodology — suitable for interview preparation or analytical review.

---

## Dark Enterprise Design

The platform uses a custom dark cybersecurity aesthetic — optimized for SOC and fraud operations center environments where analysts work long shifts.

```
Primary Background  #0D1117   Card Fill  #161B22   Border  #30363D
P0 Critical         #FF2D55   P1 High    #FF6B35   P2 Warn #FFB800
P3 Medium           #58A6FF   P4 Safe    #3FB950   Text    #F0F6FC
```

Full design specification — wireframes, color system, KPI card variants, drillthrough designs, and Power BI theme JSON — in [`docs/Dashboard_Design_Spec.md`](docs/Dashboard_Design_Spec.md).

---

## Fraud Severity Framework

All incidents are classified on a **P0–P4 scale** aligned with operational response protocols:

| Level | Label | Loss Threshold | Response SLA | Escalation |
|-------|-------|---------------|--------------|-----------|
| P0 | Catastrophic | > $1M | Immediate | CEO + Board |
| P1 | Critical | $100K–$999K | ≤ 1 hour | CRO |
| P2 | High | $10K–$99K | ≤ 4 hours | VP Operations |
| P3 | Medium | $1K–$9.9K | ≤ 8 hours | Team Lead |
| P4 | Low | < $1K | ≤ 24 hours | Analyst Queue |

---

## SOC Alert Intelligence

The [`docs/SOC_Alert_Playbook.md`](docs/SOC_Alert_Playbook.md) includes 5 production-style SOC alert tickets, incident response playbooks for all major fraud typologies, a MITRE-aligned TTP reference for financial fraud, and a full escalation matrix.

**Sample Alert Ticket (BEC Wire Fraud — P0):**
```
╔══════════════════════════════════════════════════════════════╗
║  Alert: VSC-ALERT-2024-0531        Severity: P0 CATASTROPHIC ║
║  WIRE_INTERNATIONAL | $850,000 | NG | ML Score: 95.7/100    ║
║  Rules: BLACKLIST_HIT | GEO_ANOMALY | TIME_ANOMALY | +3 more ║
║  Action: IMMEDIATE HOLD → CALLBACK → SWIFT RECALL → SAR      ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 10 Fraud Campaign Scenarios (FY2024)

The [`data/fraud_scenarios_2024.csv`](data/fraud_scenarios_2024.csv) documents 10 detailed multi-step fraud campaigns including:

| # | Codename | Type | Exposure | Outcome |
|---|----------|------|---------|---------|
| 1 | GOLDENWIRE | BEC / Wire Fraud | $2.85M | Open — $850K unrecovered |
| 2 | CREDSTORM | Credential Stuffing | $312K | Resolved — full recovery |
| 3 | PHANTOMCARD | ATM Skimming Ring | $47.8K | Resolved — LE referral |
| 4 | SYNTHWAVE24 | Synthetic Identity Ring | $195K | Under investigation |
| 5 | MULEFLUX | Money Mule Network | $287K | Partially resolved |
| 6 | RANSOMACH | Phishing → ACH Fraud | $245K | Resolved — NACHA recall |
| 7 | DEEPPHISH | AI Phishing + SIM Swap | $198K | Resolved — FIDO2 deployed |
| 8 | LUXURYCNP | High-Value CNP Ring | $312K | Resolved — full recovery |
| 9 | CROSSBORDER | Shell Corp Wire Network | $1.87M | Partially resolved |
| 10 | INSIDEREDGE | Insider Threat | $425K | Resolved — employee terminated |

---

## Skills Demonstrated

`Power BI Desktop` `DAX` `Data Modeling` `Star Schema Design` `Fraud Analytics` `Financial Crime Intelligence` `Risk Scoring` `KPI Dashboard Design` `Time Intelligence` `Power Query (M)` `SQL` `ETL Pipeline Design` `AML/KYC Concepts` `BEC Detection` `ATO Detection` `Synthetic Identity` `SOC Operations` `Incident Response` `Anomaly Detection` `ML Model Monitoring` `Executive Reporting` `Regulatory Compliance`

---

## About VaultSentinel Corp

> VaultSentinel Corp is a fictional enterprise. All transaction data, customer records, and financial figures are **100% synthetic** and generated for portfolio demonstration purposes. No real individuals, financial institutions, or transactions are represented.

---

*Portfolio project by Lucas Reyes · Fraud Risk & Business Intelligence Analytics · 2024*
*LinkedIn: [linkedin.com/in/lucasreyes2003](https://www.linkedin.com/in/lucasreyes2003/) | GitHub: [github.com/LucasreyesGitHub/fraud-risk-analytics-powerbi](https://github.com/LucasreyesGitHub/fraud-risk-analytics-powerbi)*
