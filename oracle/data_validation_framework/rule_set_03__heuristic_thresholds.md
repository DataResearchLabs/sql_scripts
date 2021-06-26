# Rule Set #3 - Heuristic Thresholds (Column Null Rates & Value Rates)
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

## Table of Contents
 - <a href="#t008">T008 - Null Rate Thresholds</a>
 - <a href="#t009">T009 - Value Frequency Thresholds</a>
<br>


Note: Although the terms "rate" and "frequency" are mostly synonomous, nulls are usually referred to as "rates" and values as "frequencies".  Don't know why, but following the convention I've heard over and over.
<br>


<a id="t008" class="anchor" href="#t008" aria-hidden="true"> </a>
### T008 - Null Rate Thresholds
There is a lot going on in this "Null Rate Threshold" data validation query below.  The basic goal is to validate that a given table's columns do not have too many, or too few NULLs.  
<details>
<summary>Click here for more...</summary>
In the example below, we are checking columns department_name, manager_id, and url in the table departments.  We want to ensure that column department_name has no NULLs, and that column manager_id is NULL less than 65% of the time and column url is NULL less than 80% of the time.  This check is like the proverbial canary in the mine in that it is a trip wire triggered when something goes awry in a data feed.  
I've used this test scenario to great effect when coupled with a create-date or last-updated-date to monitor the past week's data loads for any unexpected upticks in null rates.  There is a downside to this test scenario too, and that is when it fires but then you learn it is a false alarm and the threshold just needs to be increased or decreased.  If you find yourself tinkering with the thresholds values (ilke 0.0000, 0.65000, and 0.80000 cutoffs below), then chances are that it is not important when the test Fails and you should not waste your time applying this test scenario to that given table and field.  Be careful when using this to only pick fields that truly matter.
Below, the inner query at the bottom is doing a single table scan to calculate a null rate per column by counting nulls in each column and dividing by the total table row count.  The outer query (wrapper at the top) applies the business logic; comparing the actual calcuated null rates (nr_dept_nm, nr_mgr_id, and nr_url) against the expected threshold rates (hard-coded as 0.0000, 0.6500, and 0.8000).  The returned value is a rejection code (REJ-01, REJ-02, etc.) clearly indicating which field failed the null rate check, what the actual null rate was, and what the expected null rate threshold to exceed was.
</details>
 
```sql
WITH dtls AS (
  SELECT CASE WHEN nr_dept_nm  > 0.0000 THEN 'REJ-01: Null rate too high at department_name.  Exp=0.0000 / Act=' || CAST(nr_dept_nm AS VARCHAR2(8))
              WHEN nr_mgr_id   > 0.6500 THEN 'REJ-02: Null rate too high at manager_id.  Exp<=0.6500 / Act=' || CAST(nr_mgr_id AS VARCHAR2(8))
              WHEN nr_url      > 0.8000 THEN 'REJ-03: Null rate too high at url.  Exp<=0.8000 / Act=' || CAST(nr_url AS VARCHAR2(8))
              ELSE 'P'
         END AS status
  FROM (
    SELECT CAST(SUM(CASE WHEN department_name IS NULL THEN 1 ELSE 0 END) AS FLOAT(126)) / CAST(COUNT(*) AS FLOAT(126)) AS nr_dept_nm
         , CAST(SUM(CASE WHEN manager_id      IS NULL THEN 1 ELSE 0 END) AS FLOAT(126)) / CAST(COUNT(*) AS FLOAT(126)) AS nr_mgr_id
         , CAST(SUM(CASE WHEN url             IS NULL THEN 1 ELSE 0 END) AS FLOAT(126)) / CAST(COUNT(*) AS FLOAT(126)) AS nr_url
    FROM demo_hr.departments
  )
)

SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status 
FROM dtls 
WHERE status <> 'P';
```
<br>


<a id="t009" class="anchor" href="#t009" aria-hidden="true"> </a>
### T009 - Value Frequency Thresholds
"Value Frequency Threshold" tests are fairly similar to null rates above (T008).  The difference is that we are checking the frequency (or rate) at which a column's values occur.

In the example below,
```sql
WITH dtls AS (
  SELECT CASE WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.28 AND 0.36 THEN 'REJ-01: Frequency occurrence of region_id=1 is outside threshold|exp=0.28 thru 0.36|act=' || CAST(freq_rt AS VARCHAR2(8))
              WHEN region_id = 2  AND freq_rt NOT BETWEEN 0.16 AND 0.24 THEN 'REJ-02: Frequency occurrence of region_id=2 is outside threshold|exp=0.16 thru 0.24|act=' || CAST(freq_rt AS VARCHAR2(8))
              WHEN region_id = 3  AND freq_rt NOT BETWEEN 0.20 AND 0.28 THEN 'REJ-03: Frequency occurrence of region_id=3 is outside threshold|exp=0.20 thru 0.28|act=' || CAST(freq_rt AS VARCHAR2(8))
              WHEN region_id = 4  AND freq_rt NOT BETWEEN 0.20 AND 0.28 THEN 'REJ-04: Frequency occurrence of region_id=4 is outside threshold|exp=0.20 thru 0.28|act=' || CAST(freq_rt AS VARCHAR2(8))
              ELSE 'P'
         END AS status
  FROM (
    SELECT region_id, CAST(freq AS FLOAT(126)) / CAST(den AS FLOAT(126)) AS freq_rt
    FROM (
      SELECT region_id, COUNT(*) AS freq
      , (SELECT COUNT(*) FROM demo_hr.countries) AS den
         FROM demo_hr.countries
         GROUP BY region_id
        )
    )
)

SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status 
FROM dtls 
WHERE status <> 'P';
```
