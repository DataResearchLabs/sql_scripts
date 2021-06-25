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
### T005 - Unique Key Has No Duplicates
Sure, good database design implies that unique keys be enforced by a constraint so that you do not need to test for it.  However, there are times for whatever reason (performance, replicated from a source that does have a constraint, etc.) where a natural key has not constraint.  At work last week, I just ran this test scenario (different tables and fields of course) and found dups where there absolutely should not be any--so it does happen.  
In the example below, the inner query does a group by on the unique key fields, then using a HAVING clause filters down to those key-values with a count of more than 1 -- the dups.  The outer query returns a fail if any rows come back with dups (match_count >= 2), or a pass if no dups found.
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT country_name             -- UKey fields separated by comma 
  , COUNT(*) AS match_count 
  FROM demo_hr.countries          -- UKey fields separated by comma
  GROUP BY country_name 
  HAVING COUNT(*) > 1
);
 ```
<br>



