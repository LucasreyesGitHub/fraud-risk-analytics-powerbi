# Changelog

All notable changes to the VaultSentinel Corp Fraud Risk Analytics Platform are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [2.1.0] — 2025-01

### Added
- `sql/01_create_schema.sql` — Full SQL Server 2019+ star schema DDL with 8 tables, 10 indexes, and referential integrity constraints
- `sql/02_sample_queries.sql` — 8 production analytical queries using CTEs, window functions, and parameterized date ranges
- `sql/03_stored_procedures.sql` — 3 stored procedures: monthly channel summary refresh, KPI dashboard data feed, customer risk score recalculation
- `scripts/validate_data.py` — Automated data quality validation for all 5 CSV datasets (schema, null, uniqueness, range, business rule, and referential integrity checks)
- `requirements.txt` — Python dependency manifest for scripts
- `screenshots/README.md` — Dashboard capture guide with page-by-page instructions
- `docs/Dashboard_Design_Spec.md` — Full dark enterprise design specification: Power BI theme JSON, 6 ASCII wireframes, 4 KPI card variants, drillthrough specs
- `docs/Anomaly_Detection_Framework.md` — 7 detection method deep-dives (Z-score, IQR, Peer Group, Velocity, Isolation Forest, LSTM, Behavioral Biometrics) with DAX implementations
- `dax/Advanced_DAX_Measures.dax` — 60+ advanced measures: cohort analysis, anomaly scoring, What-If parameters, executive scorecard, performance-optimized patterns
- `data/fraud_scenarios_2024.csv` — 10 named fraud campaigns (GOLDENWIRE, CREDSTORM, SYNTHWAVE24, INSIDEREDGE, etc.) with full attack narrative and financial outcomes

### Changed
- `README.md` — Added P0–P4 severity table, SOC alert ticket preview, fraud scenarios summary, dark design palette, full repository structure, and expanded skills list
- `data/transactions_2024.csv` — Enriched with `device_fingerprint`, `ip_reputation_score`, `velocity_count_1h`, `velocity_count_24h`, `ml_model_score` columns; cross-referenced with fraud cases
- `docs/SOC_Alert_Playbook.md` — Added MITRE-aligned TTP reference for financial fraud (FIN-T1 through FIN-T10) and escalation matrix
- `docs/Executive_Intelligence_Brief_Q4_2024.md` — Added Q4 threat intelligence section, 5 strategic recommendations with ROI estimates, regulatory landscape table

---

## [2.0.0] — 2024-12

### Added
- `docs/SOC_Alert_Playbook.md` — 5 production-style alert tickets, incident response playbooks (Wire/BEC and ATO), escalation matrix
- `docs/Executive_Intelligence_Brief_Q4_2024.md` — Board-level fraud intelligence brief with P0–P4 framework and FY2024 financial summary
- `PORTFOLIO.md` — LinkedIn copy, resume bullets by role type (Fraud Analyst, BI Developer, Risk Analytics), ATS keyword list, interview talking points

### Changed
- Enhanced DAX measures with ML model performance metrics (Precision, Recall, F1 Score)
- Expanded `data/fraud_cases_2024.csv` with priority classification, escalation flags, and SAR indicators
- Added dark theme color palette and KPI card design recommendations to documentation

---

## [1.0.0] — 2024-11

### Added
- Initial repository structure
- `README.md` with project overview, architecture diagram, and usage instructions
- `data/transactions_2024.csv` — 100 synthetic transaction records across 8 payment channels
- `data/customer_risk_profiles.csv` — 50 customer risk profiles across 5 risk tiers
- `data/fraud_cases_2024.csv` — 40 fraud investigation cases
- `data/monthly_channel_summary.csv` — 96-row pre-aggregated channel KPI dataset
- `dax/VaultSentinel_FraudMeasures.dax` — 40+ core DAX measures
- `docs/Data_Dictionary.md` — Column-level documentation for all tables
- `docs/Fraud_Detection_Methodology.md` — 4-layer detection architecture and scoring logic
- `docs/Business_Context.md` — Use case, stakeholder personas, and KPI framework
- `.gitignore` — Excludes PBIX files, environment variables, OS artifacts

---

*VaultSentinel Corp is a fictional enterprise. All data is 100% synthetic.*
