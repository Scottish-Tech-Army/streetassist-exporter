# Load data from Mitti, terminating on error
# The only reason this is in python is that it lets us handle the config file
# more easily.
import subprocess
import os
import logging
import sys
import yaml

DIR = "/app"
COMMAND = f"{DIR}/mitti-exporter"
CFG_FILE = f"{DIR}/mitti-exporter.yaml"

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s.%(msecs)03d - %(levelname)s - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')

def set_config(api_token, connection_string, last_run, inspection_items_exist):
    # Run the command
    logger.info("Set up configuration")
    os.chdir(DIR)
    # Execute the command
    result = subprocess.run(f"{COMMAND} configure", shell=True, check=True, text=True)

    # Load the existing configuration from the YAML file
    with open(CFG_FILE, 'r') as file:
        config = yaml.safe_load(file)

    # Update specific fields in the configuration
    config['access_token'] = api_token
    # The exporter still defaults to the pre-rebrand API domain; use the Mitti one.
    config['api']['url'] = "https://api.mitti.com"
    config['export']['incremental'] = True
    config['export']['inspection']['archived'] = "both"
    config['export']['tables'] = ['inspections', 'inspection_items', 'templates', 'actions']

    # Only use changes after last successful run; initial runs take multiple hours, while updates take a minute or so.
    config['export']['modified_after'] = last_run

    # Now the SQL configuration
    config['db']['connection_string'] = connection_string
    config['db']['dialect'] = "sqlserver"
    # The exporter's schema migration fails on inspection_items (entry_point.sh indexes item_id), so disable
    # it when that table exists, and run it only to create the tables on a fresh database.
    # See "Upgrading the exporter" in docs/operations.md.
    config['db']['auto_migrate_disabled'] = inspection_items_exist

    # Write the updated configuration back to the YAML file
    with open(CFG_FILE, 'w') as file:
        yaml.safe_dump(config, file, default_style='"')

def export_data():
    logger.info("Download all the data")
    result = subprocess.run(f"{COMMAND} sql", shell=True, check=True, text=True)

def main():
    # Do the things
    logger.info("Get started")
    api_token = os.environ["API_TOKEN"]  # Raises KeyError if not set
    connection_string = os.environ["CONNECTION"]  # Raises KeyError if not set
    last_run_raw = os.environ["LASTRUN"]  # Raises KeyError if not set
    inspection_items_exist_raw = os.environ["INSPECTION_ITEMS_EXIST"]  # Raises KeyError if not set
    if inspection_items_exist_raw not in ("yes", "no"):
        raise ValueError(f"Expected INSPECTION_ITEMS_EXIST to be 'yes' or 'no', got {inspection_items_exist_raw!r}")
    inspection_items_exist = inspection_items_exist_raw == "yes"
    # LASTRUN is something like "2025-01-01 12:34:56" - which cannot be parsed by the exporter.
    # Convert to the correct format.
    logger.info("Last run time (raw): \"%s\"", last_run_raw)
    parts = last_run_raw.split(" ")
    if len(parts) == 2:
        date, time = parts
    else:
        raise ValueError("Expected exactly one space in last_run_raw")
    date, time = last_run_raw.split(" ")
    last_run = f"{date}T{time}Z"
    logger.info("Last run time (reformatted): \"%s\"", last_run)

    set_config(api_token, connection_string, last_run, inspection_items_exist)
    export_data()

if __name__ == "__main__":
    main()
