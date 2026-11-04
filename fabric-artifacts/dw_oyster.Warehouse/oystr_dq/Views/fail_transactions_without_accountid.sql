create view [oystr_dq].[fail_transactions_without_accountid] as 

-- This query looks for atomic transaction records missing their AccountID.
-- Returning rows here will halt and fail your Data Factory pipeline.
select
    TransactionID,
    Amount,
    TransactionTimestamp
from [dw_oyster].[oystr_silver].[s_fct_transaction]
where AccountID is null;

GO