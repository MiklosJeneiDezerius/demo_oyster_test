{{ config(
    severity = 'warn'
) }}

-- dbt tests fail/warn if they return ANY rows.
-- This query returns rows where a debit card status is 'Expired'.
select 
    card_id,
    card_number_txt,
    card_status_cd
from {{ ref('s_dim_card') }}
where card_status_cd = 'Expired'
