# Rule Set #6 - Text Values
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

Note: These text validation checks are important.  Good data loading practices land data into text data type fields, then from there validate and transform into other data types (numeric, date, boolean, etc.).  Thus, these are checks you will find yourself using over and over again over time.


## Table of Contents
 - <a href="#t021">T021 - Not Null</a>
 - <a href="#t022">T022 - Not Null String</a>
 - <a href="#t023">T023 - No Leading or Trailing Spaces</a>
 - <a href="#t024">T024 - In Value List</a>
 - <a href="#t025">T025 - Not In Value List</a>
 - <a href="#t026">T026 - Multi Field Compare</a>
 - <a href="#t027">T027 - Text Length</a>
 - <a href="#t028">T028 - Upper and Lower Case Characters</a>
 - <a href="#t029">T029 - Alpha and Numeric Characters</a>
 - <a href="#t030">T030 - No Quote Characters</a>
 - <a href="#t031">T031 - No CRLF Characters</a>
 - <a href="#t032">T032 - No TAB Characters</a>
 - <a href="#t033">T033 - No NBS Characters</a>
 - <a href="#t034">T034 - No EmDash Characters</a>
 - <a href="#t035">T035 - No VTFFNEL Characters</a>
 - <a href="#t036">T036 - No Period or Dash Characters</a>
 - <a href="#t037">T037 - No Funky Punctuation ",/:()&#?;" Characters</a>
 - <a href="#t038">T038 - Only Allowed Characters In List</a>
 - <a href="#t039">T039 - Like Wildcards</a>
 - <a href="#t040">T040 - IsNumeric()</a>
 - <a href="#t041">T041 - IsDate("yyyymmdd")</a>
 - <a href="#t042">T042 - IsDate("mm/dd/yyyy")</a>
 - <a href="#t043">T043 - IsDate("mm-dd-yyyy")</a>
 - <a href="#t044">T044 - IsDate("yyyy-mm-dd")</a>
<br>


<a id="t021" class="anchor" href="#t021" aria-hidden="true"> </a>
### T021 - Not Null
Verify text field is not null.  For example, to verify that table countries has no NULLs in field country_name:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN country_name IS NULL THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.countries
)
WHERE status <> 'P';
```
<br>

<a id="t022" class="anchor" href="#t022" aria-hidden="true"> </a>
### T022 - Not Null String
Verify text field is not null string "" (but in Oracle null strings don't exist, they are converted to nulls...therefore look for a space instead and treat this test case as a place holder equivalent to other database platforms).  For example, to verify that table countries has rows where field country_name = a space:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN country_name = ' ' THEN 'FAIL' ELSE 'P'  END AS status
  FROM demo_hr.countries
)
WHERE status <> 'P';
```
<br>


<a id="t023" class="anchor" href="#t023" aria-hidden="true"> </a>
### T023 - No Leading or Trailing Spaces
Verify text field has no leading or trailing spaces.  For example, to verify that table countries, field country_name has no rows with a leading and/or trailing space:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN country_name LIKE ' %'  THEN 'REJ-01: Verify no leading space at country_name|exp=noLeadSpace|act=''' || country_name ||''''
          				WHEN country_name LIKE '% '  THEN 'REJ-02: Verify no trailing space at country_name|exp=noTrailingSpace|act=''' || country_name ||''''
    	         ELSE 'P'
    	    END AS status
  FROM demo_hr.countries
)
WHERE status <> 'P';
```
<br>


<a id="t024" class="anchor" href="#t024" aria-hidden="true"> </a>
### T024 - In Value List
Verify text field value is in the list of approved values.  For example, to verify that field job_id of table employees is always in the list of 19 approved values:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN job_id NOT IN('ST_MAN','ST_CLERK','SH_CLERK','SA_REP','SA_MAN','PU_CLERK','PR_REP','MK_REP','MK_MAN','IT_PROG'
                                ,'HR_REP','FI_MGR','FI_ACCOUNT','AD_VP','AD_PRES','AD_ASST','AC_MGR','AC_ACCOUNT','PU_MAN')
              THEN 'FAIL'
              ELSE 'P'
         END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


