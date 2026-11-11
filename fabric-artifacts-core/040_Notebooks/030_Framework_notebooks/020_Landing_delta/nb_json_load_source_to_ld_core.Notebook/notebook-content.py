# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   }
# META }

# PARAMETERS CELL ********************

p_load_date = ""
p_root_path = "Files/oyster/landing_raw"
p_in_table_name = "Transaction_Ledger"
p_debug = 0

# METADATA ********************
# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # Oyster Core nested JSON to Delta
# flatten() combines the per-account arrays and explode() emits one row per
# transaction. The resulting Delta table uses the CSV loader's core schema.

# CELL ********************

import json
import re
from datetime import datetime

from pyspark.sql import Window
from pyspark.sql.functions import col, current_timestamp, desc, explode, flatten, lit, row_number
from pyspark.sql.types import ArrayType, StringType, StructField, StructType

required_columns = ["TransactionID", "AccountID", "Amount", "Timestamp"]
if p_in_table_name != "Transaction_Ledger":
    raise ValueError(f"Unsupported JSON source: {p_in_table_name}")
if not p_root_path:
    raise ValueError("p_root_path is required.")

valid_date = datetime.strptime(p_load_date, "%Y%m%d") if p_load_date else datetime.now()
pattern = f"{p_root_path.rstrip('/')}/**/Transaction_Ledger_*_core.json"
source_files = spark.sparkContext.binaryFiles(pattern).collect()
if not source_files:
    raise FileNotFoundError(f"No JSON files match {pattern}")

envelopes = []
for path, content in source_files:
    match = re.search(r"/(\d{8}_\d{6}|\d{14}|\d{8})/[^/]+$", path)
    if not match:
        raise ValueError(f"Missing source batch timestamp in {path}")
    timestamp_text = match.group(1)
    timestamp_format = (
        "%Y%m%d_%H%M%S" if "_" in timestamp_text
        else "%Y%m%d%H%M%S" if len(timestamp_text) == 14
        else "%Y%m%d"
    )
    source_timestamp = datetime.strptime(timestamp_text, timestamp_format).isoformat(sep=" ")
    try:
        document = json.loads(content.decode("utf-8-sig"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError(f"Invalid JSON in {path}") from error

    batches = document.get("transaction_batches") if isinstance(document, dict) else None
    if not isinstance(batches, list) or not batches:
        raise ValueError(f"Expected non-empty transaction_batches in {path}")
    normalized_batches = []
    for batch_number, batch in enumerate(batches, start=1):
        if not isinstance(batch, list) or not batch:
            raise ValueError(f"Expected a non-empty transaction batch in {path}, batch {batch_number}")
        normalized_batch = []
        for row_number, entry in enumerate(batch, start=1):
            record = entry.get("transaction") if isinstance(entry, dict) else None
            if not isinstance(record, dict):
                raise ValueError(f"Expected nested transaction object in {path}, batch {batch_number}, row {row_number}")
            missing_columns = set(required_columns) - set(record)
            if missing_columns:
                raise ValueError(f"Missing required columns {sorted(missing_columns)} in {path}")
            values = {name: record[name] for name in required_columns}
            if any(value is None or isinstance(value, (dict, list)) for value in values.values()):
                raise ValueError(f"Invalid transaction field in {path}, batch {batch_number}, row {row_number}")
            normalized_batch.append({
                "transaction": {name: str(value) for name, value in values.items()}
            })
        normalized_batches.append(normalized_batch)
    envelopes.append((normalized_batches, source_timestamp, path))

transaction_schema = StructType([
    StructField(name, StringType(), False) for name in required_columns
])
entry_schema = StructType([StructField("transaction", transaction_schema, False)])
envelope_schema = StructType([
    StructField(
        "transaction_batches",
        ArrayType(ArrayType(entry_schema, containsNull=False), containsNull=False),
        False,
    ),
    StructField("m_source_dttm", StringType(), False),
    StructField("m_source_file", StringType(), False),
])

nested = spark.createDataFrame(envelopes, envelope_schema)
flattened = nested.select(
    "m_source_dttm",
    "m_source_file",
    explode(flatten(col("transaction_batches"))).alias("entry"),
)
rows = flattened.select(
    *[col(f"entry.transaction.{name}").alias(name) for name in required_columns],
    col("m_source_dttm").cast("timestamp").alias("m_source_dttm"),
    col("m_source_file"),
)

latest = Window.partitionBy("TransactionID").orderBy(
    desc("m_source_dttm"), desc("m_source_file"), desc("TransactionID"),
)
output = (
    rows.withColumn("_rn", row_number().over(latest))
    .filter(col("_rn") == 1)
    .drop("_rn")
    .withColumn("m_valid_dt", lit(valid_date.strftime("%Y-%m-%d")))
    .withColumn("m_company_cd", lit("oyster"))
    .withColumn("m_source_system_cd", lit("oys"))
    .withColumn("m_table_nm", lit(p_in_table_name))
    .withColumn("m_loaded_at_dttm", current_timestamp())
)

table_name = "ld_oys_transaction_ledger"
if int(p_debug):
    display(output)
output.write.format("delta").option("overwriteSchema", "true").mode("overwrite").saveAsTable(table_name)
print(f"Loaded {p_in_table_name} from nested JSON into {table_name}")

# METADATA ********************
# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META 

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
