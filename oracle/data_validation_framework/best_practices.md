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

<details><summary>More details...</summary>

* In the SQL below, the first subquery (CTE) is titled "dut", short for data under test.  This simply calculates the frequency with which region_id = 1 occurs.
* The second subquery (CTE) is titles "bll", short for business logic layer.  This is where the magic happens.  Because CASE...WHEN logic is sequential, it is important that the highest severity checks are done first.  In this case, we check for the frequency being a FAIL because it is outside of the wide range 10% to 50%.  However, we come right back in the following WHEN statement and set the status to WARN if the frequency observed is outside of the narrower (than FAIL) range of 25% to 35%.  So as coded, a WARN is issue when the actual frequency is between 10% to 25% or 35% to 50%.  A frequency between 25% to 35% = Pass.  A frequency below 10% or above 50% = Fail.
* The third subquery simply parses the results to a single cell value of P, FAIL,or WARN.  
* HOWEVER, notice that the lowest query sets the status field value = 'SKIP' if the table is completely empty...we would not want to test data that does not exist.  Sometimes a value of "BLOCK" might be more appropriate than "SKIP" depending on your situation.  Regardless, it is often nice to wire in these pre-condition checks to head off false-negatives (FAILs).
</details>
	
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


<a id="t063" class="anchor" href="#t063" aria-hidden="true"> </a>
### T063 - Limit to Recent Data
There are good reasons why you should consider altering the prior example tests to only use recent data (eg: past 1 or 5 or 10 days) when you go to implement these yourself.  

<details><summary>More details...</sumary>
	
Three important reasons are:
1. **Performance** - if the test can filter down to just a small recent subset of data and test just that rather than pulling the entire past 5 years, well that is 1,500+ times less data and should run much faster (depending on underlyng table size, indexes, physical location, etc.)
2. **Sensitivity** - If you are running say a null rate check, or a value frequency check...obviously it will take many days of bad data for a defect to begin to impact the rate enough to eventually trigger an alert.  Much better in those scenarios to average rates across one or no more than 5 days and set the threhold to trigger off of that.
3.  **Garabage Decay** - This is an artifiact of the imperfect world we live in.  There are times when I'd setup an alert to fire daily and notify the appropriate people to fix it.  But if they didn't get around to fixing it for 2 or 3 days, I didn't want that alarm firing over and over again, causing me to look and confirm, oh year, known issue...they'll get to it.  Instead, I setup the alert to look only at the past 24 hours and scheduled it to run daily.  It only tested new data once and reported the error once. 

In the example below, the inner query is only checking for nulls against data that was last updated in the past 30 days. 

P.S. - To achieve maximum performance here, find an indexed field to filter on in your WHERE clause; you want to avoid an unnecessary table scan against a giant table.  So, if you are lucky and have an appropriate create or update date field that is indexed then you are golden.  However, if not, then maybe find a primary key that is a numeric integer that increments with every new row.  Worst case you could just take the MAX() - several thousand rows and test those...or you could cross reference a date somehow to that ID field (example lookup dates in a batch table to pick the minimum Batch_ID and filter on that as a surrogate for date time that is indexed and will run fast).

</details>
	
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN region_id IS NULL  THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.countries
  WHERE date_last_updated >= SYSDATE - 30 
)
WHERE status <> 'P';
```
<br>


