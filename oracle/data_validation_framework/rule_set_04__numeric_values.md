# Rule Set #4 - Numeric Values
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

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
FROM demo_hr.countries
WHERE region_id IS NULL;
```
<br>

<a id="t011" class="anchor" href="#t011" aria-hidden="true"> </a>
### T011 - Not Negative
Verify numeric field is not negative.  For example, to verify that table countries has no field region_id negative values:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM demo_hr.countries
WHERE region_id < 0;
```
<br>


<a id="t012" class="anchor" href="#t012" aria-hidden="true"> </a>
### T012 - Numeric Range
Verify numeric field value is within a range.  For example, to verify that field employee_id is between 100 and 999 in table employees:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN employee_id < 100   THEN 'REJ-01: Verify employee_id > 99|exp>99|act=' || CAST(employee_id AS VARCHAR2(10))
              WHEN employee_id > 999   THEN 'REJ-02: Verify employee_id < 1000|exp<1000|act=' || CAST(employee_id AS VARCHAR2(10))
              ELSE 'P'
         END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>

