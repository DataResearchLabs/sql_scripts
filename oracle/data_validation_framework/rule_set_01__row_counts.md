# Data Validation Examples - Oracle
## Rule Set #1 - Row Counts
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)

## Introduction
Some of the most common data validation checks involve row counts.  Total row counts for a table, partial row counts of some subset of a table, relative row counts between tables, and recent row counts are a few examples displayed below.


## T001 - "RS-1 Row Counts" #1 - Verify FullRowCount() = 25 at table [countries]

```sql
SELECT CASE WHEN COUNT(*) <> 8 THEN 'FAIL' ELSE 'P' END AS status   
FROM demo_hr.countries
WHERE region_id = 1;
```

## T002 - "RS-1 Row Counts" #2 - Verify PartialRowCount() = 8 where [region_id] = 1 (Europe) in table [countries]

```sql
SELECT CASE WHEN COUNT(*) <> 8 THEN 'FAIL' ELSE 'P' END AS status   
FROM demo_hr.countries
WHERE region_id = 1;
```


