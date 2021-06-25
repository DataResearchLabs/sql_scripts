# Rule Set #1 - Row Counts
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

### Overview
Some of the most common data validation tests involve row counts:
* T001 - Verify full row count for a table or view
* T002 - Verify partial row count for a subset of a table or view
* T003 - Verify relative row counts between tables or views
* T004 - Verify recent row counts
<br>


### T001 - Verify FullRowCount() 
<details>
  <summary>Oracle</summary>

  ```sql
  -- "RS-1 Row Counts" #1 - Verify FullRowCount() = 25 at table [countries]
  SELECT CASE WHEN COUNT(*) <> 25 THEN 'FAIL' ELSE 'P' END AS status 
  FROM demo_hr.countries;
  ```
</details>
<br>


### T002 - Verify PartialRowCount()
```sql
  -- "RS-1 Row Counts" #2 - Verify PartialRowCount() = 8 where [region_id] = 1 (Europe) in table [countries]
  SELECT CASE WHEN COUNT(*) <> 8 THEN 'FAIL' ELSE 'P' END AS status   
  FROM demo_hr.countries
  WHERE region_id = 1;
```
<br>


### T003 - Verify RelativeRowCount()
```sql
  -- "RS-1 Row Counts" #3 - Verify RelativeRowCount() table [countries] row count >= 5x table [regions] row count
  SELECT CASE WHEN countries_count < 5 * regions_count THEN 'FAIL' ELSE 'P' END AS status
  FROM (
    SELECT (SELECT COUNT(*) AS row_count FROM demo_hr.countries) AS countries_count 
    , (SELECT COUNT(*) AS row_count FROM demo_hr.regions)   AS regions_count
    FROM dual
  );
```
<br>


### T004 - Verify RecentRowCount()
```sql
  -- "RS-1 Row Counts" #4 - Verify RecentRowCount() >= 5 in table [countries] where [date_last_updated] in past
  SELECT CASE WHEN row_count < 5 THEN 'FAIL' ELSE 'P' END AS status
  FROM (
    SELECT COUNT(*) AS row_count 
    FROM demo_hr.countries
    WHERE date_last_updated >= SYSDATE - 10
  );
```



