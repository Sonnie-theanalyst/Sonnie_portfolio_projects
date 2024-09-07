SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score,
visits.location_id AS visit_location,
visits.record_id
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality AS wq
ON visits.record_id = wq.record_id;

SELECT
auditor_report.location_id AS location_id,
visits.record_id,
auditor_report.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality AS wq
ON visits.record_id = wq.record_id
WHERE 
wq.subjective_quality_score = auditor_report.true_water_source_score
AND visits.visit_count =1;




/*Employees that made incorrect records*/
SELECT
	auditor_report.location_id AS location_id,
	visits.record_id,
	employee.employee_name,
	auditor_report.true_water_source_score AS auditor_score,
	water_quality.subjective_quality_score AS surveyor_score
FROM 
	auditor_report   
JOIN
	visits
	ON auditor_report.location_id = visits.location_id
JOIN
	water_quality
  ON visits.record_id = water_quality.record_id
JOIN
	employee
ON visits.assigned_employee_id = employee.assigned_employee_id
WHERE NOT
	auditor_report.true_water_source_score = water_quality.subjective_quality_score
	AND visits.visit_count = 1; 

-- Expressing employees that made incorrect records as CTE
WITH Incorrect_records AS
						(SELECT
							auditor_report.location_id AS location_id,
							visits.record_id,
							employee.employee_name,
							auditor_report.true_water_source_score AS auditor_score,
							water_quality.subjective_quality_score AS surveyor_score
						FROM 
							auditor_report   
						JOIN
							visits
							ON auditor_report.location_id = visits.location_id
						JOIN
							water_quality
							ON visits.record_id = water_quality.record_id
						JOIN
							employee
							ON visits.assigned_employee_id = employee.assigned_employee_id
						WHERE NOT
							auditor_report.true_water_source_score = water_quality.subjective_quality_score
							AND visits.visit_count = 1)
SELECT *
FROM Incorrect_records;

-- Error count
WITH Incorrect_records AS
						(SELECT
							auditor_report.location_id AS location_id,
							visits.record_id,
							employee.employee_name,
							auditor_report.true_water_source_score AS auditor_score,
							water_quality.subjective_quality_score AS surveyor_score
						FROM 
							auditor_report   
						JOIN
							visits
							ON auditor_report.location_id = visits.location_id
						JOIN
							water_quality
							ON visits.record_id = water_quality.record_id
						JOIN
							employee
							ON visits.assigned_employee_id = employee.assigned_employee_id
						WHERE NOT
							auditor_report.true_water_source_score = water_quality.subjective_quality_score
							AND visits.visit_count = 1)
SELECT DISTINCT 
	employee_name,
    COUNT(employee_name) AS number_of_mistakes
FROM Incorrect_records
GROUP BY
	employee_name;
    
-- Saving the error count of the employees as a View
CREATE VIEW
	Incorrect_records AS
SELECT
	auditor_report.location_id AS location_id,
    visits.record_id,
    employee.employee_name,
	auditor_report.true_water_source_score AS auditor_score,
	water_quality.subjective_quality_score AS surveyor_score,
	auditor_report.statements AS Statements
FROM
	auditor_report   
JOIN
	visits
	ON auditor_report.location_id = visits.location_id
JOIN							
	water_quality
	ON visits.record_id = water_quality.record_id
JOIN
	employee
	ON visits.assigned_employee_id = employee.assigned_employee_id
WHERE NOT
	auditor_report.true_water_source_score = water_quality.subjective_quality_score
	AND visits.visit_count = 1;
SELECT *
FROM incorrect_records;

-- Rewriting error count using the incorrect records view and saving as a CTE
WITH error_count AS ( -- This CTE calculated the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
/* Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different*/
GROUP BY
employee_name)
-- Query
SELECT 
	AVG(number_of_mistakes)
FROM error_count;




WITH 
error_count AS ( -- This CTE calculated the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
/* Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different*/
GROUP BY
employee_name),
--  Suspect list as the number of mistakes of these employees are above average
Suspect_list AS
(SELECT 
	employee_name,
    number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT 
							AVG(number_of_mistakes) 
							FROM error_count))
SELECT *
FROM Suspect_list;
                            
                            
WITH Incorrect_records AS
						(SELECT
							auditor_report.location_id AS location_id,
							visits.record_id,
							employee.employee_name,
							auditor_report.true_water_source_score AS auditor_score,
							water_quality.subjective_quality_score AS surveyor_score,
                            auditor_report.statements AS Statements
						FROM 
							auditor_report   
						JOIN
							visits
							ON auditor_report.location_id = visits.location_id
						JOIN
							water_quality
							ON visits.record_id = water_quality.record_id
						JOIN
							employee
							ON visits.assigned_employee_id = employee.assigned_employee_id
						WHERE NOT
							auditor_report.true_water_source_score = water_quality.subjective_quality_score
							AND visits.visit_count = 1),
error_count AS ( -- This CTE calculated the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
/* Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different*/
GROUP BY
employee_name),
--  Suspect list as the number of mistakes of these employees are above average
Suspect_list AS
(SELECT 
	employee_name,
    number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT 
							AVG(number_of_mistakes) 
							FROM error_count))
SELECT 
	employee_name,
	location_id,
    Statements
FROM incorrect_records
WHERE employee_name IN (SELECT employee_name FROM suspect_list)
AND Statements LIKE '%cash%';

suspect_list AS (
    SELECT ec1.employee_name, 
    ec1.number_of_mistakes
    FROM error_count  ec1
    WHERE ec1.number_of_mistakes >= (
        SELECT AVG(ec2.number_of_mistakes)
        FROM error_count ec2
        WHERE ec2.employee_name = ec1.employee_name))