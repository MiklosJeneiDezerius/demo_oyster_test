{% snapshot snap_dim_customer %}

{{ config(
    target_database=var('target_snapshot_db', 'dw_oysterlake'),
    target_schema=var('target_snapshot_schema', 'snapshots'),
    unique_key='CustomerID',
    strategy='timestamp',
    updated_at='IngestedTS',
    invalidate_hard_deletes=True
) }}

-- 1. Deduplicate base customer using the unique primary key log trace
WITH latest_bronze_customer AS (
    SELECT 
        CustomerID, TaxID, CustomerTypeID, FirstName, LastName, DoB, IngestedTS,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY IngestedTS DESC) as customer_rn
    FROM {{ ref('bronze_customer') }}
),

-- 2. Enforce strict address uniqueness by ordering by the unique physical AddressID
flattened_address AS (
    SELECT 
        CustomerID, AddressLine1, City, StateRegion, PostalCode, Country,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY AddressID DESC) as address_rn
    FROM {{ ref('bronze_customeraddress') }}
)

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
FROM latest_bronze_customer c
LEFT JOIN flattened_address a 
    ON c.CustomerID = a.CustomerID 
    AND a.address_rn = 1
WHERE c.customer_rn = 1

{% endsnapshot %}
