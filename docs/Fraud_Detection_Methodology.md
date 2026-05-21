# VaultSentinel Corp — Fraud Detection Methodology

> **Multi-Channel Fraud Intelligence Platform | Technical Specification**
> Version 2.1 | Fraud Risk Analytics Team | December 2024

---

## 1. Overview

VaultSentinel Corp's fraud detection framework is a multi-layered defense architecture combining real-time rule-based controls, machine learning scoring, behavioral analytics, and human-in-the-loop investigation workflows. This document describes the methodology underpinning the Power BI analytics suite.

The system processes **~550,000 transactions per month** across eight payment channels, targeting a fraud detection rate above 92% while maintaining a false positive rate below 6%.

---

## 2. Detection Layers

### Layer 1 — Real-Time Rule Engine

The rule engine evaluates every transaction against a library of Boolean and threshold-based rules before authorization. Rules are organized into four categories:

**Velocity Rules**
- Maximum 5 card transactions within any 60-minute window per account
- Maximum 12 transactions within any 24-hour window
- Daily volume cap by account tier (Standard: $5,000 | Premium: $50,000 | Business: $500,000)
- Card-Not-Present: maximum 3 transactions to new merchants per day

**Geographic Rules**
- Flag cross-border transactions to high-risk jurisdictions (Tier 1: NG, RO, CN, BR, UA)
- Flag account-country mismatch (customer country ≠ transaction country)
- Flag IP geolocation inconsistency (IP location ≠ card billing address country)
- Flag international wires above $10,000 to non-established beneficiaries

**Device & Identity Rules**
- Flag device fingerprint not in customer's known device registry
- Flag IP addresses with reputation score below 30
- Flag SIM card changes within 72 hours of large digital transfer
- Flag new device + high-value transaction within first 30 days of account opening

**Blacklist & Watchlist Rules**
- Screen all beneficiaries against OFAC SDN list (real-time)
- Match device IDs against internal fraud ring device library
- Match merchant names/MCC against known fraud merchant database
- Match customer names against PEP/watchlist databases (LexisNexis, Dow Jones)

### Layer 2 — Machine Learning Scoring Model

Every transaction receives an ML model score (0–100) representing the probability of fraud. The production model is a **Gradient Boosted Tree (XGBoost)** trained on 36 months of labeled transaction history.

**Key Features (Top 10 by Importance)**

| Rank | Feature | Category |
|------|---------|---------|
| 1 | Velocity count (1hr window) | Behavioral |
| 2 | Amount deviation from 90-day median | Behavioral |
| 3 | IP reputation score | Network |
| 4 | Device match in known device registry | Device |
| 5 | Days since account opening | Tenure |
| 6 | Destination country risk tier | Geographic |
| 7 | Hour of day | Temporal |
| 8 | MCC risk category | Merchant |
| 9 | Cross-border flag | Geographic |
| 10 | Dispute history count (90-day) | History |

**Score Thresholds**

| Score Range | Action |
|-------------|--------|
| 0–39 | Auto-approve |
| 40–59 | Monitor — log for review queue |
| 60–74 | Soft decline — step-up authentication required |
| 75–89 | Alert — route to fraud analyst queue |
| 90–100 | Hard block — immediate decline + case creation |

**Model Version History**

| Version | Release | Key Change | Precision | Recall |
|---------|---------|-----------|-----------|--------|
| v1.0 | Jan 2023 | Initial production deployment | 87.4% | 82.1% |
| v1.5 | Jun 2023 | Wire fraud feature set added | 89.8% | 84.7% |
| v2.0 | Jan 2024 | Digital channel retraining | 92.1% | 89.3% |
| v2.3 | Sep 2024 | ATO detection module | 94.3% | 91.8% |

### Layer 3 — Behavioral Analytics (Anomaly Detection)

Behavioral analytics computes a per-customer baseline using a 90-day rolling window and flags deviations:

- **Amount Anomaly:** Transaction amount > 3σ above customer's median transaction value
- **Time Anomaly:** Transaction at an hour with < 2% historical frequency for this customer
- **Channel Anomaly:** First use of a new payment channel
- **Merchant Anomaly:** Transaction at a merchant category with no prior history
- **Geographic Anomaly:** Location inconsistent with home/work cluster

Each anomaly adds to the composite risk score additively. A transaction flagging 3+ anomalies is automatically routed to the analyst queue regardless of ML score.

### Layer 4 — Network Analysis (Fraud Ring Detection)

The network analysis module runs asynchronously (near-real-time, 5-minute lag) and builds a graph of relationships between:

- Devices (shared device fingerprints across accounts)
- IP addresses (shared IP ranges, VPN exit nodes)
- Beneficiaries (shared wire destinations, ACH routing numbers)
- Contact information (shared phone/email across accounts)

Accounts with network centrality scores above a defined threshold are escalated to the Financial Intelligence Unit (FIU) for mule network and organized fraud ring investigation.

---

## 3. Risk Scoring Model

The **Composite Risk Score** (0–100) assigned to each customer account is a weighted aggregate of five signal categories:

| Signal Category | Weight | Inputs |
|-----------------|--------|--------|
| Transaction History | 25% | Fraud history count, dispute rate, chargeback rate |
| Behavioral Patterns | 20% | Velocity trends, night-time activity, channel diversity |
| Identity & KYC Quality | 20% | KYC status, document age, verification depth |
| Network Exposure | 20% | Connected device risk, IP range history |
| Account Profile | 15% | Account age, income validation, credit score band |

**Risk Tier Classification**

| Tier | Score Range | Portfolio Share | Action |
|------|-------------|-----------------|--------|
| MINIMAL | 0–19 | ~42% | Standard monitoring |
| LOW | 20–39 | ~28% | Enhanced transaction monitoring |
| MEDIUM | 40–59 | ~16% | Periodic manual review — 90-day cycle |
| HIGH | 60–79 | ~10% | Enhanced Due Diligence — 30-day review |
| CRITICAL | 80–100 | ~4% | Immediate case review + potential account hold |

---

## 4. Alert Triage & Investigation Workflow

```
Transaction
    │
    ▼
Rule Engine ──► Score < threshold ──► Auto-Approve ──► Monitor Queue
    │
    └──► Score ≥ 75 ──► Alert Queue
                             │
                             ▼
                    Analyst Triage (Tier 1)
                       ├──► False Positive → Close + Rule Feedback
                       └──► Suspicious → Open Investigation Case
                                              │
                                              ▼
                                   Fraud Investigation (Tier 2)
                                      ├──► Confirmed Fraud
                                      │        ├──► Initiate Chargeback/Recall
                                      │        ├──► Account Action (suspend/close)
                                      │        └──► SAR Filing (if ≥$5,000)
                                      └──► Insufficient Evidence → Close
```

**SLA Targets**

| Case Priority | Initial Review | Full Investigation | Resolution |
|--------------|---------------|-------------------|------------|
| CRITICAL | ≤1 hour | ≤24 hours | ≤72 hours |
| HIGH | ≤4 hours | ≤3 days | ≤7 days |
| MEDIUM | ≤8 hours | ≤5 days | ≤14 days |
| LOW | ≤24 hours | ≤7 days | ≤21 days |

---

## 5. Regulatory & Compliance Integration

**Suspicious Activity Reports (SARs)**
- All confirmed fraud cases with net loss ≥ $5,000 require SAR filing with FinCEN within 30 calendar days
- Wire fraud cases involving foreign jurisdictions are escalated to the BSA/AML team for parallel SAR review
- Cases involving PEP-flagged accounts are filed as priority SARs within 7 days

**OFAC Screening**
- Real-time SDN list screening on all wire transfers and ACH credits above $3,000
- 100% coverage on international wire beneficiaries regardless of amount
- Automated case creation for any OFAC match — immediate account freeze pending compliance review

**NACHA Return Codes**
- ACH fraud cases leverage NACHA R10 (Customer Advises Not Authorized) and R29 (Corporate Customer Advises Not Authorized) return codes for recovery
- Return window: 60 calendar days for consumer ACH, 2 business days for corporate ACH

**PCI DSS Compliance**
- No full PANs stored in any analytics environment
- Card numbers masked to last 4 digits throughout the data pipeline
- All device fingerprints are one-way hashed before storage

---

## 6. Model Performance Monitoring

The following metrics are tracked on a monthly cadence and reviewed by the Risk Analytics team:

| Metric | Current | Target | Alert Threshold |
|--------|---------|--------|-----------------|
| Precision | 94.3% | ≥92% | <88% |
| Recall | 91.8% | ≥90% | <85% |
| F1 Score | 0.912 | ≥0.90 | <0.85 |
| False Positive Rate | 5.2% | ≤6% | >9% |
| Fraud Loss Rate (bps) | 12.4 | ≤14 | >18 |
| Avg Case Resolution Days | 3.2 | ≤3.5 | >5.0 |

**Model Drift Detection**
- Population Stability Index (PSI) computed weekly on 10 key features
- PSI > 0.20 on any feature triggers model retraining review
- Score distribution monitored monthly — shifts in mean score distribution >5% trigger investigation

---

## 7. Continuous Improvement Cycle

1. **Rule Tuning** — Monthly review of false positive root causes; rules with FP rate >15% are retired or adjusted
2. **Model Retraining** — Quarterly retraining on rolling 24-month labeled dataset
3. **Feature Engineering** — Quarterly review of new signal candidates from case analysis
4. **Threshold Optimization** — Bi-annual threshold calibration using precision-recall curve analysis
5. **Red Team Testing** — Semi-annual adversarial testing simulating new fraud typologies

---

*VaultSentinel Corp | Fraud Detection Methodology v2.1 | Fraud Risk Analytics Platform*
