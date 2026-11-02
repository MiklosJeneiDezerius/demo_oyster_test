CREATE TABLE [oystr_bronze].[bronze_account] (
    [AccountID]     VARCHAR (8000)  NULL,
    [CustomerID]    VARCHAR (8000)  NULL,
    [AccountNumber] VARCHAR (8000)  NULL,
    [AccountTypeID] VARCHAR (8000)  NULL,
    [Balance]       DECIMAL (18, 4) NULL,
    [CurrencyID]    VARCHAR (8000)  NULL,
    [IngestedTS]    DATETIME2 (6)   NULL
);


GO