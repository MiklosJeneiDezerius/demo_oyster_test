SELECT 
    [CardID] AS [card_id]
    ,[AccountID] AS [account_id]
    ,[CardNumber] AS [card_number_txt]
    ,[CardTierID] AS [card_tier_id]
    ,[Status] AS [card_status_cd]
    ,[ExpiryDate] AS [expiry_dt]
    ,CAST(GETDATE() AS DATETIME2(6)) AS [ingested_dttm]
FROM {{ source('landing_delta', 'debitcard') }}
