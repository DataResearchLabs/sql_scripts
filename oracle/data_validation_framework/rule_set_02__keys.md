# Rule Set #2 - Keys (Foreign & Unique)
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

## Table of Contents
 - <a href="#t005">T005 - Unique (Native) Key Has No Duplicates</a>
 - <a href="#t006">T006 - Foreign Key Child Is An Orphans</a>
 - <a href="#t007">T007 - Foreign Key Parent Has No Children</a>
<br>


<a id="t005" class="anchor" href="#t005" aria-hidden="true"> </a>
### T005 - Unique Key Has No Duplicates
Sure, good database design implies that unique keys be enforced by a constraint so that you do not need to test for it.  However, there are times where a decision is made to **not** add a constraint to enforce the unique key (e.g.: table is replicated from a source having the constraint so skipped for performance).  This does happen!  At work just last week, two of my data vbalidation regression tests for unique keys started failing -- and without these checks the downstream defects would have taken longer to notice, and more time to identify the root cause.
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


<a id="t006" class="anchor" href="#t006" aria-hidden="true"> </a>
### T006 - Foreign Key Child is An Orphan
Sure, as with T005 UKeys above, good database design implies that foreign keys be enforced by a constraint so that you do not need to test for it.  However, there are times where for whatever reason the constraints do not exist.  In those instances, you will want to periodically run a data validation test to ensure that this core assumption is not being violated (of course adding a foreign key constraint would be best, but if that is not an option then periodically check).
In the example below, the inner query pulls from the child table countries as the anchor, then left joins out to the parent table regions on the key field region_id. If region_id does not exist in the parent table (p.region_id IS NULL), then the child region_id is an orphan.  The outer query checks the count() of orphaned child rows: if it is >= 1 then the test fails, but if the count() = 0 then it passes.
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT DISTINCT c.region_id AS child_id, p.region_id AS parent_id
  FROM      demo_hr.countries c 
  LEFT JOIN demo_hr.regions   p  ON p.region_id = c.region_id
  WHERE p.region_id IS NULL
);
 ```
<br>


<a id="t007" class="anchor" href="#t007" aria-hidden="true"> </a>
### T007 - Foreign Key Parent Has No Children
Sure, as
