### Data Validation Examples - MS SQL Server
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
#### [Return to Data Validation Home Page](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_validation_scripts.md)
<br>

# Rule Set #4 - Numeric Values

## Table of Contents
 - <a href="#t010">T010 - Not Null</a>
 - <a href="#t011">T011 - Not Negative</a>
 - <a href="#t012">T012 - Numeric Range</a>
 - <a href="#t013">T013 - In Value List</a>
 - <a href="#t014">T014 - Not In Value List</a>
 - <a href="#t015">T015 - Multi Field Compare</a>
<br>


<a id="t010" class="anchor" href="#t010" aria-hidden="true"> </a>
### T010 - Not Null
Verify numeric field is not null.  For example, to verify that table countries has no NULLs in field region_id:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM demo_hr..countries
WHERE region_id IS NULL;
```
<br>


<a id="t011" class="anchor" href="#t011" aria-hidden="true"> </a>
### T011 - Not Negative
Verify numeric field is not negative.  For example, to verify that table countries has no field region_id negative values:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM demo_hr..countries
WHERE region_id < 0;
```
<br>


<a id="t012" class="anchor" href="#t012" aria-hidden="true"> </a>
### T012 - Numeric Range
Verify numeric field value is within a range.  In the example below, we verify that field employee_id is between 100 and 999 in table employees.  Note that you can run the inner query yourself to return the actual rejection code (is too low or too high) along with the actual value and the expected value...all nicely packaged for easy troubleshooting.
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT employee_id
  , CASE WHEN employee_id < 100   THEN 'REJ-01: Verify employee_id > 99|exp>99|act=' + CAST(employee_id AS VARCHAR(10))
         WHEN employee_id > 999   THEN 'REJ-02: Verify employee_id < 1000|exp<1000|act=' + CAST(employee_id AS VARCHAR(10))
         ELSE 'P'
    END AS status
   FROM demo_hr..employees
) t
WHERE status <> 'P';
```
<br>


<a id="t013" class="anchor" href="#t013" aria-hidden="true"> </a>
### T013 - In Value List
Verify numeric field is **in** the list of values.  For example, to verify that table countries field region_id is always values 1, 2, 3, or 4 we use the IN() clause as shown below:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT region_id
  , CASE WHEN region_id NOT IN(1,2,3,4) THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..countries
) t
WHERE status <> 'P';
```
<br>


<a id="t014" class="anchor" href="#t014" aria-hidden="true"> </a>
### T014 - Not In Value List
Verify numeric field is **not** in the list of values.  For example, to verify that table countries field region_id is never in values 97, 98, or 99 we use the NOT IN() clauses as shown below:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT region_id
  , CASE WHEN region_id IN(97,98,99) THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..countries
) t
WHERE status <> 'P';
```
<br>


<a id="t015" class="anchor" href="#t015" aria-hidden="true"> </a>
### T015 - Multi Field Compare
Verify numeric field values in relation to one another.  For example, to verify that salary times commission_pct is always less than $10,000 in table employees:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT salary, commission_pct
  , CASE WHEN salary * commission_pct > 10000 THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
WHERE status <> 'P';
```
<br>
