SELECT
    TRY_CONVERT(INT, [CardID]) AS [CardID],
    TRY_CONVERT(INT, [AccountID]) AS [AccountID],
    TRIM([CardTier]) AS [CardTier],
    CAST(GETDATE() AS DATETIME2(6)) AS [IngestedTS]
FROM {{ source('landing_delta_core', 'debitcard') }}