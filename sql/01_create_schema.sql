-- ============================================================
-- VaultSentinel Corp — Fraud Risk Analytics Platform
-- Database Schema: DDL — Table & Index Creation
-- Target: SQL Server 2019+ / Azure SQL Database
-- Version: 2.1 | Author: Lucas Reyes
-- ============================================================
-- Run order:
--   1. 01_create_schema.sql  (this file)
--   2. 02_sample_queries.sql
--   3. 03_stored_procedures.sql
-- ============================================================

USE FraudAnalyticsDB;
GO

-- ============================================================
-- SECTION 1: DIMENSION TABLES
-- ============================================================

-- ------------------------------------------------------------
-- dim_date
-- Standard date dimension for all time-intelligence joins.
-- Power BI Dim_Date equivalent — mark as date table in report.
-- ------------------------------------------------------------
CREATE TABLE dbo.dim_date (
    date_key        INT          NOT NULL,          -- Surrogate key: YYYYMMDD integer
    full_date       DATE         NOT NULL,
    [year]          SMALLINT     NOT NULL,
    quarter_number  TINYINT      NOT NULL,
    quarter_label   CHAR(6)      NOT NULL,          -- e.g. 'Q1 2024'
    [month]         TINYINT      NOT NULL,
    month_name      VARCHAR(10)  NOT NULL,
    month_short     CHAR(3)      NOT NULL,          -- e.g. 'Jan'
    year_month      CHAR(7)      NOT NULL,          -- e.g. '2024-01' — joins to monthly_channel_summary
    week_of_year    TINYINT      NOT NULL,
    day_of_month    TINYINT      NOT NULL,
    day_of_week     TINYINT      NOT NULL,          -- 1=Sunday, 7=Saturday (US convention)
    day_name        VARCHAR(10)  NOT NULL,
    is_weekend      BIT          NOT NULL DEFAULT 0,
    is_us_holiday   BIT          NOT NULL DEFAULT 0,
    fiscal_year     SMALLINT     NOT NULL,          -- VaultSentinel fiscal year (Jan–Dec)
    fiscal_quarter  TINYINT      NOT NULL,
    CONSTRAINT PK_dim_date PRIMARY KEY CLUSTERED (date_key)
);
GO

-- ------------------------------------------------------------
-- dim_channel
-- Payment channel reference — one row per channel type.
-- ------------------------------------------------------------
CREATE TABLE dbo.dim_channel (
    channel_key     TINYINT      NOT NULL IDENTITY(1,1),
    channel_code    VARCHAR(30)  NOT NULL,          -- Matches transactions.channel
    channel_name    VARCHAR(60)  NOT NULL,          -- Human-readable label
    channel_group   VARCHAR(20)  NOT NULL,          -- CARD | ACH | WIRE | DIGITAL
    base_risk_tier  VARCHAR(10)  NOT NULL,          -- LOW | MEDIUM | HIGH
    is_digital      BIT          NOT NULL DEFAULT 0,
    is_cross_border BIT          NOT NULL DEFAULT 0, -- Wire International only
    typical_fraud_rate_bps SMALLINT NULL,           -- Baseline fraud rate in basis points
    CONSTRAINT PK_dim_channel PRIMARY KEY (channel_key),
    CONSTRAINT UQ_channel_code UNIQUE (channel_code),
    CONSTRAINT CHK_channel_group CHECK (channel_group IN ('CARD','ACH','WIRE','DIGITAL'))
);
GO

-- ------------------------------------------------------------
-- dim_fraud_type
-- Fraud classification taxonomy — used for consistent labeling
-- across transactions, cases, and scenario datasets.
-- ------------------------------------------------------------
CREATE TABLE dbo.dim_fraud_type (
    fraud_type_key  SMALLINT     NOT NULL IDENTITY(1,1),
    fraud_type_code VARCHAR(30)  NOT NULL,          -- Matches transactions.fraud_type
    fraud_type_name VARCHAR(80)  NOT NULL,
    category        VARCHAR(40)  NOT NULL,          -- e.g. IDENTITY_FRAUD, PAYMENT_FRAUD
    ttp_code        VARCHAR(20)  NULL,              -- Internal MITRE-aligned TTP reference
    requires_sar    BIT          NOT NULL DEFAULT 0, -- Fraud types typically requiring SAR
    avg_loss_usd    DECIMAL(12,2) NULL,
    description     VARCHAR(500) NULL,
    CONSTRAINT PK_dim_fraud_type PRIMARY KEY (fraud_type_key),
    CONSTRAINT UQ_fraud_type_code UNIQUE (fraud_type_code)
);
GO

-- ------------------------------------------------------------
-- dim_risk_tier
-- Risk tier reference with thresholds and required actions.
-- ------------------------------------------------------------
CREATE TABLE dbo.dim_risk_tier (
    risk_tier_key   TINYINT      NOT NULL IDENTITY(1,1),
    tier_code       VARCHAR(10)  NOT NULL,          -- MINIMAL | LOW | MEDIUM | HIGH | CRITICAL
    tier_label      VARCHAR(20)  NOT NULL,
    score_min       TINYINT      NOT NULL,
    score_max       TINYINT      NOT NULL,
    review_cycle_days SMALLINT   NOT NULL,          -- Required review frequency
    requires_edd    BIT          NOT NULL DEFAULT 0, -- Enhanced Due Diligence required
    monitoring_level VARCHAR(20) NOT NULL,
    CONSTRAINT PK_dim_risk_tier PRIMARY KEY (risk_tier_key),
    CONSTRAINT UQ_tier_code UNIQUE (tier_code),
    CONSTRAINT CHK_score_range CHECK (score_min >= 0 AND score_max <= 100 AND score_min < score_max)
);
GO

-- ------------------------------------------------------------
-- dim_customer
-- Customer/account dimension — one row per customer account.
-- Source: customer_risk_profiles.csv
-- Updated via nightly ELT refresh from core banking system.
-- ------------------------------------------------------------
CREATE TABLE dbo.dim_customer (
    customer_key            INT          NOT NULL IDENTITY(1,1),
    customer_id             VARCHAR(15)  NOT NULL,  -- Natural key: CUST-NNNNN
    full_name               VARCHAR(100) NOT NULL,
    account_open_date       DATE         NOT NULL,
    account_type            VARCHAR(30)  NOT NULL,
    annual_income_band      VARCHAR(20)  NULL,
    credit_score_band       VARCHAR(20)  NULL,
    country                 CHAR(2)      NOT NULL DEFAULT 'US',
    [state]                 CHAR(2)      NULL,
    risk_tier               VARCHAR(10)  NOT NULL,
    composite_risk_score    TINYINT      NOT NULL,
    fraud_history_count     TINYINT      NOT NULL DEFAULT 0,
    dispute_count           TINYINT      NOT NULL DEFAULT 0,
    avg_monthly_transactions TINYINT     NULL,
    avg_transaction_amount_usd DECIMAL(12,2) NULL,
    primary_channel         VARCHAR(30)  NULL,
    kyc_status              VARCHAR(35)  NOT NULL DEFAULT 'VERIFIED',
    watchlist_flag          BIT          NOT NULL DEFAULT 0,
    pep_flag                BIT          NOT NULL DEFAULT 0,  -- Politically Exposed Person
    last_review_date        DATE         NULL,
    risk_analyst_id         VARCHAR(10)  NULL,
    row_created_at          DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    row_updated_at          DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_dim_customer PRIMARY KEY (customer_key),
    CONSTRAINT UQ_customer_id UNIQUE (customer_id),
    CONSTRAINT CHK_risk_score CHECK (composite_risk_score BETWEEN 0 AND 100),
    CONSTRAINT CHK_customer_risk_tier CHECK (
        risk_tier IN ('MINIMAL','LOW','MEDIUM','HIGH','CRITICAL')
    ),
    CONSTRAINT CHK_kyc_status CHECK (
        kyc_status IN (
            'VERIFIED','PENDING','EXPIRED','UNDER_REVIEW','ENHANCED_DUE_DILIGENCE'
        )
    )
);
GO

-- ============================================================
-- SECTION 2: FACT TABLES
-- ============================================================

-- ------------------------------------------------------------
-- fact_transactions
-- Central transaction fact — one row per payment transaction.
-- Source: transactions_2024.csv (sample) / core banking system.
-- Partitioned by transaction_date in production.
-- ------------------------------------------------------------
CREATE TABLE dbo.fact_transactions (
    transaction_key         BIGINT       NOT NULL IDENTITY(1,1),
    transaction_id          VARCHAR(20)  NOT NULL,  -- Natural key: TXN-YYYY-NNNNN
    transaction_date        DATE         NOT NULL,
    transaction_time        TIME(0)      NOT NULL,
    date_key                INT          NOT NULL,  -- FK → dim_date
    customer_key            INT          NOT NULL,  -- FK → dim_customer
    channel_code            VARCHAR(30)  NOT NULL,  -- Denormalized for query performance
    amount_usd              DECIMAL(14,2) NOT NULL,
    currency                CHAR(3)      NOT NULL DEFAULT 'USD',
    merchant_category_code  SMALLINT     NULL,      -- ISO 18245 MCC
    merchant_name           VARCHAR(100) NULL,
    account_last4           CHAR(4)      NULL,      -- PCI: last 4 digits only, never full PAN
    origin_country          CHAR(2)      NOT NULL DEFAULT 'US',
    destination_country     CHAR(2)      NOT NULL DEFAULT 'US',
    risk_score              TINYINT      NOT NULL,  -- Composite real-time score (0–100)
    fraud_flag              BIT          NOT NULL DEFAULT 0,
    fraud_type              VARCHAR(30)  NOT NULL DEFAULT 'NONE',
    alert_rule_triggered    VARCHAR(30)  NOT NULL DEFAULT 'NONE',
    resolution_status       VARCHAR(20)  NOT NULL DEFAULT 'CLEARED',
    chargeback_amount_usd   DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    device_fingerprint      VARCHAR(20)  NULL,      -- Hashed device identifier
    ip_reputation_score     TINYINT      NULL,      -- 0=malicious, 100=trusted
    velocity_count_1h       TINYINT      NULL,
    velocity_count_24h      TINYINT      NULL,
    ml_model_score          DECIMAL(5,2) NULL,      -- ML fraud probability score (0.00–100.00)
    row_created_at          DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_fact_transactions PRIMARY KEY CLUSTERED (transaction_key),
    CONSTRAINT UQ_transaction_id UNIQUE (transaction_id),
    CONSTRAINT FK_txn_date FOREIGN KEY (date_key)
        REFERENCES dbo.dim_date (date_key),
    CONSTRAINT FK_txn_customer FOREIGN KEY (customer_key)
        REFERENCES dbo.dim_customer (customer_key),
    CONSTRAINT CHK_txn_amount CHECK (amount_usd > 0),
    CONSTRAINT CHK_txn_risk_score CHECK (risk_score BETWEEN 0 AND 100),
    CONSTRAINT CHK_txn_fraud_flag CHECK (fraud_flag IN (0,1)),
    CONSTRAINT CHK_txn_chargeback CHECK (chargeback_amount_usd >= 0),
    CONSTRAINT CHK_txn_resolution CHECK (
        resolution_status IN (
            'CLEARED','FALSE_POSITIVE','CONFIRMED_FRAUD','UNDER_REVIEW','ESCALATED'
        )
    )
);
GO

-- ------------------------------------------------------------
-- fact_fraud_cases
-- Fraud investigation case fact — one row per case.
-- Source: fraud_cases_2024.csv / Actimize RCM case management.
-- ------------------------------------------------------------
CREATE TABLE dbo.fact_fraud_cases (
    case_key                INT          NOT NULL IDENTITY(1,1),
    case_id                 VARCHAR(20)  NOT NULL,  -- Natural key: CASE-YYYY-NNNN
    case_open_date          DATE         NOT NULL,
    case_close_date         DATE         NULL,      -- NULL = still open
    open_date_key           INT          NOT NULL,  -- FK → dim_date
    close_date_key          INT          NULL,      -- FK → dim_date (nullable)
    customer_key            INT          NOT NULL,  -- FK → dim_customer
    channel_code            VARCHAR(30)  NOT NULL,
    fraud_type              VARCHAR(30)  NOT NULL,
    case_status             VARCHAR(25)  NOT NULL,
    assigned_analyst        VARCHAR(10)  NULL,
    amount_at_risk_usd      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    recovered_amount_usd    DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    resolution              VARCHAR(25)  NULL,
    resolution_days         TINYINT      NULL,      -- Computed at case close
    linked_transaction_id   VARCHAR(20)  NULL,      -- Primary linked transaction
    priority                VARCHAR(10)  NOT NULL DEFAULT 'MEDIUM',
    escalation_flag         BIT          NOT NULL DEFAULT 0,
    sar_filed               BIT          NOT NULL DEFAULT 0,  -- FinCEN SAR filed
    regulatory_report_req   BIT          NOT NULL DEFAULT 0,
    [notes]                 VARCHAR(1000) NULL,
    row_created_at          DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    row_updated_at          DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_fact_fraud_cases PRIMARY KEY (case_key),
    CONSTRAINT UQ_case_id UNIQUE (case_id),
    CONSTRAINT FK_case_open_date FOREIGN KEY (open_date_key)
        REFERENCES dbo.dim_date (date_key),
    CONSTRAINT FK_case_customer FOREIGN KEY (customer_key)
        REFERENCES dbo.dim_customer (customer_key),
    CONSTRAINT CHK_case_amount CHECK (amount_at_risk_usd >= 0),
    CONSTRAINT CHK_case_recovered CHECK (recovered_amount_usd >= 0),
    CONSTRAINT CHK_case_priority CHECK (
        priority IN ('LOW','MEDIUM','HIGH','CRITICAL')
    ),
    CONSTRAINT CHK_case_status CHECK (
        case_status IN (
            'OPEN','UNDER_INVESTIGATION','RESOLVED','ESCALATED','SAR_FILED'
        )
    )
);
GO

-- ------------------------------------------------------------
-- agg_monthly_channel_summary
-- Pre-aggregated channel performance — one row per channel/month.
-- Source: monthly_channel_summary.csv / nightly aggregation job.
-- Optimized for time-series and trend visualizations in Power BI.
-- ------------------------------------------------------------
CREATE TABLE dbo.agg_monthly_channel_summary (
    summary_key             INT          NOT NULL IDENTITY(1,1),
    year_month              CHAR(7)      NOT NULL,  -- Format: YYYY-MM
    channel_code            VARCHAR(30)  NOT NULL,
    total_transactions      INT          NOT NULL DEFAULT 0,
    total_volume_usd        DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    fraud_transactions      INT          NOT NULL DEFAULT 0,
    fraud_loss_usd          DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    fraud_rate_pct          DECIMAL(7,4) NOT NULL DEFAULT 0.0000,
    alert_count             INT          NOT NULL DEFAULT 0,
    false_positive_count    INT          NOT NULL DEFAULT 0,
    avg_risk_score          DECIMAL(5,2) NULL,
    chargebacks_usd         DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    net_fraud_loss_usd      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    fraud_loss_rate_bps     AS (
        CASE WHEN total_volume_usd > 0
             THEN CAST((net_fraud_loss_usd / total_volume_usd) * 10000 AS DECIMAL(8,4))
             ELSE 0
        END
    ),                                              -- Computed column: bps
    false_positive_rate_pct AS (
        CASE WHEN alert_count > 0
             THEN CAST((false_positive_count * 100.0 / alert_count) AS DECIMAL(7,4))
             ELSE 0
        END
    ),
    row_created_at          DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_agg_monthly_channel PRIMARY KEY (summary_key),
    CONSTRAINT UQ_monthly_channel UNIQUE (year_month, channel_code),
    CONSTRAINT CHK_fraud_rate CHECK (fraud_rate_pct BETWEEN 0 AND 100),
    CONSTRAINT CHK_net_loss CHECK (net_fraud_loss_usd >= 0)
);
GO

-- ============================================================
-- SECTION 3: PERFORMANCE INDEXES
-- ============================================================

-- fact_transactions — most frequently queried columns
CREATE NONCLUSTERED INDEX IX_txn_date
    ON dbo.fact_transactions (transaction_date)
    INCLUDE (amount_usd, fraud_flag, channel_code, risk_score);

CREATE NONCLUSTERED INDEX IX_txn_customer_date
    ON dbo.fact_transactions (customer_key, transaction_date)
    INCLUDE (amount_usd, fraud_flag, fraud_type);

CREATE NONCLUSTERED INDEX IX_txn_fraud_flag
    ON dbo.fact_transactions (fraud_flag, transaction_date)
    INCLUDE (amount_usd, chargeback_amount_usd, channel_code);

CREATE NONCLUSTERED INDEX IX_txn_channel_date
    ON dbo.fact_transactions (channel_code, transaction_date)
    INCLUDE (amount_usd, fraud_flag, ml_model_score);

CREATE NONCLUSTERED INDEX IX_txn_risk_score
    ON dbo.fact_transactions (risk_score DESC)
    INCLUDE (transaction_id, customer_key, amount_usd, fraud_flag);

-- fact_fraud_cases — case management queries
CREATE NONCLUSTERED INDEX IX_cases_status_priority
    ON dbo.fact_fraud_cases (case_status, priority)
    INCLUDE (case_id, customer_key, amount_at_risk_usd, assigned_analyst);

CREATE NONCLUSTERED INDEX IX_cases_open_date
    ON dbo.fact_fraud_cases (case_open_date, case_status)
    INCLUDE (case_id, amount_at_risk_usd, fraud_type);

-- dim_customer — risk tier lookups
CREATE NONCLUSTERED INDEX IX_customer_risk_tier
    ON dbo.dim_customer (risk_tier, composite_risk_score DESC)
    INCLUDE (customer_id, full_name, kyc_status, watchlist_flag, pep_flag);

CREATE NONCLUSTERED INDEX IX_customer_watchlist
    ON dbo.dim_customer (watchlist_flag, pep_flag)
    WHERE watchlist_flag = 1 OR pep_flag = 1;

-- agg_monthly_channel_summary — time-series queries
CREATE NONCLUSTERED INDEX IX_monthly_channel_yearmonth
    ON dbo.agg_monthly_channel_summary (year_month, channel_code)
    INCLUDE (fraud_loss_usd, net_fraud_loss_usd, total_volume_usd, fraud_rate_pct);
GO

-- ============================================================
-- SECTION 4: SEED DATA — DIMENSION TABLES
-- ============================================================

-- Seed: dim_channel
INSERT INTO dbo.dim_channel
    (channel_code, channel_name, channel_group, base_risk_tier,
     is_digital, is_cross_border, typical_fraud_rate_bps)
VALUES
    ('CARD_POS',           'Card Present — Point of Sale',          'CARD',    'LOW',    0, 0,  30),
    ('CARD_CNP',           'Card Not Present — Online/Phone',        'CARD',    'MEDIUM', 1, 0, 250),
    ('ACH_CREDIT',         'ACH Credit — Inbound Transfer',          'ACH',     'LOW',    0, 0,  20),
    ('ACH_DEBIT',          'ACH Debit — Outbound Transfer',          'ACH',     'LOW',    0, 0,  60),
    ('WIRE_DOMESTIC',      'Wire Transfer — Domestic',               'WIRE',    'MEDIUM', 0, 0, 150),
    ('WIRE_INTERNATIONAL', 'Wire Transfer — International',          'WIRE',    'HIGH',   0, 1, 800),
    ('DIGITAL_WALLET',     'Digital Wallet (PayPal/Venmo/Zelle)',    'DIGITAL', 'MEDIUM', 1, 0, 200),
    ('DIGITAL_TRANSFER',   'Digital Bank Transfer (P2P)',            'DIGITAL', 'MEDIUM', 1, 0, 320);
GO

-- Seed: dim_risk_tier
INSERT INTO dbo.dim_risk_tier
    (tier_code, tier_label, score_min, score_max,
     review_cycle_days, requires_edd, monitoring_level)
VALUES
    ('MINIMAL',  'Minimal Risk',    0,  19, 365, 0, 'STANDARD'),
    ('LOW',      'Low Risk',       20,  39, 180, 0, 'ENHANCED_MONITORING'),
    ('MEDIUM',   'Medium Risk',    40,  59,  90, 0, 'PERIODIC_REVIEW'),
    ('HIGH',     'High Risk',      60,  79,  30, 1, 'ENHANCED_DUE_DILIGENCE'),
    ('CRITICAL', 'Critical Risk',  80, 100,   7, 1, 'IMMEDIATE_REVIEW');
GO

-- Seed: dim_fraud_type (core types)
INSERT INTO dbo.dim_fraud_type
    (fraud_type_code, fraud_type_name, category, ttp_code,
     requires_sar, avg_loss_usd, description)
VALUES
    ('NONE',                'No Fraud Detected',                      'LEGITIMATE',     NULL,       0,      0.00, 'Transaction cleared — no fraud indicators'),
    ('CNP_FRAUD',           'Card-Not-Present Fraud',                 'CARD_FRAUD',     'FIN-T1',   0,   1240.00, 'Stolen card credentials used for online purchases'),
    ('ATO',                 'Account Takeover',                       'IDENTITY_FRAUD', 'FIN-T2',   1,   3200.00, 'Criminal gains unauthorized access to legitimate account'),
    ('SYNTHETIC_ID',        'Synthetic Identity Fraud',               'IDENTITY_FRAUD', 'FIN-T4',   1,   7800.00, 'Fabricated identity combining real and fictitious information'),
    ('WIRE_FRAUD',          'Wire Transfer Fraud',                    'WIRE_FRAUD',     'FIN-T7',   1, 285000.00, 'Fraudulent initiation of wire transfer'),
    ('BEC',                 'Business Email Compromise',              'WIRE_FRAUD',     'FIN-T1',   1, 420000.00, 'Fraud via impersonation of executive or vendor via email'),
    ('ACH_FRAUD',           'ACH Fraud',                              'PAYMENT_FRAUD',  'FIN-T8',   1,  18500.00, 'Unauthorized ACH debit or fictitious credit scheme'),
    ('ACCOUNT_ABUSE',       'Account Abuse / Authorized Push Payment','PAYMENT_FRAUD',  'FIN-T9',   0,   5400.00, 'Misuse of legitimate account access'),
    ('MULE_NETWORK',        'Money Mule Network',                     'MONEY_LAUNDERING','FIN-T6',  1,  11200.00, 'Account used to layer and move illicit funds'),
    ('COUNTERFEIT_CARD',    'Counterfeit Card',                       'CARD_FRAUD',     'FIN-T5',   0,    650.00, 'Physical card cloned via compromised terminal'),
    ('SKIMMING',            'Card Skimming',                          'CARD_FRAUD',     'FIN-T5',   0,    890.00, 'Card data captured via ATM or POS hardware skimmer'),
    ('DEVICE_COMPROMISE',   'Device Compromise',                      'IDENTITY_FRAUD', 'FIN-T3',   0,   1700.00, 'Fraud via malware, SIM swap, or hijacked device'),
    ('STOLEN_CREDENTIALS',  'Stolen Credentials',                     'IDENTITY_FRAUD', 'FIN-T1',   0,   2100.00, 'Credentials obtained via phishing, breach, or dark web');
GO

PRINT 'Schema creation complete. Tables, indexes, and seed data loaded successfully.';
GO
