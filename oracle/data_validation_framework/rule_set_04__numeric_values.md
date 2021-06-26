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


