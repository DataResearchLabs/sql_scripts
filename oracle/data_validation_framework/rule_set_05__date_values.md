# Rule Set #5 - Date Values
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

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


