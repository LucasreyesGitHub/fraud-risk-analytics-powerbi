# VaultSentinel Corp — Anomaly Detection Framework
## Statistical & ML Methods for Real-Time Fraud Signal Generation
### Version 2.0 | Quantitative Risk & Model Engineering Team

---

## 1. What is Anomaly Detection in Fraud Intelligence?

Anomaly detection is the process of identifying patterns, observations, or data points that deviate significantly from an established behavioral baseline. In the context of payment fraud, anomalies are not inherently fraudulent — but they represent elevated-risk signals that justify additional scrutiny.

Unlike rule-based fraud detection (which catches *known* fraud patterns), anomaly detection is designed to surface *unknown* or *emerging* fraud typologies that no existing rule covers. Together, they form the two complementary layers of VaultSentinel's detection architecture:

```
   KNOWN FRAUD PATTERNS           UNKNOWN / EMERGING FRAUD
   ─────────────────────          ─────────────────────────────
   Rule-Based Engine              Anomaly Detection Engine
   (deterministic)                (probabilistic)
         ↓                                ↓
   "This matches pattern X"       "This is unusual for this customer"
         ↓                                ↓
   Alert triggered                Anomaly score contributed to
   (high confidence)              composite risk score
```

**Three Anomaly Types in Payments:**

| Type | Definition | Fraud Example |
|------|-----------|---------------|
| **Point Anomaly** | A single transaction deviates from normal | $45K wire from a customer whose max historical wire is $8K |
| **Contextual Anomaly** | Normal in general, abnormal in context | $200 purchase at 3AM from a customer who never transacts past 10PM |
| **Collective Anomaly** | Sequence of normal-looking transactions is abnormal | Ten $9,900 deposits in 24 hours (structuring to avoid $10K CTR) |

---

## 2. Statistical Anomaly Detection Methods

### Method 1: Z-Score (Standard Deviation Distance)

**What it is:** Measures how many standard deviations a value is from the mean of that customer's historical distribution.

**Formula:**
```
z = (x - μ) / σ

Where:
  x = current transaction value
  μ = customer's 90-day mean transaction value
  σ = customer's 90-day standard deviation
```

**Application in VaultSentinel:**
- Computed per customer per channel (separate baselines for CARD_CNP vs WIRE)
- |z| > 2.5 → Add +10 to composite risk score
- |z| > 3.5 → Add +25 to composite risk score (hard anomaly)
- |z| > 5.0 → Immediate alert regardless of other signals

**Worked Example:**
```
Customer CUST-10024 — WIRE_DOMESTIC history:
  90-day transactions: $12K, $8K, $15K, $9K, $11K
  μ = $11,000 | σ = $2,550

Incoming transaction: $450,000
  z = (450,000 - 11,000) / 2,550 = 172.2

Result: EXTREME ANOMALY — Immediate block + P0 alert
```

---

### Method 2: Interquartile Range (IQR) — Robust to Outliers

**What it is:** Uses the middle 50% of the distribution (Q1 to Q3) to define the "normal" band. Less sensitive to extreme historical values than Z-score.

**Formula:**
```
IQR = Q3 - Q1
Lower Bound = Q1 - (1.5 × IQR)
Upper Bound = Q3 + (1.5 × IQR)

Severe Outlier Bound = Q3 + (3.0 × IQR)
```

**When to prefer IQR over Z-score:**
- Customers with volatile transaction histories (e.g., business accounts with occasional large transfers)
- Premium account holders where historical transactions already include large-value outliers
- Channels like WIRE_INTERNATIONAL where the distribution is naturally right-skewed

---

### Method 3: Peer Group Analysis (Segment Baseline)

**What it is:** Instead of comparing a transaction to the *individual* customer's history, compare it to the *cohort* of similar customers (same account type, income band, primary channel).

**Application:**
- Build peer groups by: account_type + annual_income_band + primary_channel
- Compute cohort-level median, P25, P75, P95 for transaction amounts
- If current transaction exceeds cohort P95 → Peer anomaly flag
- Cross-reference with individual baseline — both signals increase confidence

**Example:**
```
Customer: CUST-10028 [Laura Thomas | PERSONAL_CHECKING | 75K-100K | CARD_CNP]
Peer Group: 847 similar accounts
Peer Group P95 amount: $1,240

Incoming CNP transaction: $2,199.00
  Individual z-score: 3.1 (high)
  Peer group: exceeds P99 (top 1% of peer group)

Combined signal: Strong anomaly → Composite risk score +35
```

---

### Method 4: Time-Series Velocity Analysis

**What it is:** Detects abnormal acceleration in transaction frequency, treating transaction count over time as a time-series signal.

**Rolling Windows Used:**
```
W1: Last 15 minutes  — used for burst detection
W2: Last 1 hour      — used for velocity breach
W3: Last 6 hours     — used for sustained campaign detection
W4: Last 24 hours    — used for daily volume anomaly
W5: Last 7 days      — used for weekly behavior shift
```

**Anomaly Signal Logic (Simplified):**
```
customer_1h_count = COUNT(transactions WHERE timestamp > NOW() - 1 HOUR)
customer_1h_baseline = P90(hourly_counts, rolling_90_days)

IF customer_1h_count > (customer_1h_baseline × 3):
    velocity_anomaly_score += 40
    TRIGGER: VELOCITY_BREACH

IF customer_1h_count > (customer_1h_baseline × 5):
    velocity_anomaly_score += 70
    TRIGGER: P1 ESCALATION
```

**Power BI DAX Equivalent (Approximate):**
```dax
[Velocity Anomaly Flag] =
    VAR CustomerVelocity1H = [Velocity Count 1H]
    VAR CustomerBaseline =
        CALCULATE(
            PERCENTILE.INC(Transactions[velocity_count_1h], 0.9),
            FILTER(ALL(Transactions), Transactions[customer_id] = MAX(Transactions[customer_id]))
        )
    RETURN
        IF(CustomerVelocity1H > CustomerBaseline * 3, "ANOMALY", "NORMAL")
```

---

## 3. Machine Learning Anomaly Detection Methods

### Method 5: Isolation Forest

**What it is:** An unsupervised tree-based algorithm that isolates anomalies rather than profiling normality. Anomalous observations are isolated earlier (require fewer splits) in random decision trees.

**Why it works for fraud:**
- Does not require labeled fraud data — useful for zero-day fraud typologies
- Scales efficiently to high-dimensional feature spaces (100+ transaction features)
- Produces an anomaly score between 0 and 1 (closer to 1 = more anomalous)
- Naturally handles mixed feature types (categorical + continuous)

**VaultSentinel Implementation:**
- Trained monthly on full 90-day transaction window (rolling, unlabeled)
- Features: amount, hour_of_day, day_of_week, velocity_1h, ip_reputation, channel_encoded
- Anomaly threshold: score > 0.72 triggers contribution to composite risk score
- Used as a *complementary* signal alongside the supervised XGBoost model

**Isolation Forest Anomaly Score → Risk Score Mapping:**
```
IF score >= 0.90 → Add +35 to composite risk
IF score >= 0.80 → Add +20 to composite risk
IF score >= 0.72 → Add +10 to composite risk
IF score <  0.72 → No contribution
```

---

### Method 6: LSTM Autoencoder (Sequence Anomaly Detection)

**What it is:** A deep learning model that learns to reconstruct normal sequences of transactions. High reconstruction error = the sequence is anomalous (doesn't match learned patterns).

**Architecture:**
```
Input Sequence (last 10 transactions per customer)
    ↓
Encoder: LSTM(64) → LSTM(32)     ← Compress to latent representation
    ↓
Bottleneck: Dense(16)             ← Learned normal pattern
    ↓
Decoder: LSTM(32) → LSTM(64)     ← Reconstruct the sequence
    ↓
Output: Reconstructed Sequence
    ↓
Reconstruction Error (MSE)        ← HIGH = ANOMALOUS SEQUENCE
```

**Best use cases:**
- Detecting ATO patterns (behavioral sequence changes after account takeover)
- Identifying synthetic identity bust-out sequences (buildup → drain pattern)
- Catching mule account layering sequences (rapid inbound-then-outbound cycles)

**Temporal Pattern Example (ATO Detection):**
```
Normal CUST-10026 sequence:
  Day 1: CVS $45 | Amazon $234 | Netflix $9.99
  Day 2: Starbucks $12 | Target $67
  Day 3: Shell Gas $55

Post-compromise sequence (ATO):
  Hour 0: Password reset
  Hour 0+1: New device registered
  Hour 0+2: Zelle $3,487 to unknown payee   ← LSTM anomaly score 0.94
  Hour 0+3: ACH debit $1,200 to new account
```

---

### Method 7: Behavioral Biometrics Anomaly (Session-Level)

**What it is:** Real-time analysis of *how* a user interacts with the banking interface — not just *what* they do.

**Signals captured:**
- Typing rhythm (keystroke dynamics) — inter-key timing
- Mouse movement trajectory and acceleration curves
- Scroll behavior and dwell time on transaction confirmation page
- Session navigation path (normal user vs. scripted bot behavior)
- Mobile: touch pressure, swipe velocity, grip orientation (gyroscope)

**Anomaly indicators:**
```
LEGITIMATE SESSION:                    ATO / BOT SESSION:
  Natural typing rhythm                  Mechanical/uniform keystrokes
  Hesitations at form fields             No hesitation — pre-filled data
  Normal navigation path                 Skips unusual pages
  Consistent mouse jitter                Perfectly straight mouse paths
  Recognizable session fingerprint       New session fingerprint
```

**Current Status at VaultSentinel:** Behavioral biometrics is planned for Q2 2025 deployment (see Executive Brief Recommendation #2). Currently, device fingerprint and session anomaly serve as proxies.

---

## 4. Feature Engineering for Anomaly Detection

The following engineered features feed both statistical and ML anomaly models:

### Transaction-Level Features

| Feature | Derivation | Anomaly Signal |
|---------|-----------|----------------|
| `amount_z_score` | (amount - cust_median_90d) / cust_std_90d | High absolute value |
| `amount_peer_percentile` | Percentile within peer group cohort | >P95 = anomaly |
| `hour_freq_score` | % of customer's historical txns at this hour | <5% = time anomaly |
| `channel_first_use` | Boolean: first transaction on this channel | TRUE = flag |
| `merchant_first_use` | Boolean: first visit to this merchant category | TRUE = elevated |
| `velocity_ratio_1h` | velocity_count_1h / cust_P90_velocity_1h | >3x = anomaly |
| `velocity_ratio_24h` | velocity_count_24h / cust_P90_velocity_24h | >2x = anomaly |
| `ip_delta` | Distance change from last IP geolocation (km) | >500km = anomaly |
| `device_age_days` | Days since device first seen on account | <7 days = new device |
| `payee_risk_score` | Composite score of historical payee signals | >60 = elevated |

### Account-Level Features (Rolling Windows)

| Feature | Window | Description |
|---------|--------|-------------|
| `dispute_rate_30d` | 30 days | Dispute count / transaction count |
| `chargeback_rate_90d` | 90 days | Chargeback count / transaction count |
| `unique_devices_30d` | 30 days | Distinct device fingerprints used |
| `password_changes_7d` | 7 days | Count of credential changes |
| `contact_changes_30d` | 30 days | Phone/email/address changes |
| `new_payees_7d` | 7 days | Count of first-time beneficiaries |

---

## 5. Anomaly Score Composition

The final **Composite Anomaly Score (0–100)** fed to the risk engine is assembled from individual anomaly signals:

```
╔══════════════════════════════════════════════════════════════╗
║  COMPOSITE ANOMALY SCORE CONSTRUCTION                       ║
╠══════════════════════════════════════════════════════════════╣
║                                                             ║
║  Amount Anomaly Signal        (0–30 points)                 ║
║    Z-score component          max 15 pts                    ║
║    Peer group component       max 15 pts                    ║
║                                                             ║
║  Velocity Anomaly Signal      (0–25 points)                 ║
║    1-hour velocity ratio      max 15 pts                    ║
║    24-hour velocity ratio     max 10 pts                    ║
║                                                             ║
║  Behavioral Anomaly Signal    (0–20 points)                 ║
║    Time-of-day anomaly        max 10 pts                    ║
║    Channel/merchant first-use  max 5 pts                    ║
║    Device/IP anomaly          max 5 pts                     ║
║                                                             ║
║  ML Anomaly Signals           (0–25 points)                 ║
║    Isolation Forest score     max 15 pts                    ║
║    LSTM reconstruction error  max 10 pts                    ║
║                                                             ║
║  ─────────────────────────────────────────────────────────  ║
║  TOTAL COMPOSITE ANOMALY SCORE              0–100 points    ║
╚══════════════════════════════════════════════════════════════╝

Score ranges:
  0–19:  Minimal anomaly — no action required
 20–39:  Low anomaly — log for weekly review
 40–59:  Moderate anomaly — contribute +15 to risk score
 60–79:  High anomaly — contribute +30 to risk score, soft alert
 80–100: Critical anomaly — trigger immediate alert, route to analyst
```

---

## 6. Real-Time vs. Batch Anomaly Detection

| Mode | Latency | Use Case | Methods Used |
|------|---------|---------|-------------|
| **Real-Time (per transaction)** | <50ms | Transaction scoring, wire holds | Z-score, IQR, Velocity, Rule Engine |
| **Near Real-Time (5 min lag)** | 5 min | Network analysis, mule detection | Graph traversal, cluster matching |
| **Batch (hourly)** | 60 min | Sequence models, campaign detection | LSTM Autoencoder, Isolation Forest |
| **Daily Batch** | 24 hr | Behavioral baseline recalibration | Peer group refresh, model scoring |
| **Weekly Batch** | 7 days | Model drift monitoring, PSI calculation | PSI, KS tests, feature distribution |

**Architecture (Simplified):**
```
Transaction Event
      ↓
  [Kafka Stream]
      ↓
Real-Time Scoring Engine (Azure Stream Analytics)
  ├── Z-Score Engine (Redis cache of customer baselines)
  ├── Velocity Counter (Redis sorted sets)
  ├── Rule Engine (FICO Falcon)
  └── ML Scoring API (XGBoost model endpoint)
      ↓
  Composite Risk Score
      ↓
  [Score ≥ 75] → Alert Queue → Power BI Streaming Dataset
  [Score <  75] → Transaction approved → DWH batch load
```

---

## 7. Threshold Tuning Methodology

Setting the right alert threshold is the most consequential operational decision in fraud analytics. The fundamental tradeoff:

```
Lower threshold  →  Catch more fraud (↑ Recall)  BUT  More false positives (↓ Precision)
Higher threshold →  Fewer false positives (↑ Precision)  BUT  Miss more fraud (↓ Recall)
```

**VaultSentinel Threshold Optimization Process (Bi-Annual):**

1. **Pull 6-month labeled dataset** (confirmed fraud / confirmed legitimate)
2. **Run model predictions at 50 score thresholds** (0.5 to 100 in 2-point increments)
3. **Calculate Precision, Recall, F1 at each threshold**
4. **Plot Precision-Recall curve** and identify:
   - F1-optimal threshold (maximizes F1 — used for balanced operations)
   - Recall-maximizing threshold (used during active fraud campaigns — accept more FPs)
   - Precision-maximizing threshold (used during low-staff periods — accept fewer FPs)
5. **Apply business cost weighting:**
   ```
   Business Cost(threshold) = 
       (False Negatives × avg_fraud_loss_$) 
     + (False Positives × analyst_review_cost_$)
   
   Optimal threshold = arg min Business Cost(threshold)
   ```
6. **Shadow test challenger threshold** on 10% of traffic for 4 weeks
7. **Champion/challenger comparison** before full production deployment

---

## 8. Power BI Implementation of Anomaly Indicators

These anomaly signals can be computed in DAX for dashboard visualization:

```dax
[Amount Anomaly Flag] =
    VAR CurrentAmt = MAX(Transactions[amount_usd])
    VAR CustMean =
        CALCULATE(
            AVERAGE(Transactions[amount_usd]),
            ALLEXCEPT(Transactions, Transactions[customer_id])
        )
    VAR CustStDev =
        CALCULATE(
            STDEV.P(Transactions[amount_usd]),
            ALLEXCEPT(Transactions, Transactions[customer_id])
        )
    VAR ZScore = DIVIDE(CurrentAmt - CustMean, CustStDev, 0)
    RETURN
        SWITCH(
            TRUE(),
            ABS(ZScore) >= 5, "EXTREME",
            ABS(ZScore) >= 3.5, "CRITICAL",
            ABS(ZScore) >= 2.5, "HIGH",
            "NORMAL"
        )

[Time Anomaly Score] =
    VAR TransactionHour = HOUR(MAX(Transactions[transaction_time]))
    RETURN
        SWITCH(
            TRUE(),
            TransactionHour >= 0 && TransactionHour <= 4, 30,
            TransactionHour >= 23, 25,
            0
        )

[IP Reputation Category] =
    VAR Score = MAX(Transactions[ip_reputation_score])
    RETURN
        SWITCH(
            TRUE(),
            Score < 20, "MALICIOUS",
            Score < 40, "SUSPICIOUS",
            Score < 60, "NEUTRAL",
            Score < 80, "TRUSTED",
            "HIGHLY_TRUSTED"
        )
```

---

## 9. Model Performance & Drift Monitoring

**Population Stability Index (PSI)** — monthly monitoring of feature distributions:

```
PSI = Σ (Actual% - Expected%) × ln(Actual% / Expected%)

Interpretation:
  PSI < 0.10  → No significant shift — model stable
  PSI 0.10–0.20 → Moderate shift — monitor closely
  PSI > 0.20  → Major shift — retraining required immediately
```

**Features monitored for PSI (top 10):**
1. amount_usd distribution by channel
2. velocity_count_1h distribution
3. ml_model_score distribution (score shift = model drift warning)
4. ip_reputation_score distribution
5. destination_country frequency distribution
6. fraud_flag rate (base rate shift detection)
7. alert_rule_triggered distribution
8. customer risk_score distribution
9. resolution_status distribution
10. chargeback_rate by channel

---

*VaultSentinel Corp | Anomaly Detection Framework v2.0 | Quantitative Risk & Model Engineering*
*Review cycle: Semi-annual | Owner: Head of Model Engineering | Next review: June 2025*
