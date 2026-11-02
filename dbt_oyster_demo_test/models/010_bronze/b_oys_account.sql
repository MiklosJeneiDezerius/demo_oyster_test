SELECT 
    [AccountID]
    ,[CustomerID]
    ,[AccountNumber]
    ,[AccountTypeID]
    ,CAST([Balance] AS DECIMAL(18,4)) as Balance
    ,[CurrencyID]
    ,CAST(GETDATE() AS DATETIME2(6)) as IngestedTS
FROM {{ source('landing_delta', 'account') }}
