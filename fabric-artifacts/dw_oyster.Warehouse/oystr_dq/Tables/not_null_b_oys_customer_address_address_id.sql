CREATE TABLE [oystr_dq].[not_null_b_oys_customer_address_address_id] (
    [address_id]         VARCHAR (8000) NULL,
    [customer_id]        VARCHAR (8000) NULL,
    [address_line_1_txt] VARCHAR (8000) NULL,
    [city_nm]            VARCHAR (8000) NULL,
    [state_region_nm]    VARCHAR (8000) NULL,
    [postal_cd]          VARCHAR (8000) NULL,
    [country_nm]         VARCHAR (8000) NULL,
    [ingested_dttm]      DATETIME2 (6)  NULL
);


GO