Welcome to your new dbt project!

### Using the starter project

Try running the following commands:


### Resources:
## Oyster Core dbt project

This project uses only these four core Lakehouse source tables:

- `dbo.ld_oys_customer`
- `dbo.ld_oys_account`
- `dbo.ld_oys_debitcard`
- `dbo.ld_oys_transaction_ledger`

The tables are expected in the `lh_oysterlake2` Lakehouse SQL analytics endpoint. The project reuses the Fabric profile from `../dbt_oyster_demo_test/profiles.yml` and writes into isolated `oystr_core_bronze`, `oystr_core_silver`, and `oystr_core_gold` schemas in the configured Warehouse.

Run from this directory:

```powershell
dbt debug --profiles-dir ..\dbt_oyster_demo_test
dbt build --profiles-dir ..\dbt_oyster_demo_test
```

The Gold layer includes `ga_dim_account`, `ga_dim_card`, `ga_dim_customer`, and `g_dim_date`, plus the periodic spend snapshot. The core transaction table has no transaction-status column, so all ledger rows are included in spend calculations. The core debit-card table contains `CardTier` directly, so no separate tier table is needed. Silver `s_dim_date` generates the calendar internally, and the Gold models expose it for downstream reporting.
