SELECT 
    [CustomerID] AS [customer_id]
    ,[TaxID] AS [tax_id]
    ,[CustomerTypeID] AS [customer_type_id]
    ,[FirstName] AS [first_nm]
    ,[LastName] AS [last_nm]
    ,[DoB] AS [birth_dt]
    ,CAST(GETDATE() AS DATETIME2(6)) AS [ingested_dttm]
FROM {{ source('landing_delta', 'customer') }}
