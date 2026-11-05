CREATE TABLE [oystr_gold].[ga_dim_customer] (
    [ga_dim_customer_sk] VARCHAR (64)   NULL,
    [customer_id]        VARCHAR (8000) NULL,
    [first_nm]           VARCHAR (8000) NULL,
    [last_nm]            VARCHAR (8000) NULL,
    [full_nm]            VARCHAR (8000) NOT NULL,
    [tax_id]             VARCHAR (8000) NULL,
    [customer_type_nm]   VARCHAR (8000) NULL,
    [birth_dt]           DATE           NULL,
    [address_line_1_txt] VARCHAR (8000) NULL,
    [city_nm]            VARCHAR (8000) NULL,
    [state_region_nm]    VARCHAR (8000) NULL,
    [postal_cd]          VARCHAR (8000) NULL,
    [country_nm]         VARCHAR (8000) NULL,
    [valid_from_dttm]    DATETIME2 (6)  NULL,
    [valid_to_dttm]      DATETIME2 (6)  NULL
);


GO