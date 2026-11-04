# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "97d704f2-e89e-488b-b8e8-7a52ded016b7",
# META       "default_lakehouse_name": "lh_oysterlake2",
# META       "default_lakehouse_workspace_id": "efc752a1-1a79-4121-b55e-0f8c8c172fba",
# META       "known_lakehouses": [
# META         {
# META           "id": "97d704f2-e89e-488b-b8e8-7a52ded016b7"
# META         }
# META       ]
# META     }
# META   }
# META }

# PARAMETERS CELL ********************

# %%
p_load_date = ""
p_root_path = "Files/oyster/landing_raw"
p_source_route_path = None
p_company_cd = "oyster"
p_source_system_cd = "oys"
p_in_table_name = "AccountType"
p_datev_filter = ""
p_debug = 0
p_lakehouse_name = "lh_oysterlake2"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************



# %%
from pyspark.sql import SparkSession, Row
from datetime import datetime, timedelta
from pyspark.sql.functions import col, lit, current_timestamp, from_utc_timestamp, row_number, desc
from pyspark.sql import Window
import re
import csv
from io import StringIO


# %%
spark.conf.set("spark.sql.parquet.int96RebaseModeInRead", "LEGACY") 
spark.conf.set("spark.sql.parquet.int96RebaseModeInWrite", "LEGACY") 
spark.conf.set("spark.sql.parquet.datetimeRebaseModeInWrite", "LEGACY") 
spark.conf.set("spark.sql.parquet.datetimeRebaseModeInRead", "LEGACY")

# %%
# Check for parameter date; if not provided, use yesterday's date
if not p_load_date:
    yesterday = datetime.now() - timedelta(days=1)
    v_valid_dt = yesterday.strftime("%Y%m%d")
else:
    v_valid_dt = p_load_date
 
print('v_valid_dt:', v_valid_dt)

# %%
# Convert load date to formatted date string (YYYY-MM-DD)
v_m_valid_dt = datetime.strptime(v_valid_dt, "%Y%m%d").strftime("%Y-%m-%d")
 
print('v_m_valid_dt:', v_m_valid_dt)

# %%
if not p_root_path:
    v_root_path = "Files/landing_raw"
else:
    v_root_path = p_root_path

print('v_root_path:', v_root_path)

# %%
if not p_debug:
    v_debug = 0
else:
    v_debug = p_debug

print('v_debug: ', v_debug)

# %%
if p_lakehouse_name:
    v_lakehouse_name = p_lakehouse_name
else:
    # Retrieve the default Lakehouse name
    v_lakehouse_name = spark.conf.get("trident.lakehouse.name", "No default Lakehouse set")

if v_lakehouse_name == "No default Lakehouse set":
    raise ValueError("No default Lakehouse is set. Please specify a Lakehouse name.")

print(f"v_lakehouse_name:", v_lakehouse_name)

# %%
# Build source filepath; destination folder is cleared by the copy job's preceding Delete activity
if not p_company_cd:
    raise ValueError("p_company_cd parameter is required but not set.")

# MandantenDaten esetén csak az aktuális év almappáját olvassuk, a többi táblánál az összeset
if p_in_table_name == "SpecialCase":
    filepath = f"Files/{p_company_cd}/landing_raw/{datetime.now().year}"
else:
    filepath = f"Files/{p_company_cd}/landing_raw"

print('Source raw filepath:', filepath)





# %%
# Create a SparkSession
spark = SparkSession.builder.appName("MergeParquetByPostingDateToDelta").getOrCreate()

# %%
# We assume we don't have errors
v_error = 0

# %%
def sanitize_column_name(name):
    """
    Sanitize a column name for use in a Spark DataFrame.
    - Replace German umlauts with ASCII equivalents
    - Replace all remaining special characters with underscores
    - Collapse multiple consecutive underscores into one
    - Strip leading and trailing underscores
    """
    umlaut_map = str.maketrans('äöüÄÖÜß', 'aouAOUs')
    name = name.translate(umlaut_map)
    name = re.sub(r'[^a-zA-Z0-9_]', '_', name)
    name = re.sub(r'_+', '_', name)
    name = name.strip('_')
    return name

# %%
def read_datev_csv_multi(file_path_pattern, table_name):
    """
    Reads Datev CSV files from year subfolders under /current/.
    Updated to recursively search all subdirectories via dynamic globbing
    and includes adaptive decoding logic to handle unexpected UTF-8 files.
    """
    if table_name == "MandantenDaten":
        glob_pattern = f"{file_path_pattern}/{table_name}_*.csv"
    else:
        glob_pattern = f"{file_path_pattern}/**/{table_name}_*.csv"

    rdd_raw = spark.sparkContext.binaryFiles(glob_pattern)

    def extract_source_timestamp(path):
        match = re.search(r'/landing_raw/(\d{8}_\d{6}|\d{14}|\d{8})/', path)
        if not match:
            raise ValueError(f"Missing source date folder in path: {path}")
        folder = match.group(1)
        date_format = "%Y%m%d_%H%M%S" if "_" in folder else "%Y%m%d%H%M%S" if len(folder) == 14 else "%Y%m%d"
        return datetime.strptime(folder, date_format).strftime("%Y-%m-%d %H:%M:%S")

    def safe_decode(content_bytes):
        """Decode BOM-marked UTF-16, otherwise prefer UTF-8."""
        if content_bytes.startswith((b"\xff\xfe", b"\xfe\xff")):
            return content_bytes.decode("utf-16")
        try:
            decoded = content_bytes.decode("utf-8-sig")
            if "\x00" not in decoded:
                return decoded
        except UnicodeDecodeError:
            pass
        return content_bytes.decode("utf-16")

    # Collect all files as (path, bytes) tuples to the driver
    all_files = rdd_raw.collect()

    if not all_files:
        raise ValueError(f"No files found matching pattern: {glob_pattern}")

    # Extract and sanitize header from first file using fallback-safe decoder
    first_file_text = safe_decode(all_files[0][1])
    first_lines = first_file_text.split("\n")
    raw_header = [c.strip("\r").strip() for c in first_lines[0].split(",")]
    header = [sanitize_column_name(c) for c in raw_header]
    num_cols = len(header)
    full_header = ["m_source_dttm", "m_source_file"] + header

    # Parse all files on the driver
    all_rows = []
    for path, content in all_files:
        source_timestamp = extract_source_timestamp(path)
        file_text = safe_decode(content)
        lines = file_text.split("\n")
        for line in lines[1:]:
            line = line.rstrip("\r")
            if not line.strip():
                continue
            parts = next(csv.reader(StringIO(line), delimiter=",", quotechar='"'))
            if len(parts) < num_cols:
                parts += [""] * (num_cols - len(parts))
            if len(parts) > num_cols:
                parts = parts[:num_cols]
            all_rows.append(Row(**dict(zip(full_header, [source_timestamp, path] + parts))))

    df = spark.createDataFrame(all_rows).withColumn("m_source_dttm", col("m_source_dttm").cast("timestamp"))
    return df

# %%
def merge_and_deduplicate(df, data_cols):
    window = Window.partitionBy(*data_cols).orderBy(desc("m_source_dttm"), desc("m_source_file"))
    df_deduped = (
        df
        .withColumn("_rn", row_number().over(window))
        .filter(col("_rn") == 1)
        .drop("_rn")
    )
    return df_deduped

# %%
try:
    # Read all CSV files across all year subfolders
    df_raw = read_datev_csv_multi(filepath, p_in_table_name)

    if p_datev_filter:
        filter_col = sanitize_column_name(p_datev_filter.strip())
        if filter_col not in df_raw.columns:
            raise ValueError(f"p_datev_filter column '{filter_col}' not found in data. Available: {df_raw.columns}")
        data_cols = [filter_col]
    else:
        data_cols = [c for c in df_raw.columns if c not in ("m_source_dttm", "m_source_file")]

    df = merge_and_deduplicate(df_raw, data_cols)
    display(df)

except Exception as e:
    print("Data couldn't be retrieved")
    print(f"Error details: {e}")
    v_error = 1

# %%
# Enrich DataFrame with metadata columns
if not v_error:
    df_with_metadata = df.withColumn("m_valid_dt", lit(v_m_valid_dt)) \
                         .withColumn("m_country_cd", lit("")) \
                         .withColumn("m_company_cd", lit(p_company_cd)) \
                         .withColumn("m_updated_at_dttm", from_utc_timestamp(current_timestamp(), "Europe/Budapest")) \
                         .withColumn("m_extracted_dttm", from_utc_timestamp(current_timestamp(), "Europe/Budapest")) \
                         .withColumn("m_source_system_cd", lit(p_source_system_cd)) \
                         .withColumn("m_table_nm", lit(p_in_table_name)) \
                         .withColumn("m_loaded_at_dttm", current_timestamp())

# %%
# Display enriched DataFrame in debug mode
if p_debug and not v_error:
    display(df_with_metadata)

# %%
# Preserve source and load timestamps while casting the remaining columns to string
if not v_error:
    df_string = df_with_metadata.selectExpr(
                *[f"`{c}`" if c in ("m_source_dttm", "m_loaded_at_dttm")
                    else f"CAST(`{c}` AS STRING) AS `{c}`" for c in df_with_metadata.columns]
    )
    display(df_string) 
    
# %%
# Log row count
if not v_error:
    print('Rows loaded for', p_in_table_name, ':', df_string.count())

# %%
# Remove dots from company code to build a clean folder/file name segment
if p_company_cd:
    v_company_cd_cleared = re.sub(r'[.]', '', p_company_cd)
else:
    v_company_cd_cleared = ''
 
print('v_company_cd_cleared:', v_company_cd_cleared)

# %%
# Build output Parquet file path
# %%
# Build the target Unified Table Root path (landing_parquet)
# We lowercase the table name to match the target architecture style guide (e.g., 'cardtier')
# v_out_table_root = f"Files/landing_parquet/{p_company_cd}/{p_in_table_name.lower()}"

#print('Unified Table Root path:', v_out_table_root)

#v_out_file_path = f"Files/{p_company_cd}/landing_parquet/{p_in_table_name.lower()}" + ".parquet"
#print('v_out_file_path:', v_out_file_path)
# %%
v_out_table_name = "ld_"+p_source_system_cd.lower()+"_"+p_in_table_name.lower()
display(v_out_table_name)

# %%
# Path to the Delta table
v_out_table_name_path = "Tables/"+v_out_table_name
display(v_out_table_name_path)


# %%
# Write output as Parquet (overwrite mode)
if not v_error:
    print('Rows to be loaded:', df_string.count())
    
    #(df_string.write
    # .format("parquet")
    # .mode("overwrite")
    # #.partitionBy("m_valid_dt")  # <-- This drives the dynamic folder creation
    # .save(v_out_file_path))    # <-- Dropping it directly into the Unified Table Root
    
    (df_string.write
     .format("delta")
        .option("mergeSchema", "true")
     .mode("overwrite")
     # .partitionBy("m_valid_dt") 
     .saveAsTable(v_out_table_name))

    print("Write complete! Check your storage lake directory.")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
