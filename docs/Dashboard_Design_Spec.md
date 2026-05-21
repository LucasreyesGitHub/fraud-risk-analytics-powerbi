# VaultSentinel Corp — Power BI Dashboard Design Specification
## Dark Enterprise Analytics Theme | Visual Design Reference
### Version 2.1 | BI Architecture & Design Team

---

## 1. Design Philosophy

The VaultSentinel Fraud Risk Intelligence Platform follows a **Cybersecurity Operations Center (SOC) aesthetic** — dark, data-dense, high-contrast, and mission-critical in feel. Every design decision prioritizes:

- **Signal over noise** — Critical KPIs surface immediately; secondary context is one click away
- **Operational density** — Analysts see maximum data without cognitive overload
- **Status at a glance** — Traffic-light color coding is consistent and unambiguous throughout
- **Executive-analyst duality** — Executive pages are minimal and KPI-first; operational pages are dense with drill capability

---

## 2. Dark Theme Color Palette

```
╔═══════════════════════════════════════════════════════════╗
║  VAULTSENTINEL DARK THEME — COLOR SYSTEM                 ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  BACKGROUNDS                                              ║
║  ─────────────────────────────────────────────────────── ║
║  Page Background      #0D1117   ████  Near-black base     ║
║  Card Fill            #161B22   ████  Elevated surface    ║
║  Header/Nav Fill      #1C2128   ████  Slightly lighter    ║
║  Hover / Selected     #21262D   ████  Interactive state   ║
║  Border / Divider     #30363D   ████  Subtle separator    ║
║                                                           ║
║  TEXT                                                     ║
║  ─────────────────────────────────────────────────────── ║
║  Primary Text         #F0F6FC   ████  Headlines, KPIs     ║
║  Secondary Text       #8B949E   ████  Labels, subtitles   ║
║  Muted Text           #484F58   ████  Placeholders        ║
║                                                           ║
║  SEMANTIC COLORS (Status / Risk)                          ║
║  ─────────────────────────────────────────────────────── ║
║  P0 Catastrophic      #FF2D55   ████  Critical fraud      ║
║  P1 Critical          #FF6B35   ████  High severity       ║
║  P2 High              #FFB800   ████  Warning / watch     ║
║  P3 Medium            #58A6FF   ████  Informational       ║
║  P4 Low / Safe        #3FB950   ████  Cleared / OK        ║
║                                                           ║
║  ACCENT & DATA COLORS                                     ║
║  ─────────────────────────────────────────────────────── ║
║  Primary Accent       #58A6FF   ████  Charts, links       ║
║  Secondary Accent     #BC8CFF   ████  Second series       ║
║  Tertiary Accent      #79C0FF   ████  Third series        ║
║  Highlight            #FFA657   ████  Callouts            ║
║  Neutral Data         #3FB950   ████  Positive trend      ║
║                                                           ║
║  CHANNEL COLORS (Consistent across all pages)             ║
║  ─────────────────────────────────────────────────────── ║
║  CARD_POS             #3FB950   ████  Green — lowest risk ║
║  CARD_CNP             #58A6FF   ████  Blue                ║
║  ACH_CREDIT           #79C0FF   ████  Light blue          ║
║  ACH_DEBIT            #A5D6FF   ████  Pale blue           ║
║  WIRE_DOMESTIC        #FFA657   ████  Orange — elevated   ║
║  WIRE_INTERNATIONAL   #FF6B35   ████  Red-orange — high   ║
║  DIGITAL_WALLET       #BC8CFF   ████  Purple              ║
║  DIGITAL_TRANSFER     #D2A8FF   ████  Light purple        ║
╚═══════════════════════════════════════════════════════════╝
```

### Power BI Theme JSON (Paste into theme file)

```json
{
  "name": "VaultSentinel Dark Theme v2.1",
  "dataColors": [
    "#3FB950", "#58A6FF", "#79C0FF", "#A5D6FF",
    "#FFA657", "#FF6B35", "#BC8CFF", "#D2A8FF"
  ],
  "background": "#0D1117",
  "foreground": "#F0F6FC",
  "tableAccent": "#58A6FF",
  "visualStyles": {
    "*": {
      "*": {
        "background": [{ "color": { "solid": { "color": "#161B22" } } }],
        "fontFamily": [{ "value": "Segoe UI, Inter, sans-serif" }]
      }
    }
  }
}
```

---

## 3. Typography

| Element | Font | Weight | Size | Color |
|---------|------|--------|------|-------|
| Page Title | Segoe UI | Semibold | 18px | #F0F6FC |
| Section Header | Segoe UI | Medium | 14px | #8B949E |
| KPI Value (Large) | Segoe UI | Bold | 32px | #F0F6FC |
| KPI Label | Segoe UI | Regular | 11px | #8B949E uppercase |
| KPI Delta | Segoe UI | Semibold | 13px | Dynamic (red/green) |
| Table Header | Segoe UI | Semibold | 12px | #8B949E |
| Table Row | Segoe UI | Regular | 12px | #F0F6FC |
| Tooltip | Segoe UI | Regular | 11px | #F0F6FC on #21262D |

---

## 4. Dashboard Wireframes

---

### PAGE 1 — Executive Risk Command Center

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ║
║ ▓  🛡 VAULTSENTINEL CORP     FRAUD RISK INTELLIGENCE PLATFORM    ● LIVE  ▓ ║
║ ▓  Executive Risk Command Center              Last refresh: 14:32 UTC     ▓ ║
║ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ║
║                                                                              ║
║  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐  ║
║  │  NET FRAUD    │ │  DETECTION    │ │  FRAUD LOSS   │ │  ML MODEL     │  ║
║  │    LOSS       │ │    RATE       │ │    RATE       │ │   F1 SCORE    │  ║
║  │               │ │               │ │               │ │               │  ║
║  │   $2.84M      │ │   94.3%       │ │  12.4 bps     │ │   0.912       │  ║
║  │               │ │               │ │               │ │               │  ║
║  │  ▼ -8.7% YoY  │ │  ▲ +2.1pp    │ │  ▼ -1.8 bps   │ │  ▲ +0.030    │  ║
║  │  ░░░░░░░░░░░  │ │  ████████░░  │ │  ████████░░   │ │  ████████░░  │  ║
║  │  Target: $4.2M│ │  Target: 92% │ │  Target: 15bp │ │  Target: 0.90│  ║
║  └───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘  ║
║                                                                              ║
║  ┌─────────────────────────────────────┐ ┌──────────────────────────────┐  ║
║  │  MONTHLY FRAUD LOSS TREND           │ │  CHANNEL RISK HEATMAP        │  ║
║  │  ($K Net Loss — FY2024)             │ │  (Fraud Rate % by Channel)   │  ║
║  │                                     │ │                              │  ║
║  │  800│ ●                             │ │         Q1  Q2  Q3  Q4       │  ║
║  │  700│  ╲                            │ │  WIRE_I  ■■■ ■■■ ■■■ ■■     │  ║
║  │  600│   ●──●                        │ │  WIRE_D  ■░░ ■░░ ░░░ ░░     │  ║
║  │  500│       ╲___●──●──●──●          │ │  DIG_TRN ░■░ ░■░ ░░░ ░░     │  ║
║  │  400│                    ╲__●       │ │  DIG_WAL ░░░ ░░░ ░░░ ░░     │  ║
║  │     └──────────────────────────     │ │  CARD_CNP░░░ ░░░ ░░░ ░░     │  ║
║  │      Jan  Mar  May  Jul  Sep  Dec   │ │  ■ HIGH  ■ MED  ░ LOW       │  ║
║  └─────────────────────────────────────┘ └──────────────────────────────┘  ║
║                                                                              ║
║  ┌───────────────────────────────────────────────────────────────────────┐  ║
║  │  ACTIVE CRITICAL CASES     [4 OPEN P0/P1]  [8 P2 HIGH]  [12 P3 MED]  │  ║
║  │  ───────────────────────────────────────────────────────────────────  │  ║
║  │  Case ID        Type              Amount       Severity  Age  Analyst  │  ║
║  │  CASE-2024-004  BEC / Wire        $850,000     🔴 P0     87d  ANL-001  │  ║
║  │  CASE-2024-015  Wire Fraud        $320,000     🔴 P1     49d  ANL-010  │  ║
║  │  CASE-2024-019  Intl Wire Fraud   $175,000     🔴 P1     27d  ANL-001  │  ║
║  │  CASE-2024-039  Wire Fraud        $175,000     🔴 P1      5d  ANL-010  │  ║
║  │  [▼ Click to drillthrough → Case Detail Page]                          │  ║
║  └───────────────────────────────────────────────────────────────────────┘  ║
║                                                                              ║
║  [ Page 1 of 6 ]  [ 1 │ 2 │ 3 │ 4 │ 5 │ 6 ]      © VaultSentinel Corp   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

### PAGE 2 — Multi-Channel Fraud Intelligence

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║ ▓▓  Multi-Channel Fraud Intelligence     [Channel ▼] [Month ▼] [Year ▼]  ▓▓ ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  ┌──────────────────────────────────────────────────────────────────────┐   ║
║  │  FRAUD RATE BY CHANNEL (%)     ← Sorted by fraud rate descending     │   ║
║  │                                                                      │   ║
║  │  WIRE_INTERNATIONAL ████████████████████████████████░░░░░░  9.35%   │   ║
║  │  DIGITAL_TRANSFER   ██████████████░░░░░░░░░░░░░░░░░░░░░░░░  3.60%   │   ║
║  │  CARD_CNP           ████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  2.38%   │   ║
║  │  DIGITAL_WALLET     ███████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  2.16%   │   ║
║  │  WIRE_DOMESTIC      █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  1.79%   │   ║
║  │  ACH_DEBIT          ███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  0.69%   │   ║
║  │  ACH_CREDIT         █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  0.22%   │   ║
║  │  CARD_POS           █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  0.28%   │   ║
║  └──────────────────────────────────────────────────────────────────────┘   ║
║                                                                              ║
║  ┌──────────────────────────────┐  ┌─────────────────────────────────────┐  ║
║  │  FRAUD LOSS SHARE BY CHANNEL │  │  TRANSACTION VOLUME vs FRAUD LOSS   │  ║
║  │  (% of Net Fraud Loss $)     │  │  (Bubble chart — size = loss)       │  ║
║  │                              │  │                                     │  ║
║  │     WIRE_INTL  ████  38.2%   │  │  Vol│         ●WIRE_I (large)       │  ║
║  │     WIRE_DOM   ███   14.7%   │  │  High│    ●CARD_CNP                │  ║
║  │     DIG_TRANS  ██    11.3%   │  │      │  ●DIG_TRN                   │  ║
║  │     CARD_CNP   ██    10.8%   │  │  Low │●CARD_POS ●ACH               │  ║
║  │     DIG_WALL   █      8.9%   │  │      └──────────────────────────── │  ║
║  │     ACH        █      8.2%   │  │        Low Fraud%     High Fraud%   │  ║
║  │     CARD_POS   ░      7.9%   │  └─────────────────────────────────────┘  ║
║  └──────────────────────────────┘                                           ║
║                                                                              ║
║  ┌──────────────────────────────────────────────────────────────────────┐   ║
║  │  FRAUD TYPE DISTRIBUTION (Top 8)         [YTD 2024]                  │   ║
║  │  WIRE_FRAUD         ████████████  28.4%                              │   ║
║  │  CNP_FRAUD          █████████     22.1%                              │   ║
║  │  ATO                ███████       17.8%                              │   ║
║  │  BEC                █████         12.3%                              │   ║
║  │  ACH_FRAUD          ████           9.7%                              │   ║
║  │  SYNTHETIC_ID       ███            7.2%                              │   ║
║  │  MULE_NETWORK       ██             1.8%                              │   ║
║  │  SKIMMING           █              0.7%                              │   ║
║  └──────────────────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

### PAGE 3 — ML Model Performance Monitor

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║ ▓▓  ML Model Performance Monitor          Model Version: v2.3  [Active] ▓▓  ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐  ║
║  │  PRECISION   │ │   RECALL     │ │   F1 SCORE   │ │  FALSE POSITIVE  │  ║
║  │   94.3%      │ │   91.8%      │ │   0.912      │ │    RATE 5.2%     │  ║
║  │  ▲ +2.2pp    │ │  ▲ +1.8pp   │ │  ▲ +0.030   │ │  ▼ -0.9pp        │  ║
║  │  Trgt: ≥92%  │ │  Trgt: ≥90% │ │  Trgt: ≥0.90│ │  Trgt: ≤6%       │  ║
║  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────────┘  ║
║                                                                              ║
║  ┌─────────────────────────────────────┐  ┌──────────────────────────────┐  ║
║  │  PRECISION-RECALL TREND (Monthly)  │  │  CONFUSION MATRIX (Nov 2024) │  ║
║  │                                    │  │                              │  ║
║  │  100│         ····Precision         │  │         PRED:0   PRED:1      │  ║
║  │   95│    ·····················      │  │  ACT:0   TN:2,847  FP:156   │  ║
║  │   90│   ·                  ·        │  │  ACT:1   FN:52   TP:1,845   │  ║
║  │   85│  Recall              ·        │  │                              │  ║
║  │   80│  ··············  ·····        │  │  Accuracy: 95.3%             │  ║
║  │     └────────────────────────       │  │  PPV: 94.3% | NPV: 98.2%    │  ║
║  │      Jan  Mar  May  Jul  Sep  Nov   │  └──────────────────────────────┘  ║
║  └─────────────────────────────────────┘                                   ║
║                                                                              ║
║  ┌──────────────────────────────────────────────────────────────────────┐   ║
║  │  ML SCORE DISTRIBUTION — Fraud vs. Legitimate (Nov 2024)             │   ║
║  │                                                                      │   ║
║  │  Freq│                         FRAUD        │   LEGIT               │   ║
║  │      │                         distribution │   distribution        │   ║
║  │  400 │                         ╭────────╮   │   ╭─────────╮         │   ║
║  │  300 │                     ╭───╯        ╰╮  │╭──╯         ╰──╮     │   ║
║  │  200 │                  ╭──╯             ╰──╯╯               ╰──   │   ║
║  │  100 │             ╭────╯                                          │   ║
║  │      └────────────────────────────────────────────────────────────  │   ║
║  │       0    10   20   30   40   50   60  [75]  80   90  100          │   ║
║  │                                         ↑ Alert Threshold          │   ║
║  └──────────────────────────────────────────────────────────────────────┘   ║
║                                                                              ║
║  ┌──────────────────────────────────────────────────────────────────────┐   ║
║  │  FALSE POSITIVE BREAKDOWN BY SEGMENT (Top 5 FP Sources)              │   ║
║  │  HIGH_VALUE_LEGIT_WIRE    ████████  31.4%  — Large legitimate wires  │   ║
║  │  NEW_CUSTOMER_FIRST_TXN   ██████    24.7%  — First transactions      │   ║
║  │  INTL_BUSINESS_TRAVEL     █████     19.2%  — Frequent intl travel    │   ║
║  │  LARGE_CNP_PURCHASE       ████      15.8%  — High-value CNP (legit)  │   ║
║  │  LATE_NIGHT_LEGIT         ██         8.9%  — Legitimate off-hrs txn  │   ║
║  └──────────────────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

### PAGE 4 — Fraud Case Operations Pipeline

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║ ▓▓  Fraud Case Operations Pipeline       [Analyst ▼] [Priority ▼] [Date ▼] ▓▓║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐  ║
║  │  OPEN CASES  │ │  AVG RESOL.  │ │  RECOVERY    │ │  SLA COMPLIANCE  │  ║
║  │      4       │ │  3.2 Days    │ │   RATE 87.3% │ │     96.8%        │  ║
║  │  (P0:1/P1:3) │ │  ▼ -0.5 days│ │  ▲ +9.0pp   │ │  ▲ +1.2pp        │  ║
║  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────────┘  ║
║                                                                              ║
║  ┌──────────────────────────────────────┐ ┌───────────────────────────────┐ ║
║  │  CASE FUNNEL                         │ │  CASES BY FRAUD TYPE          │ ║
║  │                                      │ │  (FY2024 — 40 cases total)    │ ║
║  │  100 Alerts Generated                │ │                               │ ║
║  │   ────────────────────               │ │  Wire Fraud    ██████  12     │ ║
║  │     ↓ 78 investigated                │ │  CNP Fraud     █████   10     │ ║
║  │     ────────────────────             │ │  ATO           ████     8     │ ║
║  │       ↓ 36 confirmed fraud           │ │  ACH Fraud     ███      5     │ ║
║  │       ─────────────────              │ │  Synthetic ID  ██       3     │ ║
║  │         ↓ 6 SARs filed              │ │  Mule Network  ██       2     │ ║
║  │         ──────────────               │ └───────────────────────────────┘ ║
║  │           ↓ 4 still open            │                                   ║
║  └──────────────────────────────────────┘                                   ║
║                                                                              ║
║  ┌──────────────────────────────────────────────────────────────────────┐   ║
║  │  CASE AGE DISTRIBUTION (Open Cases)                                   │   ║
║  │  > 90 days   [CASE-2024-004] ██████████████████████████████  1 case   │   ║
║  │  60–90 days  [CASE-2024-015] ████████████████████            1 case   │   ║
║  │  30–60 days  [CASE-2024-019] █████████████                   1 case   │   ║
║  │   0–30 days  [CASE-2024-040] ████                             1 case  │   ║
║  │                              ⚠ Cases >30d overdue for escalation     │   ║
║  └──────────────────────────────────────────────────────────────────────┘   ║
║                                                                              ║
║  ┌──────────────────────────────────────────────────────────────────────┐   ║
║  │  ANALYST WORKLOAD (Active Cases per Analyst)                          │   ║
║  │  ANL-001  ██████████████████  6 cases  $1.34M exposure [OVERLOADED] │   ║
║  │  ANL-010  ████████████        4 cases  $980K exposure                │   ║
║  │  ANL-009  ████████            3 cases  $350K exposure                │   ║
║  │  ANL-005  ██████              2 cases  $120K exposure                │   ║
║  │  ANL-006  ██████              2 cases  $85K exposure                 │   ║
║  └──────────────────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

### PAGE 5 — Customer Risk Segmentation

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║ ▓▓  Customer & Account Risk Segmentation    [Risk Tier ▼] [Channel ▼]     ▓▓ ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐  ║
║  │  CRITICAL    │ │  HIGH RISK   │ │  WATCHLISTED │ │  EDD REQUIRED    │  ║
║  │  ACCOUNTS    │ │  ACCOUNTS    │ │  ACCOUNTS    │ │  ACCOUNTS        │  ║
║  │      4       │ │      8       │ │      6       │ │       8          │  ║
║  │  Score ≥80   │ │  Score 60-79 │ │  (Active)    │ │  Overdue: 2      │  ║
║  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────────┘  ║
║                                                                              ║
║  ┌──────────────────────────────────┐  ┌────────────────────────────────┐  ║
║  │  RISK TIER DISTRIBUTION          │  │  RISK SCORE vs TRANSACTION VOL │  ║
║  │  (50 accounts — full portfolio)  │  │  (Bubble = monthly avg amt)    │  ║
║  │                                  │  │                                │  ║
║  │  MINIMAL  ██████████████  10 (20%)│  │  High│              ●CUST-050  │  ║
║  │  LOW      ███████████████ 15 (30%)│  │  Risk│         ●CUST-047      │  ║
║  │  MEDIUM   ████████████   13 (26%) │  │      │  ●CUST-041             │  ║
║  │  HIGH     ████████        8 (16%) │  │  Low │●●●●●●                  │  ║
║  │  CRITICAL  ████            4 (8%) │  │      └────────────────────    │  ║
║  │                                  │  │       Low Vol.    High Vol.    │  ║
║  └──────────────────────────────────┘  └────────────────────────────────┘  ║
║                                                                              ║
║  ┌──────────────────────────────────────────────────────────────────────┐   ║
║  │  HIGH RISK & CRITICAL WATCHLIST  [Click row → Drillthrough Profile]   │   ║
║  │  Customer ID    Name              Risk  Score  KYC Status   PEP  SAR │   ║
║  │  CUST-10050     Anonymous Entity   CRIT   94   ⚠ PENDING    Y    Y   │   ║
║  │  CUST-10049     Mohammed Al-R.     CRIT   91   ⚠ PENDING    Y    N   │   ║
║  │  CUST-10047     Vladimir Petrov    CRIT   88   EDD          Y    N   │   ║
║  │  CUST-10048     Chen Wei           CRIT   85   EDD          Y    N   │   ║
║  │  CUST-10043     Casey Johnson      HIGH   78   EDD          Y    N   │   ║
║  │  CUST-10041     Jordan Williams    HIGH   75   EDD          Y    N   │   ║
║  │  ...            [8 more HIGH risk accounts]                          │   ║
║  └──────────────────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

### PAGE 6 — Geospatial Fraud Intelligence

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║ ▓▓  Geospatial Fraud Intelligence       [Region ▼] [Fraud Type ▼] [Year ▼] ▓▓║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  ┌──────────────────────────────────────────────────────────────────────┐   ║
║  │  FRAUD TRANSACTION ORIGIN-DESTINATION MAP (Filled map visual)         │   ║
║  │                                                                      │   ║
║  │      [WORLD MAP — countries shaded by fraud volume received]         │   ║
║  │                                                                      │   ║
║  │      🟢 US (origin most txns)                                        │   ║
║  │      🔴 NG Nigeria     — 1 case, $850K                              │   ║
║  │      🔴 RO Romania     — 2 cases, $2.1M combined                    │   ║
║  │      🟠 CN China       — 1 case, $450K                              │   ║
║  │      🟠 MX Mexico      — 2 cases, $4.8K + $320K                    │   ║
║  │      🟡 CA/UK/DE/FR/AU — Legitimate cross-border flows              │   ║
║  │                                                                      │   ║
║  └──────────────────────────────────────────────────────────────────────┘   ║
║                                                                              ║
║  ┌──────────────────────────────────┐  ┌────────────────────────────────┐  ║
║  │  HIGH-RISK JURISDICTION TABLE    │  │  IP REPUTATION HEATMAP         │  ║
║  │                                  │  │  (Avg IP Score by Channel)     │  ║
║  │  Country  Cases  Exp.    Status  │  │                                │  ║
║  │  NG       1      $850K   🔴 TIER1│  │  CARD_POS    94  ██████████   │  ║
║  │  RO       2      $2.1M   🔴 TIER1│  │  CARD_CNP    76  ████████     │  ║
║  │  CN       1      $450K   🔴 TIER1│  │  ACH         89  █████████    │  ║
║  │  BR       1      $568K   🟠 TIER2│  │  WIRE_DOM    85  █████████    │  ║
║  │  MX       2      $324K   🟠 TIER2│  │  WIRE_INTL   45  █████        │  ║
║  │  KY       1      $320K   🟡 TIER3│  │  DIGITAL     62  ██████       │  ║
║  └──────────────────────────────────┘  └────────────────────────────────┘  ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## 5. KPI Card Design Variants

### Variant A — Primary KPI (Large Value)
```
┌─────────────────────────────────────┐
│  NET FRAUD LOSS                     │
│                                     │
│  $2.84M                             │
│  ▼ -8.7% vs prior year              │
│                                     │
│  ░░░░░░░░░░░░░░░░░░░░░░             │
│  Progress to $4.2M target  67.6%   │
└─────────────────────────────────────┘
Colors: Label=#8B949E | Value=#F0F6FC | Delta=Dynamic
```

### Variant B — Score / Rate KPI (With Sparkline)
```
┌─────────────────────────────────────┐
│  FRAUD DETECTION RATE               │
│  ▁▂▃▅▇▆▇▇▇▇  (12-month sparkline)  │
│                                     │
│  94.3%                              │
│  ▲ +2.1pp YoY  |  Target: ≥92%  ✓  │
└─────────────────────────────────────┘
```

### Variant C — Status Card (RAG Indicator)
```
┌─────────────────────────────────────┐
│  🔴  WIRE FRAUD INTERNATIONAL       │
│  STATUS: ESCALATING                 │
│                                     │
│  $1.34M open exposure               │
│  3 active cases | 87 days avg age  │
│  [▶ View Cases]                     │
└─────────────────────────────────────┘
```

### Variant D — Metric + Mini Bar (Compact)
```
┌────────────────────┐
│  FALSE POS RATE    │
│  5.2%  ▼ -0.9pp   │
│  █████░░░░ Target │
└────────────────────┘
```

---

## 6. Drillthrough Pages

### Drillthrough A — Customer Risk Profile
**Trigger:** Right-click on any customer row → Drillthrough → Customer Profile

**Content:**
- Customer header: ID, name, risk tier badge, KYC status chip
- Composite risk score gauge (0–100 needle gauge)
- Transaction history (last 12 months) — line chart by channel
- Fraud & dispute history — timeline
- Network connections — linked accounts/devices (table)
- Case history — all linked fraud cases
- KYC documentation status and expiry dates
- Recommended actions buttons: "Open Case" | "Escalate EDD" | "File SAR"

### Drillthrough B — Case Detail
**Trigger:** Right-click on any case row → Drillthrough → Case Detail

**Content:**
- Case header: ID, status badge, priority badge, assigned analyst, SLA gauge
- Transaction details: all linked transactions in a table
- Timeline: case events from alert creation to current status
- Financial summary: at-risk, recovered, outstanding
- Evidence log: rules triggered, ML scores, behavioral flags
- Communication log: callback attempts, customer contacts
- Regulatory status: SAR filed Y/N, OFAC matches, reports submitted

### Drillthrough C — Alert Detail
**Trigger:** Right-click on an alert in the queue table → Alert Detail

**Content:**
- Full alert ticket (mirroring the SOC ticket format)
- ML model feature contribution bar chart (top 10 features)
- Historical similar alerts (same customer or device)
- Recommended playbook steps (based on fraud type)
- One-click actions: "Open Case" | "Mark False Positive" | "Escalate"

---

## 7. Navigation & Bookmark Structure

```
Navigation Bar (persistent, left side):
  🛡  Home (Executive Command Center)
  📊  Channel Intelligence
  🤖  Model Performance
  📋  Case Operations
  👤  Customer Risk
  🌍  Geospatial
  ─────────────────
  🔍  Search Transactions [Bookmark]
  ⚡  Live Alert Queue [Bookmark]
  📑  SAR Pre-Filing Report [Paginated]
```

**Recommended Bookmarks:**
- "My Open Cases" (filtered to current analyst)
- "Critical Cases Only" (P0+P1 filter)
- "Wire Fraud Focus" (channel = WIRE_INTERNATIONAL)
- "Month to Date View" (date filter = current month)
- "YoY Comparison View" (shows prior year overlay)

---

## 8. Tooltip Design

**Transaction Tooltip (hover on chart data point):**
```
╭─────────────────────────────────────╮
│  TXN-2024-00075                     │
│  WIRE_INTERNATIONAL | $850,000      │
│  May 3, 2024 at 23:45 UTC           │
│  ─────────────────────────────────  │
│  Risk Score:  92 / 100  🔴          │
│  ML Score:    95.7 / 100            │
│  Destination: NG — TIER 1           │
│  Resolution:  CONFIRMED FRAUD       │
│  [▶ View Full Case]                 │
╰─────────────────────────────────────╯
```

---

*VaultSentinel Corp | Dashboard Design Spec v2.1 | BI Architecture Team*
*Design review: Quarterly | Owner: Lead BI Developer | Next review: March 2025*
