{% snapshot snap_dim_customer %}
{{ config(
    target_database='dw_oysterlake',
    target_schema='snapshots',
    unique_key='CustomerID',
    strategy='check',
    check_cols=['TaxID', 'CustomerTypeID', 'AddressLine1', 'City', 'StateRegion', 'PostalCode', 'Country'],
    invalidate_hard_deletes=True
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
    COALESCE(a.Country, 'NOT PROVIDED') AS Country
FROM {{ ref('bronze_customer') }} c
LEFT JOIN (
    -- Subquery replaces the root WITH clause to keep Fabric parser happy
    SELECT 
        CustomerID,
        AddressLine1,
        City,
        StateRegion,
        PostalCode,
        Country,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY AddressID DESC) as rn
    FROM {{ ref('bronze_customeraddress') }}
) a ON c.CustomerID = a.CustomerID AND a.rn = 1

{% endsnapshot %}
