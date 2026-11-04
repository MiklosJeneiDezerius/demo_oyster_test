SELECT 
    [CurrencyID] AS [currency_id]
    ,[CurrencyCode] AS [currency_cd]
    ,CAST(GETDATE() AS DATETIME2(6)) AS [ingested_dttm]
FROM {{ source('landing_delta', 'currency') }}
