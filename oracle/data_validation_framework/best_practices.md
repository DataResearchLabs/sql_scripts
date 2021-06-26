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


<a id="t062" class="anchor" href="#t062" aria-hidden="true"> </a>
### T062 - Use Status "WARN" and "SKIP"
This best practice revolves around the Status field that all these test cases have been calculating and returning.  Up to this point, all prior data validation tests (T001 thru t061 spanning multiple markdown .md files) have yield either "P" for pass, or "FAIL".

However, there is nothing stopping you from adding additional status values such as "WARN" or "SKIP" or even "BLOCK".

* In the SQL below, the first subquery (CTE) is titled "dut", short for data under test.  This simply calculates the frequency with which region_id = 1 occurs.
* The second subquery (CTE) is titles "bll", short for business logic layer.  This is where the magic happens.  Because CASE...WHEN logic is sequential, it is important that the highest severity checks are done first.  In this case, we check for the frequency being a FAIL because it is outside of the wide range 10% to 50%.  However, we come right back in the following WHEN statement and set the status to WARN if the frequency observed is outside of the narrower (than FAIL) range of 25% to 35%.  So as coded, a WARN is issue when the actual frequency is between 10% to 25% or 35% to 50%.  A frequency between 25% to 35% = Pass.  A frequency below 10% or above 50% = Fail.
* The third subquery simply parses the results to a single cell value of P, FAIL,or WARN.  
* HOWEVER, notice that the lowest query sets the status field value = 'SKIP' if the table is completely empty...we would not want to test data that does not exist.  Sometimes a value of "BLOCK" might be more appropriate than "SKIP" depending on your situation.  Regardless, it is often nice to wire in these pre-condition checks to head off false-negatives (FAILs).
 
 ```sql
WITH dut -- data under test
AS (
  SELECT region_id
  , CAST(freq AS FLOAT(126)) / CAST(den AS FLOAT(126)) AS freq_rt
  FROM (
    SELECT region_id, COUNT(*) AS freq
    , (SELECT COUNT(*) FROM demo_hr.countries) AS den
    FROM demo_hr.countries
    GROUP BY region_id
  ) t
)
, bll -- business logic layer: apply heuristics...what constitutes a pass or a fail?
AS (
  SELECT CASE WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.10 AND 0.50 then 'FAIL: Frequency occurrence of region_id=1 is FAR outside threshold|exp=0.28 thru 0.36|act=' || CAST(freq_rt AS VARCHAR2(8))
              WHEN region_id = 1  AND freq_rt NOT BETWEEN 0.25 AND 0.35 then 'WARN: Frequency occurrence of region_id=1 is outside threshold|exp=0.20 thru 0.28|act=' || CAST(freq_rt AS VARCHAR2(8))
              ELSE 'P'
    	    END AS status
  FROM dut
)
	
SELECT CASE WHEN (SELECT COUNT(*) FROM bll) = 0 THEN 'SKIP'
            WHEN (SELECT COUNT(*) FROM bll WHERE status LIKE 'FAIL:%') > 0 THEN 'FAIL'
            WHEN (SELECT COUNT(*) FROM bll WHERE status LIKE 'WARN:%') > 0 THEN 'WARN'
            ELSE 'P'
       END AS status
FROM dual; 
```
<br>


