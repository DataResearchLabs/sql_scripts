### Data Validation Examples - MS SQL Server
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
#### [Return to Data Validation Home Page](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_validation_scripts.md)
<br>

# Rule Set #5 - Date Values

## Table of Contents
 - <a href="#t016">T016 - Not Null</a>
 - <a href="#t017">T017 - Date Range</a>
 - <a href="#t018">T018 - No Time Part</a>
 - <a href="#t019">T019 - Has Time Part</a>
 - <a href="#t020">T020 - Multi Field Compare</a>
 - <a href="#bonus">Bonus Tip - Joining Tables with 2 Pairs of Start-End Date Overlaps</a>
<br>


<a id="t016" class="anchor" href="#t016" aria-hidden="true"> </a>
### T016 - Not Null
Verify date field is not null.  For example, to verify that table countries has no NULLs in field date_last_updated:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT date_last_updated
       , CASE WHEN date_last_updated IS NULL THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..countries
) t
WHERE status <> 'P';
```
<br>


<a id="t017" class="anchor" href="#t017" aria-hidden="true"> </a>
### T017 - Date Range
Verify date field is within specified range.  For example, you can run the sql below to verify that table countries field date_last_updated is between 1/1/2021 and today.  Note the use of SYSDATE to represent today's date dynamically in Oracle.  Notice the inner query uses a CASE...WHEN...ELSE structure to identify two rejections codes: (1) date is too high, and (2) date is too low.  Expected and actual values are displayed in the output if you run the inner query only.  The outer query is a wrapper to determine whether the test passed or failed.
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT date_last_updated
  , CASE WHEN date_last_updated > GETDATE()    THEN 'REJ-01: Field date_last_updated cannot be in the future|exp<=' + CAST(GETDATE() AS VARCHAR(20)) + '|act=' + CAST(date_last_updated AS VARCHAR(20))
    	    WHEN date_last_updated < '01/01/2021' THEN 'REJ-02: Field date_last_updated cannot be too old|exp>=1/1/2021|act=' + CAST(date_last_updated AS VARCHAR(20))
    	    ELSE 'P'
    END AS status
  FROM demo_hr..countries
) t
WHERE status <> 'P';
```
<br>


<a id="t018" class="anchor" href="#t018" aria-hidden="true"> </a>
### T018 - No Time Part
Verify date field is a date only, no time part present.  For example, to verify that table employees has no time part in field hire_date (time part must be "12:00:00"):
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT hire_date
  , CASE WHEN CONVERT(VARCHAR(8), hire_date, 108) <> '00:00:00' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
WHERE status <> 'P';
```
<br>


<a id="t019" class="anchor" href="#t019" aria-hidden="true"> </a>
### T019 - Has Time Part
Verify date field is a date **and** time.  For example, to verify that table employees has a time part in field hire_date (time part cannot be "12:00:00"):
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT date_last_updated
  , CASE WHEN CONVERT(VARCHAR(8), date_last_updated, 108) = '00:00:00' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..countries
) t
WHERE status <> 'P';
```
<br>


<a id="t020" class="anchor" href="#t020" aria-hidden="true"> </a>
### T020 - Multi Field Compare
Verify multiple date fields relative to each other.  For example, to verify that field start_date must be < field end_date in table job_history (thus if start_date is >= end_date the test case fails):
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT start_date, end_date
  , CASE WHEN start_date >= end_date THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..job_history
) t
WHERE status <> 'P';
```
<br>


<a id="bonus" class="anchor" href="#bonus" aria-hidden="true"> </a>
### Bonus Tip - Joining Tables with 2 Pairs of Start-End Date Overlaps
So this is a fantastic tip I learned from a co-worker in healthcare back in 2011 (was it Jennifer C.?  or Matt G.?  or Jonathon P.? I can't remember).


The **problem** is that you are trying to join two tables with logic where the table1.start_dt/end_dt's overlap with the table2.start_dt/end_dt.


The **solution** is to join where `table1.start_dt <= table2.end_dt AND table1.end_dt >= table2.start_dt.`

Here is why:

```
Scenario #1 = "Discard - No Overlap" Table #1 is completely before Table #2 (T#1.End is NOT > T#2.St)
T#1.St ---------- T#1.End 
                          T#2.St ----------- T#2.End
                          

Scenario #2 = "Include - T1 Ends at T2 Start" Table #1 ends exactly where Table #2 starts (T#1.End = T#2.St  AND  T#1.St < T#2.End)
T#1.St ---------- T#1.End 
                  T#2.St ----------- T#2.End
                  

Scenario #3 = "Include - T1 Ends Midway T2 Span" Table #1 nicely overlaps Table #2 (T#1.End > T#2.St  AND  T#1.St < T#2.End)
T#1.St ------------------- T#1.End 
                  T#2.St ----------- T#2.End
                  

Scenario #4 = "Include - T1 Starts Midway T2 Span" Table #1 nicely overlaps Table #2 (T#1.End > T#2.St  AND  T#1.St < T#2.End)
                           T#1.St ------------------- T#1.End 
                  T#2.St ----------- T#2.End
                  

Scenario #5 = "Include - T1 Starts at T2 End" Table #1 start exactly at Table #2 End (T#1.End > T#2.St  AND  T#1.St = T#2.End)
                                     T#1.St ------------------- T#1.End 
                  T#2.St ----------- T#2.End
                  

Scenario #6 = "Discard - No Overlap" Table #1 is completely after Table #2 (T#1.St is NOT < T#2.End)
                                                      T#1.St ---------- T#1.End 
                          T#2.St ----------- T#2.End

```


<br>
