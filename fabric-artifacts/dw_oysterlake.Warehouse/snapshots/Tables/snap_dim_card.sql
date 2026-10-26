CREATE TABLE [snapshots].[snap_dim_card] (
    [CardID]         VARCHAR (8000) NULL,
    [AccountID]      VARCHAR (8000) NULL,
    [CardNumber]     VARCHAR (8000) NULL,
    [Tier]           VARCHAR (8000) NULL,
    [Status]         VARCHAR (8000) NULL,
    [Expiry]         VARCHAR (8000) NULL,
    [dbt_scd_id]     VARCHAR (32)   NULL,
    [dbt_updated_at] DATETIME2 (6)  NULL,
    [dbt_valid_from] DATETIME2 (6)  NULL,
    [dbt_valid_to]   DATETIME2 (6)  NULL
);


GO