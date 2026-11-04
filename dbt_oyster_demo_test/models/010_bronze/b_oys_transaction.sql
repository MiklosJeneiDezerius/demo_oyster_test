SELECT 
    [TransactionID] AS [transaction_id]
    ,[AccountID] AS [account_id]
    ,CAST([Amount] AS DECIMAL(18,4)) AS [transaction_amt]
    ,CAST([Timestamp] AS DATETIME2(6)) AS [transaction_dttm]
    ,[Counterparty] AS [counterparty_nm]
    ,[TransactionStatusID] AS [transaction_status_id]
    ,CAST(GETDATE() AS DATETIME2(6)) AS [ingested_dttm]
FROM {{ source('landing_delta', 'transaction') }}
