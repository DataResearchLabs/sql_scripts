# Rule Set #1 - Row Counts
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

## Table of Contents
 - <a href="#t001">T001 - "Full" Row Count</a>
 - <a href="#t002">T002 - "Partial" Row Count</a>
 - <a href="#t003">T003 - "Relative" Row Count</a>
 - <a href="#t004">T004 - "Recent" Row Count</a>
<br>


<a id="t001" class="anchor" href="#t001" aria-hidden="true"> </a>
### T001 - "Full" Row Count
Verify full row count for a table or view.  For example, to verify that table countries has exactly 25 rows:
 ```sql
SELECT CASE WHEN COUNT(*) <> 25 THEN 'FAIL' ELSE 'P' END AS status 
FROM demo_hr.countries;
 ```
<br>


<a id="t002" class="anchor" href="#t002" aria-hidden="true"> </a>
### T002 - "Partial" Row Count
Verify partial row count for a subset of a table or view.  For example, to verify that table countries has exactly 8 rows where region_id = 1 (Europe):
```sql
SELECT CASE WHEN COUNT(*) <> 8 THEN 'FAIL' ELSE 'P' END AS status   
FROM demo_hr.countries
WHERE region_id = 1;
```
<br>


<a id="t003" class="anchor" href="#t003" aria-hidden="true"> </a>
### T003 - "Relative" Row Count
Verify relative row counts between tables or views.  For example, to verify that table countries has at least 5 times the number of rows as table regions:
```sql
SELECT CASE WHEN countries_count < 5 * regions_count THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT (SELECT COUNT(*) AS row_count FROM demo_hr.countries) AS countries_count 
       , (SELECT COUNT(*) AS row_count FROM demo_hr.regions)   AS regions_count
  FROM dual
);
```
<br>


<a id="t004" class="anchor" href="#t004" aria-hidden="true"> </a>
### T004 - "Recent" Row Count
Verify recent row counts.  For example, to verify that table countries has had at least 5 rows updated in the past 10 days based on the date stamp in field date_last_updated:
```sql
SELECT CASE WHEN row_count < 5 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT COUNT(*) AS row_count 
  FROM demo_hr.countries
  WHERE date_last_updated >= SYSDATE - 10
);
```



