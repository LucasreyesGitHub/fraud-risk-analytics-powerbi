"""
VaultSentinel Corp — Fraud Risk Analytics Platform
Data Validation Script

Validates all CSV datasets for:
  - Schema completeness (required columns present)
  - Null / missing value counts
  - Data type consistency
  - Value range constraints (risk_score 0-100, fraud_flag 0/1, etc.)
  - Referential integrity (customer IDs cross-file)
  - Business rule checks (chargeback <= amount, etc.)
  - Summary statistics for QA review

Usage:
    python scripts/validate_data.py
    python scripts/validate_data.py --data-dir ./data --verbose

Author: Lucas Reyes
Version: 1.0
"""

import os
import sys
import argparse
import json
from datetime import datetime
from pathlib import Path

import pandas as pd
import numpy as np


# ============================================================
# Configuration — expected schemas per file
# ============================================================

SCHEMAS: dict[str, dict] = {
    "transactions_2024.csv": {
        "required_columns": [
            "transaction_id", "transaction_date", "transaction_time",
            "channel", "amount_usd", "currency", "merchant_category_code",
            "customer_id", "origin_country", "destination_country",
            "risk_score", "fraud_flag", "fraud_type", "alert_rule_triggered",
            "resolution_status", "chargeback_amount_usd", "ml_model_score",
        ],
        "not_null": [
            "transaction_id", "transaction_date", "channel",
            "amount_usd", "customer_id", "fraud_flag", "risk_score",
        ],
        "unique": ["transaction_id"],
        "numeric_ranges": {
            "amount_usd": (0.01, 10_000_000),
            "risk_score": (0, 100),
            "fraud_flag": (0, 1),
            "chargeback_amount_usd": (0, 10_000_000),
            "ip_reputation_score": (0, 100),
            "ml_model_score": (0, 100),
            "velocity_count_1h": (0, 1000),
            "velocity_count_24h": (0, 10000),
        },
        "allowed_values": {
            "channel": [
                "CARD_POS", "CARD_CNP", "ACH_CREDIT", "ACH_DEBIT",
                "WIRE_DOMESTIC", "WIRE_INTERNATIONAL",
                "DIGITAL_WALLET", "DIGITAL_TRANSFER",
            ],
            "fraud_flag": [0, 1],
            "resolution_status": [
                "CLEARED", "FALSE_POSITIVE", "CONFIRMED_FRAUD",
                "UNDER_REVIEW", "ESCALATED",
            ],
            "currency": ["USD", "EUR", "GBP", "CAD"],
        },
        "business_rules": [
            {
                "name": "chargeback_le_amount",
                "description": "Chargeback amount must not exceed transaction amount",
                "check": lambda df: df["chargeback_amount_usd"] <= df["amount_usd"],
            },
            {
                "name": "fraud_chargeback_consistency",
                "description": "Non-fraud transactions should have zero chargeback",
                "check": lambda df: ~(
                    (df["fraud_flag"] == 0) & (df["chargeback_amount_usd"] > 0)
                ),
            },
            {
                "name": "ml_score_high_on_fraud",
                "description": "Confirmed fraud should have ML score > 50 on average",
                "check": lambda df: (
                    df[df["fraud_flag"] == 1]["ml_model_score"].mean() > 50
                    if "ml_model_score" in df.columns else True
                ),
                "aggregate": True,  # Aggregate check, not row-level
            },
        ],
    },

    "customer_risk_profiles.csv": {
        "required_columns": [
            "customer_id", "full_name", "account_open_date", "account_type",
            "country", "risk_tier", "composite_risk_score",
            "fraud_history_count", "dispute_count", "kyc_status",
            "watchlist_flag", "pep_flag",
        ],
        "not_null": [
            "customer_id", "full_name", "account_open_date",
            "account_type", "risk_tier", "composite_risk_score",
        ],
        "unique": ["customer_id"],
        "numeric_ranges": {
            "composite_risk_score": (0, 100),
            "fraud_history_count": (0, 100),
            "dispute_count": (0, 100),
            "avg_monthly_transactions": (0, 10000),
            "avg_transaction_amount_usd": (0, 10_000_000),
        },
        "allowed_values": {
            "risk_tier": ["MINIMAL", "LOW", "MEDIUM", "HIGH", "CRITICAL"],
            "account_type": [
                "PERSONAL_CHECKING", "PERSONAL_SAVINGS",
                "BUSINESS_CHECKING", "PREMIUM_ACCOUNT",
            ],
            "kyc_status": [
                "VERIFIED", "PENDING", "EXPIRED",
                "UNDER_REVIEW", "ENHANCED_DUE_DILIGENCE",
            ],
            "watchlist_flag": ["Y", "N"],
            "pep_flag": ["Y", "N"],
        },
        "business_rules": [
            {
                "name": "critical_tier_score",
                "description": "CRITICAL risk tier customers must have score >= 80",
                "check": lambda df: ~(
                    (df["risk_tier"] == "CRITICAL") & (df["composite_risk_score"] < 80)
                ),
            },
            {
                "name": "pep_kyc_edd",
                "description": "PEP-flagged customers should have EDD or PENDING KYC",
                "check": lambda df: ~(
                    (df["pep_flag"] == "Y")
                    & (~df["kyc_status"].isin(
                        ["ENHANCED_DUE_DILIGENCE", "PENDING"]
                    ))
                ),
            },
        ],
    },

    "fraud_cases_2024.csv": {
        "required_columns": [
            "case_id", "case_open_date", "channel", "fraud_type",
            "case_status", "amount_at_risk_usd", "recovered_amount_usd",
            "customer_id", "priority", "sar_filed",
        ],
        "not_null": [
            "case_id", "case_open_date", "channel",
            "fraud_type", "case_status", "amount_at_risk_usd",
        ],
        "unique": ["case_id"],
        "numeric_ranges": {
            "amount_at_risk_usd": (0, 100_000_000),
            "recovered_amount_usd": (0, 100_000_000),
        },
        "allowed_values": {
            "case_status": [
                "OPEN", "UNDER_INVESTIGATION", "RESOLVED",
                "ESCALATED", "SAR_FILED",
            ],
            "priority": ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
            "sar_filed": ["Y", "N"],
            "escalation_flag": ["Y", "N"],
        },
        "business_rules": [
            {
                "name": "recovery_le_exposure",
                "description": "Recovered amount must not exceed amount at risk",
                "check": lambda df: df["recovered_amount_usd"] <= df["amount_at_risk_usd"],
            },
        ],
    },

    "monthly_channel_summary.csv": {
        "required_columns": [
            "year_month", "channel", "total_transactions", "total_volume_usd",
            "fraud_transactions", "fraud_loss_usd", "fraud_rate_pct",
            "alert_count", "false_positive_count",
            "chargebacks_usd", "net_fraud_loss_usd",
        ],
        "not_null": [
            "year_month", "channel", "total_transactions",
            "fraud_transactions", "fraud_rate_pct",
        ],
        "unique": [],  # Compound unique: (year_month, channel)
        "compound_unique": [["year_month", "channel"]],
        "numeric_ranges": {
            "total_transactions": (0, 10_000_000),
            "total_volume_usd": (0, 1_000_000_000_000),
            "fraud_transactions": (0, 10_000_000),
            "fraud_rate_pct": (0, 100),
            "false_positive_count": (0, 10_000_000),
        },
        "business_rules": [
            {
                "name": "fraud_le_total",
                "description": "Fraud transactions must not exceed total transactions",
                "check": lambda df: df["fraud_transactions"] <= df["total_transactions"],
            },
            {
                "name": "fp_le_alerts",
                "description": "False positives must not exceed alert count",
                "check": lambda df: df["false_positive_count"] <= df["alert_count"],
            },
            {
                "name": "net_loss_le_gross",
                "description": "Net fraud loss must not exceed gross fraud loss",
                "check": lambda df: df["net_fraud_loss_usd"] <= df["fraud_loss_usd"],
            },
        ],
    },

    "fraud_scenarios_2024.csv": {
        "required_columns": [
            "scenario_id", "scenario_name", "codename",
            "campaign_start", "threat_actor_type", "primary_fraud_type",
            "total_exposure_usd", "confirmed_loss_usd",
            "severity_level", "outcome",
        ],
        "not_null": [
            "scenario_id", "scenario_name", "primary_fraud_type",
            "severity_level",
        ],
        "unique": ["scenario_id", "codename"],
        "numeric_ranges": {
            "total_exposure_usd": (0, 1_000_000_000),
            "confirmed_loss_usd": (0, 1_000_000_000),
            "recovered_usd": (0, 1_000_000_000),
        },
        "allowed_values": {
            "severity_level": ["P0", "P1", "P2", "P3", "P4"],
        },
        "business_rules": [
            {
                "name": "loss_le_exposure",
                "description": "Confirmed loss must not exceed total exposure",
                "check": lambda df: df["confirmed_loss_usd"] <= df["total_exposure_usd"],
            },
            {
                "name": "recovery_le_loss",
                "description": "Recovered amount must not exceed confirmed loss",
                "check": lambda df: df["recovered_usd"] <= df["confirmed_loss_usd"],
            },
        ],
    },
}


# ============================================================
# Validation Engine
# ============================================================

class DataValidator:
    """Runs validation checks on a single CSV dataset."""

    def __init__(self, filepath: Path, schema: dict, verbose: bool = False):
        self.filepath = filepath
        self.schema = schema
        self.verbose = verbose
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.df: pd.DataFrame | None = None

    def _log(self, msg: str) -> None:
        if self.verbose:
            print(f"    {msg}")

    def load(self) -> bool:
        """Load CSV into dataframe. Returns False on failure."""
        try:
            self.df = pd.read_csv(self.filepath, low_memory=False)
            self._log(f"Loaded {len(self.df):,} rows × {len(self.df.columns)} columns")
            return True
        except Exception as exc:
            self.errors.append(f"LOAD FAILED: {exc}")
            return False

    def check_schema(self) -> None:
        """Verify all required columns are present."""
        missing = [
            col for col in self.schema.get("required_columns", [])
            if col not in self.df.columns
        ]
        if missing:
            self.errors.append(f"Missing required columns: {missing}")
        else:
            self._log(f"Schema check PASSED ({len(self.df.columns)} columns)")

    def check_nulls(self) -> None:
        """Check not-null constraints on required fields."""
        for col in self.schema.get("not_null", []):
            if col not in self.df.columns:
                continue
            null_count = self.df[col].isna().sum()
            if null_count > 0:
                self.errors.append(
                    f"NOT NULL violation — '{col}': {null_count:,} null values"
                )
            else:
                self._log(f"Null check PASSED: '{col}'")

    def check_unique(self) -> None:
        """Check uniqueness constraints on key columns."""
        for col in self.schema.get("unique", []):
            if col not in self.df.columns:
                continue
            dup_count = self.df[col].duplicated().sum()
            if dup_count > 0:
                self.errors.append(
                    f"UNIQUE violation — '{col}': {dup_count:,} duplicate values"
                )

        for cols in self.schema.get("compound_unique", []):
            if not all(c in self.df.columns for c in cols):
                continue
            dup_count = self.df[cols].duplicated().sum()
            if dup_count > 0:
                self.errors.append(
                    f"COMPOUND UNIQUE violation — {cols}: {dup_count:,} duplicates"
                )

    def check_ranges(self) -> None:
        """Validate numeric column value ranges."""
        for col, (lo, hi) in self.schema.get("numeric_ranges", {}).items():
            if col not in self.df.columns:
                continue
            series = pd.to_numeric(self.df[col], errors="coerce")
            violations = ((series < lo) | (series > hi)).sum()
            if violations > 0:
                self.errors.append(
                    f"RANGE violation — '{col}' [{lo}, {hi}]: "
                    f"{violations:,} values out of range "
                    f"(min={series.min():.2f}, max={series.max():.2f})"
                )
            else:
                self._log(f"Range check PASSED: '{col}' [{lo}–{hi}]")

    def check_allowed_values(self) -> None:
        """Validate categorical columns contain only allowed values."""
        for col, allowed in self.schema.get("allowed_values", {}).items():
            if col not in self.df.columns:
                continue
            invalid = ~self.df[col].isin(allowed)
            inv_count = invalid.sum()
            if inv_count > 0:
                bad_vals = self.df.loc[invalid, col].unique()[:5].tolist()
                self.warnings.append(
                    f"ALLOWED VALUES — '{col}': {inv_count:,} invalid values "
                    f"(e.g. {bad_vals})"
                )

    def check_business_rules(self) -> None:
        """Run business rule checks defined in the schema."""
        for rule in self.schema.get("business_rules", []):
            try:
                if rule.get("aggregate"):
                    # Aggregate check — returns a scalar bool
                    result = rule["check"](self.df)
                    if not result:
                        self.warnings.append(
                            f"BUSINESS RULE — '{rule['name']}': "
                            f"{rule['description']} — FAILED"
                        )
                else:
                    # Row-level check — returns a bool Series
                    mask = rule["check"](self.df)
                    failures = (~mask).sum()
                    if failures > 0:
                        self.errors.append(
                            f"BUSINESS RULE — '{rule['name']}': "
                            f"{rule['description']} — "
                            f"{failures:,} violations"
                        )
                    else:
                        self._log(f"Business rule PASSED: '{rule['name']}'")
            except Exception as exc:
                self.warnings.append(
                    f"BUSINESS RULE — '{rule['name']}': "
                    f"Could not evaluate — {exc}"
                )

    def summary_stats(self) -> dict:
        """Return summary statistics for numeric columns."""
        numeric_cols = self.df.select_dtypes(include=[np.number]).columns.tolist()
        stats = {}
        for col in numeric_cols[:10]:  # Limit to first 10 numeric columns
            stats[col] = {
                "count": int(self.df[col].notna().sum()),
                "mean": round(float(self.df[col].mean()), 4),
                "min": round(float(self.df[col].min()), 4),
                "max": round(float(self.df[col].max()), 4),
                "nulls": int(self.df[col].isna().sum()),
            }
        return stats

    def run(self) -> dict:
        """Execute all checks and return results dict."""
        if not self.load():
            return {
                "file": self.filepath.name,
                "status": "LOAD_ERROR",
                "errors": self.errors,
                "warnings": [],
                "rows": 0,
                "columns": 0,
                "stats": {},
            }

        self.check_schema()
        self.check_nulls()
        self.check_unique()
        self.check_ranges()
        self.check_allowed_values()
        self.check_business_rules()

        status = "FAIL" if self.errors else ("WARN" if self.warnings else "PASS")

        return {
            "file": self.filepath.name,
            "status": status,
            "rows": len(self.df),
            "columns": len(self.df.columns),
            "errors": self.errors,
            "warnings": self.warnings,
            "stats": self.summary_stats(),
        }


# ============================================================
# Referential Integrity Check
# ============================================================

def check_referential_integrity(data_dir: Path) -> list[str]:
    """
    Cross-file checks:
      - customer_id in transactions must exist in customer_risk_profiles
      - customer_id in fraud_cases must exist in customer_risk_profiles
    """
    issues: list[str] = []

    txn_path = data_dir / "transactions_2024.csv"
    cust_path = data_dir / "customer_risk_profiles.csv"
    case_path = data_dir / "fraud_cases_2024.csv"

    try:
        if txn_path.exists() and cust_path.exists():
            txn = pd.read_csv(txn_path, usecols=["customer_id"])
            cust = pd.read_csv(cust_path, usecols=["customer_id"])
            valid_ids = set(cust["customer_id"].dropna())
            orphans = txn[~txn["customer_id"].isin(valid_ids)]["customer_id"].unique()
            if len(orphans) > 0:
                issues.append(
                    f"REFERENTIAL INTEGRITY: {len(orphans)} customer_id(s) in "
                    f"transactions_2024.csv not found in customer_risk_profiles.csv: "
                    f"{list(orphans[:5])}"
                )
            else:
                issues.append(
                    "REFERENTIAL INTEGRITY PASSED: "
                    "All transaction customer_ids exist in customer profiles"
                )

        if case_path.exists() and cust_path.exists():
            cases = pd.read_csv(case_path, usecols=["customer_id"])
            cust = pd.read_csv(cust_path, usecols=["customer_id"])
            valid_ids = set(cust["customer_id"].dropna())
            orphans = cases[~cases["customer_id"].isin(valid_ids)]["customer_id"].unique()
            if len(orphans) > 0:
                issues.append(
                    f"REFERENTIAL INTEGRITY: {len(orphans)} customer_id(s) in "
                    f"fraud_cases_2024.csv not found in customer_risk_profiles.csv: "
                    f"{list(orphans[:5])}"
                )
            else:
                issues.append(
                    "REFERENTIAL INTEGRITY PASSED: "
                    "All case customer_ids exist in customer profiles"
                )

    except Exception as exc:
        issues.append(f"Referential integrity check failed: {exc}")

    return issues


# ============================================================
# Report Printer
# ============================================================

def print_report(results: list[dict], ri_checks: list[str]) -> int:
    """Print formatted validation report. Returns exit code (0=pass, 1=fail)."""
    total_errors = 0
    total_warnings = 0
    divider = "─" * 65

    print(f"\n{'═' * 65}")
    print("  VAULTSENTINEL CORP — DATA VALIDATION REPORT")
    print(f"  Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}")
    print(f"{'═' * 65}\n")

    for r in results:
        status_icon = {"PASS": "✅", "WARN": "⚠️ ", "FAIL": "❌", "LOAD_ERROR": "💥"}.get(
            r["status"], "?"
        )
        print(f"  {status_icon}  {r['file']}")
        print(f"  {divider}")
        print(f"  Rows: {r['rows']:,}  |  Columns: {r['columns']}")

        if r["errors"]:
            total_errors += len(r["errors"])
            for err in r["errors"]:
                print(f"  ❌  {err}")

        if r["warnings"]:
            total_warnings += len(r["warnings"])
            for w in r["warnings"]:
                print(f"  ⚠️   {w}")

        if not r["errors"] and not r["warnings"]:
            print("  All checks passed.")

        print()

    # Referential integrity section
    print(f"  REFERENTIAL INTEGRITY CHECKS")
    print(f"  {divider}")
    for check in ri_checks:
        icon = "✅" if "PASSED" in check else "❌"
        print(f"  {icon}  {check}")

    # Summary
    print(f"\n{'═' * 65}")
    exit_code = 1 if total_errors > 0 else 0
    overall = "❌ FAILED" if exit_code else "✅ PASSED"
    print(f"  OVERALL: {overall}")
    print(f"  Errors: {total_errors}  |  Warnings: {total_warnings}")
    print(f"{'═' * 65}\n")

    return exit_code


# ============================================================
# Entry Point
# ============================================================

def main() -> None:
    parser = argparse.ArgumentParser(
        description="VaultSentinel Corp — CSV Data Validation Tool"
    )
    parser.add_argument(
        "--data-dir",
        type=str,
        default="data",
        help="Path to the data directory (default: ./data)",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Print detailed pass-level check results",
    )
    parser.add_argument(
        "--output-json",
        type=str,
        default=None,
        help="Optional path to save results as JSON",
    )
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    if not data_dir.exists():
        print(f"ERROR: Data directory not found: {data_dir}", file=sys.stderr)
        sys.exit(1)

    results: list[dict] = []

    for filename, schema in SCHEMAS.items():
        filepath = data_dir / filename
        if not filepath.exists():
            results.append({
                "file": filename,
                "status": "MISSING",
                "errors": [f"File not found: {filepath}"],
                "warnings": [],
                "rows": 0,
                "columns": 0,
                "stats": {},
            })
            continue

        print(f"  Validating: {filename}...")
        validator = DataValidator(filepath, schema, verbose=args.verbose)
        results.append(validator.run())

    ri_checks = check_referential_integrity(data_dir)

    exit_code = print_report(results, ri_checks)

    if args.output_json:
        report = {
            "generated_at": datetime.utcnow().isoformat(),
            "files": results,
            "referential_integrity": ri_checks,
        }
        with open(args.output_json, "w") as f:
            json.dump(report, f, indent=2, default=str)
        print(f"  Report saved to: {args.output_json}")

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
