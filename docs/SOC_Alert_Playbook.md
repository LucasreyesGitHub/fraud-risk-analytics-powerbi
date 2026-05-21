# VaultSentinel Corp — SOC Alert Playbook
## Fraud Operations Security Center | Incident Response Reference
### Version 3.2 | Fraud Intelligence & Operations Division

---

## 1. SOC Organization Structure

```
┌─────────────────────────────────────────────────────────────┐
│           VAULTSENTINEL FRAUD OPERATIONS CENTER             │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  TIER 1 — ALERT TRIAGE (L1 Analysts × 12)           │  │
│  │  • Real-time alert queue monitoring                  │  │
│  │  • Initial risk scoring validation                   │  │
│  │  • False positive disposition                        │  │
│  │  • P3/P4 case resolution                             │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │ escalate                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  TIER 2 — FRAUD INVESTIGATION (Senior Analysts × 8) │  │
│  │  • P1/P2 case investigation                          │  │
│  │  • Cross-channel pattern analysis                    │  │
│  │  • Chargeback & recovery coordination                │  │
│  │  • SAR pre-filing documentation                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │ escalate                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  TIER 3 — FIU / FINANCIAL INTELLIGENCE (FIU × 4)   │  │
│  │  • P0 major incident response                        │  │
│  │  • Regulatory filing (SAR, CTR)                      │  │
│  │  • Law enforcement liaison                           │  │
│  │  • Network analysis & threat intel                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │ brief                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  EXECUTIVE — VP FRAUD OPS + CRO                     │  │
│  │  • P0 war room leadership                            │  │
│  │  • Regulatory notifications                          │  │
│  │  • Board reporting                                   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Alert Severity Classification

| Severity | Label | Color | ML Score | Loss Threshold | Response Time | Escalation |
|----------|-------|-------|----------|----------------|---------------|-----------|
| P0 | CATASTROPHIC | 🔴 #FF2D55 | 90–100 | >$1M | Immediate | CEO + Board |
| P1 | CRITICAL | 🟠 #FF6B35 | 80–89 | $100K–$999K | ≤1 hour | CRO |
| P2 | HIGH | 🟡 #FFB800 | 70–79 | $10K–$99K | ≤4 hours | VP Ops |
| P3 | MEDIUM | 🔵 #58A6FF | 60–69 | $1K–$9.9K | ≤8 hours | Team Lead |
| P4 | LOW | 🟢 #3FB950 | <60 | <$1K | ≤24 hours | Queue |

---

## 3. SOC Alert Ticket Examples

---

### ALERT TICKET #1 — Business Email Compromise (P0)

```
╔═══════════════════════════════════════════════════════════════════╗
║  ⚠  VAULTSENTINEL SOC — FRAUD ALERT                              ║
║  Alert ID  : VSC-ALERT-2024-0531                                  ║
║  Severity  : P0 — CATASTROPHIC          Status : ACTIVE / OPEN   ║
║  Timestamp : 2024-05-03 23:45:12 UTC                              ║
╠═══════════════════════════════════════════════════════════════════╣
║  TRANSACTION DETAILS                                              ║
║  ─────────────────────────────────────────────────────────────── ║
║  Transaction ID  : TXN-2024-00075                                 ║
║  Channel         : WIRE_INTERNATIONAL                             ║
║  Amount          : $850,000.00 USD                                ║
║  Beneficiary     : Unknown Beneficiary Ltd                        ║
║  Destination     : Lagos, Nigeria (NG) — SWIFT: ZENBNLGX          ║
║  Customer        : CUST-10041 [Jordan Williams]                   ║
║  Account Type    : BUSINESS_CHECKING                              ║
╠═══════════════════════════════════════════════════════════════════╣
║  RULES TRIGGERED                                                  ║
║  ─────────────────────────────────────────────────────────────── ║
║  [P0] BLACKLIST_HIT        — Beneficiary bank on OFAC watch list  ║
║  [P0] GEO_ANOMALY          — Destination: NG (Tier 1 high-risk)   ║
║  [P1] TIME_ANOMALY         — 23:45 UTC (outside business hours)   ║
║  [P1] AMOUNT_THRESHOLD     — Exceeds $500K single-wire limit      ║
║  [P1] NEW_BENEFICIARY      — First-time beneficiary, 0 history    ║
║  [P2] VELOCITY_BREACH      — 4 wires initiated in past 6 hours    ║
╠═══════════════════════════════════════════════════════════════════╣
║  ML MODEL OUTPUT                                                  ║
║  ─────────────────────────────────────────────────────────────── ║
║  Model Score     : 95.7 / 100  [BLOCK THRESHOLD: 75]             ║
║  Top Features    : destination_country_risk (+28.4)               ║
║                    beneficiary_history_days (0) (+19.7)           ║
║                    hour_of_day (23) (+14.2)                       ║
║                    velocity_6h (4) (+11.8)                        ║
║  Confidence Band : 93.1% — 97.3% (95% CI)                        ║
╠═══════════════════════════════════════════════════════════════════╣
║  THREAT INTELLIGENCE                                              ║
║  ─────────────────────────────────────────────────────────────── ║
║  FS-ISAC FEED     : Beneficiary bank flagged in 3 peer BEC cases  ║
║  TTP Indicator    : BEC / T1566.002 (Spearphishing via email)     ║
║  Campaign Match   : Matches "Operation GoldenWire" IOCs           ║
╠═══════════════════════════════════════════════════════════════════╣
║  RECOMMENDED ACTIONS                                              ║
║  ─────────────────────────────────────────────────────────────── ║
║  1. IMMEDIATE HOLD — Wire placed on 4-hour administrative hold    ║
║  2. CALLBACK VERIFY — Call CUST-10041 on registered number        ║
║  3. ESCALATE → Tier 3 FIU + CRO notification                      ║
║  4. SWIFT GPI — If wire released, initiate recall via SWIFT gpi   ║
║  5. SAR PRE-FILE — Complete FinCEN SAR within 24 hours            ║
╠═══════════════════════════════════════════════════════════════════╣
║  ASSIGNED TO : ANL-001 (Tier 3 FIU)   CASE : CASE-2024-0004      ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

### ALERT TICKET #2 — Account Takeover via Device Mismatch (P2)

```
╔═══════════════════════════════════════════════════════════════════╗
║  ⚠  VAULTSENTINEL SOC — FRAUD ALERT                              ║
║  Alert ID  : VSC-ALERT-2024-0419                                  ║
║  Severity  : P2 — HIGH                  Status : UNDER REVIEW    ║
║  Timestamp : 2024-04-20 02:55:18 UTC                              ║
╠═══════════════════════════════════════════════════════════════════╣
║  TRANSACTION DETAILS                                              ║
║  ─────────────────────────────────────────────────────────────── ║
║  Transaction ID  : TXN-2024-00084                                 ║
║  Channel         : DIGITAL_WALLET (Zelle)                        ║
║  Amount          : $3,487.00 USD                                  ║
║  Recipient       : External account — first-time payee            ║
║  Customer        : CUST-10026 [Christina Taylor]                  ║
║  Typical Zelle   : $0 — no prior Zelle history on account         ║
╠═══════════════════════════════════════════════════════════════════╣
║  RULES TRIGGERED                                                  ║
║  ─────────────────────────────────────────────────────────────── ║
║  [P1] DEVICE_MISMATCH      — DEV-B2C3D502 not in known registry  ║
║  [P2] TIME_ANOMALY         — 02:55 UTC (2.3% freq. for customer) ║
║  [P2] CHANNEL_ANOMALY      — No prior Zelle transactions          ║
║  [P2] AMOUNT_THRESHOLD     — 4.1x customer 90-day median ($842)  ║
║  [P3] IP_REPUTATION        — IP score 19/100 (VPN exit node)     ║
╠═══════════════════════════════════════════════════════════════════╣
║  ML MODEL OUTPUT                                                  ║
║  ─────────────────────────────────────────────────────────────── ║
║  Model Score     : 82.4 / 100  [ALERT THRESHOLD: 75]             ║
║  ATO Sub-Model   : 88.1 / 100  [ATO-specific module v2.3]        ║
║  Primary Driver  : device_in_registry (FALSE) (+31.2)            ║
╠═══════════════════════════════════════════════════════════════════╣
║  BEHAVIORAL CONTEXT                                               ║
║  ─────────────────────────────────────────────────────────────── ║
║  Last Login      : 2024-04-19 22:11 [Known device — iOS 17]      ║
║  This Session    : 2024-04-20 02:47 [NEW device — Android 14]    ║
║  Password Reset  : 2024-04-19 21:58 (63 minutes before txn)      ║
║  MFA Used        : SMS OTP — phone number changed 48h prior       ║
╠═══════════════════════════════════════════════════════════════════╣
║  RECOMMENDED ACTIONS                                              ║
║  ─────────────────────────────────────────────────────────────── ║
║  1. SOFT BLOCK — Hold pending authentication                      ║
║  2. PUSH ALERT — Notify customer via email + in-app notification  ║
║  3. STEP-UP AUTH — Require video selfie + knowledge-based auth    ║
║  4. FLAG ACCOUNT — Elevate risk tier to HIGH pending review       ║
║  5. If confirmed ATO: Force password reset, invalidate sessions   ║
╠═══════════════════════════════════════════════════════════════════╣
║  ASSIGNED TO : ANL-004 (Tier 2)        CASE : CASE-2024-0009     ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

### ALERT TICKET #3 — CNP Fraud with Geo Anomaly (P2)

```
╔═══════════════════════════════════════════════════════════════════╗
║  ⚠  VAULTSENTINEL SOC — FRAUD ALERT                              ║
║  Alert ID  : VSC-ALERT-2024-0218                                  ║
║  Severity  : P2 — HIGH                  Status : CONFIRMED FRAUD ║
║  Timestamp : 2024-02-19 23:47:55 UTC                              ║
╠═══════════════════════════════════════════════════════════════════╣
║  TRANSACTION DETAILS                                              ║
║  ─────────────────────────────────────────────────────────────── ║
║  Transaction ID  : TXN-2024-00024                                 ║
║  Channel         : CARD_CNP (online card-not-present)            ║
║  Amount          : $1,849.99 USD                                  ║
║  Merchant        : Luxury Watch Online (MCC: 5944)                ║
║  Card Holder     : CUST-10024 [Sarah Mitchell]                    ║
║  Billing Country : US       Destination Country : RO (Romania)   ║
╠═══════════════════════════════════════════════════════════════════╣
║  RULES TRIGGERED                                                  ║
║  ─────────────────────────────────────────────────────────────── ║
║  [P1] GEO_ANOMALY          — Destination: RO (Tier 1 high-risk)  ║
║  [P2] TIME_ANOMALY         — 23:47 UTC (near-midnight purchase)  ║
║  [P2] MCC_RISK             — Luxury goods (5944) + intl delivery ║
║  [P2] AMOUNT_THRESHOLD     — 2.1x customer 90-day CNP median     ║
║  [P3] VELOCITY_BREACH      — 6th online transaction in 12 hours  ║
╠═══════════════════════════════════════════════════════════════════╣
║  ML MODEL OUTPUT                                                  ║
║  ─────────────────────────────────────────────────────────────── ║
║  Model Score     : 84.2 / 100                                    ║
║  Geography Risk  : Destination RO → Risk multiplier ×2.3         ║
║  Velocity Score  : 18/hour → P90 velocity breach                 ║
╠═══════════════════════════════════════════════════════════════════╣
║  RESOLUTION                                                       ║
║  ─────────────────────────────────────────────────────────────── ║
║  Outcome         : CONFIRMED_FRAUD                                ║
║  Customer Contact: Cardholder confirmed no authorization          ║
║  Chargeback      : $1,849.99 — recovered in full                  ║
║  Card Action     : Card cancelled, replacement issued             ║
╠═══════════════════════════════════════════════════════════════════╣
║  ASSIGNED TO : ANL-005 (Tier 2)        CASE : CASE-2024-0002     ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

### ALERT TICKET #4 — Synthetic Identity Bust-Out (P2)

```
╔═══════════════════════════════════════════════════════════════════╗
║  ⚠  VAULTSENTINEL SOC — FRAUD ALERT                              ║
║  Alert ID  : VSC-ALERT-2024-0316                                  ║
║  Severity  : P2 — HIGH                  Status : CONFIRMED FRAUD ║
║  Timestamp : 2024-03-17 01:17:42 UTC                              ║
╠═══════════════════════════════════════════════════════════════════╣
║  TRANSACTION DETAILS                                              ║
║  ─────────────────────────────────────────────────────────────── ║
║  Transaction ID  : TXN-2024-00093                                 ║
║  Channel         : DIGITAL_TRANSFER (P2P platform)               ║
║  Amount          : $8,750.00 USD                                  ║
║  Recipient       : External account (unknown institution)         ║
║  Customer        : CUST-10023 [Andrew Scott]                      ║
║  Account Age     : 63 days (opened 2018-12-11... DISCREPANCY)    ║
╠═══════════════════════════════════════════════════════════════════╣
║  RULES TRIGGERED                                                  ║
║  ─────────────────────────────────────────────────────────────── ║
║  [P1] PATTERN_MATCH        — Matches SynthWave-24 cluster IOCs    ║
║  [P2] TIME_ANOMALY         — 01:17 UTC (1.1% historical freq.)   ║
║  [P2] VELOCITY_BREACH      — 6 transactions in past hour          ║
║  [P2] BUST_OUT_SIGNAL      — Balance 98% depleted in 2 hours     ║
║  [P3] DEVICE_ANOMALY       — New device registered 14 hours prior ║
╠═══════════════════════════════════════════════════════════════════╣
║  IDENTITY INTELLIGENCE                                            ║
║  ─────────────────────────────────────────────────────────────── ║
║  SSN Issue Date  : 2019 — INCONSISTENT with claimed age (34)      ║
║  Credit Thin     : 3 tradelines, all opened within 18 months      ║
║  Address History : 4 addresses in 18 months (abnormal churn)      ║
║  KYC Documents   : State ID — microprint anomaly detected (AI)   ║
║  Network Links   : Shares device hash with CUST-10045, CUST-10046 ║
╠═══════════════════════════════════════════════════════════════════╣
║  RECOMMENDED ACTIONS                                              ║
║  ─────────────────────────────────────────────────────────────── ║
║  1. FREEZE ACCOUNT — Immediate hold on all debit activity         ║
║  2. NETWORK EXPAND — Investigate linked device accounts           ║
║  3. ID FORENSICS  — Submit documents to Socure/Jumio review       ║
║  4. SAR PREPARE  — Pre-file SAR; SYN-ID + $8.75K threshold met   ║
║  5. CREDIT BUREAU ALERT — Flag SSN to Experian/TransUnion         ║
╠═══════════════════════════════════════════════════════════════════╣
║  ASSIGNED TO : ANL-009 (Tier 2)        CASE : CASE-2024-0006     ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

### ALERT TICKET #5 — Money Mule Network Detection (P2)

```
╔═══════════════════════════════════════════════════════════════════╗
║  ⚠  VAULTSENTINEL SOC — NETWORK FRAUD ALERT                      ║
║  Alert ID  : VSC-ALERT-2024-0702                                  ║
║  Severity  : P2 — HIGH        Sub-Type : MULE_NETWORK CLUSTER    ║
║  Timestamp : 2024-07-03 02:44:17 UTC                              ║
╠═══════════════════════════════════════════════════════════════════╣
║  NETWORK CLUSTER SUMMARY                                          ║
║  ─────────────────────────────────────────────────────────────── ║
║  Cluster ID      : MULE-CLUSTER-2024-007                          ║
║  Hub Account     : CUST-10045 [Devin Taylor] ← Primary mule      ║
║  Connected Nodes : CUST-10046, CUST-10037, CUST-10029 (unconf.)  ║
║  Total Exposure  : $12,500.00 (confirmed) + $23,400 (suspected)  ║
║  Layering Method : Inbound DIGITAL_TRANSFER → Rapid ACH out       ║
╠═══════════════════════════════════════════════════════════════════╣
║  TRIGGERING TRANSACTION                                           ║
║  ─────────────────────────────────────────────────────────────── ║
║  Transaction ID  : TXN-2024-00096                                 ║
║  Inbound Amount  : $12,500.00 (Shell Account Transfer)            ║
║  Transit Time    : 8 minutes (inbound → outbound)                 ║
║  Outbound Split  : $6,200 → CUST-10046 | $6,300 → External       ║
║  Pattern         : Classic layering — round-trip smurfing         ║
╠═══════════════════════════════════════════════════════════════════╣
║  NETWORK GRAPH SIGNALS                                            ║
║  ─────────────────────────────────────────────────────────────── ║
║  Shared IP Range : 192.168.x.x proxy cluster — 3 accounts         ║
║  Shared Device   : DEV-K2L3M502 seen on CUST-10045 + CUST-10046  ║
║  Shared Phone    : One phone number linked to 2 accounts          ║
║  Transaction PSI : Population Stability Index = 0.42 (HIGH DRIFT) ║
╠═══════════════════════════════════════════════════════════════════╣
║  AML RISK INDICATORS                                              ║
║  ─────────────────────────────────────────────────────────────── ║
║  Structuring     : 3 transactions below $10K within 24hr window  ║
║  Velocity        : 9 transactions in 1 hour — velocity breach     ║
║  Fund Origin     : Inbound from DIGITAL_TRANSFER (no clear source)║
║  Fund Destination: Rapid outbound to external institution          ║
╠═══════════════════════════════════════════════════════════════════╣
║  RECOMMENDED ACTIONS                                              ║
║  ─────────────────────────────────────────────────────────────── ║
║  1. FREEZE ALL NODES — Hold CUST-10045, CUST-10046 accounts       ║
║  2. NETWORK EXPANSION — Run full graph query on shared signals    ║
║  3. SAR MULTI-SUBJECT — File multi-subject SAR within 30 days     ║
║  4. CLOSE ACCOUNTS — Terminate all confirmed mule accounts        ║
║  5. FRAUD CONSORTIUM — Share IOCs with peer institution network   ║
╠═══════════════════════════════════════════════════════════════════╣
║  ASSIGNED TO : ANL-006 (Tier 2) + FIU  CASE : CASE-2024-0014    ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## 4. Incident Response Playbooks

### Playbook A: Wire Fraud / BEC Response

```
TRIGGER: Wire alert with ML score ≥75 OR amount ≥$50K to new beneficiary

STEP 1 — DETECTION (T+0 to T+5 min)
  ├─ Rule engine / ML model generates alert
  ├─ Wire placed on 4-hour administrative hold (automatic)
  └─ Alert routed to on-call Tier 2 analyst

STEP 2 — TRIAGE (T+5 to T+30 min)
  ├─ Verify: Is beneficiary on known good list? → If YES, release
  ├─ Verify: Is destination country Tier 1 risk? → If YES, escalate P0/P1
  ├─ Verify: Customer initiated via expected channel/device? → If NO, ATO check
  └─ Verify: Matches any active threat intelligence IOC? → If YES, immediate hold

STEP 3 — CALLBACK VERIFICATION (T+30 to T+90 min)
  ├─ Call customer on REGISTERED phone number (not number from email/message)
  ├─ Verbally confirm: beneficiary name, amount, purpose, urgency claims
  ├─ If unverifiable → HOLD wire, escalate to Tier 3
  └─ If confirmed unauthorized → PROCEED TO CONTAINMENT

STEP 4 — CONTAINMENT (T+90 min to T+4h)
  ├─ Issue wire HOLD or RECALL order via SWIFT gpi or FedWire
  ├─ Block account for outbound wires pending investigation
  ├─ Notify correspondent bank of potential fraud (SWIFT message MT999)
  └─ Escalate to CRO if amount ≥$100K

STEP 5 — EVIDENCE COLLECTION (T+4h to T+24h)
  ├─ Pull full session logs: IP, device, session timeline
  ├─ Preserve email headers if BEC suspected
  ├─ Screenshot all account activity for case file
  └─ Document timeline of events

STEP 6 — REGULATORY FILING (T+24h to T+30 days)
  ├─ If loss ≥$5K confirmed → SAR required within 30 days
  ├─ If OFAC match → Immediate FinCEN notification
  └─ Document all actions in case management system

STEP 7 — RECOVERY (Ongoing)
  ├─ Coordinate chargeback / recall with receiving institution
  ├─ Engage FBI IC3 if recovery unsuccessful (wire fraud >$10K)
  └─ Close case with documented outcome
```

---

### Playbook B: Account Takeover (ATO) Response

```
TRIGGER: DEVICE_MISMATCH + HIGH_RISK_SCORE on digital channel transaction

STEP 1 — IMMEDIATE BLOCK (T+0 to T+2 min)
  ├─ Soft decline transaction pending step-up authentication
  ├─ Flag session for real-time monitoring
  └─ Push in-app notification to customer's REGISTERED device

STEP 2 — AUTHENTICATION CHALLENGE (T+2 to T+15 min)
  ├─ Require step-up: Push to registered device (not SMS if SIM swap suspected)
  ├─ If no registered device: knowledge-based auth + video selfie
  └─ If authentication fails 3x: Force logout, lock account

STEP 3 — ACCOUNT FORENSICS (T+15 min to T+2h)
  ├─ Review: Password reset activity in past 72 hours
  ├─ Review: Phone number / MFA changes in past 72 hours
  ├─ Review: New device registrations
  └─ Review: Contact information changes

STEP 4 — CONTAINMENT (If ATO confirmed)
  ├─ Reset all credentials, invalidate all active sessions
  ├─ Reverse SIM swap with carrier if applicable
  ├─ Block all outbound transactions for 24 hours
  └─ Notify customer via email to non-compromised backup address

STEP 5 — REMEDIATION
  ├─ Issue new account numbers if card data exposed
  ├─ Upgrade customer to hardware token or FIDO2 authenticator
  ├─ Flag account for 90-day enhanced monitoring
  └─ File SAR if confirmed ATO loss ≥$5K
```

---

## 5. TTP Reference — Financial Fraud (MITRE-Aligned)

| TTP Code | Tactic | Technique | Fraud Type | Indicators |
|----------|--------|-----------|-----------|-----------|
| FIN-T1 | Initial Access | Phishing / BEC Email | Wire Fraud, ATO | Spoofed domain, urgent language, CFO impersonation |
| FIN-T2 | Initial Access | Credential Stuffing | ATO | High-velocity login failures, multiple accounts, bot signature |
| FIN-T3 | Initial Access | SIM Swapping | ATO, Digital | Phone number change + immediate high-value transaction |
| FIN-T4 | Execution | Synthetic Identity | SYN-ID, ACH | Thin credit file, SSN age mismatch, multiple address changes |
| FIN-T5 | Execution | Skimming | Card Fraud | Device installation at POS/ATM, counterfeit card usage |
| FIN-T6 | Lateral Movement | Mule Recruitment | Mule Network | Rapid inbound-outbound, smurfing, shared device signals |
| FIN-T7 | Exfiltration | Wire Transfer | BEC, Wire Fraud | New beneficiary, high value, off-hours, high-risk jurisdiction |
| FIN-T8 | Exfiltration | ACH Pull | ACH Fraud | New ACH originator, unusual timing, account depletion |
| FIN-T9 | Exfiltration | P2P Transfer | ATO, Digital | First-use P2P platform, new payee, rapid transfer |
| FIN-T10 | Impact | Account Bust-Out | SYN-ID, Mule | Full balance depletion, immediate after account maturation |

---

## 6. Escalation Matrix

| Scenario | L1 Action | L2 Action | L3/FIU Action | Executive |
|----------|-----------|-----------|---------------|-----------|
| Wire ≥$1M | Immediate hold | Escalate L3 within 15 min | War room | CRO + CEO within 1hr |
| Wire $100K–$999K | Hold + triage | Investigate | Advise | CRO within 1hr |
| BEC confirmed | Hold + callback | Full investigation | SAR filing | CRO notified |
| ATO confirmed | Block + remediate | Forensics | If ≥$50K, SAR | VP Ops |
| Mule network (3+ accounts) | Flag all accounts | Network expansion | SAR multi-subject | VP Ops |
| OFAC match (any amount) | IMMEDIATE BLOCK | Do not release | FinCEN within 24hr | CRO + CLO |
| Synthetic ID bust-out | Freeze account | ID forensics | SAR filing | Team Lead |
| Data breach (internal) | Preserve logs | Evidence collection | FBI referral | CEO + CLO |

---

## 7. On-Call Analyst Reference

**Fraud Operations Center Contact Tree**

```
Primary On-Call (rotating weekly):
  L1 Lead:     [Call escalation line: ext. 5100]
  L2 Senior:   [Call escalation line: ext. 5200]
  L3 FIU:      [Call escalation line: ext. 5300]
  CRO Direct:  [Emergency line: ext. 5000]

External Escalation Contacts:
  SWIFT GPI Recall:   [gpi.operations@vaultsentinelcorp.com]
  FedWire Recall:     [fedwire.ops@vaultsentinelcorp.com]
  FinCEN SAR Line:    1-800-767-2825
  FBI IC3 Wire Fraud: ic3.gov
  OFAC Hotline:       1-800-540-6322
  FS-ISAC SOC:        [Member portal: fsisac.com]
```

---

*VaultSentinel Corp | SOC Alert Playbook v3.2 | CONFIDENTIAL — INTERNAL USE ONLY*
*Review cycle: Quarterly | Owner: VP Fraud Operations | Next review: March 2025*
