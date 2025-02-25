CREATE OR REPLACE EXTERNAL TABLE `de_zoomcamp_kestra.external_yellow_tripdata_2024`
OPTIONS (
  format = 'parquet',
  uris = ['gs://kestra_de_zoomcamp_bucket_2/yellow_tripdata_2024-*.parquet']
);

-- Create a non partitioned table from external table
CREATE OR REPLACE TABLE `de_zoomcamp_kestra.yellow_tripdata_2024_non_partitioned` AS
SELECT * FROM `de_zoomcamp_kestra.external_yellow_tripdata_2024`;

-- Question 1: What is count of records for the 2024 Yellow Taxi Data?
SELECT COUNT(*) from de-zoomcamp-terraform-449109.de_zoomcamp_kestra.yellow_tripdata_2024_non_partitioned;
-- Answer: 20 332 093

-- Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.
-- What is the estimated amount of data that will be read when this query is executed on the External Table and the Table?
SELECT count(distinct(PULocationID)) from `de_zoomcamp_kestra.external_yellow_tripdata_2024`; -- 0B
SELECT count(distinct(PULocationID)) from de-zoomcamp-terraform-449109.de_zoomcamp_kestra.yellow_tripdata_2024_non_partitioned; --155.12 MB

-- Write a query to retrieve the PULocationID from the table (not the external table) in BigQuery. 
-- Now write a query to retrieve the PULocationID and DOLocationID on the same table. Why are the estimated number of Bytes different?
select (PULocationID) from de-zoomcamp-terraform-449109.de_zoomcamp_kestra.yellow_tripdata_2024_non_partitioned; --    155.12 MB
select PULocationID, DOLocationID from de-zoomcamp-terraform-449109.de_zoomcamp_kestra.yellow_tripdata_2024_non_partitioned;
-- Answer: 
-- BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.

-- How many records have a fare_amount of 0?
SELECT count(*) from de-zoomcamp-terraform-449109.de_zoomcamp_kestra.yellow_tripdata_2024_non_partitioned
WHERE fare_amount = 0;
-- Answer: 8 333

-- What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)
-- Creating a partition and cluster table
CREATE OR REPLACE TABLE de_zoomcamp_kestra.yellow_tripdata_2024_partitioned_clustered
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * FROM `de_zoomcamp_kestra.external_yellow_tripdata_2024`;
-- Answer: Partition by tpep_dropoff_datetime and Cluster on VendorID

-- Write a query to retrieve the distinct VendorIDs between tpep_dropoff_datetime 2024-03-01 and 2024-03-15 (inclusive)
-- Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values?
-- Choose the answer which most closely matches.
SELECT DISTINCT VendorID
from 
-- de_zoomcamp_kestra.yellow_tripdata_2024_non_partitioned --310.24 MB
de_zoomcamp_kestra.yellow_tripdata_2024_partitioned_clustered -- 26.84 MB
where tpep_dropoff_datetime between '2024-03-01' and '2024-03-15';
-- Answer: 310.24 MB for non-partitioned table and 26.84 MB for the partitioned table

-- Where is the data stored in the External Table you created?
-- Answer: GCP Bucket

-- It is best practice in Big Query to always cluster your data:
-- False




