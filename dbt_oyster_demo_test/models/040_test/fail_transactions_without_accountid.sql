{{ config(
    severity = 'error'
) }}

-- This query looks for atomic transaction records missing their AccountID.
-- Returning rows here will halt and fail your Data Factory pipeline.
select
    TransactionID,
    Amount,
    TransactionTimestamp
from {{ ref('fact_transaction') }}
where AccountID is null
