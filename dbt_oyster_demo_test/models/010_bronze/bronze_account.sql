SELECT 
    [AccountID]
    ,[CustomerID]
    ,[AccountNumber]
    ,[Type] as AccountType
    ,CAST([Balance] AS DECIMAL(18,2)) as current_balance
    ,[Currency] as CurrencyCode
    ,CAST(GETDATE() AS DATETIME2(6)) as IngestedTS
FROM {{ source('landing_delta', 'account') }}
