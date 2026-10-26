CREATE TABLE [oystr_bronze].[bronze_account] (
    [AccountID]       VARCHAR (8000)  NULL,
    [CustomerID]      VARCHAR (8000)  NULL,
    [AccountNumber]   VARCHAR (8000)  NULL,
    [AccountType]     VARCHAR (8000)  NULL,
    [current_balance] DECIMAL (18, 2) NULL,
    [CurrencyCode]    VARCHAR (8000)  NULL,
    [IngestedTS]      DATETIME2 (6)   NULL
);


GO