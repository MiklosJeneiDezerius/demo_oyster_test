SELECT 
    [AccountID] AS [account_id]
    ,[CustomerID] AS [customer_id]
    ,[AccountNumber] AS [account_number_txt]
    ,[AccountTypeID] AS [account_type_id]
    ,CAST([Balance] AS DECIMAL(18,4)) AS [balance_amt]
    ,[CurrencyID] AS [currency_id]
    ,CAST(GETDATE() AS DATETIME2(6)) AS [ingested_dttm]
FROM {{ source('landing_delta', 'account') }}
