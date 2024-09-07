-- Joining pieces together
SELECT *
FROM visits;
SELECT *
FROM water_source;
SELECT *
FROM location;
/*We want to see if there are any specific provinces or towns where
some sources are more abundant.
The problem is that the location table uses location_id while water_source only has source_id.
So we won't be able to join these tables directly. But the visits table maps location_id and 
source_id. 
So if we use visits as the table we query from, we can join location where the location_id matches,
 and water_source where the source_id matches.*/
 -- Therefore,
 SELECT
	loc.province_name,
    loc.town_name,
	v.visit_count,
    v.location_id
FROM visits AS v
JOIN
location AS loc
ON v.location_id = loc.location_id;
--  Joining the water_source table on the key shared between water_source and visits
 SELECT
	loc.province_name,
    loc.town_name,
	v.visit_count,
    v.location_id,
    ws.type_of_water_source,
    ws.number_of_people_served
FROM visits AS v
JOIN
location AS loc
ON v.location_id = loc.location_id
JOIN
water_source AS ws
ON v.source_id = ws.source_id
WHERE v.visit_count = 1;
/*There you can see what I mean. For one location, there are multiple AkHa00103 records for 
the same location. If we aggregate, we will include these rows, so our results will be incorrect. 
To fix this, we can just select rows where visits.visit_count = 1*/

/*Now that we verified that the table is joined correctly, 
we can remove the location_id and visit_count columns and 
then add location_type column from location and time_in_queue from visits to our results set*/
-- That is,
SELECT
	loc.province_name,
    loc.town_name,
    ws.type_of_water_source,
    loc.location_type,
    ws.number_of_people_served,
    v.time_in_queue,
    wp.results
FROM visits AS v
JOIN
location AS loc
ON v.location_id = loc.location_id
JOIN
water_source AS ws
ON v.source_id = ws.source_id
LEFT JOIN
well_pollution AS wp
ON v.source_id = wp.source_id
WHERE v.visit_count = 1;
-- Turning it to a view,
CREATE VIEW combined_analysis_table AS 
-- This view assembles data from different tables into one to simplify analysis
SELECT
	loc.province_name,
    loc.town_name,
    ws.type_of_water_source,
    loc.location_type,
    ws.number_of_people_served,
    v.time_in_queue,
    wp.results
FROM visits AS v
JOIN
location AS loc
ON v.location_id = loc.location_id
JOIN
water_source AS ws
ON v.source_id = ws.source_id
LEFT JOIN
well_pollution AS wp
ON v.source_id = wp.source_id
WHERE v.visit_count = 1;
-- Last Analysis
/*We are going to be building a pivot table to breakdown our data into provinces/towns and source types*/
WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
province_name,
SUM(number_of_people_served) AS total_people_served
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_people_served), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_people_served), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_people_served), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_people_served), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_people_served), 0) AS well
FROM
	combined_analysis_table AS ct
JOIN
	province_totals AS pt 
	ON ct.province_name = pt.province_name
GROUP BY
	ct.province_name
ORDER BY
	ct.province_name;
/*This table gives us amazing insights on the various types of sources in the different
provinces. We can now make decisions based on the one that affects most people*/
-- Aggregating the data per town,
WITH town_totals AS (-- This CTE calculates the population of each town
SELECT
province_name,
town_name,
SUM(number_of_people_served) AS total_people_served
FROM
	combined_analysis_table
GROUP BY
	province_name, town_name
)
SELECT
	ct.province_name,
	ct.town_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well' 
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS well
FROM
	combined_analysis_table AS ct
JOIN -- Since the town names are not unique, we join on a composite key
	town_totals AS tt 
	ON ct.province_name = tt.province_name 
    AND ct.town_name = tt.town_name
GROUP BY -- We group by province first and then by town
	ct.province_name,
    ct.town_name
ORDER BY
    ct.province_name
;

-- MCQ question
/*If you were to modify the query to include the percentage of people served
 by only dirty wells as a water source, which part of the town_aggregated_water_access 
 CTE would you need to change?*/
WITH town_totals AS (-- This CTE calculates the population of each town
SELECT
province_name,
town_name,
SUM(number_of_people_served) AS total_people_served
FROM
	combined_analysis_table
GROUP BY
	province_name, town_name
)
SELECT
	ct.province_name,
	ct.town_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well' AND CT.results != 'Clean'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS well
FROM
	combined_analysis_table AS ct
JOIN -- Since the town names are not unique, we join on a composite key
	town_totals AS tt 
	ON ct.province_name = tt.province_name 
    AND ct.town_name = tt.town_name
GROUP BY -- We group by province first and then by town
	ct.province_name,
    ct.town_name
ORDER BY
    ct.province_name
;



CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (-- This CTE calculates the population of each town
SELECT
province_name,
town_name,
SUM(number_of_people_served) AS total_people_served
FROM
	combined_analysis_table
GROUP BY
	province_name, town_name
)
SELECT
	ct.province_name,
	ct.town_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS well
FROM
	combined_analysis_table AS ct
JOIN -- Since the town names are not unique, we join on a composite key
	town_totals AS tt 
	ON ct.province_name = tt.province_name 
    AND ct.town_name = tt.town_name
GROUP BY -- We group by province first and then by town
	ct.province_name,
    ct.town_name
ORDER BY
    ct.province_name;
/*Due to the fact that the query has become more complex and slower to run, we store the 
query in a temporary table so it is quicker to access*/
/*Query from the mcq to see which provinces had all of it's towns
 with less than 50% access to home taps - both broken and working*/
SELECT
province_name,
town_name,
river,
shared_tap,
tap_in_home,
tap_in_home_broken,
well
FROM
town_aggregated_water_access
WHERE
tap_in_home AND tap_in_home_broken < 50
;

WITH town_totals AS (-- This CTE calculates the population of each town
SELECT
	province_name,
	town_name,
	SUM(number_of_people_served) AS total_people_served
FROM
	combined_analysis_table 
GROUP BY
	province_name, town_name
)
SELECT
	province_name
FROM
	(SELECT 
		ct.province_name,
		ct.town_name,
		ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
		THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS tap_in_home,
		ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
		THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_people_served), 0) AS tap_in_home_broken
FROM
	combined_analysis_table AS ct
JOIN 
	town_totals AS tt 
	ON ct.province_name = tt.province_name 
    AND ct.town_name = tt.town_name
GROUP BY -- We group by province first and then by town
	ct.province_name,
    ct.town_name) AS town_tap_access_percentage
GROUP BY
    province_name
HAVING
	MAX(tap_in_home + tap_in_home_broken) < 50;
    
    
-- Percentage of broken taps in each town and province
SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *
100,0) AS Pct_broken_taps
FROM
town_aggregated_water_access;
-- A practical plan
/*Our final goal is to implement our plan in the database. create a table where our teams
have the information they need to fix, upgrade and repair water sources. They will need the
addresses of the places they should visit (street address, town, province), the type of water
source they should improve, and what should be done to improve it. We should also make space for 
them in the database to update us on their progress. We need to know if the repair is complete, and
the date it was completed, and give them space to upgrade the sources. Let's call this table Project_progress*/
-- Creating project progress table
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
/* Project_id −− Unique key for sources in case we visit the same
source more than once in the future.
*/
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
/* source_id −− Each of the sources we want to improve should exist,
and should refer to the source table. This ensures data integrity.*/
Address VARCHAR(50), -- Street address
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvements VARCHAR(50), -- What the engineers should do at that place
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
/* Source_status −− We want to limit the type of information engineers can give us, so we
limit Source_status.
− By DEFAULT all projects are in the "Backlog" which is like a TO-DO list.
− CHECK() ensures only those three options will be accepted. This helps to maintain clean data.*/
Date_of_completion DATE,  -- Engineers will add this the day the source has been upgraded
Comments TEXT)
; -- Engineers can leave comments. We use a TEXT type that has no limit on char length
-- Create Table query without comments
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvements VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);
-- Project Progress query
SELECT
	loc.address,
	loc.town_name,
	loc.province_name,
	ws.source_id,
	ws.type_of_water_source,
	wp.results,
CASE
	WHEN wp.results = 'Contaminated: Biological' THEN 'Install UV filter'
    WHEN wp.results = 'Contaminated: Chemical' THEN 'Install RO filter'
    WHEN ws.type_of_water_source = 'river' THEN 'Drill well'
    WHEN ws.type_of_water_source = 'shared_tap' AND  v.time_in_queue >= 30
		THEN CONCAT("Install ", FLOOR(v.time_in_queue / 30), " taps nearby")
	WHEN ws.type_of_water_source = "tap_in_home_broken" THEN "Diagnose local infrastructure"
ELSE NULL
END Improvements
FROM
	water_source AS ws
LEFT JOIN
	well_pollution AS wp
    ON ws.source_id = wp.source_id
JOIN
	visits AS v
    ON ws.source_id = v.source_id
JOIN
	location AS loc
    ON loc.location_id = v.location_id
WHERE
v.visit_count = 1 -- This must always be true
AND ( -- AND one of the following (OR) options must be true as well.
wp.results != 'Clean'
OR type_of_water_source IN ('tap_in_home_broken','river')
OR (type_of_water_source = 'shared_tap' AND v.time_in_queue >= 30)
);
-- Adding all of this data into our progress tabe
INSERT INTO 
	md_water_services.project_progress(
		source_id,
        Address,
        Town,
        Province,
        Source_type,
        Improvements)
SELECT
	ws.source_id,
    loc.address,
	loc.town_name,
	loc.province_name,
	ws.type_of_water_source,
CASE
	WHEN wp.results = 'Contaminated: Biological' THEN 'Install UV filter'
    WHEN wp.results = 'Contaminated: Chemical' THEN 'Install RO filter'
    WHEN ws.type_of_water_source = 'river' THEN 'Drill well'
    WHEN ws.type_of_water_source = 'shared_tap' AND  v.time_in_queue >= 30
		THEN CONCAT("Install ", FLOOR(v.time_in_queue / 30), " taps nearby")
	WHEN ws.type_of_water_source = "tap_in_home_broken" THEN "Diagnose local infrastructure"
ELSE NULL
END Improvements
FROM
	water_source AS ws
LEFT JOIN
	well_pollution AS wp
    ON ws.source_id = wp.source_id
JOIN
	visits AS v
    ON ws.source_id = v.source_id
JOIN
	location AS loc
    ON loc.location_id = v.location_id
WHERE
v.visit_count = 1 -- This must always be true
AND ( -- AND one of the following (OR) options must be true as well.
wp.results != 'Clean'
OR type_of_water_source IN ('tap_in_home_broken','river')
OR (type_of_water_source = 'shared_tap' AND v.time_in_queue >= 30)
);

-- DROP TABLE md_water_services.project_progress;

SELECT 
count(Improvements)
FROM md_water_services.project_progress
WHERE Improvements = 'Install UV filter';		