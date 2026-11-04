CREATE TABLE [oystr_dq].[not_null_ga_dim_account_ga_dim_account_sk] (
    [ga_dim_account_sk]   VARCHAR (64)    NULL,
    [s_dim_customer_sk]   VARCHAR (64)    NULL,
    [account_id]          VARCHAR (8000)  NULL,
    [customer_id]         VARCHAR (8000)  NULL,
    [account_number_txt]  VARCHAR (8000)  NULL,
    [account_type_nm]     VARCHAR (8000)  NULL,
    [current_balance_amt] DECIMAL (18, 4) NULL,
    [currency_cd]         VARCHAR (8000)  NULL
);


GO