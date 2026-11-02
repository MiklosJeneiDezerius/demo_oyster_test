SELECT 
    [CardID]
    ,[AccountID]
    ,[CardNumber]
    ,[CardTierID]
    ,[Status]
    ,[ExpiryDate]
    ,CAST(GETDATE() AS DATETIME2(6)) as IngestedTS
FROM {{ source('landing_delta', 'debitcard') }}
