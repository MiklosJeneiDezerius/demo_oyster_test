# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "6a5d7d27-1cff-4cc1-8128-60ab61a60ad2",
# META       "default_lakehouse_name": "lh_oysterlake2",
# META       "default_lakehouse_workspace_id": "2a3b7ca3-b1d8-4251-bada-cb2a3100cef9",
# META       "known_lakehouses": [
# META         {
# META           "id": "6a5d7d27-1cff-4cc1-8128-60ab61a60ad2"
# META         }
# META       ]
# META     }
# META   }
# META }

# MARKDOWN ********************

# # Oyster Bank Relational Data Generation Engine
# This notebook generates mock data that adheres strictly to the physical ERD specification of the Oyster Bank project while incorporating specific misalignment criteria where Gold and Standard cards qualify as update candidates (`isupdatecandidate`).

# CELL ********************

import os
import csv
from datetime import datetime, timedelta
from pyspark.sql import SparkSession
from pyspark.sql.functions import current_date, current_timestamp, date_format

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# 1. Pipeline Parameter - Set your desired volume here
num_customers = 100  
datetime_var = spark.range(1).select(date_format(current_timestamp(), "yyyyMMddHHmmss")).first()[0]
year_month = spark.range(1).select(date_format(current_timestamp(), "yyyyMMdd_HHmmss")).first()[0]
# 2. ROOT OUTPUT DIRECTORY PRESERVED UNCHANGED
output_dir = f'/lakehouse/default/Files/oyster/landing_raw/{year_month}'

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************





# Ensure the output directory structure physically exists inside OneLake
os.makedirs(output_dir, exist_ok=True)

print(f"📌 SCALING CONFIGURATION CHECK: Enforcing multi-scenario truth scaling for {num_customers} customers...")

# =====================================================================
# STATIC REFERENCE FRAMEWORKS (METADATA MAPS)
# =====================================================================
currency_rows = [(1, "EUR"), (2, "USD"), (3, "HUF")]
customer_type_rows = [(1, "Regular"), (2, "Premium")]
account_type_rows = [(1, "Checking"), (2, "Savings")]
card_tier_rows = [(1, "Standard"), (2, "Gold"), (3, "Platinum")]
transaction_status_rows = [(1, "Approved"), (2, "Pending"), (3, "Denied")]

# =====================================================================
# DETERMINISTIC LOOP GENERATION ENGINE
# =====================================================================
customer_rows = []
customer_address_rows = []
account_rows = []
debit_card_rows = []
transaction_rows = []

tx_id_counter = 1
ANCHOR_DATE = datetime(2026, 9, 1, 0, 0, 0)

# Pool arrays to provide realistic variety deterministically
first_names = ["Jakub", "Tomasz", "Zoltán", "Anna", "Katarzyna", "Lenka", "Réka", "Luka", "Stefan", "David"]
last_names = ["Nagy", "Tóth", "Marković", "Radu", "Kovačić", "Kowalski", "Dvořák", "Kozłowski", "Popović", "Popescu"]
cities = ["Prague", "Warsaw", "Bratislava", "Zagreb", "Bucharest", "Belgrade", "Budapest"]
countries = ["Czech Republic", "Poland", "Slovakia", "Croatia", "Romania", "Serbia", "Hungary"]

def add_deterministic_tx(account_id, amount, day_offset, hour_offset, status_id=1, vendor="Lidl"):
    global tx_id_counter
    tx_time = ANCHOR_DATE + timedelta(days=int(day_offset), hours=int(hour_offset))
    transaction_rows.append((tx_id_counter, account_id, float(amount), tx_time.strftime("%Y-%m-%d %H:%M:%S"), vendor, status_id))
    tx_id_counter += 1

# Generate related items sequentially based on user input size
for i in range(1, num_customers + 1):
    f_name = first_names[i % len(first_names)]
    l_name = last_names[i % len(last_names)]
    city = cities[i % len(cities)]
    country = countries[i % len(countries)]
    
    # Base Entities
    customer_rows.append((i, f"10{100000 + i}", 2 if i % 5 == 0 else 1, f_name, l_name, f"{1970 + (i % 38)}-05-01"))
    customer_address_rows.append((i, i, f"Street No. {i * 13}", city, "Region State", f"ZIP-{1000 + i}", country))
    
    # 1:1 Linked Structural Account Routing
    account_id = i * 10
    account_rows.append((account_id, i, f"OYS100{190000 + i}", 2 if i % 2 == 0 else 1, float(i * 111.11), (i % 3) + 1))
    
    # 🛑 THE DETERMINISTIC SYSTEM ROUTING SCENARIOS (Modulo 6 Engine)
    scenario = i % 6
    
    if scenario == 1:
        # Scenario 1: Aligned Base Users (Standard Card, Low Spend)
        # Target: Spend < $2,000.00 (Standard) -> Aligned
        debit_card_rows.append((i * 100, account_id, f"40011003100{7000 + i}", 1, "Active", "2029-02-28"))
        for d in range(15):
            add_deterministic_tx(account_id, 60.00, day_offset=d, hour_offset=10, vendor="Kaufland") # Total ~$900
            
    elif scenario == 2:
        # Scenario 2: Aligned Base Users (Gold Card, Aligned Mid Spend)
        # Target: Spend between $2,000.00 and $5,000.00 (Gold) -> Aligned
        debit_card_rows.append((i * 100, account_id, f"40021006100{7000 + i}", 2, "Active", "2029-03-28"))
        for d in range(12):
            add_deterministic_tx(account_id, 300.00, day_offset=d, hour_offset=14, vendor="Biedronka") # Total ~$3,600
            
    elif scenario == 3:
        # Scenario 3: Standard Card Upgrade Candidates (Standard Card, Extreme Spend)
        # Target: Spend >= $5,000.00 (Calculated Platinum, on Standard Card) -> IsUpgradeCandidate = 1
        debit_card_rows.append((i * 100, account_id, f"40031009100{7000 + i}", 1, "Active", "2029-04-28"))
        for d in range(15):
            add_deterministic_tx(account_id, 550.00, day_offset=d, hour_offset=8, vendor="MOL Group") # Total ~$8,250
            
    elif scenario == 4:
        # Scenario 4: Gold Card Upgrade Candidates (Gold Card, Extreme Spend) -> NEW SCENARIO
        # Target: Spend >= $5,000.00 (Calculated Platinum, on Gold Card) -> IsUpgradeCandidate = 1
        debit_card_rows.append((i * 100, account_id, f"40041006100{7000 + i}", 2, "Active", "2029-05-28"))
        for d in range(15):
            add_deterministic_tx(account_id, 600.00, day_offset=d, hour_offset=9, vendor="Albert") # Total ~$9,000
            
    elif scenario == 5:
        # Scenario 5: Gold Card Downgrade Anomalies (Gold Card, Low Spend) -> NEW SCENARIO
        # Target: Spend < $2,000.00 (Calculated Standard, on Gold Card) -> IsLowSpendPremiumAnomaly = 1
        debit_card_rows.append((i * 100, account_id, f"40051006100{7000 + i}", 2, "Active", "2029-06-28"))
        for d in range(3):
            add_deterministic_tx(account_id, 250.00, day_offset=d*4, hour_offset=11, vendor="Mega Image") # Total ~$750
            
    elif scenario == 0:
        # Scenario 6: Platinum Card Downgrade Anomalies (Platinum Card, Tiny Spend)
        # Target: Spend < $2,000.00 (Calculated Standard, on Platinum Card) -> IsLowSpendPremiumAnomaly = 1
        debit_card_rows.append((i * 100, account_id, f"40061012100{7000 + i}", 3, "Active", "2029-07-28"))
        for d in range(3):
            add_deterministic_tx(account_id, 225.00, day_offset=d*5, hour_offset=15, vendor="Konzum") # Total ~$675

# =====================================================================
# PHYSICAL NATIVE FILE SYSTEM WRITE OPERATION
# =====================================================================
print("Exporting all structural tables securely out to CSV landing structures...")

# 1. Properly extract the string value from the PySpark Row object

# 2. Use f-strings (f'...') for the dictionary keys to inject the date
files_config = {
    f'Customer_{datetime_var}.csv': (['CustomerID', 'TaxID', 'CustomerTypeID', 'FirstName', 'LastName', 'DoB'], customer_rows),
    f'CustomerType_{datetime_var}.csv': (['CustomerTypeID', 'TypeName'], customer_type_rows),
    f'CustomerAddress_{datetime_var}.csv': (['AddressID', 'CustomerID', 'AddressLine1', 'City', 'State/Region', 'PostalCode', 'Country'], customer_address_rows),
    f'Account_{datetime_var}.csv': (['AccountID', 'CustomerID', 'AccountNumber', 'AccountTypeID', 'Balance', 'CurrencyID'], account_rows),
    f'AccountType_{datetime_var}.csv': (['AccountTypeID', 'TypeName'], account_type_rows),
    f'Currency_{datetime_var}.csv': (['CurrencyID', 'CurrencyCode'], currency_rows),
    f'DebitCard_{datetime_var}.csv': (['CardID', 'AccountID', 'CardNumber', 'CardTierID', 'Status', 'ExpiryDate'], debit_card_rows),
    f'CardTier_{datetime_var}.csv': (['CardTierID', 'TierName'], card_tier_rows),
    f'Transaction_Ledger_{datetime_var}.csv': (['TransactionID', 'AccountID', 'Amount', 'Timestamp', 'Counterparty', 'TransactionStatusID'], transaction_rows),
    f'TransactionStatus_{datetime_var}.csv': (['TransactionStatusID', 'StatusName'], transaction_status_rows)
}

for filename, (header, rows) in files_config.items():
    file_path = os.path.join(output_dir, filename)
    with open(file_path, mode='w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)

print(f"Success: landed {len(files_config)} physical CSV files containing production-grade records.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
