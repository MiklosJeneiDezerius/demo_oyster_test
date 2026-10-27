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
# This notebook generates mock data that adheres strictly to the physical ERD specification of the Oyster Bank project without data quality anomalies.

# CELL ********************

import os
import csv
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
num_customers = 50  # Adjusted parameter for generation threshold
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

def distribute_spend(target_amount, total_tx_count, seed_base):
    """Splits a target amount into N purely deterministic transactions using math cycles."""
    if target_amount == 0:
        return [0.0] * total_tx_count
    
    # Create deterministic weights using math progressions based on seed_base
    raw_weights = []
    for i in range(total_tx_count):
        weight = ((seed_base * (i + 1) * 17) % 100) + 5
        raw_weights.append(weight)
        
    total_weight = sum(raw_weights)
    amounts = []
    for w in raw_weights:
        amt = round((w / total_weight) * target_amount, 4)
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

# Execute full relational data generation matching the physical model structures deterministically
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
    
    # Deterministic index selectors without random module
    f_name = first_names[(idx) % len(first_names)]
    l_name = last_names[(idx * 3) % len(last_names)]
    
    tax_part1 = 100 + (idx % 900)
    tax_part2 = 10 + (idx % 90)
    tax_part3 = 1000 + (idx * 7 % 9000)
    tax_id = f"{tax_part1}{tax_part2}{tax_part3}"
    
    cust_type_id = 1 if (idx % 5 != 0) else 2
    
    age_offset = 18 + (idx % 48)
    month_offset = 1 + (idx % 12)
    day_offset = 1 + (idx % 28)
    dob_str = f"{2026 - age_offset}-{month_offset:02d}-{day_offset:02d}"
    
    customer_rows.append([cust_id, tax_id, cust_type_id, f_name, l_name, dob_str])
    
    country_idx = idx % len(countries)
    street_num = 1 + (idx * 13 % 250)
    zip_num = 1000 + (idx * 11 % 9000)
    customer_address_rows.append([
        address_global_counter,
        cust_id,
        f"Street No. {street_num}",
        cities[country_idx],
        "Region State",
        f"ZIP-{zip_num}",
        countries[country_idx]
    ])
    address_global_counter += 1

    acc_num_part1 = 100000 + (idx * 19 % 900000)
    acc_num = f"OYS{acc_num_part1}{idx:06d}"
    random_balance = round(100.00 + ((idx * 123.456) % 84900.00), 4)
    acc_type_id = 1 if (idx % 3 != 0) else 2
    currency_id = 1 + (idx % 3)
    
    account_rows.append([acc_id, cust_id, acc_num, acc_type_id, random_balance, currency_id])
    
    # Scenarios mapping entirely based on loop sequence parity formulas
    scen_mod = idx % 3
    if scen_mod == 0:
        initial_tier = ['Standard', 'Gold', 'Platinum'][idx % 3]
        target_spend_tier = initial_tier
    elif scen_mod == 1:
        initial_tier = ['Standard', 'Gold'][idx % 2]
        target_spend_tier = 'Platinum' if initial_tier == 'Gold' else ['Gold', 'Platinum'][(idx + 1) % 2]
    else:
        initial_tier = ['Gold', 'Platinum'][idx % 2]
        target_spend_tier = 'Standard' if initial_tier == 'Gold' else ['Standard', 'Gold'][(idx + 1) % 2]
        
    card_tier_id = tier_name_to_id[initial_tier]
    
    p1 = 4000 + (idx % 1000)
    p2 = 1000 + (idx * 3 % 9000)
    p3 = 1000 + (idx * 7 % 9000)
    card_num = f"{p1}{p2}{p3}{idx:04d}"
    
    status_pool = ['Active', 'Blocked', 'Expired']
    card_status = status_pool[idx % len(status_pool)]
    expiry_month = 1 + (idx % 12)
    expiry_date = f"2029-{expiry_month:02d}-28"
    
    debit_card_rows.append([card_id, acc_id, card_num, card_tier_id, card_status, expiry_date])
    
    tx_count = 10 + (idx % 16)
    min_spend, max_spend = tier_bounds[target_spend_tier]
    total_spend = round(min_spend + ((idx * 54.321) % (max_spend - min_spend)), 4)
    tx_amounts = distribute_spend(total_spend, tx_count, idx)
    
    for tx_idx in range(tx_count):
        tx_amount = tx_amounts[tx_idx]
        tx_day = 1 + ((idx + tx_idx) % 28)
        tx_hour = (idx + tx_idx * 3) % 24
        tx_min = (idx * 7 + tx_idx) % 60
        timestamp = f"2026-09-{tx_day:02d} {tx_hour:02d}:{tx_min:02d}:00"
        
        vendor = counterparties[(idx + tx_idx) % len(counterparties)]
        
        status_pool_tx = [1, 1, 1, 1, 2, 3]
        tx_status_id = status_pool_tx[(idx + tx_idx) % len(status_pool_tx)]
        
        current_tx_id = tx_global_counter
        current_acc_id = acc_id
        
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

print(f"Success: landed {len(files_config)} physical CSV files containing production-grade records.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
