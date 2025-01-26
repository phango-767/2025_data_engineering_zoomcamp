import pandas as pd
from sqlalchemy import create_engine
from time import time
import argparse


engine = create_engine('postgresql://root:root@localhost:5432/ny_taxi')
engine.connect()


#df is now not a dataframe, it's an iterator. We have to use this method as we can't add 1300000 rows to db all at once
df_iter = pd.read_csv('yellow_tripdata_2021-01.csv', iterator = True, chunksize=100000)
df = next(df_iter)

df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)

df.head(0).to_sql(name= 'yellow_taxi_data', con = engine, if_exists = 'replace')

#now we will update our table with information in the chunks. Removing df.head(0) - note `append`
df.to_sql(name= 'yellow_taxi_data', con = engine, if_exists = 'append')


query = """
select count(*) from yellow_taxi_data;
"""

pd.read_sql(query, con = engine)


# In[32]:


#appended one chunk of 100000. now we need to do it iteratively. 


while True:
    try:
        t_start = time()

        df = next(df_iter)

        df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
        df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)

        df.to_sql(name= 'yellow_taxi_data', con = engine, if_exists = 'append') #adds data to the table as chunks because inside while loop

        t_end = time()

        duration = t_end - t_start

        print('inserted another chunk... this chunk took %.3f seconds' % (duration))
    
    except StopIteration:
        print('finished inserting all chunks.')
        break
