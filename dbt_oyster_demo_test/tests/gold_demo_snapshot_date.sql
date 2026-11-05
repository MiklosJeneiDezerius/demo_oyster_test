SELECT *
FROM {{ ref('g_fct_periodic_spend_snapshot') }}
WHERE [snapshot_dt] IS NULL
   OR [snapshot_dt] <> CAST('{{ var("demo_snapshot_date") }}' AS DATE)
