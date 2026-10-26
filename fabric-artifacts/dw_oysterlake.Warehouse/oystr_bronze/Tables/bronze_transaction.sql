CREATE TABLE [oystr_bronze].[bronze_transaction] (
    [TransactionID]  VARCHAR (8000)  NULL,
    [CardID]         VARCHAR (8000)  NULL,
    [Amount]         DECIMAL (18, 2) NULL,
    [transaction_at] DATETIME2 (6)   NULL,
    [Counterparty]   VARCHAR (8000)  NULL,
    [Status]         VARCHAR (8000)  NULL,
    [IngestedTS]     DATETIME2 (6)   NULL
);


GO