# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "a93d4a2d-90c2-4a81-9df5-31820e8e4989",
# META       "default_lakehouse_name": "lh_oysterlake",
# META       "default_lakehouse_workspace_id": "2a3b7ca3-b1d8-4251-bada-cb2a3100cef9",
# META       "known_lakehouses": [
# META         {
# META           "id": "a93d4a2d-90c2-4a81-9df5-31820e8e4989"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

import os
import csv
import random
from datetime import datetime, date

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Enforce direct pathway mapping to the lakehouse explorer "Files" layer
output_dir = '/lakehouse/default/Files/landing/Oyster'
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
num_customers = 56  # Change this value to adjust the number of customers generated
# ==========================================

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************



# Determine formatting padding dynamically based on customer count
id_digits = max(3, len(str(num_customers)))

# Base template data matching source structures
# General Central European, Balkan, and Eastern European Counterparties
counterparties = [
    'Lidl',            
    'Kaufland',        
    'Biedronka',       
    'Konzum',          
    'MOL Group',       
    'Albert',          
    'Mega Image'       
]

first_names = [
    'Jan', 'Jakub', 'Tomasz', 'Zoltán',       
    'Anna', 'Katarzyna', 'Lenka', 'Réka',     
    'Luka', 'Stefan', 'David', 'Ivan',        
    'Sofia', 'Sara', 'Elena', 'Maria'         
]

last_names = [
    'Nowak', 'Kowalski', 'Svoboda', 'Nagy',   
    'Dvořák', 'Varga', 'Tóth', 'Kozłowski',   
    'Kovačević', 'Marković', 'Popović', 'Popa', 
    'Radu', 'Popescu', 'Horvat', 'Kovačić'    
]




def distribute_spend(target_amount, total_tx_count):
    """Splits a target amount into N random transactions."""
    if target_amount == 0:
        return [0.0] * total_tx_count
    
    splits = sorted([random.random() for _ in range(total_tx_count - 1)])
    splits = [0.0] + splits + [1.0]
    
    amounts = []
    for i in range(total_tx_count):
        amt = round((splits[i+1] - splits[i]) * target_amount, 2)
        amounts.append(amt)
        
    diff = round(target_amount - sum(amounts), 2)
    if diff != 0:
        amounts[-1] = round(amounts[-1] + diff, 2)
        
    return amounts

# Define fixed strict target spend boundaries to guarantee matching the SQL logic
tier_bounds = {
    'Standard': (150.00, 1800.00),
    'Gold': (2200.00, 4500.00),
    'Platinum': (5500.00, 8500.00)
}

customers, accounts, debit_cards, transactions = [], [], [], []
tx_global_counter = 1

# Generate customer entities with strict 1-to-1 relationships based on the parameter
for idx in range(1, num_customers + 1):
    cust_id = f"CUST_{idx:0{id_digits}d}"
    acc_id = f"ACC_{idx:0{id_digits}d}"
    card_id = f"CARD_{idx:0{id_digits}d}"
    
    # 1. Customer Baseline Metadata
    f_name = random.choice(first_names)
    l_name = random.choice(last_names)
    full_name = f"{f_name} {l_name}"
    tax_id = f"{random.randint(100,999)}-{random.randint(10,99)}-{random.randint(1000,9999)}"
    customers.append([cust_id, full_name, tax_id, 'Regular', f_name, l_name, '1985-05-15'])
    
    # 2. Account Information with Random Balance Enforced
    acc_num = f"OYS1000000{idx:0{id_digits}d}"
    random_balance = round(random.uniform(1000.00, 75000.00), 2)
    accounts.append([acc_id, cust_id, acc_num, 'Checking', random_balance, 'EUR'])
    
    # 3. Dynamic Randomized Profile Assignment
    # Selects a scenario strategy on a per-customer basis entirely at random
    alignment_scenario = random.choice(['aligned', 'upgrade', 'downgrade'])
    
    if alignment_scenario == 'aligned':
        initial_tier = random.choice(['Standard', 'Gold', 'Platinum'])
        target_spend_tier = initial_tier
        
    elif alignment_scenario == 'upgrade':
        # Card tier is lower than actual spending threshold
        initial_tier = random.choice(['Standard', 'Gold'])
        target_spend_tier = 'Platinum' if initial_tier == 'Gold' else random.choice(['Gold', 'Platinum'])
        
    else:
        # Downgrade: Card tier is higher than actual spending threshold
        initial_tier = random.choice(['Gold', 'Platinum'])
        target_spend_tier = 'Standard' if initial_tier == 'Gold' else random.choice(['Standard', 'Gold'])
        
    card_num = f"4532-1122-3344-{idx:04d}"
    debit_cards.append([card_id, acc_id, card_num, initial_tier, 'Active', '12/30'])
    
    # 4. Transaction Generation (10 to 20 records per account required)
    tx_count = random.randint(10, 20)
    
    # Fetch random spending limit ranges matching the calculated goal tier
    min_spend, max_spend = tier_bounds[target_spend_tier]
    total_spend = round(random.uniform(min_spend, max_spend), 2)
            
    tx_amounts = distribute_spend(total_spend, tx_count)
    
    for tx_idx in range(tx_count):
        tx_id = f"TX_{tx_global_counter:05d}"
        amount = tx_amounts[tx_idx]
        day = random.randint(10, 24)
        timestamp = f"2026-09-{day} 14:30:00"
        vendor = random.choice(counterparties)
        
        transactions.append([tx_id, card_id, amount, timestamp, vendor, 'approved'])
        tx_global_counter += 1

# File routing targets the standard local runtime mount configuration
files_config = {
    'Customer.csv': (['CustomerID', 'Name', 'TaxID', 'CustomerType', 'FirstName', 'LastName', 'DoB'], customers),
    'Account.csv': (['AccountID', 'CustomerID', 'AccountNumber', 'Type', 'Balance', 'Currency'], accounts),
    'DebitCard.csv': (['CardID', 'AccountID', 'CardNumber', 'Tier', 'Status', 'Expiry'], debit_cards),
    'Transaction_Ledger.csv': (['TransactionID', 'CardID', 'Amount', 'Timestamp', 'Counterparty', 'Status'], transactions)
}

for filename, (header, rows) in files_config.items():
    file_path = os.path.join(output_dir, filename)
    with open(file_path, mode='w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)

print(f"Success: Files safely landed inside the Fabric Workspace: '{output_dir}'")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
