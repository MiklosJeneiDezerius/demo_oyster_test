# Fabric notebook source

# METADATA ********************
# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   }
# META }

# CELL ********************
# MAGIC %%configure
# MAGIC {
# MAGIC     "defaultLakehouse": {
# MAGIC         "name": "lh_oysterlake2"
# MAGIC     }
# MAGIC }

# PARAMETERS CELL ********************

num_customers = 83
anchor_date = "2026-09-01"

# METADATA ********************
# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # Oyster full-demo JSON transaction generator
# Generates only Transaction_Ledger using the same deterministic seven spend
# scenarios and full ledger fields as the original CSV generator.

# CELL ********************

import json
import os
from datetime import datetime, timedelta

num_customers = int(num_customers)
if num_customers < 1:
    raise ValueError("num_customers must be positive.")
anchor = datetime.strptime(anchor_date, "%Y-%m-%d")
batch_timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
output_dir = f"/lakehouse/default/Files/oyster/landing_raw/{batch_timestamp}"
os.makedirs(output_dir, exist_ok=True)

scenarios = {
    1: (15, 60.00, 1, 10, "Kaufland"),
    2: (12, 300.00, 1, 14, "Biedronka"),
    3: (15, 550.00, 1, 8, "MOL Group"),
    4: (15, 600.00, 1, 9, "Albert"),
    5: (3, 250.00, 4, 11, "Mega Image"),
    0: (3, 225.00, 5, 15, "Konzum"),
    6: (15, 550.00, 1, 16, "Tesco"),
}
transactions_by_account = {}
transaction_id = 1
for customer_id in range(1, num_customers + 1):
    account_id = customer_id * 10
    days, amount, day_step, hour, vendor = scenarios[customer_id % 7]
    account_transactions = transactions_by_account.setdefault(account_id, [])
    for day in range(days):
        transaction_time = anchor + timedelta(days=day * day_step, hours=hour)
        record = {
            "TransactionID": transaction_id,
            "AccountID": account_id,
            "Amount": amount,
            "Timestamp": transaction_time.strftime("%Y-%m-%d %H:%M:%S"),
            "Counterparty": vendor,
            "TransactionStatusID": 1,
        }
        account_transactions.append({"transaction": record})
        transaction_id += 1

document = {"transaction_batches": list(transactions_by_account.values())}
output_path = os.path.join(
    output_dir, f"Transaction_Ledger_{batch_timestamp}_full.json",
)
with open(output_path, "w", encoding="utf-8") as output_file:
    json.dump(document, output_file, ensure_ascii=False, indent=2)
print(f"Transaction_Ledger: {transaction_id - 1} rows written to {output_path}")

# METADATA ********************
# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }