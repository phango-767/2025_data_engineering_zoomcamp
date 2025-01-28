# Module 1 Homework: Docker & SQL


### Question 1. Understanding docker first run
---

Run docker with the `python:3.12.8` image in an interactive mode, use the entrypoint `bash`.

What's the version of `pip` in the image?

```
docker run -it --entrypoint bash python:3.12.8 

```

Answer: `pip 24.3.1 from /usr/local/lib/python3.12/site-packages/pip (python 3.12)`

### Question 2. Understanding Docker networking and docker-compose
---
Given the following `docker-compose.yaml`, what is the `hostname` and `port` that *pgadmin* should use to connect to the postgres database?

```
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin  

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data

```

- postgres:5433
- localhost:5432
- db:5433
- postgres:5432
- db:5432

Answer: Option 5 `db:5432`

### Question 3. Trip Segmentation Count
---
During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, respectively, happened:

   1. Up to 1 mile
   2. In between 1 (exclusive) and 3 miles (inclusive),
   3. In between 3 (exclusive) and 7 miles (inclusive),
   4. In between 7 (exclusive) and 10 miles (inclusive),
   5. Over 10 miles


```
select
count(*),
case 
when trip_distance <= 1.0 then '1'
when trip_distance > 1.0 and trip_distance <=3.0 then '2'
when trip_distance > 3.0 and trip_distance <=7.0 then '3'
when trip_distance > 7.0 and trip_distance <=10.0 then '4'
when trip_distance > 10.0 then '5'
end as grouped_distances


from public.green_taxi_data
where lpep_pickup_datetime >= '2019-10-01' AND lpep_dropoff_datetime < '2019-11-01' 
group by grouped_distances
```

`
104802	"1"
198924	"2"
109603	"3"
27678	"4"
35189	"5"
`

### Question 4. Longest trip for each day
---
Which was the pick up day with the longest trip distance? Use the pick up time for your calculations.

Tip: For every day, we only care about one single trip with the longest distance.
- 2019-10-11
- 2019-10-24
- 2019-10-26
- 2019-10-31

```
SELECT 
cast(lpep_pickup_datetime as date)
FROM public.green_taxi_data
where trip_distance in
(select max(trip_distance) from public.green_taxi_data)
```

### Question 5. Three biggest pickup zones
---
Which were the top pickup locations with over 13,000 in total_amount (across all trips) for 2019-10-18?

Consider only `lpep_pickup_datetime` when filtering by date.

```
SELECT 
    z."Zone",
    SUM(t.total_amount) AS Total_amount
FROM 
    public.green_taxi_data t
LEFT JOIN 
    public.green_zones z
ON 
    z."LocationID" = t."PULocationID"
WHERE 
    DATE(t.lpep_pickup_datetime) = '2019-10-18'
GROUP BY 
    z."Zone"
HAVING 
    SUM(t.total_amount) > 13000
ORDER BY
	Total_amount desc;
```
Answer: `"East Harlem North"	18686.68000000005
"East Harlem South"	16797.260000000068
"Morningside Heights"	13029.790000000039`

### Question 6. Largest tip
---
For the passengers picked up in October 2019 in the zone named "East Harlem North" which was the drop off zone that had the largest tip?

Note: it's `tip` , not `trip`

We need the name of the zone, not the ID.

```
SELECT 
    z2."Zone" as "Drop_off_zone",
	t.tip_amount
FROM 
    public.green_taxi_data t
JOIN 
    public.green_zones z
ON 
    z."LocationID" = t."PULocationID"
JOIN 
    public.green_zones z2
ON 
    z2."LocationID" = t."DOLocationID"
WHERE 
    DATE(t.lpep_pickup_datetime) >= '2019-10-01'
AND
	DATE(t.lpep_pickup_datetime) <= '2019-10-31'
AND z."Zone" = 'East Harlem North'
ORDER BY tip_amount desc
```
Answer: `JFK Airport`