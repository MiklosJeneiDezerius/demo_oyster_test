CREATE TABLE [oystr_bronze].[bronze_debitcard] (
    [CardID]     VARCHAR (8000) NULL,
    [AccountID]  VARCHAR (8000) NULL,
    [CardNumber] VARCHAR (8000) NULL,
    [CardTierID] VARCHAR (8000) NULL,
    [Status]     VARCHAR (8000) NULL,
    [ExpiryDate] VARCHAR (8000) NULL,
    [IngestedTS] DATETIME2 (6)  NULL
);


GO