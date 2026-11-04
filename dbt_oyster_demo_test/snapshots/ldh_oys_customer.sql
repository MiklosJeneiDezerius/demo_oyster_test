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
        CustomerID,
        TaxID,
        CustomerTypeID,
        FirstName,
        LastName,
        DoB,
        IngestedTS,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID
            ORDER BY IngestedTS DESC
        ) AS customer_rn
    FROM {{ ref('b_oys_customer') }}
) c
LEFT JOIN (
    SELECT
        CustomerID,
        AddressLine1,
        City,
        StateRegion,
        PostalCode,
        Country,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID
            ORDER BY AddressID DESC
        ) AS address_rn
    FROM {{ ref('b_oys_customer_address') }}
) a
    ON c.CustomerID = a.CustomerID
    AND a.address_rn = 1
WHERE c.customer_rn = 1

{% endsnapshot %}
