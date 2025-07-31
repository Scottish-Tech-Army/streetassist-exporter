# Load a CSV file into a table.
# This is primarily intended to handle getting the column names and ordering right in a safe way.
import base64
import csv
import logging
import os
import pandas as pd
import re
import requests
import subprocess
import sys
import yaml
import hashlib

FILELIST = ["places", "historic_welfare_checks", "historic_all_suf", "historic_nightly", "valid_locations", "place_synonyms", "location_corrections"]
STORAGEACCOUNTNAME = os.environ["STORAGEACCOUNTNAME"]
SERVER = os.environ["SERVER"]
ADMINUSER = os.environ["ADMINUSER"]
ADMINPWD = os.environ["ADMINPWD"]
DB = os.environ["DB"]

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s.%(msecs)03d - %(levelname)s - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')

def download_csv(csvfile, path=None):
    logger.info("Downloading CSV file %s", csvfile)
    if not path:
        path = f"/tmp/{csvfile}"
    cmd = f"az storage blob download -f \"{path}\" -c csvdata -n {csvfile} --account-name {STORAGEACCOUNTNAME} --auth-mode login"
    result = subprocess.run(cmd, shell=True, check=True, text=True, stdout=subprocess.DEVNULL)

def upload_csv(csvfile):
    # Upload the CSV file to Azure Storage; this is for backup purposes.
    logger.info("Uploading CSV file %s", csvfile)
    cmd = f"az storage blob upload -f \"/tmp/{csvfile}\" -c csvdata -n {csvfile} --account-name {STORAGEACCOUNTNAME} --overwrite --auth-mode login"
    result = subprocess.run(cmd, shell=True, check=True, text=True, stdout=subprocess.DEVNULL)

def load_tsv(file, tsvfile):
    # Load the TSV file to the database using bcp.
    logger.info("Loading TSV file %s", tsvfile)
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

def get_valid_locations(api_token):
    # Valid locations are in the SafetyCulture data.
    logger.info("Extracting valid locations")
    RESPONSESET = "responseset_53d4a29d5525468a991eabe5aa71d2cd"
    url = f"https://api.safetyculture.io/response_sets/{RESPONSESET}"
    headers = {
        "accept": "application/json",
        "authorization": f"Bearer {api_token}"
    }
    response = requests.get(url, headers=headers)
    if not response.ok:
        logger.error("Failed to fetch valid locations: %s %s", response.status_code, response.text)
        response.raise_for_status()
    data = response.json()

    # Parse the data. We deliberately fail if the structure is not as expected.
    responses = data['responses']
    names = []
    for response in responses:
        names.append(response['label'])

    # Write the names to a CSV file.
    csvfile = "/tmp/valid_locations.csv"
    logger.info("Writing valid locations to %s", csvfile)
    with open(csvfile, "w", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(['name'])
        for name in names:
            writer.writerow([name])

def get_places():
    # The places file we need to get is in the automation container of the blob store.
    logger.info("Fetching places from automation container")
    xlsxfile = "places.xlsx"
    xlsxpath = f"/tmp/{xlsxfile}"
    csvpath = "/tmp/places.csv"
    cmd = f"az storage blob download -f \"{xlsxpath}\" -c automation -n {xlsxfile} --account-name {STORAGEACCOUNTNAME} --auth-mode login"
    result = subprocess.run(cmd, shell=True, check=True, text=True, stdout=subprocess.DEVNULL)

    # Convert to CSV
    logger.info("Converting %s to CSV", xlsxfile)
    pd.read_excel(xlsxpath).to_csv(csvpath, index=False)

def main():
    logger.info("Starting CSV download and upload process")
    api_token = os.environ["API_TOKEN"]  # Raises KeyError if not set

    for file in FILELIST:
        logger.info("Uploading file %s", file)

        csvfile = f"{file}.csv"
        tsvfile = f"/tmp/{file}.tsv"

        if file in ("valid_locations", "places"):
            # Special case - download the CSV file that exists if any, then get the data from SafetyCulture.
            # If the same, just continue; if different, upload the new one so we have an archived copy.
            logger.info("Handling valid_locations file")
            saved_file = f"/tmp/{csvfile}.orig"
            download_csv(csvfile, path=saved_file)
            if file == "valid_locations":
                # If the file is valid_locations, we need to get the data from SafetyCulture.
                logger.info("Fetching valid locations from SafetyCulture")
                get_valid_locations(api_token)
            else:
                logger.info("Fetching places from SharePoint")
                get_places()

            def file_hash(filepath):
                hasher = hashlib.sha256()
                with open(filepath, "rb") as f:
                    for chunk in iter(lambda: f.read(4096), b""):
                        hasher.update(chunk)
                return hasher.hexdigest()

            if os.path.exists(saved_file):
                orig_hash = file_hash(saved_file)
                new_hash = file_hash(f"/tmp/{csvfile}")
                if orig_hash == new_hash:
                    logger.info("No changes in %s.csv, skipping upload of CSV", file)
                    pass
                else:
                    logger.info("%s.csv has changed, proceeding with upload.", file)
                    upload_csv(csvfile)
        else:
            # Just download the file
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
                writer = csv.writer(tsv, delimiter="\t", quoting=csv.QUOTE_NONE, lineterminator="\n")
                # Write the column names as headers to the TSV file
                writer.writerow(columns)
                for row in reader:
                    # Remove BOM and quotes from each cell in the row
                    clean_row = []
                    for cell in row:
                        # Remove BOM, and CRs and LFs
                        cell = cell.replace('\ufeff', '').replace("\r", "").replace("\n", "")
                        # Truncate decimals if matches pattern: optional -, 1-2 digits, ., >8 decimals
                        match = re.match(r'^-?\d{1,2}\.(\d{9,})$', cell)
                        if match:
                            int_part, dec_part = cell.split('.')
                            cell = f"{int_part}.{dec_part[:8]}"
                        clean_row.append(cell)
                    # Reorder the row based on the column map, putting in None for missing columns
                    reordered_row = [clean_row[column_map[col]] if col in column_map else None for col in columns]
                    writer.writerow(reordered_row)

        load_tsv(file, tsvfile)

if __name__ == "__main__":
    main()
