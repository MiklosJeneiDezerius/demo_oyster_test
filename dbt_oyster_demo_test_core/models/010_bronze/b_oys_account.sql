{{ config(materialized='incremental', incremental_strategy='append', full_refresh=false, on_schema_change='append_new_columns') }}

SELECT
    CAST([AccountID] AS INT) AS [account_id],
    CAST([CustomerID] AS INT) AS [customer_id],
    CAST([Balance] AS DECIMAL(18, 4)) AS [balance_amt],
    CAST('{{ invocation_id }}' AS VARCHAR(36)) AS [batch_id],
    CAST(GETDATE() AS DATETIME2(6)) AS [ingested_dttm]
FROM {{ source('landing_delta_core', 'account') }}