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
# This notebook generates mock data that adheres strictly to the physical ERD specification of the Oyster Bank project, incorporating intentional data quality issues to test downstream medallion pipelines.

# CELL ********************

import os
import csv
import random
from datetime import datetime, date

# Enforce direct pathway mapping to the lakehouse explorer "Files" layer
output_dir = '/lakehouse/default/Files/landing/oyster'
os.makedirs(output_dir, exist_ok=True)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# PARAMETERS CELL ********************

# ==========================================
# PARAMETERS
# ==========================================
num_customers = 2  # Adjusted parameter for generation threshold
# ==========================================

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Dynamic configuration arrays and spending utility methods
counterparties = ['Lidl', 'Kaufland', 'Biedronka', 'Konzum', 'MOL Group', 'Albert', 'Mega Image', 'ATB-Market','Linella']
first_names = ['Jan', 'Jakub', 'Tomasz', 'Zoltán', 'Anna', 'Katarzyna', 'Lenka', 'Réka', 'Luka', 'Stefan', 'David', 'Ivan', 'Sofia', 'Sara', 'Elena', 'Maria','Oleksandr']
last_names = ['Nowak', 'Kowalski', 'Svoboda', 'Nagy', 'Dvořák', 'Varga', 'Tóth', 'Kozłowski', 'Kovačević', 'Marković', 'Popović', 'Popa', 'Radu', 'Popescu', 'Horvat', 'Kovačić','Vasile']
cities = ['Budapest', 'Prague', 'Warsaw', 'Bratislava', 'Zagreb', 'Bucharest', 'Belgrade']
countries = ['Hungary', 'Czech Republic', 'Poland', 'Slovakia', 'Croatia', 'Romania', 'Serbia']

def distribute_spend(target_amount, total_tx_count):
    """Splits a target amount into N random transactions."""
    if target_amount == 0:
        return [0.0] * total_tx_count
    splits = sorted([random.random() for _ in range(total_tx_count - 1)])
    splits = [0.0] + splits + [1.0]
    amounts = []
    for i in range(total_tx_count):
        amt = round((splits[i+1] - splits[i]) * target_amount, 4) # Matches DECIMAL(18,4)
        amounts.append(amt)
    diff = round(target_amount - sum(amounts), 4)
    if diff != 0:
        amounts[-1] = round(amounts[-1] + diff, 4)
    return amounts

# Strict spend boundaries to support business rules (Upgrades/Downgrades/Aligned)
tier_bounds = {
    'Standard': (150.00, 1800.00),
    'Gold': (2200.00, 4500.00),
    'Platinum': (5500.00, 8500.00)
}

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Execute full relational data generation matching the physical model structures
customer_rows = []
customer_type_rows = [[1, 'Regular'], [2, 'Premium']]
customer_address_rows = []
account_rows = []
account_type_rows = [[1, 'Checking'], [2, 'Savings']]
currency_rows = [[1, 'EUR'], [2, 'USD'], [3, 'HUF']]
debit_card_rows = []
card_tier_rows = [[1, 'Standard'], [2, 'Gold'], [3, 'Platinum']]
transaction_rows = []
transaction_status_rows = [[1, 'Approved'], [2, 'Pending'], [3, 'Denied']]

tx_global_counter = 1
address_global_counter = 1
tier_name_to_id = {'Standard': 1, 'Gold': 2, 'Platinum': 3}

for idx in range(1, num_customers + 1):
    cust_id = idx
    acc_id = idx * 10
    card_id = idx * 100
    
    inject_error = random.random() < 0.15
    
    f_name = random.choice(first_names)
    l_name = random.choice(last_names)
    tax_id = f"{random.randint(100,999)}{random.randint(10,99)}{random.randint(1000,9999)}"
    cust_type_id = random.choice([1, 2])
    dob_str = f"{(2026 - random.randint(18, 65))}-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}"
    
    if inject_error:
        error_type = random.choice(['null_pk', 'missing_names', 'bad_dob'])
        if error_type == 'null_pk':
            cust_id = ''
        elif error_type == 'missing_names':
            f_name = ''
            l_name = ''
        elif error_type == 'bad_dob':
            dob_str = '1900-99-99'
            
    customer_rows.append([cust_id, tax_id, cust_type_id, f_name, l_name, dob_str])
    
    if cust_id != '':
        country_idx = random.randint(0, len(countries)-1)
        customer_address_rows.append([
            address_global_counter,
            cust_id,
            f"Street No. {random.randint(1, 250)}",
            cities[country_idx],
            "Region State",
            f"ZIP-{random.randint(1000, 9999)}",
            countries[country_idx]
        ])
        address_global_counter += 1

    acc_num = f"OYS{random.randint(100000, 999999)}{idx:06d}"
    random_balance = round(random.uniform(100.00, 85000.00), 4)
    acc_type_id = random.choice([1, 2])
    currency_id = random.choice([1, 2, 3])
    
    if inject_error and random.choice([True, False]):
        acc_num = ''
        
    account_rows.append([acc_id, cust_id, acc_num, acc_type_id, random_balance, currency_id])
    
    alignment_scenario = random.choice(['aligned', 'upgrade', 'downgrade'])
    if alignment_scenario == 'aligned':
        initial_tier = random.choice(['Standard', 'Gold', 'Platinum'])
        target_spend_tier = initial_tier
    elif alignment_scenario == 'upgrade':
        initial_tier = random.choice(['Standard', 'Gold'])
        target_spend_tier = 'Platinum' if initial_tier == 'Gold' else random.choice(['Gold', 'Platinum'])
    else:
        initial_tier = random.choice(['Gold', 'Platinum'])
        target_spend_tier = 'Standard' if initial_tier == 'Gold' else random.choice(['Standard', 'Gold'])
        
    card_tier_id = tier_name_to_id[initial_tier]
    card_num = f"{random.randint(4000, 4999)}{random.randint(1000, 9999)}{random.randint(1000, 9999)}{idx:04d}"
    card_status = random.choice(['Active', 'Blocked', 'Expired'])
    expiry_date = f"2029-{random.randint(1,12):02d}-28"
    
    debit_card_rows.append([card_id, acc_id, card_num, card_tier_id, card_status, expiry_date])
    
    tx_count = random.randint(10, 25)
    min_spend, max_spend = tier_bounds[target_spend_tier]
    total_spend = round(random.uniform(min_spend, max_spend), 4)
    tx_amounts = distribute_spend(total_spend, tx_count)
    
    for tx_idx in range(tx_count):
        tx_amount = tx_amounts[tx_idx]
        day = random.randint(1, 28)
        timestamp = f"2026-09-{day:02d} {random.randint(0,23):02d}:{random.randint(0,59):02d}:00"
        vendor = random.choice(counterparties)
        tx_status_id = random.choice([1, 1, 1, 1, 2, 3])
        
        current_tx_id = tx_global_counter
        current_acc_id = acc_id
        
        if inject_error and random.random() < 0.05:
            error_variant = random.choice(['null_fk', 'negative_spend'])
            if error_variant == 'null_fk':
                current_acc_id = ''
            elif error_variant == 'negative_spend':
                tx_amount = -500.0000
                
        transaction_rows.append([current_tx_id, current_acc_id, tx_amount, timestamp, vendor, tx_status_id])
        tx_global_counter += 1

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Export all structural tables securely out to CSV landing structures
files_config = {
    'Customer.csv': (['CustomerID', 'TaxID', 'CustomerTypeID', 'FirstName', 'LastName', 'DoB'], customer_rows),
    'CustomerType.csv': (['CustomerTypeID', 'TypeName'], customer_type_rows),
    'CustomerAddress.csv': (['AddressID', 'CustomerID', 'AddressLine1', 'City', 'State/Region', 'PostalCode', 'Country'], customer_address_rows),
    'Account.csv': (['AccountID', 'CustomerID', 'AccountNumber', 'AccountTypeID', 'Balance', 'CurrencyID'], account_rows),
    'AccountType.csv': (['AccountTypeID', 'TypeName'], account_type_rows),
    'Currency.csv': (['CurrencyID', 'CurrencyCode'], currency_rows),
    'DebitCard.csv': (['CardID', 'AccountID', 'CardNumber', 'CardTierID', 'Status', 'ExpiryDate'], debit_card_rows),
    'CardTier.csv': (['CardTierID', 'TierName'], card_tier_rows),
    'Transaction_Ledger.csv': (['TransactionID', 'AccountID', 'Amount', 'Timestamp', 'Counterparty', 'TransactionStatusID'], transaction_rows),
    'TransactionStatus.csv': (['TransactionStatusID', 'StatusName'], transaction_status_rows)
}

for filename, (header, rows) in files_config.items():
    file_path = os.path.join(output_dir, filename)
    with open(file_path, mode='w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)

print(f"Success: landed {len(files_config)} physical CSV files containing intentional anomaly states.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
