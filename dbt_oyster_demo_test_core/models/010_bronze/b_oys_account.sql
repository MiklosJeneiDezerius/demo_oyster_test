SELECT
    TRY_CONVERT(INT, [AccountID]) AS [AccountID],
    TRY_CONVERT(INT, [CustomerID]) AS [CustomerID],
    TRY_CONVERT(DECIMAL(18, 4), [Balance]) AS [Balance],
    CAST(GETDATE() AS DATETIME2(6)) AS [IngestedTS]
FROM {{ source('landing_delta_core', 'account') }}