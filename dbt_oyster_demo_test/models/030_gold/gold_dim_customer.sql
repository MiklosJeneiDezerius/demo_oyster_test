{{ config(materialized='table', schema='gold') }}
SELECT 
    CustomerSK, CustomerID, FirstName, LastName, FullName, TaxID, CustomerType, BirthDate
FROM {{ ref('dim_customer') }}
