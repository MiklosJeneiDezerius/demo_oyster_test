# Oyster Core dbt project

The full project's naming, Bronze/Silver/Gold layering, SHA-256 keys, calendar,
30-day spend thresholds, stored test failures and notebook user-token runner
are retained, with four Lakehouse sources:

| Source | Required columns |
| --- | --- |
| `dbo.ld_oys_customer` | `CustomerID`, `FirstName`, `LastName` |
| `dbo.ld_oys_account` | `AccountID`, `CustomerID`, `Balance` |
| `dbo.ld_oys_debitcard` | `CardID`, `AccountID`, `CardTier` |
| `dbo.ld_oys_transaction_ledger` | `TransactionID`, `AccountID`, `Amount`, `Timestamp` |

Physical dbt columns use snake_case and dimension-qualified keys such as
`s_dim_customer_sk` and `ga_dim_account_sk`. Bronze performs explicit casts;
invalid source values fail rather than silently becoming null.

## Simple execution

Run from this directory:

```powershell
dbt debug --profiles-dir .
dbt build --profiles-dir .
```

[profiles.yml](profiles.yml) uses the same Warehouse server, CLI authentication
and `DBT_DATABASE` / `DBT_TARGET` overrides as the full project. Its default
Warehouse is `dw_oyster`. The default source is `lh_oysterlake_core`;
`DBT_SOURCE_DATABASE` can override it for an existing core source Lakehouse.
The notebook runner finds this project's own profile; no sibling-directory
profile lookup is needed.

Outputs are isolated in `oystr_core_bronze`, `oystr_core_silver`,
`oystr_core_gold` and `oystr_core_dq`. Materialization and schemas are configured
once in [dbt_project.yml](dbt_project.yml), not repeated in individual models.

## Deliberate simplifications

- Dimensions contain current values with stable business-key hashes. No SCD2
  snapshots, lookup-table joins, packages or custom macros are required.
- Debit cards remain a separate Bronze source. Silver `s_dim_account` joins
  `card_id` and `card_tier_nm` by `account_id`, with at most one card per account.
  A unique test on the card's `account_id` rejects multiple cards. The LEFT JOIN
  retains cardless accounts with null card attributes, without inventing a tier.
  Gold `ga_dim_account` and its semantic table expose the same attributes.
  No separate Silver/Gold card dimension, history or card mismatch/upgrade
  metrics are needed for this simplified model.
- All ledger rows contribute to spend; no transaction-status table exists.
- Gold exposes account, customer and date dimensions and a daily spend snapshot.
  Each account has one snapshot per day from 2025-01-01 through today, including
  zero-spend days. The calculation includes 29 warm-up days before the first
  output date. Spend of at least 2000 is Gold; at least 5000 is Platinum.
- Customer names/balances are current attributes, not historical point-in-time
  values. Rerunning `build` recomputes the tables; changes require no migration
  macros.

Generic tests validate keys, foreign keys and required values. SQL tests check
that Silver account and ledger counts match Bronze and that each Gold rolling amount
and tier match the exact 30-calendar-day ledger range. Failures are stored in
the core DQ schema; a diagnostic view exposes missing account IDs.

Local, cloud-independent contract checks:

```powershell
python -m unittest discover -s tests -p "test_core_contract.py"
```

For Fabric setup, see [the core artifacts guide](../fabric-artifacts-core/Readme.md).
Commit and push the dbt changes before running the GitHub-cloning notebook.
`dbt build` checks only models currently in this project; it does not delete old
card tables or PascalCase exports left behind by an earlier core deployment.
