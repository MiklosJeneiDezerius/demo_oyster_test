SELECT
    TRY_CONVERT(INT, [TransactionID]) AS [TransactionID],
    TRY_CONVERT(INT, [AccountID]) AS [AccountID],
    TRY_CONVERT(DECIMAL(18, 4), [Amount]) AS [Amount],
    TRY_CONVERT(DATETIME2(6), [Timestamp]) AS [TransactionTimestamp],
    CAST(GETDATE() AS DATETIME2(6)) AS [IngestedTS]
FROM {{ source('landing_delta_core', 'transaction') }}