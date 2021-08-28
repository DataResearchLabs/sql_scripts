### Data Validation Examples - MySQL
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
#### [Return to Data Validation Home Page](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_validation_scripts.md)

# Rule Set #3 - Heuristic Thresholds (Column Null Rates & Value Rates)


## Table of Contents
 - <a href="#t008">T008 - Null Rate Thresholds</a>
 - <a href="#t009">T009 - Value Frequency Thresholds</a>

Note: Although the terms "rate" and "frequency" are mostly synonomous, nulls are usually referred to as "rates" and values as "frequencies".  Don't know why, but following the convention I've heard over and over.
<br>


<a id="t008" class="anchor" href="#t008" aria-hidden="true"> </a>
### T008 - Null Rate Thresholds
There is a lot going on in this "Null Rate Threshold" data validation query below.  The basic goal is to validate that a given table's columns do not have too many, or too few NULLs.  
<details>
<summary>In the example below...</summary><br>
...we are checking columns department_name, manager_id, and url in the table departments.  We want to ensure that column department_name has no NULLs, and that column manager_id is NULL less than 65% of the time and column url is NULL less than 80% of the time.  
 
This check is like the proverbial miner's canary in that it is a trip wire triggered when something goes awry in a data feed.  I've used this test scenario to great effect when coupled with a create-date or last-updated-date to monitor the past week's data loads for any unexpected upticks in null rates.  

There is a downside to this test scenario too however; and that is when it fires false alarms and you find yourself tinkering with the thresholds values (0.0000, 0.65000, and 0.80000 cutoffs below), raising and lowering them over and over.  If this happens,  chances are test fails are not actionable nor important and you should not waste your time applying this test scenario to that given table and field.  Be careful to only pick fields that truly matter.

Below, there is an upper CTE (common table expression) named "dtls" at the WITH clause, and a lower wrapper that applies the business logic (if any null rate rejections were found, fail the case).  Inside the dtls CTE, there is an inner query at the bottom (at the FROM clause) doing a single table scan to calculate a null rate per column by counting nulls in each column and dividing by the total table row count.  The SELECT CASE logic at the top applies the business logic; comparing the actual calcuated null rates (nr_dept_nm, nr_mgr_id, and nr_url) against the expected threshold rates (hard-coded as 0.0000, 0.6500, and 0.8000).  The returned value is a rejection code (REJ-01, REJ-02, etc.) clearly indicating which field failed the null rate check, what the actual null rate was, and what the expected null rate threshold to exceed was.  If no rejections are triggered, then status returns a "P" for pass.
</details>
 
```sql
WITH dtls AS (
  SELECT CASE WHEN nr_dept_nm > 0.0000 THEN CONCAT('REJ-01: Null rate too high at department_name|exp=0.0000|act=', CAST(nr_dept_nm AS CHAR(8)) )
              WHEN nr_mgr_id  > 0.6500 THEN CONCAT('REJ-02: Null rate too high at manager_id|exp<=0.6500|act=', CAST(nr_mgr_id AS CHAR(8)) )
              WHEN nr_url     > 0.8000 THEN CONCAT('REJ-03: Null rate too high at url|exp<=0.8000|act=', CAST(nr_url AS CHAR(8)) )
              ELSE 'P'
         END AS status
  FROM (
    SELECT CAST(SUM(CASE WHEN department_name IS NULL THEN 1 ELSE 0 END) AS DECIMAL(10, 5)) / CAST(COUNT(*) AS DECIMAL(10, 5)) AS nr_dept_nm
    , CAST(SUM(CASE WHEN manager_id      IS NULL THEN 1 ELSE 0 END) AS DECIMAL(10, 5)) / CAST(COUNT(*) AS DECIMAL(10, 5)) AS nr_mgr_id
    , CAST(SUM(CASE WHEN url             IS NULL THEN 1 ELSE 0 END) AS DECIMAL(10, 5)) / CAST(COUNT(*) AS DECIMAL(10, 5)) AS nr_url
    FROM demo_hr.departments
  ) t
)
    
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status 
FROM dtls 
WHERE status <> 'P';
```
<br>


<a id="t009" class="anchor" href="#t009" aria-hidden="true"> </a>
### T009 - Value Frequency Thresholds
"Value Frequency Threshold" tests are fairly similar to null rates above (T008).  The difference is that we are checking the frequency (or rate) at which a column's values occur.
<details>
<summary>In the example below...</summary><br>
...we are checking the frequencies with which the values 1, 2, 3, and 4 occur in field region_id of table countries.  There is an upper CTE (common table expression) named "dtls" at the WITH clause, and a lower wrapper that applies the business logic (if any value frequency rejections were found, fail the case).  Inside the dtls CTE, there is an inner query at the bottom (at the FROM clause) doing a single table scan to calculate a frequencies for each value in the GROUP BY for the column.  It the GROUP BY value count (field "freq") is divided by the total table row count (field "den") to calculate field "freq_rt".  The SELECT CASE logic at the top applies the business logic; comparing the actual value frequencies (freq_rt when region_id = 1, or =2, etc.) against the expected threshold frequencies (hard-coded as 0.28 to 0.36, 016 to 0.24 and so on).  The returned value is a rejection code (REJ-01, REJ-02, etc.) clearly indicating which field failed the value ferquency check, what the actual value frequency was, and what the expected value frequency threshold ranges were.  If no rejections are triggered, then status returns a "P" for pass.
</details>
 
```sql
WITH dtls AS (
  SELECT region_id, freq_rt
  , CASE WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.28 AND 0.36 THEN CONCAT('REJ-01: Frequency occurrence of region_id=1 is outside threshold|exp=0.28 thru 0.36|act=' , CAST(freq_rt AS CHAR(8)))
         WHEN region_id = 2  AND freq_rt NOT BETWEEN 0.16 AND 0.24 THEN CONCAT('REJ-02: Frequency occurrence of region_id=2 is outside threshold|exp=0.16 thru 0.24|act=' , CAST(freq_rt AS CHAR(8)))
         WHEN region_id = 3  AND freq_rt NOT BETWEEN 0.20 AND 0.28 THEN CONCAT('REJ-03: Frequency occurrence of region_id=3 is outside threshold|exp=0.20 thru 0.28|act=' , CAST(freq_rt AS CHAR(8)))
         WHEN region_id = 4  AND freq_rt NOT BETWEEN 0.20 AND 0.28 THEN CONCAT('REJ-04: Frequency occurrence of region_id=4 is outside threshold|exp=0.20 thru 0.28|act=' , CAST(freq_rt AS CHAR(8)))
         ELSE 'P'
    END AS status
  FROM (
    SELECT region_id, CAST(freq AS FLOAT) / CAST(den AS FLOAT) AS freq_rt
    FROM (
      SELECT region_id, COUNT(*) AS freq
      , (SELECT COUNT(*) FROM demo_hr.countries) AS den
      FROM demo_hr.countries
      GROUP BY region_id
    ) t
  ) t2
)

SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status 
FROM dtls 
WHERE status <> 'P';
```
