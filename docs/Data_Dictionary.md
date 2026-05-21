# VaultSentinel Corp — Data Dictionary

> **Fraud Risk Analytics Platform | Table & Column Reference**
> Version 2.1 | December 2024

---

## Overview

This document provides complete column-level documentation for all tables used in the VaultSentinel Fraud Risk Analytics Power BI solution. All data is synthetic and generated for portfolio demonstration purposes.

---

## Table: `Transactions` (Fact Table)

**Source file:** `data/transactions_2024.csv`
**Grain:** One row per payment transaction
**Row count (sample):** 100 records

| Column | Data Type | Description | Example | Notes |
|--------|-----------|-------------|---------|-------|
| `transaction_id` | Text | Unique transaction identifier | `TXN-2024-00001` | Format: TXN-YYYY-NNNNN |
| `transaction_date` | Date | Date transaction was initiated | `2024-03-15` | Used for time intelligence joins to Dim_Date |
| `transaction_time` | Time | Time of day (24hr format) | `14:23:11` | Late-night transactions correlate with higher fraud rates |
| `channel` | Text | Payment channel | `CARD_CNP` | See Channel Reference below |
| `amount_usd` | Decimal | Transaction amount in USD | `1849.99` | |
| `currency` | Text | ISO 4217 currency code | `USD` | All values in this dataset are USD |
| `merchant_category_code` | Integer | ISO 18245 Merchant Category Code | `5944` | 4-digit code classifying merchant type |
| `merchant_name` | Text | Merchant or beneficiary name | `Luxury Watch Online` | |
| `customer_id` | Text | Customer identifier (FK to CustomerRiskProfiles) | `CUST-10024` | |
| `account_last4` | Integer | Last 4 digits of account/card | `5567` | Masked for PII compliance |
| `origin_country` | Text | ISO 3166-1 alpha-2 country of transaction origin | `US` | |
| `destination_country` | Text | ISO 3166-1 alpha-2 country of beneficiary | `RO` | Cross-border = higher risk flag |
| `risk_score` | Integer | Composite real-time risk score (0-100) | `79` | 0=no risk, 100=maximum risk |
| `fraud_flag` | Integer | Binary fraud indicator | `1` | 1=Fraud confirmed, 0=Legitimate |
| `fraud_type` | Text | Classification of fraud type | `CNP_FRAUD` | See Fraud Type Reference below |
| `alert_rule_triggered` | Text | Rule that generated the alert | `GEO_ANOMALY` | See Alert Rule Reference below |
| `resolution_status` | Text | Case resolution outcome | `CONFIRMED_FRAUD` | See Resolution Status Reference below |
| `chargeback_amount_usd` | Decimal | Amount recovered via chargeback | `1849.99` | 0.00 if no chargeback initiated |
| `device_fingerprint` | Text | Unique device identifier | `DEV-X1D4F284` | Masked device hash |
| `ip_reputation_score` | Integer | IP address trust score (0-100) | `15` | 100=fully trusted, 0=known malicious |
| `velocity_count_1h` | Integer | Number of transactions from same account in past 1 hour | `6` | High velocity is a key fraud indicator |
| `velocity_count_24h` | Integer | Number of transactions in past 24 hours | `18` | |
| `ml_model_score` | Decimal | Machine learning model fraud probability score (0-100) | `84.2` | Scores >70 trigger investigation queue |

---

## Table: `CustomerRiskProfiles` (Dimension Table)

**Source file:** `data/customer_risk_profiles.csv`
**Grain:** One row per customer account
**Row count (sample):** 50 records

| Column | Data Type | Description | Example | Notes |
|--------|-----------|-------------|---------|-------|
| `customer_id` | Text | Unique customer identifier (PK) | `CUST-10024` | |
| `full_name` | Text | Customer full name | `Sarah Mitchell` | Synthetic data only |
| `account_open_date` | Date | Date the account was opened | `2017-04-05` | Newer accounts have higher baseline risk |
| `account_type` | Text | Account classification | `PREMIUM_ACCOUNT` | See Account Type Reference below |
| `annual_income_band` | Text | Self-reported income bracket | `250K+` | Used for risk stratification |
| `credit_score_band` | Text | Credit bureau score band | `GOOD` | EXCELLENT / GOOD / FAIR / POOR / UNKNOWN |
| `country` | Text | Account holder country | `US` | |
| `state` | Text | US state (2-letter code) | `CA` | |
| `risk_tier` | Text | Composite risk classification | `HIGH` | MINIMAL / LOW / MEDIUM / HIGH / CRITICAL |
| `composite_risk_score` | Integer | Proprietary composite risk score (0-100) | `71` | Derived from multiple behavioral signals |
| `fraud_history_count` | Integer | Total confirmed fraud incidents on account | `3` | Increases composite risk score |
| `dispute_count` | Integer | Total payment disputes filed | `7` | High dispute rates indicate risk |
| `avg_monthly_transactions` | Integer | Average monthly transaction count | `9` | |
| `avg_transaction_amount_usd` | Decimal | Average transaction value in USD | `789.50` | Large deviations from this flag anomalies |
| `primary_channel` | Text | Most-used payment channel | `CARD_CNP` | |
| `kyc_status` | Text | Know Your Customer verification status | `ENHANCED_DUE_DILIGENCE` | See KYC Status Reference |
| `watchlist_flag` | Text | Regulatory watchlist match indicator | `Y` | Y/N — triggers manual review |
| `pep_flag` | Text | Politically Exposed Person indicator | `N` | Y/N — requires enhanced AML screening |
| `last_review_date` | Date | Date of most recent risk review | `2024-01-15` | Reviews should occur at least annually |
| `risk_analyst_id` | Text | Assigned risk analyst | `ANL-010` | |

---

## Table: `FraudCases` (Fact Table)

**Source file:** `data/fraud_cases_2024.csv`
**Grain:** One row per fraud investigation case
**Row count (sample):** 40 records

| Column | Data Type | Description | Example | Notes |
|--------|-----------|-------------|---------|-------|
| `case_id` | Text | Unique case identifier (PK) | `CASE-2024-0004` | Format: CASE-YYYY-NNNN |
| `case_open_date` | Date | Date investigation was initiated | `2024-02-23` | |
| `case_close_date` | Date | Date case was resolved (blank = open) | `2024-03-09` | Null for open/active cases |
| `channel` | Text | Payment channel of originating transaction | `WIRE_INTERNATIONAL` | |
| `fraud_type` | Text | Primary fraud classification | `BEC` | See Fraud Type Reference |
| `case_status` | Text | Current investigation status | `OPEN` | See Case Status Reference |
| `assigned_analyst` | Text | Investigating analyst ID | `ANL-001` | |
| `amount_at_risk_usd` | Decimal | Total amount under investigation | `850000.00` | |
| `recovered_amount_usd` | Decimal | Amount successfully recovered | `0.00` | Via chargeback, SWIFT recall, or legal recovery |
| `resolution` | Text | Final case outcome | `CONFIRMED_FRAUD` | |
| `resolution_days` | Integer | Days from open to close | `15` | SLA target is ≤14 days for HIGH priority |
| `linked_transaction_id` | Text | Related transaction (FK to Transactions) | `TXN-2024-00075` | |
| `customer_id` | Text | Customer involved (FK to CustomerRiskProfiles) | `CUST-10041` | |
| `priority` | Text | Case priority level | `CRITICAL` | LOW / MEDIUM / HIGH / CRITICAL |
| `escalation_flag` | Text | Escalated to senior team or law enforcement | `Y` | Y/N |
| `sar_filed` | Text | Suspicious Activity Report filed with FinCEN | `Y` | Y/N — regulatory filing indicator |
| `notes` | Text | Analyst investigation notes | `BEC - $850K wire to Nigeria` | Free-text case summary |

---

## Table: `MonthlyChannelSummary` (Aggregated Fact Table)

**Source file:** `data/monthly_channel_summary.csv`
**Grain:** One row per channel per calendar month
**Row count:** 96 records (12 months × 8 channels)

| Column | Data Type | Description | Example |
|--------|-----------|-------------|---------|
| `year_month` | Text | Year-month period (YYYY-MM) | `2024-07` |
| `channel` | Text | Payment channel | `WIRE_INTERNATIONAL` |
| `total_transactions` | Integer | Total transaction count for period | `107` |
| `total_volume_usd` | Decimal | Total dollar volume for period | `83900000.00` |
| `fraud_transactions` | Integer | Count of confirmed fraud transactions | `10` |
| `fraud_loss_usd` | Decimal | Gross fraud loss amount | `1530000.00` |
| `fraud_rate_pct` | Decimal | Fraud transaction rate (%) | `9.35` |
| `alert_count` | Integer | Total alerts generated | `42` |
| `false_positive_count` | Integer | Alerts resolved as non-fraud | `9` |
| `avg_risk_score` | Decimal | Average risk score across all transactions | `44.8` |
| `chargebacks_usd` | Decimal | Total chargeback amount recovered | `1074000.00` |
| `net_fraud_loss_usd` | Decimal | Net loss after chargeback recovery | `456000.00` |

---

## Reference Tables

### Channel Reference

| Channel Code | Description | Risk Profile |
|---|---|---|
| `CARD_POS` | Card Present — in-store point-of-sale | Lowest fraud rate (~0.3%) |
| `CARD_CNP` | Card Not Present — online/phone transactions | Elevated fraud risk (~2-3%) |
| `ACH_CREDIT` | ACH Credit — inbound ACH transfers | Low fraud risk (~0.2%) |
| `ACH_DEBIT` | ACH Debit — outbound ACH debits | Low-medium fraud risk (~0.6%) |
| `WIRE_DOMESTIC` | Domestic wire transfer | Medium fraud risk (~1.5%) |
| `WIRE_INTERNATIONAL` | International wire transfer | Highest fraud risk (~7-10%) |
| `DIGITAL_WALLET` | P2P digital wallets (PayPal, Venmo, Zelle) | Medium fraud risk (~2%) |
| `DIGITAL_TRANSFER` | Online bank-to-bank digital transfers | Medium-high fraud risk (~3%) |

### Fraud Type Reference

| Fraud Type | Description |
|---|---|
| `CNP_FRAUD` | Card-Not-Present — stolen card credentials used online |
| `ATO` | Account Takeover — criminal gains access to legitimate account |
| `SYNTHETIC_ID` | Synthetic Identity — fabricated identity combining real & fictitious info |
| `WIRE_FRAUD` | Wire Transfer Fraud — fraudulent wire initiation |
| `BEC` | Business Email Compromise — fraud via impersonated executive/vendor email |
| `ACH_FRAUD` | Unauthorized ACH debit or fictitious credit scheme |
| `ACCOUNT_ABUSE` | Authorized push payment or account misuse |
| `MULE_NETWORK` | Money mule — account used to layer and move illicit funds |
| `COUNTERFEIT_CARD` | Physical card cloned via skimming device |
| `SKIMMING` | Data captured via ATM or POS skimming hardware |
| `DEVICE_COMPROMISE` | Fraud via malware, SIM swap, or hijacked device |
| `STOLEN_CREDENTIALS` | Credentials obtained via phishing, breach, or dark web |
| `NONE` | No fraud detected |

### Alert Rule Reference

| Rule | Trigger Condition |
|---|---|
| `VELOCITY_BREACH` | Transaction count exceeds threshold within rolling time window |
| `GEO_ANOMALY` | Origin/destination country differs from customer profile or prior behavior |
| `HIGH_RISK_SCORE` | Composite risk score exceeds defined threshold (default: ≥70) |
| `DEVICE_MISMATCH` | Device fingerprint does not match any known customer device |
| `AMOUNT_THRESHOLD` | Transaction exceeds customer-level or channel-level amount limit |
| `BLACKLIST_HIT` | Merchant, IP, device, or beneficiary matches known fraud blacklist |
| `PATTERN_MATCH` | Transaction matches known fraud typology pattern in rules engine |
| `ML_MODEL_FLAG` | ML model score exceeds alert threshold (default: ≥75) |
| `NONE` | No alert triggered |

### Resolution Status Reference

| Status | Meaning |
|---|---|
| `CLEARED` | Transaction reviewed and confirmed legitimate — no fraud |
| `FALSE_POSITIVE` | Alert triggered but transaction was not fraudulent |
| `CONFIRMED_FRAUD` | Investigation confirmed fraudulent activity |
| `UNDER_REVIEW` | Alert is currently under analyst investigation |
| `ESCALATED` | Referred to senior analyst, management, or law enforcement |

### Case Status Reference

| Status | Meaning |
|---|---|
| `OPEN` | Case created, not yet assigned or in early triage |
| `UNDER_INVESTIGATION` | Active investigation by assigned analyst |
| `RESOLVED` | Case closed with final determination |
| `ESCALATED` | Referred to Financial Intelligence Unit (FIU) or law enforcement |
| `SAR_FILED` | Suspicious Activity Report filed with FinCEN (US) |

### KYC Status Reference

| Status | Meaning |
|---|---|
| `VERIFIED` | Customer identity fully verified — standard monitoring |
| `PENDING` | KYC documentation submitted but not yet reviewed |
| `EXPIRED` | KYC documentation has passed its review expiry date |
| `UNDER_REVIEW` | Active KYC review in progress |
| `ENHANCED_DUE_DILIGENCE` | High-risk customer requiring additional verification steps |

### Account Type Reference

| Type | Description |
|---|---|
| `PERSONAL_CHECKING` | Standard personal checking account |
| `PERSONAL_SAVINGS` | Personal savings account |
| `BUSINESS_CHECKING` | Business/commercial checking account |
| `PREMIUM_ACCOUNT` | High-net-worth or private banking account |

---

*VaultSentinel Corp | Data Dictionary v2.1 | Fraud Risk Analytics Platform*
