CREATE TABLE [oystr_silver].[fact_transaction] (
    [TransactionSK]        VARCHAR (64)    NULL,
    [CardSK]               VARCHAR (64)    NULL,
    [AccountSK]            VARCHAR (64)    NULL,
    [CustomerSK]           VARCHAR (64)    NULL,
    [TransactionDateSK]    INT             NULL,
    [TransactionID]        VARCHAR (8000)  NULL,
    [CardID]               VARCHAR (8000)  NULL,
    [AccountID]            VARCHAR (8000)  NULL,
    [CustomerID]           VARCHAR (8000)  NULL,
    [Amount]               DECIMAL (18, 2) NULL,
    [TransactionTimestamp] DATETIME2 (6)   NULL,
    [Counterparty]         VARCHAR (8000)  NULL,
    [TransactionStatus]    VARCHAR (8000)  NULL,
    [IngestedTS]           DATETIME2 (6)   NULL
);


GO