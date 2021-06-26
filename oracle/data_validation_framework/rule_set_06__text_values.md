# Rule Set #6 - Text Values
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

Note: These validation checks are some of the most important.  Good data loading practices land data into text fields, then from there validate and transform into other data types.  Thus, these are checks you can use over and over in one form or another.


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


<a id="t016" class="anchor" href="#t016" aria-hidden="true"> </a>
### T016 - Not Null
Verify date field is not null.  For example, to verify that table countries has no NULLs in field date_last_updated:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN date_last_updated IS NULL THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.countries
)
WHERE status <> 'P';
```
<br>

