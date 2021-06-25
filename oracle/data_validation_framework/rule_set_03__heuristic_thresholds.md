# Rule Set #3 - Heuristic Thresholds (Column Null Rates & Value Rates)
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

## Table of Contents
 - <a href="#t008">T008 - Null Rate Thresholds</a>
 - <a href="#t009">T009 - Value Rate Thresholds</a>
<br>


<a id="t008" class="anchor" href="#t008" aria-hidden="true"> </a>
### T008 - Null Rate Thresholds
Sure, good database design implies that unique keys be enforced by a constraint so that you do not need to test for it.  However, there are times where a decision is made to **not** add a constraint to enforce the unique key (e.g.: table is replicated from a source having the constraint so skipped for performance).  This does happen!  At work just last week, two of my data vbalidation regression tests for unique keys started failing -- and without these checks the downstream defects would have taken longer to notice, and more time to identify the root cause.
In the example below, the inner query does a group by on the unique key fields, then using a HAVING clause filters down to those key-values with a count of more than 1 -- the dups.  The outer query returns a fail if any rows come back with dups (match_count >= 2), or a pass if no dups found.
 ```sql
SELECT CASE WHEN nr_dept_nm  > 0.0000 THEN 'REJ-01: Null rate too high at department_name.  Exp=0.0000 / Act=' || CAST(nr_dept_nm AS VARCHAR2(8))
             WHEN nr_mgr_id   > 0.6500 THEN 'REJ-02: Null rate too high at manager_id.  Exp<=0.6500 / Act=' || CAST(nr_mgr_id AS VARCHAR2(8))
             WHEN nr_url      > 0.8000 THEN 'REJ-03: Null rate too high at url.  Exp<=0.8000 / Act=' || CAST(nr_url AS VARCHAR2(8))
             ELSE 'P'
       END AS status
FROM (
  SELECT CAST(SUM(CASE WHEN department_name IS NULL THEN 1 ELSE 0 END) AS FLOAT(126)) / CAST(COUNT(*) AS FLOAT(126)) AS nr_dept_nm
       , CAST(SUM(CASE WHEN manager_id      IS NULL THEN 1 ELSE 0 END) AS FLOAT(126)) / CAST(COUNT(*) AS FLOAT(126)) AS nr_mgr_id
       , CAST(SUM(CASE WHEN url             IS NULL THEN 1 ELSE 0 END) AS FLOAT(126)) / CAST(COUNT(*) AS FLOAT(126)) AS nr_url
  FROM demo_hr.departments
);
```
<br>


