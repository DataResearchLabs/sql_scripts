### Data Validation Examples - Oracle
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
#### [Return to Data Validation Home Page](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_validation_scripts.md)
<br>

# Rule Set #5 - Date Values

## Table of Contents
 - <a href="#t016">T016 - Not Null</a>
 - <a href="#t017">T017 - Date Range</a>
 - <a href="#t018">T018 - No Time Part</a>
 - <a href="#t019">T019 - Has Time Part</a>
 - <a href="#t020">T020 - Multi Field Compare</a>
<br>


<a id="t016" class="anchor" href="#t016" aria-hidden="true"> </a>
### T016 - Not Null
Verify date field is not null.  For example, to verify that table countries has no NULLs in field date_last_updated:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN date_last_updated IS NULL THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.countries
)
WHERE status <> 'P';
```
<br>


<a id="t017" class="anchor" href="#t017" aria-hidden="true"> </a>
### T017 - Date Range
Verify date field is within specified range.  For example, you can run the sql below to verify that table countries field date_last_updated is between 1/1/2021 and today.  Note the use of SYSDATE to represent today's date dynamically in Oracle.  Notice the inner query uses a CASE...WHEN...ELSE structure to identify two rejections codes: (1) date is too high, and (2) date is too low.  Expected and actual values are displayed in the output if you run the inner query only.  The outer query is a wrapper to determine whether the test passed or failed.
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN date_last_updated > SYSDATE                             THEN 'REJ-01: Field date_last_updated cannot be in the future|exp<=' || CAST(SYSDATE AS VARCHAR2(20)) || '|act=' || CAST(date_last_updated AS VARCHAR2(20))
              WHEN date_last_updated < TO_DATE('01/01/2021', 'mm/dd/yyyy') THEN 'REJ-02: Field date_last_updated cannot be too old|exp>=1/1/2021|act=' || CAST(date_last_updated AS VARCHAR2(20))
              ELSE 'P'
         END AS status
  FROM demo_hr.countries
)
WHERE status <> 'P';
```
<br>


<a id="t018" class="anchor" href="#t018" aria-hidden="true"> </a>
### T018 - No Time Part
Verify date field is a date only, no time part present.  For example, to verify that table employees has no time part in field hire_date (time part must be "12:00:00"):
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN TO_CHAR(hire_date, 'hh:mi:ss') <> '12:00:00' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


<a id="t019" class="anchor" href="#t019" aria-hidden="true"> </a>
### T019 - Has Time Part
Verify date field is a date **and** time.  For example, to verify that table employees has a time part in field hire_date (time part cannot be "12:00:00"):
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN TO_CHAR(start_tm, 'hh:mi:ss') = '12:00:00' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.test_case_results
)
WHERE status <> 'P';
```
<br>


<a id="t020" class="anchor" href="#t020" aria-hidden="true"> </a>
### T020 - Multi Field Compare
Verify multiple date fields relative to each other.  For example, to verify that field start_date must be < field end_date in table job_history (thus if start_date is >= end_date the test case fails):
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN start_date >= end_date THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.job_history
)
WHERE status <> 'P';
```
<br>
