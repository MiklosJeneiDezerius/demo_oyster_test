CREATE TABLE [oystr_dq].[not_null_s_fct_transaction_TransactionSK] (
    [TransactionSK]        VARCHAR (64)    NULL,
    [CardSK]               VARCHAR (64)    NULL,
    [AccountSK]            VARCHAR (64)    NULL,
    [CustomerSK]           VARCHAR (64)    NULL,
    [TransactionDateSK]    INT             NULL,
    [TransactionID]        VARCHAR (8000)  NULL,
    [AccountID]            VARCHAR (8000)  NULL,
    [Amount]               DECIMAL (18, 4) NULL,
    [TransactionTimestamp] DATETIME2 (6)   NULL,
    [Counterparty]         VARCHAR (8000)  NULL,
    [TransactionStatus]    VARCHAR (8000)  NULL
);


GO