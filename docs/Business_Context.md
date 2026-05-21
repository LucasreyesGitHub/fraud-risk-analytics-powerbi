# VaultSentinel Corp — Business Context & Project Scope

> **Fraud Risk Analytics Platform | Stakeholder & Use Case Reference**
> Version 2.1 | December 2024

---

## 1. Company Overview

**VaultSentinel Corp** is a mid-market fintech payments processor serving over 2,400 financial institution clients across North America. The company processes an average of **$14.2 billion in payment volume per month** across card, ACH, wire, and digital channels. With a growing volume of digital-first transactions and an increasingly sophisticated fraud threat landscape, VaultSentinel's Risk Operations division launched the **Fraud Risk Analytics Platform** in Q1 2024 to modernize fraud intelligence and reporting capabilities.

**Key Business Facts (FY2024)**
- Monthly payment volume: $14.2B
- Monthly transaction count: ~550,000
- Active customer accounts: 2,400+
- Fraud operations team size: 42 analysts across 3 tiers
- Annual fraud loss target: ≤$4.2M (≤15 bps of volume)
- Regulatory filings: FinCEN, NACHA, PCI DSS, OFAC

---

## 2. Business Problem

Prior to this initiative, VaultSentinel's fraud reporting relied on **Excel-based manual reporting** compiled weekly by a dedicated analyst. Key limitations included:

- **No real-time visibility** — senior leadership received fraud KPIs 5–7 days after period close
- **Channel blind spots** — wire and digital channel fraud was tracked separately from card fraud, preventing cross-channel pattern detection
- **Manual false positive reviews** — no systematic tracking of alert accuracy, making rule tuning reactive rather than data-driven
- **No customer-level risk view** — fraud was analyzed by transaction only; no portfolio-level customer risk score existed
- **Regulatory lag** — SAR filing deadlines were tracked in a separate spreadsheet with no integration to case management

These gaps resulted in an estimated **$380,000 in preventable annual fraud loss** and contributed to a False Positive Rate of 8.4% — significantly above the industry benchmark of 5-6%.

---

## 3. Solution Objectives

The Power BI Fraud Risk Analytics Platform was designed to address four strategic objectives:

**Objective 1 — Real-Time Fraud Intelligence**
Replace weekly Excel reports with a live Power BI dashboard refreshing every 4 hours from the production database. Enable fraud analysts and management to monitor KPIs intraday rather than retrospectively.

**Objective 2 — Multi-Channel Consolidated View**
Unify fraud metrics across all eight payment channels into a single data model, enabling cross-channel pattern detection and consolidated loss reporting that was previously impossible.

**Objective 3 — Model Performance Accountability**
Create a dedicated ML Model Performance dashboard to track precision, recall, and F1 score over time — enabling the quantitative risk team to defend model performance to regulators and calibrate alert thresholds with data.

**Objective 4 — Customer Risk Portfolio Management**
Build a customer-level risk segmentation model and dashboard, enabling the risk team to proactively manage high-risk accounts and demonstrate compliance with Enhanced Due Diligence (EDD) requirements to regulators.

---

## 4. Stakeholders & User Personas

### Persona 1 — Chief Risk Officer (CRO)
**Role:** Executive oversight of all financial crime risk  
**Dashboard Used:** Executive Risk Command Center  
**Key Questions:**
- What is our current fraud loss rate in basis points?
- Are we trending above or below our FY target?
- How does this quarter compare to the same period last year?
- What is our biggest exposure channel right now?

**Reporting Cadence:** Daily (KPI monitoring) + Monthly (board reporting)

---

### Persona 2 — VP of Fraud Operations
**Role:** Leads 42-person fraud analyst team, owns fraud strategy  
**Dashboard Used:** Multi-Channel Intelligence + Case Operations Pipeline  
**Key Questions:**
- Which channel has the highest fraud rate this month?
- How is analyst caseload distributed — are any analysts overwhelmed?
- Are we meeting our case resolution SLA targets?
- Which fraud types are increasing most rapidly?

**Reporting Cadence:** Daily review + Weekly team reporting

---

### Persona 3 — Senior Fraud Analyst (Tier 2)
**Role:** Investigates complex, high-value fraud cases  
**Dashboard Used:** Fraud Case Operations + Customer Risk Segmentation  
**Key Questions:**
- Which open cases are closest to their SLA breach?
- What is the risk profile of the customer linked to this case?
- Are there other active cases linked to the same customer/device?
- What is the total exposure across open wire fraud cases?

**Reporting Cadence:** Real-time case queue monitoring

---

### Persona 4 — Quantitative Risk Analyst
**Role:** Owns the ML fraud model and rule engine performance  
**Dashboard Used:** ML Model Performance Monitor  
**Key Questions:**
- Has model precision changed after the last retraining?
- At what score threshold does the optimal precision-recall tradeoff occur?
- Are false positives concentrated in a specific customer segment or channel?
- Is there evidence of model drift in any feature distribution?

**Reporting Cadence:** Weekly model monitoring + Monthly model review

---

### Persona 5 — BSA/AML Compliance Officer
**Role:** Ensures regulatory compliance, oversees SAR filing  
**Dashboard Used:** Geospatial Intelligence + Customer Risk Segmentation  
**Key Questions:**
- Which accounts are flagged as PEP or on the watchlist?
- Which transactions involve high-risk jurisdictions (OFAC considerations)?
- How many SARs have been filed this month, and what is the total exposure?
- Are there any accounts that are overdue for their annual KYC review?

**Reporting Cadence:** Daily compliance monitoring + Monthly regulatory reporting

---

## 5. KPI Framework

The following KPIs were defined collaboratively with the CRO and VP Fraud Operations as the primary metrics for the FY2024 fraud operations scorecard:

### Tier 1 — Executive KPIs (Board-Level)

| KPI | Description | FY2024 Target | FY2024 Actual |
|-----|-------------|--------------|---------------|
| Fraud Loss Rate (bps) | Net fraud loss as % of payment volume | ≤15 bps | **12.4 bps** ✓ |
| Annual Net Fraud Loss ($) | Total fraud loss net of recoveries | ≤$4.2M | **$2.84M** ✓ |
| Fraud Detection Rate (%) | % of fraud transactions detected | ≥92% | **94.3%** ✓ |
| Chargeback Recovery Rate (%) | % of fraud loss recovered | ≥75% | **78.4%** ✓ |

### Tier 2 — Operational KPIs (Team-Level)

| KPI | Description | FY2024 Target | FY2024 Actual |
|-----|-------------|--------------|---------------|
| False Positive Rate (%) | % of alerts that are not fraud | ≤6% | **5.2%** ✓ |
| Avg Case Resolution Days | Average days to close a fraud case | ≤3.5 days | **3.2 days** ✓ |
| Alert Volume (monthly) | Total alerts generated per month | Monitor only | 1,847 avg |
| SLA Compliance Rate (%) | Cases resolved within SLA | ≥95% | **96.8%** ✓ |

### Tier 3 — Model & Risk KPIs (Technical-Level)

| KPI | Description | FY2024 Target | FY2024 Actual |
|-----|-------------|--------------|---------------|
| Model Precision (%) | True positives / (True + False Positives) | ≥92% | **94.3%** ✓ |
| Model Recall (%) | True positives / (True Positives + False Negatives) | ≥90% | **91.8%** ✓ |
| Model F1 Score | Harmonic mean of precision and recall | ≥0.90 | **0.912** ✓ |
| High-Risk Customer Count | Customers with risk tier HIGH or CRITICAL | Monitor only | **12 accounts** |

---

## 6. FY2024 Key Events & Fraud Campaigns

**Q1 2024 — Baseline Period**
Standard fraud patterns established. ML model v2.0 deployed January 2024, improving digital channel detection. Wire fraud rate averaged 8.5% on international channel.

**Q2 2024 — CNP Fraud Campaign**
Spike in CARD_CNP fraud attributable to a major US retailer data breach in late March. Approximately 340 stolen card credentials active in the market. Fraud rate on CNP channel reached 3.28% in February before declining after batch invalidation.

**Q3 2024 — Wire Fraud Surge**
BEC (Business Email Compromise) campaign targeting business accounts resulted in three high-value wire fraud cases totaling $1.57M. CASE-2024-0004 (CUST-10041, $850K to Nigeria) remains under FinCEN investigation. Wire fraud SARs filed for all three cases. Internal emergency response deployed in July.

**Q4 2024 — ATO Campaign**
Credential stuffing attack wave in October–November targeting digital wallet and digital transfer channels. ML model v2.3 (ATO module) deployed in September contributed to rapid detection. Nine ATO cases identified and blocked with full recovery.

---

## 7. Technology Architecture (Production Context)

| Component | Technology | Notes |
|-----------|-----------|-------|
| Core Banking System | FIS Modern Banking Platform | Transaction source |
| Fraud Detection Engine | FICO Falcon 9 + Custom XGBoost | Hybrid rule + ML |
| Case Management | Actimize RCM | Investigator workflow |
| Data Warehouse | Azure Synapse Analytics | Aggregation & BI source |
| BI Platform | Power BI Premium | Dashboards & reporting |
| Alerting | Azure Monitor + PagerDuty | Real-time analyst alerts |
| Regulatory Filing | FINCEN BSA E-Filing | SAR submission |
| Sanctions Screening | LexisNexis Bridger Insight | OFAC / PEP screening |

---

## 8. Future Roadmap

The following enhancements are planned for FY2025 pending budget approval:

**Q1 2025 — Real-Time Streaming Analytics**
Replace 4-hour batch refresh with real-time Power BI streaming via Azure Event Hub integration. Target: sub-5-minute dashboard latency.

**Q2 2025 — Explainable AI Integration**
Surface ML model feature contribution scores in the investigator dashboard — enabling analysts to understand *why* a transaction was scored high-risk, improving investigation speed and false positive feedback loops.

**Q3 2025 — Network Graph Visualization**
Embed a D3.js-powered network graph into the dashboard showing relationships between flagged accounts, devices, and IP addresses — improving mule network identification.

**Q4 2025 — Predictive Risk Forecasting**
Build a 30-day forward-looking fraud loss forecast using time-series ARIMA model on channel-level data — enabling proactive staffing and budget decisions.

---

*VaultSentinel Corp | Business Context v2.1 | Fraud Risk Analytics Platform*
*All data, company names, and figures are synthetic and for portfolio demonstration purposes only.*
