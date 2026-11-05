create view [oystr_dq].[warn_expired_debit_cards] as 

-- dbt tests fail/warn if they return ANY rows.
-- This query returns rows where a debit card status is 'Expired'.
select 
    card_id,
    card_number_txt,
    card_status_cd
from [dw_oyster].[oystr_silver].[s_dim_card]
where card_status_cd = 'Expired';

GO