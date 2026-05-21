-- ============================================================
-- VaultSentinel Corp — Fraud Risk Analytics Platform
-- Sample Analytical Queries — Power BI Data Source Reference
-- Target: SQL Server 2019+ / Azure SQL Database
-- Version: 2.1 | Author: Lucas Reyes
-- ============================================================
-- These queries serve as the logical basis for Power BI
-- measures and visuals. Parameterize dates via Power Query
-- or pass as stored procedure arguments in production.
-- ============================================================

USE FraudAnalyticsDB;
GO

-- ============================================================
-- QUERY 1: Executive KPI Summary
-- Powers: Executive Risk Command Center — KPI Cards
-- ============================================================
SELECT
    -- Volume
    COUNT(*)                                                        AS total_transactions,
    COUNT(CASE WHEN fraud_flag = 1 THEN 1 END)                     AS fraud_transactions,
    COUNT(CASE WHEN fraud_flag = 0 THEN 1 END)                     AS legitimate_transactions,

    -- Financial
    SUM(amount_usd)                                                 AS total_volume_usd,
    SUM(CASE WHEN fraud_flag = 1 THEN amount_usd ELSE 0 END)       AS gross_fraud_loss_usd,
    SUM(chargeback_amount_usd)                                      AS chargeback_recovered_usd,
    SUM(CASE WHEN fraud_flag = 1 THEN amount_usd ELSE 0 END)
        - SUM(chargeback_amount_usd)                               AS net_fraud_loss_usd,

    -- Rate metrics
    CAST(
        COUNT(CASE WHEN fraud_flag = 1 THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(7,4))                                                AS fraud_detection_rate_pct,

    CAST(
        (SUM(CASE WHEN fraud_flag = 1 THEN amount_usd ELSE 0 END)
            - SUM(chargeback_amount_usd))
        / NULLIF(SUM(amount_usd), 0) * 10000
    AS DECIMAL(8,4))                                                AS fraud_loss_rate_bps,

    -- Alert metrics
    COUNT(CASE WHEN alert_rule_triggered <> 'NONE' THEN 1 END)     AS total_alerts,
    COUNT(CASE WHEN resolution_status = 'FALSE_POSITIVE' THEN 1 END) AS false_positives,
    AVG(CAST(risk_score AS DECIMAL(5,2)))                          AS avg_risk_score

FROM dbo.fact_transactions
WHERE transaction_date BETWEEN @start_date AND @end_date;
GO

-- ============================================================
-- QUERY 2: Monthly Fraud Loss Trend (12-Month Rolling)
-- Powers: Executive page — Fraud Loss Trend line chart
-- ============================================================
SELECT
    d.year_month,
    d.[year],
    d.[month],
    d.month_name,
    COUNT(*)                                                        AS total_transactions,
    SUM(t.amount_usd)                                               AS total_volume_usd,
    COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END)                   AS fraud_count,
    SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)   AS gross_fraud_loss_usd,
    SUM(t.chargeback_amount_usd)                                    AS chargebacks_usd,
    SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)
        - SUM(t.chargeback_amount_usd)                             AS net_fraud_loss_usd,
    CAST(
        (SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)
            - SUM(t.chargeback_amount_usd))
        / NULLIF(SUM(t.amount_usd), 0) * 10000
    AS DECIMAL(8,4))                                               AS fraud_loss_rate_bps,

    -- Month-over-month change (using LAG)
    LAG(
        SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)
        - SUM(t.chargeback_amount_usd)
    , 1) OVER (ORDER BY d.year_month)                              AS prior_month_net_loss_usd,

    -- Running YTD total
    SUM(
        SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)
        - SUM(t.chargeback_amount_usd)
    ) OVER (
        PARTITION BY d.[year]
        ORDER BY d.[month]
        ROWS UNBOUNDED PRECEDING
    )                                                              AS ytd_net_fraud_loss_usd

FROM dbo.fact_transactions t
INNER JOIN dbo.dim_date d
    ON t.date_key = d.date_key
WHERE d.[year] >= YEAR(GETDATE()) - 1      -- Current + prior year
GROUP BY d.year_month, d.[year], d.[month], d.month_name
ORDER BY d.year_month;
GO

-- ============================================================
-- QUERY 3: Fraud Rate & Loss by Channel
-- Powers: Multi-Channel Intelligence — channel bar charts
-- ============================================================
SELECT
    t.channel_code,
    c.channel_name,
    c.channel_group,
    c.base_risk_tier,
    COUNT(*)                                                        AS total_transactions,
    COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END)                   AS fraud_transactions,
    CAST(
        COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(7,4))                                               AS fraud_rate_pct,
    SUM(t.amount_usd)                                              AS total_volume_usd,
    SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)  AS gross_fraud_loss_usd,
    SUM(t.chargeback_amount_usd)                                   AS recovered_usd,
    SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)
        - SUM(t.chargeback_amount_usd)                            AS net_fraud_loss_usd,
    CAST(
        (SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)
            - SUM(t.chargeback_amount_usd))
        / NULLIF(SUM(t.amount_usd), 0) * 10000
    AS DECIMAL(8,4))                                               AS fraud_loss_rate_bps,
    AVG(CAST(t.ml_model_score AS DECIMAL(6,2)))                    AS avg_ml_score,
    COUNT(CASE WHEN t.alert_rule_triggered <> 'NONE' THEN 1 END)   AS alert_count,

    -- Rank channels by fraud loss (for sorting in Power BI)
    RANK() OVER (ORDER BY
        SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)
        - SUM(t.chargeback_amount_usd) DESC
    )                                                              AS loss_rank

FROM dbo.fact_transactions t
LEFT JOIN dbo.dim_channel c
    ON t.channel_code = c.channel_code
WHERE t.transaction_date BETWEEN @start_date AND @end_date
GROUP BY t.channel_code, c.channel_name, c.channel_group, c.base_risk_tier
ORDER BY net_fraud_loss_usd DESC;
GO

-- ============================================================
-- QUERY 4: ML Model Performance — Confusion Matrix Components
-- Powers: ML Model Performance Monitor page
-- ============================================================
WITH model_outcomes AS (
    SELECT
        transaction_id,
        fraud_flag                                                  AS actual_fraud,
        ml_model_score,
        CASE WHEN ml_model_score >= @alert_threshold THEN 1
             ELSE 0
        END                                                        AS model_predicted_fraud,
        resolution_status
    FROM dbo.fact_transactions
    WHERE transaction_date BETWEEN @start_date AND @end_date
)
SELECT
    -- Confusion matrix
    COUNT(CASE WHEN actual_fraud = 1 AND model_predicted_fraud = 1 THEN 1 END) AS true_positives,
    COUNT(CASE WHEN actual_fraud = 0 AND model_predicted_fraud = 1 THEN 1 END) AS false_positives,
    COUNT(CASE WHEN actual_fraud = 1 AND model_predicted_fraud = 0 THEN 1 END) AS false_negatives,
    COUNT(CASE WHEN actual_fraud = 0 AND model_predicted_fraud = 0 THEN 1 END) AS true_negatives,

    -- Derived performance metrics
    CAST(
        COUNT(CASE WHEN actual_fraud = 1 AND model_predicted_fraud = 1 THEN 1 END) * 100.0
        / NULLIF(
            COUNT(CASE WHEN actual_fraud = 1 AND model_predicted_fraud = 1 THEN 1 END)
            + COUNT(CASE WHEN actual_fraud = 0 AND model_predicted_fraud = 1 THEN 1 END)
        , 0)
    AS DECIMAL(7,4))                                               AS precision_pct,

    CAST(
        COUNT(CASE WHEN actual_fraud = 1 AND model_predicted_fraud = 1 THEN 1 END) * 100.0
        / NULLIF(
            COUNT(CASE WHEN actual_fraud = 1 AND model_predicted_fraud = 1 THEN 1 END)
            + COUNT(CASE WHEN actual_fraud = 1 AND model_predicted_fraud = 0 THEN 1 END)
        , 0)
    AS DECIMAL(7,4))                                               AS recall_pct,

    -- F1 Score (computed in application layer or Power BI DAX)
    COUNT(*)                                                       AS total_transactions_scored,
    AVG(ml_model_score)                                            AS avg_model_score,
    STDEV(ml_model_score)                                          AS stdev_model_score,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY ml_model_score)
        OVER ()                                                    AS median_model_score

FROM model_outcomes;
GO

-- ============================================================
-- QUERY 5: Customer Risk Portfolio Summary
-- Powers: Customer Risk Segmentation page
-- ============================================================
SELECT
    rt.tier_code                                                   AS risk_tier,
    rt.tier_label,
    rt.score_min,
    rt.score_max,
    COUNT(c.customer_key)                                          AS customer_count,
    CAST(COUNT(c.customer_key) * 100.0
        / SUM(COUNT(c.customer_key)) OVER ()
    AS DECIMAL(6,2))                                               AS portfolio_share_pct,
    AVG(c.composite_risk_score)                                    AS avg_risk_score,
    SUM(c.fraud_history_count)                                     AS total_fraud_incidents,
    COUNT(CASE WHEN c.watchlist_flag = 1 THEN 1 END)               AS watchlisted_count,
    COUNT(CASE WHEN c.pep_flag = 1 THEN 1 END)                     AS pep_count,
    COUNT(CASE WHEN c.kyc_status = 'ENHANCED_DUE_DILIGENCE' THEN 1 END) AS edd_count,
    COUNT(CASE WHEN c.kyc_status = 'PENDING' THEN 1 END)           AS pending_kyc_count,
    AVG(c.avg_transaction_amount_usd)                              AS avg_transaction_amount

FROM dbo.dim_customer c
LEFT JOIN dbo.dim_risk_tier rt
    ON c.risk_tier = rt.tier_code
GROUP BY rt.tier_code, rt.tier_label, rt.score_min, rt.score_max
ORDER BY rt.score_min DESC;
GO

-- ============================================================
-- QUERY 6: Open Fraud Case Queue with SLA Status
-- Powers: Case Operations Pipeline page — case queue table
-- ============================================================
SELECT
    fc.case_id,
    fc.case_open_date,
    DATEDIFF(DAY, fc.case_open_date, GETDATE())                    AS days_open,
    c.customer_id,
    c.full_name,
    c.risk_tier                                                    AS customer_risk_tier,
    fc.channel_code,
    fc.fraud_type,
    fc.case_status,
    fc.priority,
    fc.assigned_analyst,
    fc.amount_at_risk_usd,
    fc.recovered_amount_usd,
    fc.amount_at_risk_usd - fc.recovered_amount_usd                AS outstanding_exposure_usd,
    fc.escalation_flag,
    fc.sar_filed,

    -- SLA status based on priority and days open
    CASE fc.priority
        WHEN 'CRITICAL' THEN
            CASE WHEN DATEDIFF(DAY, fc.case_open_date, GETDATE()) > 3  THEN 'SLA_BREACHED'
                 WHEN DATEDIFF(DAY, fc.case_open_date, GETDATE()) >= 2 THEN 'SLA_AT_RISK'
                 ELSE 'ON_TARGET' END
        WHEN 'HIGH' THEN
            CASE WHEN DATEDIFF(DAY, fc.case_open_date, GETDATE()) > 7  THEN 'SLA_BREACHED'
                 WHEN DATEDIFF(DAY, fc.case_open_date, GETDATE()) >= 5 THEN 'SLA_AT_RISK'
                 ELSE 'ON_TARGET' END
        WHEN 'MEDIUM' THEN
            CASE WHEN DATEDIFF(DAY, fc.case_open_date, GETDATE()) > 14 THEN 'SLA_BREACHED'
                 WHEN DATEDIFF(DAY, fc.case_open_date, GETDATE()) >= 10 THEN 'SLA_AT_RISK'
                 ELSE 'ON_TARGET' END
        ELSE  -- LOW
            CASE WHEN DATEDIFF(DAY, fc.case_open_date, GETDATE()) > 21 THEN 'SLA_BREACHED'
                 WHEN DATEDIFF(DAY, fc.case_open_date, GETDATE()) >= 15 THEN 'SLA_AT_RISK'
                 ELSE 'ON_TARGET' END
    END                                                            AS sla_status

FROM dbo.fact_fraud_cases fc
INNER JOIN dbo.dim_customer c
    ON fc.customer_key = c.customer_key
WHERE fc.case_status IN ('OPEN', 'UNDER_INVESTIGATION', 'ESCALATED')
ORDER BY
    CASE fc.priority
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH'     THEN 2
        WHEN 'MEDIUM'   THEN 3
        ELSE 4
    END,
    fc.amount_at_risk_usd DESC;
GO

-- ============================================================
-- QUERY 7: Geospatial Fraud Intelligence
-- Powers: Geospatial Fraud Intelligence page
-- ============================================================
SELECT
    t.destination_country                                          AS country_code,
    COUNT(*)                                                       AS transaction_count,
    COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END)                   AS fraud_count,
    CAST(
        COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(7,4))                                               AS fraud_rate_pct,
    SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)   AS gross_fraud_loss_usd,
    SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd ELSE 0 END)
        - SUM(t.chargeback_amount_usd)                            AS net_fraud_loss_usd,
    AVG(CAST(t.risk_score AS DECIMAL(5,2)))                        AS avg_risk_score,
    AVG(CAST(t.ip_reputation_score AS DECIMAL(5,2)))               AS avg_ip_reputation,
    COUNT(DISTINCT t.customer_key)                                 AS unique_customers,

    -- Risk tier for map color coding
    CASE
        WHEN COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) * 100.0
             / NULLIF(COUNT(*), 0) >= 8  THEN 'TIER_1_HIGH'
        WHEN COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) * 100.0
             / NULLIF(COUNT(*), 0) >= 4  THEN 'TIER_2_ELEVATED'
        WHEN COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) * 100.0
             / NULLIF(COUNT(*), 0) >= 1  THEN 'TIER_3_WATCH'
        ELSE 'TIER_4_NORMAL'
    END                                                            AS jurisdiction_risk_tier

FROM dbo.fact_transactions t
WHERE t.transaction_date BETWEEN @start_date AND @end_date
GROUP BY t.destination_country
ORDER BY net_fraud_loss_usd DESC;
GO

-- ============================================================
-- QUERY 8: Analyst Workload & Case Resolution Performance
-- Powers: Case Operations Pipeline — analyst heatmap
-- ============================================================
SELECT
    fc.assigned_analyst,
    COUNT(CASE WHEN fc.case_status IN ('OPEN','UNDER_INVESTIGATION') THEN 1 END) AS open_cases,
    COUNT(CASE WHEN fc.case_status = 'RESOLVED' THEN 1 END)        AS resolved_cases,
    COUNT(*)                                                       AS total_cases_ytd,
    SUM(CASE WHEN fc.case_status IN ('OPEN','UNDER_INVESTIGATION')
             THEN fc.amount_at_risk_usd ELSE 0 END)               AS open_exposure_usd,
    AVG(CASE WHEN fc.case_status = 'RESOLVED'
             THEN CAST(fc.resolution_days AS DECIMAL(6,2)) END)    AS avg_resolution_days,
    COUNT(CASE WHEN fc.sar_filed = 1 THEN 1 END)                   AS sars_filed,
    SUM(fc.recovered_amount_usd)                                   AS total_recovered_usd,
    CAST(
        SUM(fc.recovered_amount_usd) * 100.0
        / NULLIF(SUM(fc.amount_at_risk_usd), 0)
    AS DECIMAL(7,4))                                               AS recovery_rate_pct
FROM dbo.fact_fraud_cases fc
WHERE YEAR(fc.case_open_date) = @report_year
  AND fc.assigned_analyst IS NOT NULL
GROUP BY fc.assigned_analyst
ORDER BY open_cases DESC, open_exposure_usd DESC;
GO
