 -- Cleaning our data - updating employee data
SELECT
	*
FROM md_water_services.employee;
 -- Email
SELECT CONCAT(
	LOWER(REPLACE(employee_name, ' ', '.') ), '@ndogowater.gov') AS new_email
FROM EMPLOYEE;

SET SQL_SAFE_UPDATES = 0;
UPDATE employee
SET email = CONCAT(
	LOWER(REPLACE(employee_name, ' ', '.') ), '@ndogowater.gov');
    
SELECT *
FROM employee;
-- Checking the length of phone numbers
SELECT
	LENGTH(phone_number)
FROM employee;
-- Trimming the numbers to remove extra spaces
SELECT
	LENGTH(TRIM(phone_number)) AS Trimmed_numbers
FROM employee;
-- updating on main table
SET SQL_SAFE_UPDATES = 0;
UPDATE employee
SET phone_number = TRIM(phone_number);
-- Cross-checking
SELECT 
	LENGTH(phone_number)
FROM employee;
-- Honouring our workers
SELECT 
	*
FROM employee;
-- Where our employees live
SELECT
	town_name,
    COUNT(town_name) AS num_employees
FROM employee
GROUP BY
	town_name;
-- Top 3 employees with highest visits
SELECT 
	assigned_employee_id,
    COUNT(visit_count) AS num_visits
FROM visits
GROUP BY
	assigned_employee_id
ORDER BY
	COUNT(visit_count) DESC
LIMIT 3;
-- Details of top 3 employees
SELECT
	employee_name,
    phone_number,
    email
FROM employee
WHERE assigned_employee_id IN (1,30,34);
/*Analysing locations
Records per towm*/
SELECT 
	town_name,
    COUNT(town_name) AS records_per_town
FROM location
GROUP BY
	town_name;
-- Records per province
SELECT *
FROM location;
SELECT 
	province_name,
    COUNT(province_name) AS records_per_province
FROM location
GROUP BY
	province_name;
-- Rural provinces
SELECT 
	province_name,
    location_type,
    COUNT(province_name) AS records_per_province
FROM location
GROUP BY
	province_name, location_type
HAVING location_type ='Rural';
-- Records per town sorted based on town and province
SELECT
	province_name,
    town_name,
    COUNT(town_name) AS records_per_town
FROM location
GROUP BY
	province_name, 
    town_name
ORDER BY
	province_name, records_per_town DESC;
-- Number of sources per location type
SELECT
	location_type,
    COUNT(location_type) AS num_sources
FROM location
GROUP BY 
	location_type
ORDER BY  num_sources DESC;

-- Percentage rural location
SELECT 
	ROUND(23740/(23740 + 15910) *100);
    
SELECT * FROM md_water_services.water_source;
SELECT 
	SUM(number_of_people_served) AS total_people_served
FROM water_source;
SELECT
	type_of_water_source,
	COUNT(type_of_water_source)  AS number_of_sources
FROM water_source
GROUP BY type_of_water_source
ORDER BY number_of_sources DESC;

SELECT
	type_of_water_source,
	ROUND(AVG(number_of_people_served))  AS ave_people_per_source
FROM water_source
GROUP BY type_of_water_source
ORDER BY ave_people_per_source DESC;

SELECT
	type_of_water_source,
	ROUND(SUM(number_of_people_served))  AS population_served
FROM water_source
GROUP BY type_of_water_source
ORDER BY population_served DESC;

SELECT
	type_of_water_source,
	ROUND(SUM(number_of_people_served) /27628140 * 100)  AS population_served
FROM water_source
GROUP BY type_of_water_source
ORDER BY population_served DESC;

-- Ranking each type of source based on the total number of people that use it
SELECT
	type_of_water_source,
	ROUND(SUM(number_of_people_served))  AS population_served,
    RANK() OVER(
    ORDER BY ROUND(SUM(number_of_people_served)) DESC) AS rank_by_population
FROM water_source
WHERE type_of_water_source <> 'tap_in_home'
GROUP BY type_of_water_source;
-- Rank by priority
SELECT
	source_id,
    type_of_water_source,
	number_of_people_served,
    DENSE_RANK() OVER(
    PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS priority_rank
FROM water_source
WHERE type_of_water_source <> 'tap_in_home'
ORDER BY priority_rank DESC;
-- Duration of survey
SELECT
DATEDIFF(MAX(time_of_record), MIN(time_of_record)) AS survey_duration
FROM visits;
-- Average queue time in Maji Ndog
SELECT
	ROUND(AVG(NULLIF(time_in_queue,0)))
FROM visits;
-- Average queue times on different days
SELECT
	DAYNAME(time_of_record) AS day_of_week,
    ROUND(AVG(NULLIF(time_in_queue,0))) AS avg_queue_time
FROM visits
GROUP BY
	day_of_week;
-- Time during the day people collect water
SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
ROUND(AVG(NULLIF(time_in_queue,0))) AS avg_queue_time
FROM visits
GROUP BY hour_of_day;
-- Creating a pivot table
SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
DAYNAME(time_of_record),
CASE
WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
ELSE NULL
END AS Sunday
FROM
visits
WHERE
time_in_queue != 0; -- this exludes other sources with 0 queue times.
-- Aggregating a Pivot Table...
SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
-- Sunday
ROUND(AVG(
CASE
	WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
	ELSE NULL
END
)) AS Sunday,
-- Monday
ROUND(AVG(
CASE
	WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
	ELSE NULL
END
),0) AS Monday,
-- Tuesday
ROUND(AVG(
CASE
	WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
	ELSE NULL
END
),0) AS Tuesday,
-- Wednesday
ROUND(AVG(
CASE
	WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
	ELSE NULL
END
),0) AS Wednesday,
-- Thursday
ROUND(AVG(
CASE
	WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
	ELSE NULL
END
),0) AS Thursday,
-- Friday
ROUND(AVG(
CASE
	WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
	ELSE NULL
END
),0) AS Friday,
-- Saturday
ROUND(AVG(
CASE
	WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
	ELSE NULL
END
),0) AS Saturday
FROM
visits
WHERE
time_in_queue <> 0 -- this excludes other sources with 0 queue times
GROUP BY
hour_of_day
ORDER BY
hour_of_day;
