{% snapshot ldh_oys_customer %}

{{ config(
    target_database=var('target_snapshot_db', 'dw_oysterlake'),
    target_schema=var('target_snapshot_schema', 'snapshots'),
    unique_key='CustomerID',
    strategy='check',
    check_cols=[
        'TaxID',
        'CustomerTypeID',
        'FirstName',
        'LastName',
        'DoB',
        'AddressLine1',
        'City',
        'StateRegion',
        'PostalCode',
        'Country'
    ],
    hard_deletes='invalidate',
    snapshot_meta_column_names={
        'dbt_valid_from': 'm_valid_from_dttm',
        'dbt_valid_to': 'm_valid_to_dttm',
        'dbt_scd_id': 'm_scd_id',
        'dbt_updated_at': 'm_update_at_dttm'
    },
    dbt_valid_to_current="CAST('9999-12-31 00:00:00' AS DATETIME2(6))"
) }}

SELECT
    c.CustomerID,
    c.TaxID,
    c.CustomerTypeID,
    c.FirstName,
    c.LastName,
    c.DoB,
    COALESCE(a.AddressLine1, 'NOT PROVIDED') AS AddressLine1,
    COALESCE(a.City, 'NOT PROVIDED') AS City,
    COALESCE(a.StateRegion, 'NOT PROVIDED') AS StateRegion,
    COALESCE(a.PostalCode, 'NOT PROVIDED') AS PostalCode,
    COALESCE(a.Country, 'NOT PROVIDED') AS Country,
    c.IngestedTS
FROM (
    SELECT
        customer_id AS CustomerID,
        tax_id AS TaxID,
        customer_type_id AS CustomerTypeID,
        first_nm AS FirstName,
        last_nm AS LastName,
        birth_dt AS DoB,
        ingested_dttm AS IngestedTS,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY ingested_dttm DESC
        ) AS customer_rn
    FROM {{ ref('b_oys_customer') }}
) c
LEFT JOIN (
    SELECT
        customer_id AS CustomerID,
        address_line_1_txt AS AddressLine1,
        city_nm AS City,
        state_region_nm AS StateRegion,
        postal_cd AS PostalCode,
        country_nm AS Country,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY address_id DESC
        ) AS address_rn
    FROM {{ ref('b_oys_customer_address') }}
) a
    ON c.CustomerID = a.CustomerID
    AND a.address_rn = 1
WHERE c.customer_rn = 1

{% endsnapshot %}
