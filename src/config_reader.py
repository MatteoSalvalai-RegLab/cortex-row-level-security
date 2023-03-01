import futures
import logging
from string import Template
import sys

from google.cloud import bigquery

_VIEW_SQL_TEMPLATE = 'sec_view_template.sql'

client = bigquery.Client()

def process_table(table_name, src_dataset, tgt_dataset):
    src_table = f"{ src_dataset }.{ table_name }"
    
    with open(_VIEW_SQL_TEMPLATE, mode='r',
              encoding='utf-8') as stream:
        sql_template = Template(stream.read())
    sql_code = sql_template.substitute(
        src_table=src_table
    )

    tgt_view = f"{ tgt_dataset }.{ table_name }"
    view = bigquery.Table(tgt_view)
    view.view_query = sql_code
    client.create_table(view, exists_ok = True)
    print(f"Created view: {tgt_view}")

def main():
    logging.basicConfig()
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    logging.info("Starting config_reader...")

    if not sys.argv[1]:
        raise SystemExit("ERROR: No Source Project argument provided!")
    source_project = sys.argv[1]

    if not sys.argv[2]:
        raise SystemExit("ERROR: No Source Dataset argument provided!")
    source_dataset = source_project + "." + sys.argv[2]

    if not sys.argv[3]:
        raise SystemExit("ERROR: No Target Project argument provided!")
    target_project = sys.argv[3]

    if not sys.argv[4]:
        raise SystemExit("ERROR: No Target Dataset argument provided!")
    target_dataset = target_project + "." + sys.argv[4]


    # Process each table entry in the settings to create CDC table/view.
    # This is done in parallel using multiple threads.
    pool = futures.ThreadPoolExecutor(10)
    threads = []
    for table in client.list_tables(source_dataset):
        threads.append(
            pool.submit(
                process_table, table, source_dataset, target_dataset
            )
        )
    if len(threads) > 0:
        logging.info("Waiting for all tasks to complete...")
        futures.wait(threads)

    # In order to capture error from any of the threads,
    # we need to access the result. If any individual thread
    # throws an exception, it will be caught with this call.
    # Otherwise, system will always exit with SUCCESS.
    for t in threads:
        _ = t.result()

    logging.info("✅ config_reader done.")


if __name__ == "__main__":
    main()