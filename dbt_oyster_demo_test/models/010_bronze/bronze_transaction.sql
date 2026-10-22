SELECT 
    [TransactionID]
    ,[CardID]
    ,CAST([Amount] AS DECIMAL(18,2)) as Amount
    ,CAST([Timestamp] AS DATETIME2(6)) as transaction_at
    ,[Counterparty]
    ,[Status]
    ,CAST(GETDATE() AS DATETIME2(6)) as IngestedTS
FROM {{ source('landing_delta', 'transaction') }}
