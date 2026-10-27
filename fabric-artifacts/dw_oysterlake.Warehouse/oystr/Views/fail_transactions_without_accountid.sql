create view [oystr].[fail_transactions_without_accountid] as 

-- This query looks for atomic transaction records missing their AccountID.
-- Returning rows here will halt and fail your Data Factory pipeline.
select
    TransactionID,
    Amount,
    TransactionTimestamp
from [dw_oysterlake].[oystr_silver].[fact_transaction]
where AccountID is null;

GO