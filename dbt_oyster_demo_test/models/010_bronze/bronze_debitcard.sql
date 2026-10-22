SELECT 
    [CardID]
    ,[AccountID]
    ,[CardNumber]
    ,[Tier]
    ,[Status]
    ,[Expiry]
    ,CAST(GETDATE() AS DATETIME2(6)) as IngestedTS
FROM {{ source('landing_delta', 'debitcard') }}
