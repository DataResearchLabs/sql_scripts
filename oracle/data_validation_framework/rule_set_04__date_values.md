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


