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


<a id="t025" class="anchor" href="#t025" aria-hidden="true"> </a>
### T025 - Not In Value List
Verify text field value is **not** in the list of invalid values.  For example, to verify that field job_id of table employees is never in the list of 5 invalid values:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN job_id IN('CEO','CFO','COO','CIO','POTUS') THEN 'FAIL'  ELSE 'P'  END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


<a id="t026" class="anchor" href="#t026" aria-hidden="true"> </a>
### T026 - Multi Field Compare
Verify text field value is comprised of other field values.  For example, use the SQL below to verify that field email = first letter of field first_name + field last_name in table employees.  Note that there were exceptions to the rule in the data, so these were manually removed from the test in the WHERE clause.
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN email <> SUBSTR(UPPER(SUBSTR(first_name, 1, 1) || last_name), 1, 8) THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
  	WHERE email NOT IN('DRAPHEAL', 'JAMRLOW', 'JMURMAN', 'LDEHAAN', 'JRUSSEL', 'TJOLSON')  
  	                 -- DRAPHAEL vs DRAPHEAL, JMARLOW vs JAMRLOW, JMURMAN vs JURMAN, LDE HAAN VS LDEHAAN, JRUSSELL vs JRUSSEL, TOLSON vs TJOLSON 
)
WHERE status <> 'P';
```
<br>


<a id="t027" class="anchor" href="#t027" aria-hidden="true"> </a>
### T027 - Text Length
Verify text field value length is an exact amount or within a range.  For example, to verify that the field phone_number length is either 12 (US) or 18 (international) characters in length:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN LENGTH(phone_number) NOT IN(12,18)  THEN 'REJ-01: Verify phone_number length is allowed|exp=12,18|act=' || LENGTH(phone_number)
              ELSE 'P'
         END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


<a id="t028" class="anchor" href="#t028" aria-hidden="true"> </a>
### T028 - Upper and Lower Case Characters
Verify text field characters are uppercase, lowercase, or a mix.  For example, to verify that the field last_name is all lowercase **after** the first character, and that field job_id is all uppercase in table employees:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN REGEXP_LIKE(job_id, '[[:lower:]]')                  THEN 'REJ-01: Verify job_id does not contain lower case characters|exp=ucase|act=' || job_id
              WHEN NOT REGEXP_LIKE(SUBSTR(last_name,1), '[[:upper:]]') THEN 'REJ-02: Verify last_name after first char is all lower case|exp=lcase|act=' || last_name 
              ELSE 'P'
         END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


<a id="t029" class="anchor" href="#t029" aria-hidden="true"> </a>
### T029 - Alpha and Numeric Characters
Verify text field characters are alpha, numeric, or a mix.  For example, to verify that the field employee_id is numeric only, and field last_name is slpha only in table employees:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN REGEXP_LIKE(employee_id, '[[:alpha:]]')   THEN 'REJ-01: Verify employee_id does not contain alpha characters|exp=no-alphas|act=' || EMPLOYEE_ID
              WHEN REGEXP_LIKE(last_name, '[[:digit:]]')     THEN 'REJ-02: Verify last_name does not contain numeric digits|exp=no-digits|act=' || LAST_NAME 
 	            ELSE 'P'
 	       END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


<a id="t030" class="anchor" href="#t030" aria-hidden="true"> </a>
### T030 - No Quote Characters
Verify text field does not have ' or " characters.  For example, to verify that the field first_name has no quotes or single quotes in table employees:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN first_name LIKE '%''%'  THEN 'REJ-01: Verify first_name does not contain single quote characters|exp=none|act=' || first_name
              WHEN first_name LIKE '%"%'   THEN 'REJ-02: Verify first_name does not contain quotation characters|exp=none|act=' || first_name
              ELSE 'P'
 	       END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


<a id="t031" class="anchor" href="#t031" aria-hidden="true"> </a>
### T031 - No CRLF Characters
Verify text field does not have carriage return (CHAR-13 / "CR") or line feed (CHAR-10 / "LF") characters.  For example, to verify that the field last_name has no CRLFs in table employees:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN INSTR(last_name, CHR(10))  > 0 THEN 'REJ-01: Field last_name has a Line Feed (CHR-10)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(10)) AS VARCHAR2(4))
              WHEN INSTR(last_name, CHR(13))  > 0 THEN 'REJ-02: Field last_name has a Carriage Return (CHR-13)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(13)) AS VARCHAR2(4))
    	         ELSE 'P'
 	       END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


<a id="t032" class="anchor" href="#t032" aria-hidden="true"> </a>
### T032 - No TAB Characters
Verify text field does not have tab (CHAR-9) characters.  For example, to verify that the field last_name has no TABs in table employees:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN INSTR(last_name, CHR(9)) > 0 THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


<a id="t033" class="anchor" href="#t033" aria-hidden="true"> </a>
### T033 - No NBS Characters
Verify text field does not have non-breaking-space (CHAR-160 / "NBS") characters.  For example, to verify that the field last_name has no NBS chars in table employees:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN INSTR(last_name, CHR(160)) > 0 THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


<a id="t034" class="anchor" href="#t034" aria-hidden="true"> </a>
### T034 - No EmDash Characters
Verify text field does not have an em-dash character (CHAR-151; common Microsoft Office "--" copy-paste conversion causing data load issues).  For example, to verify that the field last_name has no em-dashes in table employees:
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN INSTR(last_name, CHR(151)) > 0 THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


<a id="t035" class="anchor" href="#t035" aria-hidden="true"> </a>
### T035 - No VTFFNEL Characters
Verify text field does not have any vertical tab (CHAR-11 / "VT"), form feed (CHAR-12 / "FF"), or next line (CHAR-133 / "NEL") characters.  For example, use the SQL below to verify that the field last_name has no VT, FF, or NEL characters in table employees.  Note that this SQL checks for all three characters, each on its own CASE...WHEN clause, and that it returns the location within a string where the bad character occurs.
```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT CASE WHEN INSTR(last_name, CHR(11)) > 0  THEN 'REJ-01: Field last_name has a Vertical Tab (CHR-11)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(11)) AS VARCHAR2(4))
 	            WHEN INSTR(last_name, CHR(12)) > 0  THEN 'REJ-02: Field last_name has a Form Feed (CHR-12)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(12)) AS VARCHAR2(4))
 	            WHEN INSTR(last_name, CHR(133)) > 0 THEN 'REJ-03: Field last_name has a Next Line (CHR-133)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(133)) AS VARCHAR2(4))
 	            ELSE 'P'
 	       END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
<br>


