SELECT 
    [TransactionStatusID] AS [transaction_status_id]
    ,[StatusName] AS [status_nm]
    ,CAST(GETDATE() AS DATETIME2(6)) AS [ingested_dttm]
FROM {{ source('landing_delta', 'transactionstatus') }}
