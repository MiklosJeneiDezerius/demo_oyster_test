SELECT 
    [CustomerTypeID] AS [customer_type_id]
    ,[TypeName] AS [type_nm]
    ,CAST(GETDATE() AS DATETIME2(6)) AS [ingested_dttm]
FROM {{ source('landing_delta', 'customertype') }}
