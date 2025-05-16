# Load a CSV file into a table.
# This is primarily intended to handle getting the column names and ordering right in a safe way.
import csv
import logging
import os
import re
import subprocess
import sys
import yaml

FILELIST = ["places"]
STORAGEACCOUNTNAME = os.environ["STORAGEACCOUNTNAME"]
SERVER = os.environ["SERVER"]
ADMINUSER = os.environ["ADMINUSER"]
ADMINPWD = os.environ["ADMINPWD"]
DB = os.environ["DB"]

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s.%(msecs)03d - %(levelname)s - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')


def download_csv(csvfile):
    logger.info("Downloading CSV file %s", csvfile)
    cmd = f"az storage blob download -f \"/tmp/{csvfile}\" -c csvdata -n {csvfile} --account-name {STORAGEACCOUNTNAME} --auth-mode login"
    result = subprocess.run(cmd, shell=True, check=True, text=True)

def upload_tsv(file, tsvfile):
    logger.info("Uploading TSV file %s", tsvfile)
    cmd = f"bcp dbo.{file} in {tsvfile} -S {SERVER} -U {ADMINUSER} -P {ADMINPWD} -d {DB} -c -r \"\\n\" -F 2"
    result = subprocess.run(cmd, shell=True, check=True, text=True)

def read_format(file):
    logger.info("Read format for %s", file)
    formatfile = f"/tmp/{file}.fmt"
    cmd = f"bcp dbo.{file} format nul -S {SERVER} -U {ADMINUSER} -P {ADMINPWD} -d {DB} -n -f {formatfile}"
    result = subprocess.run(cmd, shell=True, check=True, text=True)

    # Crack out the file, reading the ordered list of column names.
    columns = []
    with open(formatfile, "r") as f:
        lines = f.readlines()

        # Toss the two header lines.
        lines.pop(0)
        lines.pop(0)

        for line in lines:
            words = line.strip().split()
            column = words[6].lower()
            columns.append(column)

    logger.info("Columns: %s", columns)

    return columns

for file in FILELIST:
    logger.info("Uploading file %s", file)

    csvfile = f"{file}.csv"
    tsvfile = f"/tmp/{file}.tsv"

    download_csv(csvfile)

    columns = read_format(file)

    # Read the CSV file, and convert it to TSV, removing any quotes and BOM characters. We store the header row in a list.
    logger.info("Converting CSV to TSV for %s", file)
    with open(f"/tmp/{csvfile}", "r", encoding="utf-8-sig") as f:
        reader = csv.reader(f)
        headers = next(reader)
        # Remove BOM and quotes from headers
        headers = [h.lower().replace('"', '').replace('\ufeff', '') for h in headers]

        # Check that there are no values in headers that are not in columns
        for header in headers:
            if header not in columns:
                logger.error("Header %s not in columns %s", header, columns)
                raise ValueError(f"Header {header} not in columns")

        # Figure out the ordering - we need to create a mapping for each column in order where it comes from
        # (or if it is not present, that it is missing and should be NULL)
        column_map = {}
        for i, header in enumerate(headers):
            if header in columns:
                column_map[header] = i
            else:
                logger.error("Header %s not in columns %s", header, columns)
                raise ValueError(f"Header {header} not in columns")

        with open(tsvfile, "w", encoding="utf-8") as tsv:
            writer = csv.writer(tsv, delimiter="\t", quoting=csv.QUOTE_NONE)
            # Write the column names as headers to the TSV file
            writer.writerow(columns)
            for row in reader:
                # Remove BOM and quotes from each cell in the row
                clean_row = []
                for cell in row:
                    # Remove BOM
                    cell = cell.replace('\ufeff', '')
                    # Truncate decimals if matches pattern: optional -, 1-2 digits, ., >8 decimals
                    match = re.match(r'^-?\d{1,2}\.(\d{9,})$', cell)
                    if match:
                        int_part, dec_part = cell.split('.')
                        cell = f"{int_part}.{dec_part[:8]}"
                    clean_row.append(cell)
                # Reorder the row based on the column map, putting in None for missing columns
                reordered_row = [clean_row[column_map[col]] if col in column_map else None for col in columns]
                writer.writerow(reordered_row)

    upload_tsv(file, tsvfile)
