{{ config(
    severity = 'error'
) }}

-- This query looks for atomic transaction records missing their AccountID.
-- Returning rows here will halt and fail your Data Factory pipeline.
select
    transaction_id,
    transaction_amt,
    transaction_dttm
from {{ ref('s_fct_transaction') }}
where account_id is null
