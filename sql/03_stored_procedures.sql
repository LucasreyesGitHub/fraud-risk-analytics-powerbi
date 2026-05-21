-- ============================================================
-- VaultSentinel Corp — Fraud Risk Analytics Platform
-- Stored Procedures — Data Refresh & Maintenance
-- Target: SQL Server 2019+ / Azure SQL Database
-- Version: 2.1 | Author: Lucas Reyes
-- ============================================================

USE FraudAnalyticsDB;
GO

-- ============================================================
-- SP 1: usp_refresh_monthly_channel_summary
-- Refreshes the pre-aggregated channel summary table for a
-- given month. Called nightly by the Azure Data Factory pipeline
-- for the current month, and on-demand for historical backfill.
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_refresh_monthly_channel_summary
    @year_month     CHAR(7),            -- Format: 'YYYY-MM'
    @replace_mode   BIT = 1             -- 1=delete+insert, 0=insert only
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @start_date DATE = CAST(@year_month + '-01' AS DATE);
    DECLARE @end_date   DATE = EOMONTH(@start_date);
    DECLARE @rows_inserted INT = 0;
    DECLARE @rows_deleted  INT = 0;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Remove existing rows for this period if replace mode
        IF @replace_mode = 1
        BEGIN
            DELETE FROM dbo.agg_monthly_channel_summary
            WHERE year_month = @year_month;

            SET @rows_deleted = @@ROWCOUNT;
        END

        -- Insert fresh aggregation
        INSERT INTO dbo.agg_monthly_channel_summary (
            year_month,
            channel_code,
            total_transactions,
            total_volume_usd,
            fraud_transactions,
            fraud_loss_usd,
            fraud_rate_pct,
            alert_count,
            false_positive_count,
            avg_risk_score,
            chargebacks_usd,
            net_fraud_loss_usd
        )
        SELECT
            @year_month                                             AS year_month,
            t.channel_code,
            COUNT(*)                                               AS total_transactions,
            SUM(t.amount_usd)                                      AS total_volume_usd,
            COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END)           AS fraud_transactions,
            SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd
                     ELSE 0 END)                                   AS fraud_loss_usd,
            CAST(
                COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END) * 100.0
                / NULLIF(COUNT(*), 0)
            AS DECIMAL(7,4))                                       AS fraud_rate_pct,
            COUNT(CASE WHEN t.alert_rule_triggered <> 'NONE'
                       THEN 1 END)                                 AS alert_count,
            COUNT(CASE WHEN t.resolution_status = 'FALSE_POSITIVE'
                       THEN 1 END)                                 AS false_positive_count,
            AVG(CAST(t.risk_score AS DECIMAL(5,2)))                AS avg_risk_score,
            SUM(t.chargeback_amount_usd)                           AS chargebacks_usd,
            SUM(CASE WHEN t.fraud_flag = 1 THEN t.amount_usd
                     ELSE 0 END)
                - SUM(t.chargeback_amount_usd)                    AS net_fraud_loss_usd
        FROM dbo.fact_transactions t
        WHERE t.transaction_date BETWEEN @start_date AND @end_date
        GROUP BY t.channel_code;

        SET @rows_inserted = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Return execution summary
        SELECT
            @year_month         AS refreshed_period,
            @rows_deleted       AS rows_deleted,
            @rows_inserted      AS rows_inserted,
            SYSUTCDATETIME()    AS completed_at,
            'SUCCESS'           AS status;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        SELECT
            @year_month             AS refreshed_period,
            ERROR_NUMBER()          AS error_number,
            ERROR_MESSAGE()         AS error_message,
            ERROR_LINE()            AS error_line,
            SYSUTCDATETIME()        AS failed_at,
            'FAILED'                AS status;

        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- SP 2: usp_get_fraud_kpi_dashboard
-- Returns all KPI values for the executive dashboard for a
-- given date range. Called by Power BI DirectQuery mode or
-- as a cached Import refresh every 4 hours.
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_get_fraud_kpi_dashboard
    @start_date     DATE = NULL,        -- Default: first day of current month
    @end_date       DATE = NULL,        -- Default: today
    @compare_start  DATE = NULL,        -- Default: same period prior year
    @compare_end    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Set default date ranges
    SET @start_date   = ISNULL(@start_date, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));
    SET @end_date     = ISNULL(@end_date, CAST(GETDATE() AS DATE));
    SET @compare_start = ISNULL(@compare_start, DATEADD(YEAR, -1, @start_date));
    SET @compare_end   = ISNULL(@compare_end, DATEADD(YEAR, -1, @end_date));

    -- Current period KPIs
    WITH current_period AS (
        SELECT
            COUNT(*)                                               AS total_txns,
            COUNT(CASE WHEN fraud_flag = 1 THEN 1 END)             AS fraud_txns,
            SUM(amount_usd)                                        AS total_volume,
            SUM(CASE WHEN fraud_flag = 1 THEN amount_usd ELSE 0 END) AS gross_loss,
            SUM(chargeback_amount_usd)                             AS recovered,
            COUNT(CASE WHEN alert_rule_triggered <> 'NONE' THEN 1 END) AS alerts,
            COUNT(CASE WHEN resolution_status = 'FALSE_POSITIVE' THEN 1 END) AS false_pos
        FROM dbo.fact_transactions
        WHERE transaction_date BETWEEN @start_date AND @end_date
    ),
    -- Prior period KPIs (for YoY / period-over-period deltas)
    prior_period AS (
        SELECT
            SUM(CASE WHEN fraud_flag = 1 THEN amount_usd ELSE 0 END)
                - SUM(chargeback_amount_usd)                      AS prior_net_loss,
            CAST(COUNT(CASE WHEN fraud_flag = 1 THEN 1 END) * 100.0
                / NULLIF(COUNT(*), 0) AS DECIMAL(7,4))            AS prior_detection_rate
        FROM dbo.fact_transactions
        WHERE transaction_date BETWEEN @compare_start AND @compare_end
    ),
    -- Case metrics
    case_metrics AS (
        SELECT
            COUNT(CASE WHEN case_status IN ('OPEN','UNDER_INVESTIGATION') THEN 1 END) AS open_cases,
            AVG(CASE WHEN case_status = 'RESOLVED'
                     THEN CAST(resolution_days AS DECIMAL(6,2)) END) AS avg_resolution_days,
            SUM(CASE WHEN case_status IN ('OPEN','UNDER_INVESTIGATION')
                     THEN amount_at_risk_usd ELSE 0 END)           AS open_exposure
        FROM dbo.fact_fraud_cases
        WHERE case_open_date BETWEEN @start_date AND @end_date
            OR (case_status IN ('OPEN','UNDER_INVESTIGATION')
                AND case_open_date <= @end_date)
    )
    SELECT
        -- Period labels
        @start_date                                                AS period_start,
        @end_date                                                  AS period_end,

        -- Volume
        cp.total_txns,
        cp.fraud_txns,
        cp.total_txns - cp.fraud_txns                             AS legitimate_txns,

        -- Financial
        cp.total_volume,
        cp.gross_loss,
        cp.recovered,
        cp.gross_loss - cp.recovered                              AS net_fraud_loss,
        CAST((cp.gross_loss - cp.recovered) / NULLIF(cp.total_volume, 0) * 10000
            AS DECIMAL(8,4))                                      AS fraud_loss_rate_bps,

        -- Detection
        CAST(cp.fraud_txns * 100.0 / NULLIF(cp.total_txns, 0)
            AS DECIMAL(7,4))                                      AS detection_rate_pct,
        CAST(cp.false_pos * 100.0 / NULLIF(cp.alerts, 0)
            AS DECIMAL(7,4))                                      AS false_positive_rate_pct,

        -- YoY delta
        pp.prior_net_loss,
        CAST((cp.gross_loss - cp.recovered - pp.prior_net_loss)
            / NULLIF(pp.prior_net_loss, 0) * 100
            AS DECIMAL(7,4))                                      AS yoy_net_loss_change_pct,

        -- Case management
        cm.open_cases,
        cm.avg_resolution_days,
        cm.open_exposure,

        SYSUTCDATETIME()                                           AS generated_at

    FROM current_period cp
    CROSS JOIN prior_period pp
    CROSS JOIN case_metrics cm;
END;
GO

-- ============================================================
-- SP 3: usp_flag_high_risk_customers
-- Updates composite_risk_score and risk_tier for customers
-- based on recent transaction behavior. Run nightly.
-- Simplified scoring logic — production version integrates
-- with the full feature pipeline from the ML platform.
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_flag_high_risk_customers
    @lookback_days  INT = 90            -- Rolling window for behavioral scoring
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @cutoff_date DATE = DATEADD(DAY, -@lookback_days, CAST(GETDATE() AS DATE));
    DECLARE @updated_rows INT = 0;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Update risk scores based on recent transaction signals
        UPDATE c
        SET
            composite_risk_score = CAST(
                -- Base score (existing)
                c.composite_risk_score * 0.4
                -- Fraud history weight
                + CASE WHEN stats.fraud_count_90d >= 3 THEN 30
                       WHEN stats.fraud_count_90d >= 1 THEN 15
                       ELSE 0 END
                -- Dispute history weight
                + CASE WHEN stats.dispute_count_90d >= 5 THEN 20
                       WHEN stats.dispute_count_90d >= 2 THEN 10
                       ELSE 0 END
                -- Velocity anomaly weight
                + CASE WHEN stats.max_daily_velocity >= 10 THEN 15
                       WHEN stats.max_daily_velocity >= 6  THEN 8
                       ELSE 0 END
                -- High-risk channel usage
                + CASE WHEN stats.intl_wire_count_90d >= 3 THEN 10
                       WHEN stats.intl_wire_count_90d >= 1 THEN 5
                       ELSE 0 END
            AS TINYINT),

            -- Reclassify risk tier based on updated score
            risk_tier = CASE
                WHEN CAST(
                        c.composite_risk_score * 0.4
                        + CASE WHEN stats.fraud_count_90d >= 3 THEN 30
                               WHEN stats.fraud_count_90d >= 1 THEN 15 ELSE 0 END
                        + CASE WHEN stats.dispute_count_90d >= 5 THEN 20
                               WHEN stats.dispute_count_90d >= 2 THEN 10 ELSE 0 END
                        + CASE WHEN stats.max_daily_velocity >= 10 THEN 15
                               WHEN stats.max_daily_velocity >= 6  THEN 8  ELSE 0 END
                        + CASE WHEN stats.intl_wire_count_90d >= 3 THEN 10
                               WHEN stats.intl_wire_count_90d >= 1 THEN 5  ELSE 0 END
                    AS TINYINT) >= 80 THEN 'CRITICAL'
                WHEN CAST(
                        c.composite_risk_score * 0.4
                        + CASE WHEN stats.fraud_count_90d >= 3 THEN 30
                               WHEN stats.fraud_count_90d >= 1 THEN 15 ELSE 0 END
                    AS TINYINT) >= 60 THEN 'HIGH'
                WHEN c.composite_risk_score >= 40 THEN 'MEDIUM'
                WHEN c.composite_risk_score >= 20 THEN 'LOW'
                ELSE 'MINIMAL'
            END,

            row_updated_at = SYSUTCDATETIME()

        FROM dbo.dim_customer c
        INNER JOIN (
            SELECT
                t.customer_key,
                COUNT(CASE WHEN t.fraud_flag = 1 THEN 1 END)           AS fraud_count_90d,
                COUNT(CASE WHEN t.resolution_status = 'FALSE_POSITIVE'
                               OR t.alert_rule_triggered <> 'NONE'
                           THEN 1 END)                                  AS dispute_count_90d,
                MAX(daily_counts.daily_count)                           AS max_daily_velocity,
                COUNT(CASE WHEN t.channel_code = 'WIRE_INTERNATIONAL'
                           THEN 1 END)                                  AS intl_wire_count_90d
            FROM dbo.fact_transactions t
            INNER JOIN (
                SELECT customer_key, CAST(transaction_date AS DATE) AS txn_date,
                       COUNT(*) AS daily_count
                FROM dbo.fact_transactions
                WHERE transaction_date >= @cutoff_date
                GROUP BY customer_key, CAST(transaction_date AS DATE)
            ) daily_counts ON t.customer_key = daily_counts.customer_key
            WHERE t.transaction_date >= @cutoff_date
            GROUP BY t.customer_key
        ) stats ON c.customer_key = stats.customer_key;

        SET @updated_rows = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @updated_rows       AS customers_updated,
            @lookback_days      AS lookback_window_days,
            SYSUTCDATETIME()    AS completed_at,
            'SUCCESS'           AS status;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

PRINT 'Stored procedures created successfully.';
GO
