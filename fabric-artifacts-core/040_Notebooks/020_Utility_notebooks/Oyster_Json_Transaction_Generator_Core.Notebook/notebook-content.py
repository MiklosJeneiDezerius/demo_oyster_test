# Fabric notebook source

# METADATA ********************
# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   }
# META }

# PARAMETERS CELL ********************

num_customers = 83
anchor_date = "2026-09-01"

# METADATA ********************
# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # Oyster Core JSON transaction generator
# Generates only Transaction_Ledger. The nested arrays require flatten and
# explode before the rows can be written to a Delta table.

# CELL ********************

import json
import os
from datetime import datetime, timedelta

num_customers = int(num_customers)
if num_customers < 1:
    raise ValueError("num_customers must be positive.")
anchor = datetime.strptime(anchor_date, "%Y-%m-%d")
batch_timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
output_dir = f"/lakehouse/default/Files/oyster/landing_raw/{batch_timestamp}"
os.makedirs(output_dir, exist_ok=True)

scenarios = {
    1: (15, 60, 1, 10),
    2: (12, 300, 1, 14),
    3: (15, 550, 1, 8),
    4: (15, 600, 1, 9),
    5: (3, 250, 4, 11),
    0: (3, 225, 5, 15),
    6: (15, 550, 1, 16),
}
transactions_by_account = {}
transaction_id = 1
for customer_id in range(1, num_customers + 1):
    account_id = customer_id * 10
    days, amount, day_step, hour = scenarios[customer_id % 7]
    account_transactions = transactions_by_account.setdefault(account_id, [])
    for day in range(days):
        transaction_time = anchor + timedelta(days=day * day_step, hours=hour)
        record = {
            "TransactionID": transaction_id,
            "AccountID": account_id,
            "Amount": amount,
            "Timestamp": transaction_time.strftime("%Y-%m-%d %H:%M:%S"),
        }
        account_transactions.append({"transaction": record})
        transaction_id += 1

document = {"transaction_batches": list(transactions_by_account.values())}
output_path = os.path.join(
    output_dir, f"Transaction_Ledger_{batch_timestamp}_core.json",
)
with open(output_path, "w", encoding="utf-8") as output_file:
    json.dump(document, output_file, ensure_ascii=False, indent=2)
print(f"Transaction_Ledger: {transaction_id - 1} rows written to {output_path}")

# METADATA ********************
# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }