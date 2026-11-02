{{ config(
    severity = 'warn'
) }}

-- dbt tests fail/warn if they return ANY rows.
-- This query returns rows where a debit card status is 'Expired'.
select 
    CardID,
    CardNumber,
    CardStatus
from {{ ref('s_dim_card') }}
where CardStatus = 'Expired'
