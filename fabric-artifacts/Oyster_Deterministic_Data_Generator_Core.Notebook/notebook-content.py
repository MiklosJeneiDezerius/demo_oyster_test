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

# 1. Configuration & Parameters
num_customers = 100  
datetime_var = datetime.now().strftime("%Y%m%d%H%M%S")
output_dir = f'/lakehouse/default/Files/oyster/landing_raw/{datetime_var}'
os.makedirs(output_dir, exist_ok=True)

# 2. Data Reservoirs
customer_rows = []
account_rows = []
debit_card_rows = []
transaction_rows = []

tx_id_counter = 1
ANCHOR_DATE = datetime(2026, 10, 1, 0, 0, 0)

first_names = ["Jakub", "Tomasz", "Zoltán", "Anna", "Katarzyna", "Lenka", "Réka", "Luka", "Stefan", "David"]
last_names = ["Nagy", "Tóth", "Marković", "Radu", "Kovačić", "Kowalski", "Dvořák", "Kozłowski", "Popović", "Popescu"]

def add_deterministic_tx(account_id, amount, day_offset, hour_offset):
    global tx_id_counter
    tx_time = ANCHOR_DATE + timedelta(days=int(day_offset), hours=int(hour_offset))
    transaction_rows.append((tx_id_counter, account_id, float(amount), tx_time.strftime("%Y-%m-%d %H:%M:%S")))
    tx_id_counter += 1

# 3. Streamlined Generation Engine
for i in range(1, num_customers + 1):
    f_name = first_names[i % len(first_names)]
    l_name = last_names[i % len(last_names)]
    
    account_id = i * 10
    card_id = i * 100
    scenario = i % 6  # 6-Scenario Engine mapping all alignments and misalignments
    
    # Generate minimized Core Entities
    customer_rows.append((i, f_name, l_name))
    account_rows.append((account_id, i, float(i * 100.00)))
    
    if scenario == 1:
        # 1. Aligned Base: Standard Card (Low Spend < €2k)
        debit_card_rows.append((card_id, account_id, "Standard"))
        for d in range(15):
            add_deterministic_tx(account_id, 60.00, day_offset=d, hour_offset=10) # Total: €900
            
    elif scenario == 2:
        # 2. Aligned Mid: Gold Card (Aligned Spend €2k - €5k)
        debit_card_rows.append((card_id, account_id, "Gold"))
        for d in range(12):
            add_deterministic_tx(account_id, 300.00, day_offset=d, hour_offset=14) # Total: €3,600
            
    elif scenario == 3:
        # 3. Standard to Gold/Platinum Upgrade: Standard Card (Extreme Spend >= €5k)
        debit_card_rows.append((card_id, account_id, "Standard"))
        for d in range(15):
            add_deterministic_tx(account_id, 550.00, day_offset=d, hour_offset=8) # Total: €8,250
            
    elif scenario == 4:
        # 4. Gold to Platinum Upgrade: Gold Card (Extreme Spend >= €5k)
        debit_card_rows.append((card_id, account_id, "Gold"))
        for d in range(15):
            add_deterministic_tx(account_id, 600.00, day_offset=d, hour_offset=9) # Total: €9,000
            
    elif scenario == 5:
        # 5. Gold to Standard Downgrade Anomaly: Gold Card (Low Spend < €2k)
        debit_card_rows.append((card_id, account_id, "Gold"))
        for d in range(3):
            add_deterministic_tx(account_id, 250.00, day_offset=d*4, hour_offset=11) # Total: €750
            
    elif scenario == 0:
        # 6. Platinum to Gold Downgrade Anomaly: Platinum Card (Low Spend < €2k)
        debit_card_rows.append((card_id, account_id, "Platinum"))
        for d in range(3):
            add_deterministic_tx(account_id, 225.00, day_offset=d*5, hour_offset=15) # Total: €675

# 4. Native CSV Safe File Export
files_config = {
    f'Customer_{datetime_var}_core.csv': (['CustomerID', 'FirstName', 'LastName'], customer_rows),
    f'Account_{datetime_var}_core.csv': (['AccountID', 'CustomerID', 'Balance'], account_rows),
    f'DebitCard_{datetime_var}_core.csv': (['CardID', 'AccountID', 'CardTier'], debit_card_rows),
    f'Transaction_Ledger_{datetime_var}_core.csv': (['TransactionID', 'AccountID', 'Amount', 'Timestamp'], transaction_rows)
}

for filename, (header, rows) in files_config.items():
    file_path = os.path.join(output_dir, filename)
    with open(file_path, mode='w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)

print(f"Success: Landed minimized Core CSV datasets to {output_dir}")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
