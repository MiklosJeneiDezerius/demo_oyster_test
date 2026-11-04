create view [oystr].[fail_transactions_without_accountid] as 

-- This query looks for atomic transaction records missing their AccountID.
-- Returning rows here will halt and fail your Data Factory pipeline.
select
    transaction_id,
    transaction_amt,
    transaction_dttm
from [dw_oyster].[oystr_silver].[s_fct_transaction]
where account_id is null;

GO