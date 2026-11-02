CREATE TABLE [oystr_silver].[dim_account] (
    [AccountSK]      VARCHAR (64)    NULL,
    [CustomerSK]     VARCHAR (64)    NULL,
    [AccountID]      VARCHAR (8000)  NULL,
    [CustomerID]     VARCHAR (8000)  NULL,
    [AccountNumber]  VARCHAR (8000)  NULL,
    [AccountType]    VARCHAR (8000)  NULL,
    [CurrentBalance] DECIMAL (18, 4) NULL,
    [CurrencyCode]   VARCHAR (8000)  NULL,
    [ValidFromTS]    DATETIME2 (6)   NULL
);


GO