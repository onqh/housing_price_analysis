/* CREATE TABLE */
CREATE TABLE IF NOT EXISTS houses
(
    tid text,
    sold_price integer,
    sold_date date,
    postcode text,
    property_type character(1),
    new_build character(1),
    duration character(1),
    building_number text,
    building_name text,
    street text,
    locality text,
    town text,
    district text,
    county text,
    ppd_cat_type character(1),
    record_status character(1)
);

----------------------------------------------------------------------
/* EXPLORATORY DATA*/

-- 1. Observe the first 5 rows
SELECT * 
FROM houses 
LIMIT 5;

-- Note taken after searching on Google to understand the field:
-- TID: Transaction ID: unique ID for each time a property is sold
-- PROPERTY TYPE: D = Detachted, S = Semi-Detached, T = Terraced, F = Flat, O = Others
-- PPD Cartegory type is the type of price paid data. There are two cartegories: A: Standard Price Paid entry and B: Additional Price Paid entry. HM Land Registry has been collecting the information on Category A transactions from January 1995. Category B transactions were identified from October 2013.
-- RECORD STATUS: demonstrates monthly files only Indicates additions, changes and deletions to the records. The categories are A, C, D.

-- 2. Check missing data
SELECT
  SUM(CASE WHEN houses.tid IS NULL OR houses.tid = '' THEN 1 ELSE 0 END) AS tid,
  SUM(CASE WHEN houses.sold_price IS NULL OR houses.sold_price = 0 THEN 1 ELSE 0 END) AS sold_price,
  SUM(CASE WHEN houses.sold_date IS NULL THEN 1 ELSE 0 END) AS sold_date,
  SUM(CASE WHEN houses.postcode IS NULL OR houses.postcode = '' THEN 1 ELSE 0 END)AS postcode,
  SUM(CASE WHEN houses.property_type IS NULL OR houses.property_type = '' THEN 1 ELSE 0 END) AS property_type,
  SUM(CASE WHEN houses.new_build IS NULL OR houses.new_build = '' THEN 1 ELSE 0 END) AS new_build,
  SUM(CASE WHEN houses.duration IS NULL OR houses.duration = '' THEN 1 ELSE 0 END) AS duration,
  SUM(CASE WHEN houses.town IS NULL OR houses.town = '' THEN 1 ELSE 0 END) AS town,
  SUM(CASE WHEN houses.district IS NULL OR houses.district = '' THEN 1 ELSE 0 END) AS district
FROM houses;

-- There are only missing data in postcode collumn.
-- As this analysis aim to understand the general housing price from 1995-2022 of the whole UK, I have no intention to make a really deep postcode analysis so these null values can be ignored.

-- 3. Check if any duplicates
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
-- No duplicates found.

-- 4. Find outliers
SELECT *
FROM houses
WHERE sold_price < 1000 OR sold_price > 50 * 10^6
ORDER BY sold_price DESC;
-- AS a rule of thumbs, the mean value is not a good example for representing financial assets. Also, there are some extreme sold prices so we use median for the analysis.


-- 5. Answering questions
/* This part of the Exploratory Data is to answer some questions to understand the data. Then it will be visualised in Tableau */
/* Query used for Tableau input */


-- Q1. What is the total number of sales recorded, median sold price, maximum and minimum sale price?
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median,
	   COUNT(*) AS total_sales,
	   MAX(sold_price) AS max_price,
	   MIN(sold_price) AS min_price
FROM houses

-- Q2. What the price distribution ?
-- First method: manually categorise
SELECT h.dist_group, COUNT(*)
FROM
(
 SELECT CASE WHEN sold_price BETWEEN 0 AND 49999 THEN '0 - 49,999'
			 WHEN sold_price BETWEEN 50000 AND 99999 THEN '50,000 - 99,999'
             WHEN sold_price BETWEEN 100000 AND 149999 THEN '100,000 - 149,999'
             WHEN sold_price BETWEEN 150000 AND 199999 THEN '150,000 - 199,999'
	     	 WHEN sold_price BETWEEN 200000 AND 249999 THEN '200,000 - 249,999'
	         WHEN sold_price BETWEEN 250000 AND 299999 THEN '250,000 - 299,999'
             WHEN sold_price BETWEEN 300000 AND 349999 THEN '300,000 - 349,999'
	         WHEN sold_price BETWEEN 350000 AND 399999 THEN '350,000 - 399,999'
             WHEN sold_price BETWEEN 400000 AND 449999 THEN '400,000 - 449,999'
	     	 WHEN sold_price BETWEEN 450000 AND 499999 THEN '450,000 - 499,999'
	         WHEN sold_price BETWEEN 500000 AND 549999 THEN '500,000 - 549,999'
             WHEN sold_price BETWEEN 550000 AND 599999 THEN '550,000 - 599,999'
	         WHEN sold_price BETWEEN 600000 AND 649999 THEN '600,000 - 649,999'
             WHEN sold_price BETWEEN 650000 AND 699999 THEN '650,000 - 699,999'
	     	 WHEN sold_price BETWEEN 700000 AND 749999 THEN '700,000 - 749,999'
	         WHEN sold_price BETWEEN 750000 AND 799999 THEN '750,000 - 799,999'
             WHEN sold_price BETWEEN 800000 AND 849999 THEN '800,000 - 849,999'
	     	 WHEN sold_price BETWEEN 850000 AND 899999 THEN '850,000 - 899,999'
	     	 WHEN sold_price BETWEEN 900000 AND 949999 THEN '900,000 - 949,999'
             WHEN sold_price BETWEEN 950000 AND 999999 THEN '950,000 - 999,999'
	     	 ELSE 'more than 1,0000,000' END AS dist_group
 FROM houses
) AS h
GROUP BY dist_group
ORDER BY 1;

-- Second method: by Tableau
SELECT tid, sold_price
FROM houses

-- Q3. What is the median price and count over time (month, year) ?
SELECT date_trunc('month', sold_date)::date AS order_month,
	   PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY h.sold_price) AS median,
	   COUNT(h.*) AS volume
FROM houses h
GROUP BY 1

-- Q4. Which month has the most sales in overall?
SELECT extract(month from h.sold_date) AS month,
	   COUNT(h.*) AS sales_volume
FROM houses h
GROUP BY 1
ORDER BY 2 DESC;
-- June followed by July and August.

-- Q5. So what is the YoY change in volume and price ?
WITH year_price AS
(SELECT extract(year from sold_date) AS year,
 		extract(month from sold_date) AS month,
 		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY h.sold_price) AS median
FROM houses h
GROUP BY 1,2
HAVING extract(month from sold_date) = 6
)
SELECT  year, month,
		median AS median,
 		100* (median - LAG(median) OVER(ORDER BY year)) / LAG(median) OVER(ORDER BY year) AS YoY_changes
FROM year_price
GROUP BY 1, 2, 3
ORDER BY 1, 2;

-- Q6. Which county/region has the highest median prices ? What are their sales volume ?
SELECT county, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median, COUNT(*) AS volume
FROM houses 
GROUP BY 1
ORDER BY 2 DESC;

-- Q7. Which city has the highest volume of sales?
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
-- Here I filtered out all cities has sales volume less than average sales.

-- Q8 - Question about property types
-- a. What is the median price of each prperty type over year?
SELECT h2.year, h2.property_type, h2.median
FROM
(SELECT extract(year from h.sold_date) AS year, h.property_type,
 		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY h.sold_price) AS median
FROM houses h
GROUP BY 1,2) h2
ORDER BY 1,2;

-- b. Counting each property type per year in percentage
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


-- c. Median price each property types
SELECT property_type,COUNT(*), PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median_price
FROM houses
GROUP BY property_type
ORDER BY 2 DESC;

-- Q9. Question about new build
-- a. Counting total new build and price
SELECT new_build, COUNT(*), PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median_price
FROM houses
GROUP BY new_build
ORDER BY 2;

-- b. Calculate percentage of new build per year
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

-- Q10. So what is the number of new build in each property type ? And its median price ?
SELECT property_type, new_build, COUNT(*), 
	   PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median_price
FROM houses
GROUP BY 1,2
ORDER BY 1,2 DESC;

-- Q11. DURATION: Counting Leashold and Freehold or Unknown and its median sold price each year?
SELECT h2.year, h2.duration, h2.volume, h2.median_price
FROM
(SELECT extract(year from sold_date) AS year, duration, COUNT(*) AS volume, 
 		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) AS median_price
FROM houses
GROUP BY 1,2) h2
ORDER BY 1,2;
