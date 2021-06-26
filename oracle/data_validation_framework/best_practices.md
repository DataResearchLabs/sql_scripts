# Best Practices
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

## Table of Contents
 - <a href="#t062">T062 - New Status "WARN" and "SKIP"</a>
 - <a href="#t063">T063 - Limit to Recent Data</a>
 - <a href="#t064">T064 - Ignore Known Fails that Won't be Fixed</a>
 - <a href="#t065">T065 - Single Large Tablescan for Performance</a>
 - <a href="#t066">T066 - Use Config Tables</a>
<br>


<a id="t062" class="anchor" href="#t062" aria-hidden="true"> </a>
### T062 - New Status "WARN" and "SKIP"
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

<details><summary>More details...</summary>
	
Three important reasons are:
1. **Performance** - if the test can filter down to just a small recent subset of data and test just that rather than pulling the entire past 5 years, well that is 1,500+ times less data and should run much faster (depending on underlyng table size, indexes, physical location, etc.)
2. **Sensitivity** - If you are running say a null rate check, or a value frequency check...obviously it will take many days of bad data for a defect to begin to impact the rate enough to eventually trigger an alert.  Much better in those scenarios to average rates across one or no more than 5 days and set the threhold to trigger off of that.
3.  **Garabage Decay** - This is an artifiact of the imperfect world we live in.  There are times when I'd setup an alert to fire daily and notify the appropriate people to correct it, but other higher priorities kept them from geting to it for 2 or 3 days.  I didn't want that alarm firing over and over again, causing me to look and confirm, "Oh year, known issue...they'll get to it".  Instead, I setup the alert to look only at the past 24 hours and scheduled it to run daily.  It only tested new data once and reported the error once. 

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


<a id="t064" class="anchor" href="#t064" aria-hidden="true"> </a>
### T064 - Ignore Known Fails that Won't be Fixed
There are times when developers aren't going to fix a defect for weeks/months, or the data will only be corrected on a go-forward basis.  When eitehr occurs, you want your data validation check to stop trigger a Fail alert.  Sometimes the quickest way to resolve the issue is to implement T063 above and reset the minimum test data to today's date.  Otehr times, you may want to specifically exclude known data rows going forward.  Below is such an example, where country_id BR, DK, and IL were causing fails due to some defect that won't be resolved.  So for this test scenario, those countries will be excluded from the null check going forward.  The WHERE clause at the inner query is doing all the work for this best practice.

 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN region_id IS NULL  THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.countries
  WHERE country_id NOT IN('BR','DK','IL') 
)
WHERE status <> 'P';
```
<br>


<a id="t065" class="anchor" href="#t065" aria-hidden="true"> </a>
### T065 - Single Large Tablescan for Performance
In all the prior validation test cases (T001 thr T0065), the tests were granular and standalone so easier to follow as examples.  However, in reality each of those checks often involves a single slow table scan pass (except for the few times indexes are available and applicable).  Therefore, it is often better to bundle as many checks against as many fields as possible, one table per table-scan query.

For example, below I've bundled validation tests from many small granular tests above into a single test here.  

* The **upside** is much faster performance.  When you look at execution times in the advanced test script, this single table scan test runs all the checks in the same amount of time as any one of the granular tests.  Translation: Rolling 25 granular tests into one bigger table scan pass makes the script 25 times faster because the database does everything in one table scan pass rather than 25 equal duration but smaller sql passes.
* The **downside** is clarity.  Since all the logic is in one giant CASE...WHEN...ELSE statement, the sequencing matters.  Translation: when the first rejection is encountered during validation of a given row, all subsequent WHEN statements are skipped.  So you only know of the highest level rejection code, but have no idea about other possible data validation errors until you fix the first one and er-run.  Sometimes this is an acceptable trade-off to improvve performance (esp. when fails are rare and the system is mature).

<details><summary>More details and the source code...</summary>

In the example below, there is an inner query that you can highlight and execute from your SQL IDE to see results at the row level with specific rejection codes encountered, if any.  The outer query is simply a wrapper that returns a single value of pass or fail depending on whether rejection codes were found in the data.

```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN employee_id < 100                                        THEN 'REJ-01: Field employee_id > 99|exp>99|act=' || CAST(employee_id AS VARCHAR2(10))
              WHEN employee_id > 999                                        THEN 'REJ-02: Field employee_id < 1000|exp<1000|act=' || CAST(employee_id AS VARCHAR2(10))
              WHEN salary * commission_pct > 10000                          THEN 'REJ-03: Fields salary x commission_pct <= $10,000|exp<10,000|act=' || CAST(salary * commission_pct AS VARCHAR2(15))
              WHEN TO_CHAR(hire_date, 'hh:mi:ss') <> '12:00:00'             THEN 'REJ-04: Field hire_date cannot have a time part|exp=12:00:00|act=' || TO_CHAR(hire_date, 'hh:nn:ss')
              WHEN NOT REGEXP_LIKE(zip5, '^[0-5]+$')                        THEN 'REJ-05: Field zip5 failed RegExpression check|exp=Like"^[0-5]+$"|act=' || zip5 
              WHEN job_id IN('CEO','CFO','COO','CIO','POTUS')               THEN 'REJ-06: Verify job_id not in domain list of excluded values|exp<>1of5|act=' || job_id
              WHEN email <> SUBSTR(UPPER(SUBSTR(
                              first_name, 1, 1) || last_name), 1, 8)        THEN 'REJ-07: Field email <> first char of first_name + last_name|exp=' || SUBSTR(UPPER(SUBSTR(first_name, 1, 1) || last_name), 1, 8) || '|act=' || email
              WHEN LENGTH(phone_number) NOT IN(12,18)                       THEN 'REJ-08: Field phone_number length is allowed|exp=12,18|act=' || LENGTH(phone_number)
              WHEN REGEXP_LIKE(job_id, '[[:lower:]]')                       THEN 'REJ-09: Field job_id does not contain lower case characters|exp=ucase|act=' || EMAIL
              WHEN NOT REGEXP_LIKE(SUBSTR(LAST_NAME,1), '[[:upper:]]')      THEN 'REJ-10: Field last_name after first char is all lower case|exp=lcase|act=' || LAST_NAME 
              WHEN REGEXP_LIKE(employee_id, '[[:alpha:]]')                  THEN 'REJ-11: Field employee_id does not contain alpha characters|exp=no-alphas|act=' || EMPLOYEE_ID
              WHEN REGEXP_LIKE(last_name, '[[:digit:]]')                    THEN 'REJ-12: Field last_name does not contain numeric digits|exp=no-digits|act=' || LAST_NAME 
              WHEN first_name LIKE '%''%'                                   THEN 'REJ-13: Field first_name does not contain single quote characters|exp=none|act=' || first_name
              WHEN first_name LIKE '%"%'                                    THEN 'REJ-14: Field first_name does not contain quotation characters|exp=none|act=' || first_name
              WHEN INSTR(last_name, CHR(10))  > 0                           THEN 'REJ-15: Field last_name has a Line Feed (CHR-10)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(10)) AS VARCHAR2(4))
              WHEN INSTR(last_name, CHR(13))  > 0                           THEN 'REJ-16: Field last_name has a Carriage Return (CHR-13)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(13)) AS VARCHAR2(4))
              WHEN INSTR(last_name, CHR(9))   > 0                           THEN 'REJ-17: Field last_name has a Tab (CHR-9)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(9)) AS VARCHAR2(4))
              WHEN INSTR(last_name, CHR(160)) > 0                           THEN 'REJ-18: Field last_name has a Non-Breaking-Space (CHR-160)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(160)) AS VARCHAR2(4))
              WHEN INSTR(last_name, CHR(151)) > 0                           THEN 'REJ-19: Field last_name has a Non-Breaking-Space (CHR-151)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(151)) AS VARCHAR2(4))
              WHEN INSTR(last_name, CHR(11)) > 0                            THEN 'REJ-20: Field last_name has a Vertical Tab (CHR-11)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(11)) AS VARCHAR2(4))
              WHEN INSTR(last_name, CHR(12)) > 0                            THEN 'REJ-21: Field last_name has a Form Feed (CHR-12)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(12)) AS VARCHAR2(4))
              WHEN INSTR(last_name, CHR(133)) > 0                           THEN 'REJ-22: Field last_name has a Next Line (CHR-133)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(133)) AS VARCHAR2(4))
              WHEN INSTR(last_name, '.') > 0                                THEN 'REJ-23: Field last_name has a period|exp=none|act=at position ' || CAST(INSTR(last_name, '.') AS VARCHAR2(4))
              WHEN REGEXP_LIKE(last_name, '[,/:()&#?;]')                    THEN 'REJ-24: Field last_name has a ",/:()&#?;" characters|exp=none|act=' || last_name 
              WHEN REGEXP_LIKE(phone_number, '[^.0123456789]')              THEN 'REJ-25: Field phone_number can only have characters ".012345789"|exp=onlyAlloweChars|act=' || phone_number 
              WHEN phone_number NOT LIKE '%.%'                              THEN 'REJ-26: Verify phone_number contains a ''.''|exp=contains-.|act=' || phone_number
              WHEN phone_number NOT LIKE '___.___.____' 
               AND phone_number NOT LIKE '011.__.____._____%'               THEN 'REJ-27: Verify phone_number like pattern "___.___.____" or "011.__.____._____"|exp=yes|act=' || phone_number
              WHEN NOT REGEXP_LIKE(zip5, '^\d+(\.\d+)?$')                   THEN 'REJ-28: Field zip9 will not convert to a number|exp=converts to number|act=' || zip5 
              WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    	           REPLACE(REPLACE(REPLACE(some_date_fmt1,'0',''),'1','')
    	           ,'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8'
    	           ,''),'9','')  > ''                                       THEN 'REJ-29: Unexpected chars exist (numeric 0-9 only)|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
              WHEN NOT LENGTH(TRIM(some_date_fmt1)) = 8                     THEN 'REJ-30: Must be 8 Chars|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
              WHEN NOT SUBSTR(some_date_fmt1,1,4) BETWEEN '1753' AND '9999' THEN 'REJ-31: Year Not Btw 1753-9999|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
              WHEN NOT SUBSTR(some_date_fmt1,5,2) BETWEEN '01' AND '12'     THEN 'REJ-32: Month Not Btw 01-12|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
              WHEN NOT SUBSTR(some_date_fmt1,7,2) BETWEEN '01' AND '31'     THEN 'REJ-33: Day Not Btw 01-31|exp=Fmt="yyyymmdd"|act=' || some_date_fmt1
              ELSE 'P'
    	    END AS status
  FROM demo_hr.employees
  WHERE email NOT IN('DRAPHEAL', 'JAMRLOW', 'JMURMAN', 'LDEHAAN', 'JRUSSEL', 'TJOLSON')  
                   -- DRAPHAEL vs DRAPHEAL, JMARLOW vs JAMRLOW, JMURMAN vs JURMAN, LDE HAAN VS LDEHAAN, JRUSSELL vs JRUSSEL, TOLSON vs TJOLSON)
)
WHERE status <> 'P';
```
</details>
<br>


