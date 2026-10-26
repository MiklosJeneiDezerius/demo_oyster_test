SELECT 
    [CustomerID]
    ,[TaxID]
    ,[CustomerTypeID]
    ,[FirstName]
    ,[LastName]
    ,[DoB]
    ,CAST(GETDATE() AS DATETIME2(6)) as IngestedTS
FROM {{ source('landing_delta', 'customer') }}
