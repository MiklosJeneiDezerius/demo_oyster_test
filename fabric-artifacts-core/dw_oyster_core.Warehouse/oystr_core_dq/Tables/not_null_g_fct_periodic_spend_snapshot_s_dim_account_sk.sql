CREATE TABLE [oystr_core_dq].[not_null_g_fct_periodic_spend_snapshot_s_dim_account_sk] (
    [g_fct_periodic_spend_snapshot_sk] VARCHAR (64)    NULL,
    [s_dim_date_sk]                    INT             NULL,
    [snapshot_dt]                      DATE            NULL,
    [s_dim_account_sk]                 VARCHAR (64)    NULL,
    [s_dim_customer_sk]                VARCHAR (64)    NULL,
    [account_id]                       INT             NULL,
    [rolling_30_day_spend_amt]         DECIMAL (38, 4) NULL,
    [calculated_spending_tier_nm]      VARCHAR (8)     NOT NULL,
    [snapshot_materialized_dttm]       DATETIME2 (6)   NULL
);


GO