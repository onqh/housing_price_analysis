-- CREATE TABLE houses AS 
-- TABLE houses_2022 
-- WITH NO DATA;

-- Understanding data
SELECT * 
FROM houses 
LIMIT 5;

-- PPD Cartegory type is the type of price paid data. There are two cartegories: 
-- A: Standard Price Paid entry and B: Additional Price Paid entry. 
-- HM Land Registry has been collecting the information on Category A transactions from January 1995. Category B transactions were identified from October 2013.
-- In this project, we don't analyse this information.

-- RECORD STATUS: demonstrates monthly files only Indicates additions, changes and deletions to the records. The categories are A, C, D
-- We don't analyse this information.

-- ADDRESS: We analyse the data based on the Town/City and District so we only use this column

-- ALTER TABLE houses
--     DROP COLUMN IF EXISTS building_number,
--     DROP COLUMN IF EXISTS building_name,
-- 	DROP COLUMN IF EXISTS street,
-- 	DROP COLUMN IF EXISTS locality,
-- 	DROP COLUMN IF EXISTS county,
-- 	DROP COLUMN IF EXISTS ppd_cat_type,
-- 	DROP COLUMN IF EXISTS record_status;

-----CLEANING DATA------
-- CHECK MISSING DATA
SELECT
  round(1.0 * SUM(CASE WHEN houses.tid IS NULL THEN 1 ELSE 0 END) / COUNT(*) OVER (), 2) AS tid,
  round(1.0 * SUM(CASE WHEN houses.sold_price IS NULL THEN 1 ELSE 0 END) / COUNT(*) OVER (), 2) AS sold_price,
  round(1.0 * SUM(CASE WHEN houses.sold_date IS NULL THEN 1 ELSE 0 END) / COUNT(*) OVER (), 2) AS sold_date,
  round(1.0 * SUM(CASE WHEN houses.postcode IS NULL THEN 1 ELSE 0 END) / COUNT(*) OVER (), 2) AS postcode,
  round(1.0 * SUM(CASE WHEN houses.property_type IS NULL THEN 1 ELSE 0 END) / COUNT(*) OVER (), 2) AS property_type,
  round(1.0 * SUM(CASE WHEN houses.new_build IS NULL THEN 1 ELSE 0 END) / COUNT(*) OVER (), 2) AS new_build,
  round(1.0 * SUM(CASE WHEN houses.duration IS NULL THEN 1 ELSE 0 END) / COUNT(*) OVER (), 2) AS duration,
  round(1.0 * SUM(CASE WHEN houses.town IS NULL THEN 1 ELSE 0 END) / COUNT(*) OVER (), 2) AS town,
  round(1.0 * SUM(CASE WHEN houses.district IS NULL THEN 1 ELSE 0 END) / COUNT(*) OVER (), 2) AS district
FROM houses;

-- FIND IF THERE ARE ANY DUPLICATES
WITH cte AS
(SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY tid,
				 sold_price,
				 sold_date,
				 postcode
				 ORDER BY tid
			 ) AS row_number
FROM houses)
SELECT *
FROM cte
WHERE row_number > 1;

-- FIND OUTLIER
SELECT *
FROM houses
WHERE sold_price < 1000 OR sold_price > 50 * 10^6
ORDER BY sold_price DESC;
-- There are some extreme sold prices so we use median for the analysis
----------------------------------------------------------------------
-- TID: Transaction ID: unique ID for each time a property is sold

-- PROPERTY TYPE: D = Detachted, S = Semi-Detached, T = Terraced, F = Flat, O = Others
-- average price of each types over year
SELECT h2.year, h2.property_type, h2.median
FROM
(SELECT extract(year from sold_date) AS year, property_type,
 		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median
FROM houses
GROUP BY 1,2) h2
ORDER BY 1,2;

-- count of each type per year percentage wise
WITH property_type AS
(SELECT extract(year from sold_date) AS year, property_type, COUNT(*) as count
FROM houses
GROUP BY 1,2
ORDER BY 1)
SELECT year, property_type, count,
	   round(100.0 * count / SUM(count) OVER(PARTITION BY year), 1) AS perc
FROM property_type
GROUP BY 1,2,3
ORDER BY year


-- median price each types
SELECT property_type,COUNT(*), PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median_price
FROM houses
GROUP BY property_type
ORDER BY 2 DESC;

-- NEW BUILD
-- count total new build and price
SELECT new_build, COUNT(*), PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median_price
FROM houses
GROUP BY new_build
ORDER BY 2;

-- percentage wise each year of new_build
WITH new_build AS
(SELECT extract(year from sold_date) AS year, new_build, 
 		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median_price, 
 		COUNT(*) as count
FROM houses
GROUP BY 1,2
)
SELECT year, new_build, median_price, count,
	   round(100.0 * count / SUM(count) OVER(PARTITION BY year), 1) AS perc
FROM new_build
GROUP BY 1,2,3,4
ORDER BY year

-- -- each type and each year
-- SELECT h2.year, h2.new_build, h2.volume, h2.average_price
-- FROM
-- (SELECT extract(year from sold_date) AS year, new_build, COUNT(*) AS volume, round(AVG(sold_price), 2) AS Average_price
-- FROM houses
-- GROUP BY 1,2) h2
-- ORDER BY 1,2;

-- New Build vs Property type
SELECT property_type, new_build, COUNT(*), 
	   PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median_price
FROM houses
GROUP BY 1,2
ORDER BY 1,2 DESC;

-- DURATION: Leashold and Freehold or Unknown
SELECT duration, COUNT(*), PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median_price
FROM houses
GROUP BY 1;

SELECT h2.year, h2.duration, h2.volume, h2.median_price
FROM
(SELECT extract(year from sold_date) AS year, duration, COUNT(*) AS volume, 
 		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median_price
FROM houses
GROUP BY 1,2) h2
ORDER BY 1,2;

-- TOWN/CITY
-- SELECT town, COUNT(*) AS frequency, round(AVG(sold_price), 2) AS average_price, AVG(COUNT(*)) OVER () AS mean
-- FROM houses
-- GROUP BY 1
-- ORDER BY 3 DESC;

-- Only take the town with number of property sold large than the average
SELECT x.town,x.volume, x.median
FROM (
	SELECT h.town, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median, 
	COUNT(h.*) AS volume, AVG(COUNT(h.*)) OVER () AS mean
	FROM houses AS h
	GROUP BY 1
	ORDER BY 2 DESC
) x
WHERE x.volume > x.mean
ORDER BY 3 DESC;


-- -- Count by year for each town
-- SELECT extract(year from sold_date) AS year, town, COUNT(*) AS volume
-- FROM houses
-- GROUP BY 1, 2
-- ORDER BY 3 DESC

-- COUNTY
SELECT county, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median, COUNT(*) AS volume
FROM houses 
GROUP BY 1
ORDER BY 2 DESC

-- QUUESTION: 
-- Average Price per year and  Year on Year Price changes
WITH year_price AS
(SELECT extract(year from sold_date) AS year,
 		extract(month from sold_date) AS month,
 		round(AVG(sold_price),2) AS average_price
FROM houses
GROUP BY 1,2
HAVING extract(month from sold_date) = 12
)
SELECT  year, month,
 		average_price AS average_price,
 		round(100* (average_price - LAG(average_price) OVER(ORDER BY year)) / LAG(average_price) OVER(ORDER BY year) , 2) AS YoY_changes
FROM year_price
GROUP BY 1, 2, 3
ORDER BY 1, 2;

-- Sales volume and YoY change
SELECT h.year AS year,
       h.month AS month,
	   h.sales_volume AS sales_volume,
	   round(100 * (h.sales_volume - LAG(h.sales_volume) OVER(ORDER BY h.year)) / LAG(h.sales_volume) OVER(ORDER BY h.year),2) AS perc_changes
FROM
(
	SELECT extract(year from h.sold_date) AS year,
	   extract(month from h.sold_date) AS month,
	   COUNT(h.*) AS sales_volume
	FROM houses AS h
	GROUP BY 1,2
	HAVING extract(month from h.sold_date) = 12
) h
GROUP BY 1, 2, 3
ORDER BY 1, 2;

-- Sales distribution
SELECT h.dist_group, COUNT(*)
FROM
(
 SELECT CASE WHEN sold_price BETWEEN 0 AND 99999 THEN '0 - 99,999'
             WHEN sold_price BETWEEN 100000 AND 199999 THEN '100,000 - 199,999'
             WHEN sold_price BETWEEN 200000 AND 299999 THEN '200,000 - 299,999'
	     	 WHEN sold_price BETWEEN 300000 AND 399999 THEN '300,000 - 399,999'
	         WHEN sold_price BETWEEN 400000 AND 499999 THEN '400,000 - 499,999'
             WHEN sold_price BETWEEN 500000 AND 599999 THEN '500,000 - 599,999'
	     	 WHEN sold_price BETWEEN 600000 AND 699999 THEN '600,000 - 699,999'
	     	 WHEN sold_price BETWEEN 700000 AND 799999 THEN '700,000 - 799,999'
             WHEN sold_price BETWEEN 800000 AND 899999 THEN '800,000 - 899,999'
	     	 WHEN sold_price BETWEEN 900000 AND 999999 THEN '900,000 - 999,999'
	     	 ELSE 'more than 1,0000,000' END AS dist_group
 FROM HOUSES
) AS h
GROUP BY dist_group
ORDER BY 1;


