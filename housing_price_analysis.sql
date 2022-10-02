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


-- TID: Transaction ID: unique ID for each time a property is sold
SELECT COUNT(*)
FROM houses
WHERE tid = '' OR tid IS NULL;

-- PROPERTY TYPE: D = Detachted, S = Semi-Detached, T = Terraced, F = Flat, O = Others
-- to find NULL
SELECT COUNT(DISTINCT property_type) AS "Number of property type"
FROM houses;

-- count each types
SELECT property_type, COUNT(*) 
FROM houses
GROUP BY property_type
ORDER BY 2;

-- NEW BUILD
SELECT new_build, COUNT(*)
FROM houses
GROUP BY new_build
ORDER BY 2;

-- New Build vs Property type
SELECT property_type, new_build, COUNT(*)
FROM houses
GROUP BY 1,2;

-- DURATION: Leashold and Freehold or Unknown
SELECT duration, COUNT(*)
FROM houses
GROUP BY 1;

-- PRICE: 
SELECT sold_price
FROM houses
WHERE sold_price IS NULL;


-- Average Price per year
SELECT extract(year from sold_date) AS Year, AVG(sold_price) AS "Average Price"
FROM houses
GROUP BY 1
ORDER BY 1;



