create view [oystr].[warn_expired_debit_cards] as 

-- dbt tests fail/warn if they return ANY rows.
-- This query returns rows where a debit card status is 'Expired'.
select 
    CardID,
    CardNumber,
    CardStatus
from [dw_oysterlake].[oystr_silver].[dim_card]
where CardStatus = 'Expired';

GO