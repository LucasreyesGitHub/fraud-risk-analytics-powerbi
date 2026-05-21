# Dashboard Screenshots

This directory contains screenshots of the VaultSentinel Corp Power BI dashboard suite.

> **Note:** Screenshots are captured from Power BI Desktop using the sample data in `/data`. All figures are synthetic and for portfolio demonstration only.

---

## Naming Convention

| Filename | Dashboard Page |
|----------|---------------|
| `01_executive_command_center.png` | Executive Risk Command Center |
| `02_multichannel_intelligence.png` | Multi-Channel Fraud Intelligence |
| `03_ml_model_performance.png` | ML Model Performance Monitor |
| `04_case_operations_pipeline.png` | Fraud Case Operations Pipeline |
| `05_customer_risk_segmentation.png` | Customer & Account Risk Segmentation |
| `06_geospatial_intelligence.png` | Geospatial Fraud Intelligence |

---

## How to Capture Screenshots

1. Open Power BI Desktop and load the sample CSVs from `/data`
2. Build relationships per the star schema in `README.md`
3. Import DAX measures from `/dax/VaultSentinel_FraudMeasures.dax`
4. Navigate to each dashboard page
5. Use **File → Export → Export to PDF** or press `Win + Shift + S` to capture
6. Save at **1920×1080** resolution for best quality

**Recommended Power BI export settings:**
- View mode: Full screen (F11)
- Theme: Import `dark_enterprise_theme.json` from `/docs/Dashboard_Design_Spec.md`
- Filters: Set date range to Jan 2024 – Dec 2024 for the full-year narrative

---

## Page-by-Page Capture Guide

### 01 — Executive Risk Command Center
Show: Net Fraud Loss ($2.84M), Fraud Loss Rate (12.4 bps), Detection Rate (94.3%), open alert queue.
Highlight the channel risk heat map with WIRE_INTERNATIONAL in red.

### 02 — Multi-Channel Fraud Intelligence
Show: Q3 spike in WIRE_INTERNATIONAL corresponding to the GOLDENWIRE campaign.
Ensure YoY delta cards are visible with downward trend arrows.

### 03 — ML Model Performance Monitor
Show: F1 Score trend line, confusion matrix visual, and the threshold slider at 0.5.
Highlight the Q1→Q4 precision improvement from 87.4% to 94.3%.

### 04 — Fraud Case Operations Pipeline
Show: Open case queue with CASE-2024-0004 (P0, $850K exposure) at top.
Ensure SLA status column shows RED for overdue cases.

### 05 — Customer & Account Risk Segmentation
Show: Treemap with CRITICAL tier (4 customers) highlighted in #FF2D55.
PEP-flagged customers should be visible in the watchlist table.

### 06 — Geospatial Intelligence
Show: Nigeria, Romania, Moldova flagged as high-risk destinations.
WIRE_INTERNATIONAL flows to high-risk jurisdictions should be prominent.

---

*Screenshots pending Power BI Desktop build — placeholder guide only.*
