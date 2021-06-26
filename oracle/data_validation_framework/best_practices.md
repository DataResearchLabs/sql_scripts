# Best Practices
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

## Table of Contents
 - <a href="#t062">T062 - Use Status "WARN" and "SKIP"</a>
 - <a href="#t063">T063 - Limit to Recent Data</a>
 - <a href="#t064">T064 - "Teach" to Ignore Bad Rows</a>
 - <a href="#t065">T065 - Single Large Tablescan for Performance</a>
 - <a href="#t066">T066 - Use Config Tables</a>
<br>


<a id="t001" class="anchor" href="#t001" aria-hidden="true"> </a>
### T001 - "Full" Row Count
Verify full row count for a table or view.  For example, to verify that table countries has exactly 25 rows:
 ```sql
SELECT CASE WHEN COUNT(*) <> 25 THEN 'FAIL' ELSE 'P' END AS status 
FROM demo_hr.countries;
 ```
<br>


