/*Maji Ndogo Part 1*/
-- Getting to know our data
SHOW TABLES;
SELECT *
FROM location;
SELECT *
FROM visits;
SELECT *
FROM water_source;
SELECT *
FROM data_dictionary;
-- Diving into the water sources
SELECT DISTINCT 
	type_of_water_source
FROM water_source;
/*This helps us assess the various types of water sources to understand them better. Multiple households were surveyed together with an average household consisting of 6 people. So 956 records refers to 160 households (956/6)*/
-- Unpack the visits to water sources
SELECT *
FROM visits
WHERE time_in_queue >= 500;
/*Retrieves records where the time in queue exceeded 500 mins i.e. 8 hours or more*/
-- We want to see in what water sources the queue time exceeded 500 mins
SELECT *
FROM water_source
WHERE source_id IN ('AkRu05234224',
'HaZa21742224', 'AkKi00881224',
'SoRu37635224','SoRu36096224', 'AkLu01628224');
/*We can see that most shared taps served a large number of people and thus had larger queue times*/
-- Assess the quality of water sources
SELECT 
    wq.visit_count,
	ws.type_of_water_source,
	wq.subjective_quality_score
FROM md_water_services.visits
JOIN
water_source AS ws
ON ws.source_id = visits.source_id
JOIN
water_quality AS wq
ON wq.record_id = visits.record_id
WHERE  ws.type_of_water_source = 'tap_in_home' AND wq.visit_count > 1
AND wq.subjective_quality_score = 10;

SELECT
	wq.record_id,
    wq.subjective_quality_score,
    wq.visit_count,
    ws.type_of_water_source
FROM water_quality AS wq
JOIN visits
ON visits.record_id = wq.record_id
JOIN water_source AS ws
ON ws.source_id= visits.source_id
WHERE wq.subjective_quality_score = 10 AND wq.visit_count > 1
	AND ws.type_of_water_source = "tap_in_home"; -- **
-- Investigate pollution issues
SELECT *
FROM well_pollution
WHERE results  LIKE 'Clean' AND biological > 0.01;
-- Fixing discrepancies in well pollution data
SELECT *
FROM well_pollution
WHERE description LIKE 'Clean%' AND biological > 0.01;
/*To update, we crate a new table to test out our code before running it on our main table*/
CREATE TABLE
md_water_services.well_pollution_copy
AS (
SELECT *
FROM
md_water_services.well_pollution
);
-- Updating columns
SET SQL_safe_updates = 0;
UPDATE 
	well_pollution_copy
SET description = 'Bacteria: E. coli'
WHERE description = 'Clean Bacteria: E. coli';
UPDATE
well_pollution_copy
SET description = 'Bacteria: Giardia Lamblia'
WHERE description = 'Clean Bacteria: Giardia Lamblia';
UPDATE
well_pollution_copy
SET
results = 'Contaminated: Biological'
WHERE biological > 0.01 AND results = 'Clean';
-- Testing query
SELECT
*
FROM
well_pollution_copy
WHERE
description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);
-- Making updates on the main table
SET SQL_safe_updates = 0;
UPDATE 
	well_pollution
SET description = 'Bacteria: E. coli'
WHERE description = 'Clean Bacteria: E. coli';
UPDATE
well_pollution
SET description = 'Bacteria: Giardia Lamblia'
WHERE description = 'Clean Bacteria: Giardia Lamblia';
UPDATE
well_pollution
SET
results = 'Contaminated: Biological'
WHERE biological > 0.01 AND results = 'Clean';
-- Testing out the query on the main Table
SELECT
*
FROM
well_pollution
WHERE
description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);