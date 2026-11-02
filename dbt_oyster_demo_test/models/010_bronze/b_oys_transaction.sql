SELECT 
    [TransactionID]
    ,[AccountID]
    ,CAST([Amount] AS DECIMAL(18,4)) as Amount
    ,CAST([Timestamp] AS DATETIME2(6)) as transaction_at
    ,[Counterparty]
    ,[TransactionStatusID]
    ,CAST(GETDATE() AS DATETIME2(6)) as IngestedTS
FROM {{ source('landing_delta', 'transaction') }}
