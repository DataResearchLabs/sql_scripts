# Rule Set #2 - Keys (Foreign & Unique)
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

## Table of Contents
 - <a href="#t005">T005 - Unique (Native) Key Has No Duplicates</a>
 - <a href="#t006">T006 - Foreign Key Has No Orphans</a>
 - <a href="#t007">T007 - Foreign Key Has Children</a>
<br>


<a id="t005" class="anchor" href="#t005" aria-hidden="true"> </a>
### T005 - Unique Key Has No Fuplicates
Verify full row count for a table or view.  For example, to verify that table countries has exactly 25 rows:
 ```sql
SELECT CASE WHEN COUNT(*) <> 25 THEN 'FAIL' ELSE 'P' END AS status 
FROM demo_hr.countries;
 ```
<br>
