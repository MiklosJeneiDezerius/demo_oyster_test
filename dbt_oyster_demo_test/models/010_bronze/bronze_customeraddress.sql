SELECT 
    [AddressID]
    ,[CustomerID]
    ,[AddressLine1]
    ,[City]
    ,[State/Region] AS [StateRegion]
    ,[PostalCode]
    ,[Country]
    ,CAST(GETDATE() AS DATETIME2(6)) as IngestedTS
FROM {{ source('landing_delta', 'customeraddress') }}
