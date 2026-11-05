CREATE TABLE [oystr_silver].[s_fct_transaction] (
    [s_fct_transaction_sk]  VARCHAR (64)    NULL,
    [s_dim_card_sk]         VARCHAR (64)    NULL,
    [s_dim_account_sk]      VARCHAR (64)    NULL,
    [s_dim_customer_sk]     VARCHAR (64)    NULL,
    [s_dim_date_sk]         INT             NULL,
    [transaction_id]        VARCHAR (8000)  NULL,
    [account_id]            VARCHAR (8000)  NULL,
    [transaction_amt]       DECIMAL (18, 4) NULL,
    [transaction_dttm]      DATETIME2 (6)   NULL,
    [counterparty_nm]       VARCHAR (8000)  NULL,
    [transaction_status_cd] VARCHAR (8000)  NULL
);


GO