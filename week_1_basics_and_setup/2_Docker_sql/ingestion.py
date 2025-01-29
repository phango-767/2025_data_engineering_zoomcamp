import pandas as pd
from sqlalchemy import create_engine
from time import time
import argparse
import os
import gzip
import shutil

def main(params):
    user = params.user
    password = params.password
    host = params.host
    port = params.port
    db = params.db
    table_name = params.table_name
    url = params.url

    # gzipped_file = 'output.csv.gz'
    # csv_name = 'output.csv'

    # Step 1: Download the gzipped file
    # os.system(f"wget {url} -O {csv_name}")  # Download gzipped file
    csv_name = 'output.csv'
    gzip_name = 'output.gz'
    if url.endswith('.csv'):
        os.system(f"wget {url} -O {csv_name}")
    if url.endswith('.gz'):
        os.system(f"wget {url} -O {gzip_name}")
        with gzip.open(gzip_name, 'rb') as f_in:
            with open(csv_name, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)


    # Step 3: Connect to the database using SQLAlchemy engine
    engine = create_engine(f'postgresql://{user}:{password}@{host}:{port}/{db}')
    engine.connect()

    # Step 4: Read the CSV in chunks and insert into the database
    df_iter = pd.read_csv(csv_name, iterator=True, chunksize=100000, on_bad_lines='skip')  # Read in chunks
    # df_iter = pd.read_csv(csv_name, iterator= True, chunksize= 100000, compression= 'gzip') 
    df = next(df_iter)

    # Convert datetime columns
    # df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
    # df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
    # df.lpep_pickup_datetime = pd.to_datetime(df.lpep_pickup_datetime)
    # df.lpep_dropoff_datetime = pd.to_datetime(df.lpep_dropoff_datetime)

    # Create the table in Postgres if it doesn't exist
    df.head(0).to_sql(name=table_name, con=engine, if_exists='replace')

    # Insert the first chunk
    df.to_sql(name=table_name, con=engine, if_exists='append')

    # Now, loop over the rest of the chunks
    while True:
        try:
            t_start = time()

            df = next(df_iter)

            # Convert datetime columns
            # df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
            # df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
            # df.lpep_pickup_datetime = pd.to_datetime(df.lpep_pickup_datetime)
            # df.lpep_dropoff_datetime = pd.to_datetime(df.lpep_dropoff_datetime)

            # Append the current chunk to the database
            df.to_sql(name=table_name, con=engine, if_exists='append')

            t_end = time()

            duration = t_end - t_start

            print(f'Inserted another chunk... this chunk took {duration:.3f} seconds')

        except StopIteration:
            print('Finished inserting all chunks.')
            break

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Ingest csv data to Postgres")

    parser.add_argument('--user', help='User name for Postgres')
    parser.add_argument('--password', help='Password for Postgres')
    parser.add_argument('--host', help='Host for Postgres')
    parser.add_argument('--port', help='Port for Postgres')
    parser.add_argument('--db', help='Database name for Postgres')
    parser.add_argument('--table_name', help='Name of the table where we will write the results to')
    parser.add_argument('--url', help='URL of the gzipped CSV file')

    args = parser.parse_args()

    main(args)
