# Oyster Core Fabric artifacts

This is the four-source counterpart of `fabric-artifacts`. The full artifact
tree is unchanged. Core items have their own names and unique Git logical IDs;
these IDs identify Git artifacts, not pre-existing deployed Fabric items.

## Flow

`pl_Master_Core` runs, in order:

1. `pl_Landing_Raw_Core`: generate Customer, Account, DebitCard and Transaction_Ledger CSV
   batches using the same six deterministic spend scenarios as the full demo.
   `num_customers` defaults to 83 and is forwarded to the generator.
2. `pl_Landing_Delta_Core`: read [config/load_config.json](config/load_config.json),
   filter on both `is_active` and `is_active_delta`, then sequentially load
   **only those four tables** into the core Lakehouse.
3. `pl_Create_DW_Core`: run `dbt build` in `dbt_oyster_demo_test_core`, using the
   full runner's isolated environment, runtime user-token profile and one
   30-second-delayed `dbt retry` on failure.
4. `pl_Refresh_Semantic_Model_Core`: refresh the core semantic model.

Raw files live under `Files/oyster/landing_raw/<batch timestamp>`. The Delta
loader reads all batches and chooses the latest row per business key using
source timestamp, filename and row number. It rebuilds each table, preserving
older transactions and making reruns idempotent. The incremental flag is kept
in the configuration for compatibility with the full configuration shape; it
does not enable a separate incremental/MERGE path in this simple loader.
Missing files, missing business keys and malformed CSV fail the notebook.

## Deployment prerequisites

These files are local Git definitions; no live workspace is changed by editing
them.

1. Sync/import the core Lakehouse, notebooks, pipelines, semantic model and
   report into the intended Fabric workspace with active capacity. Do not
   overwrite full-demo items. The notebooks attach `lh_oysterlake_core` by name
   in their first `%%configure` cell. The Lakehouse uses the `dbo` default schema.
2. Upload [config/load_config.json](config/load_config.json) to
   **`lh_oysterlake_core/Files/config/load_config.json`**. A Git-side config file
   is not automatically copied into Lakehouse Files by Fabric Git integration.
3. Use the existing `dw_oyster` Warehouse. dbt creates isolated
   `oystr_core_bronze`, `oystr_core_silver`, `oystr_core_gold` and `oystr_core_dq`
   schemas; there is no second Warehouse copy. Confirm the SQL server in
   [the core profile](../dbt_oyster_demo_test_core/profiles.yml) matches the
   Warehouse, and grant the runner identity Warehouse DDL/DML and Lakehouse
   source SELECT permissions.
4. Bind pipeline user connections to the intended execution identity. Verify
   Git-remapped notebook, Lakehouse and child-pipeline references. In the
   semantic refresh activity, select the actual workspace and `sm_oyster_core`
   model: its exported zero workspace ID and Git logical model ID are binding
   placeholders, not a live refresh target.
5. Build the dbt tables before refreshing/opening the core semantic model.
   Its shared Warehouse connection matches the default core profile. Rebind
   the model connection when deploying to a different server/database and
   configure its credentials in Fabric.

## Reporting

[sm_oyster_core.SemanticModel](sm_oyster_core.SemanticModel) preserves the
full model's report-facing column names over snake_case physical fields. It
contains current account/customer/date dimensions and the periodic spend fact,
with many-to-one, single-direction relationships.
DebitCard is denormalized into the Silver account dimension and passed through
to Gold and the semantic account table as `CardID` and `CardTier`. There is at
most one card per account (validated by dbt); cardless accounts remain with
null card attributes. There is no separate Silver/Gold card dimension.

[rpt_oyster_core.Report](050_Reports/rpt_oyster_core.Report) shows total accounts,
Platinum accounts, 30-day spend and the calculated spending-tier distribution.
Card-based alignment and upgrade visuals remain omitted from the simplified
report; actual card tier is available on the account dimension. Measures evaluate the last snapshot date in the
current filter context so overlapping daily rolling totals are not added
together.

The generator defaults to the full demo's 2026-09-01 anchor date. Historical
spend naturally drops out of the latest 30-day window; set its `anchor_date`
notebook parameter to a recent date when demonstrating current spend.

After replacing an older core deployment, remove obsolete separate Silver/Gold
card tables/items manually only after confirming they are no longer needed.
Keep the DebitCard Delta and Bronze tables.