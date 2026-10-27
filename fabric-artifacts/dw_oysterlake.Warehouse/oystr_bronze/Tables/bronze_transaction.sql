CREATE TABLE [oystr_bronze].[bronze_transaction] (
    [TransactionID]       VARCHAR (8000)  NULL,
    [AccountID]           VARCHAR (8000)  NULL,
    [Amount]              DECIMAL (18, 4) NULL,
    [transaction_at]      DATETIME2 (6)   NULL,
    [Counterparty]        VARCHAR (8000)  NULL,
    [TransactionStatusID] VARCHAR (8000)  NULL,
    [IngestedTS]          DATETIME2 (6)   NULL
);


GO