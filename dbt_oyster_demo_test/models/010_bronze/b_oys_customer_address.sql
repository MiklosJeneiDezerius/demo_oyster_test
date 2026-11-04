SELECT 
    [AddressID] AS [address_id]
    ,[CustomerID] AS [customer_id]
    ,[AddressLine1] AS [address_line_1_txt]
    ,[City] AS [city_nm]
    ,[State_Region] AS [state_region_nm]
    ,[PostalCode] AS [postal_cd]
    ,[Country] AS [country_nm]
    ,CAST(GETDATE() AS DATETIME2(6)) AS [ingested_dttm]
FROM {{ source('landing_delta', 'customeraddress') }}
