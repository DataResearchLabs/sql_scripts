### Data Validation Examples - MySQL
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
#### [Return to Data Validation Home Page](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_validation_scripts.md)


# Rule Set #6 - Text Values

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
 - <a href="#t037">T037 - No Funky ",/:()&#?;" Characters</a>
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
SELECT country_name
     , CASE WHEN country_name IS NULL THEN 'FAIL' ELSE 'P' END AS status
FROM demo_hr.countries;
```
<br>

<a id="t022" class="anchor" href="#t022" aria-hidden="true"> </a>
### T022 - Not Null String
Verify text field is not null string "" (but in Oracle null strings don't exist, they are converted to nulls...therefore look for a space instead and treat this test case as a place holder equivalent to other database platforms).  For example, to verify that table countries has rows where field country_name = a space:
```sql
SELECT country_name
     , CASE WHEN country_name = '' THEN 'FAIL' ELSE 'P'  END AS status
FROM demo_hr.countries;
```
<br>


<a id="t023" class="anchor" href="#t023" aria-hidden="true"> </a>
### T023 - No Leading or Trailing Spaces
Verify text field has no leading or trailing spaces.  For example, to verify that table countries, field country_name has no rows with a leading and/or trailing space:
```sql
SELECT country_name
     , CASE WHEN country_name LIKE ' %'  THEN CONCAT('REJ-02: Verify no leading space at country_name|exp=noLeadSpace|act=''', country_name, '''')
            WHEN country_name LIKE '% '  THEN CONCAT('REJ-03: Verify no trailing space at country_name|exp=noTrailingSpace|act=''', country_name, '''')
             ELSE 'P'
       END AS status
FROM demo_hr.countries;
```
<br>


<a id="t024" class="anchor" href="#t024" aria-hidden="true"> </a>
### T024 - In Value List
Verify text field value is in the list of approved values.  For example, to verify that field job_id of table employees is always in the list of 19 approved values:
```sql
SELECT job_id
, CASE WHEN job_id NOT IN('ST_MAN','ST_CLERK','SH_CLERK','SA_REP','SA_MAN','PU_CLERK','PR_REP','MK_REP','MK_MAN','IT_PROG'
                         ,'HR_REP','FI_MGR','FI_ACCOUNT','AD_VP','AD_PRES','AD_ASST','AC_MGR','AC_ACCOUNT','PU_MAN')
            THEN 'FAIL'
  	    ELSE 'P'
 	END AS status
FROM demo_hr.employees;
```
<br>


<a id="t025" class="anchor" href="#t025" aria-hidden="true"> </a>
### T025 - Not In Value List
Verify text field value is **not** in the list of invalid values.  For example, to verify that field job_id of table employees is never in the list of 5 invalid values:
```sql
SELECT job_id
     , CASE WHEN job_id IN('CEO','CFO','COO','CIO','POTUS') THEN 'FAIL'  ELSE 'P'  END AS status
FROM demo_hr.employees;
```
<br>


<a id="t026" class="anchor" href="#t026" aria-hidden="true"> </a>
### T026 - Multi Field Compare
Verify text field value is comprised of other field values.  For example, use the SQL below to verify that field email = first letter of field first_name + field last_name in table employees.  Note that there were exceptions to the rule in the data, so these were manually removed from the test in the WHERE clause.
```sql
SELECT email, first_name, last_name
     , CASE WHEN email <> SUBSTRING(UPPER(CONCAT(SUBSTRING(first_name, 1, 1), last_name)), 1, 8) THEN 'FAIL' ELSE 'P' END AS status
FROM demo_hr.employees
WHERE email NOT IN('DRAPHEAL', 'JAMRLOW', 'JMURMAN', 'LDEHAAN', 'JRUSSEL', 'TJOLSON')  
                 -- DRAPHAEL vs DRAPHEAL, JMARLOW vs JAMRLOW, JMURMAN vs JURMAN, LDE HAAN VS LDEHAAN, JRUSSELL vs JRUSSEL, TOLSON vs TJOLSON 
;
```
<br>


<a id="t027" class="anchor" href="#t027" aria-hidden="true"> </a>
### T027 - Text Length
Verify text field value length is an exact amount or within a range.  For example, to verify that the field phone_number length is either 12 (US) or 18 (international) characters in length:
```sql
SELECT phone_number
     , CASE WHEN LENGTH(phone_number) NOT IN(12,18)  THEN CONCAT('REJ-01: Verify phone_number length is allowed|exp=12,18|act=', CAST(LENGTH(phone_number) AS CHAR(6)))
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t028" class="anchor" href="#t028" aria-hidden="true"> </a>
### T028 - Upper and Lower Case Characters
Verify text field characters are uppercase, lowercase, or a mix.  For example, to verify that the field last_name is all lowercase **after** the first character, and that field job_id is all uppercase in table employees:
```sql
SELECT job_id, last_name
     , CASE WHEN job_id COLLATE utf8mb4_bin <> UPPER(job_id)                 THEN CONCAT('REJ-01: Verify job_id does not contain lower case characters|exp=ucase|act=', job_id)
            WHEN SUBSTRING(last_name COLLATE utf8mb4_bin, 2, 255) 
                  <> LOWER(SUBSTRING(last_name COLLATE utf8mb4_bin, 2, 255)) THEN CONCAT('REJ-02: Verify last_name after first char is all lower case|exp=lcase|act=', last_name)
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t029" class="anchor" href="#t029" aria-hidden="true"> </a>
### T029 - Alpha and Numeric Characters
Verify text field characters are alpha, numeric, or a mix.  For example, to verify that the field employee_id is numeric only, and field last_name is slpha only in table employees:
```sql
SELECT employee_id, last_name
     , CASE WHEN employee_id REGEXP '[A-Za-z]' THEN CONCAT('REJ-01: Verify employee_id does not contain alpha characters|exp=no-alphas|act=', CAST(employee_id AS CHAR(20)))
            WHEN last_name REGEXP '[0-9]'      THEN CONCAT('REJ-02: Verify last_name does not contain numeric digits|exp=no-digits|act=', last_name)
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t030" class="anchor" href="#t030" aria-hidden="true"> </a>
### T030 - No Quote Characters
Verify text field does not have ' or " characters.  For example, to verify that the field first_name has no quotes or single quotes in table employees:
```sql
SELECT first_name
     , CASE WHEN first_name LIKE '%''%'  THEN CONCAT('REJ-01: Verify first_name does not contain single quote characters|exp=none|act=', first_name)
            WHEN first_name LIKE '%"%'   THEN CONCAT('REJ-02: Verify first_name does not contain quotation characters|exp=none|act=', first_name)
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t031" class="anchor" href="#t031" aria-hidden="true"> </a>
### T031 - No CRLF Characters
Verify text field does not have carriage return (CHAR-13 / "CR") or line feed (CHAR-10 / "LF") characters.  For example, to verify that the field last_name has no CRLFs in table employees:
```sql
SELECT last_name
     , CASE WHEN LOCATE(last_name, CHAR(10))  > 0 THEN CONCAT('REJ-01: Field last_name has a Line Feed (CHAR-10)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(10 using ASCII)) AS CHAR(4)))
            WHEN LOCATE(last_name, CHAR(13))  > 0 THEN CONCAT('REJ-02: Field last_name has a Carriage Return (CHAR-13)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(13 using ASCII)) AS CHAR(4)))
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t032" class="anchor" href="#t032" aria-hidden="true"> </a>
### T032 - No TAB Characters
Verify text field does not have tab (CHAR-9) characters.  For example, to verify that the field last_name has no TABs in table employees:
```sql
SELECT last_name
     , CASE WHEN LOCATE(last_name, CHAR(9 using ASCII)) > 0 THEN CONCAT('REJ-01: Field last_name has a Tab (CHAR-9)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(9 using ASCII)) AS CHAR(4))) 
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t033" class="anchor" href="#t033" aria-hidden="true"> </a>
### T033 - No NBS Characters
Verify text field does not have non-breaking-space (CHAR-160 / "NBS") characters.  For example, to verify that the field last_name has no NBS chars in table employees:
```sql
SELECT last_name
     , CASE WHEN LOCATE(last_name, CHAR(160 using ASCII)) > 0 THEN CONCAT('REJ-01: Field last_name has a Non-Breaking-Space (CHAR-160)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(160 using ASCII)) AS CHAR(4)))
            ELSE 'P' 
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t034" class="anchor" href="#t034" aria-hidden="true"> </a>
### T034 - No EmDash Characters
Verify text field does not have an em-dash character (CHAR-151; common Microsoft Office "--" copy-paste conversion causing data load issues).  For example, to verify that the field last_name has no em-dashes in table employees:
```sql
SELECT last_name
     , CASE WHEN LOCATE(last_name, CHAR(151 using ASCII)) > 0 THEN CONCAT('REJ-01: Field last_name has a Non-Breaking-Space (CHAR-151)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(151 using ASCII)) AS CHAR(4)))
            ELSE 'P' 
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t035" class="anchor" href="#t035" aria-hidden="true"> </a>
### T035 - No VT-FF-NEL Characters
Verify text field does not have any vertical tab (CHAR-11 / "VT"), form feed (CHAR-12 / "FF"), or next line (CHAR-133 / "NEL") characters.  For example, use the SQL below to verify that the field last_name has no VT, FF, or NEL characters in table employees.  Note that this SQL checks for all three characters, each on its own CASE...WHEN clause, and that it returns the location within a string where the bad character occurs.
```sql
SELECT last_name
     , CASE WHEN LOCATE(last_name, CHAR(11 using ASCII)) > 0  THEN CONCAT('REJ-01: Field last_name has a Vertical Tab (CHAR-11)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(11 using ASCII)) AS CHAR(4)))
            WHEN LOCATE(last_name, CHAR(12 using ASCII)) > 0  THEN CONCAT('REJ-02: Field last_name has a Form Feed (CHAR-12)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(12 using ASCII)) AS CHAR(4)))
            WHEN LOCATE(last_name, CHAR(133 using ASCII)) > 0 THEN CONCAT('REJ-03: Field last_name has a Next Line (CHAR-133)|exp=none|act=at position ', CAST(LOCATE(last_name, CHAR(133 using ASCII)) AS CHAR(4)))
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t036" class="anchor" href="#t036" aria-hidden="true"> </a>
### T036 - No Period or Dash Characters
Verify text field does not have any periods or dashes.  For example, to verify that the field last_name has no periods or dashes in table employees:
```sql
SELECT last_name
     , CASE WHEN LOCATE(last_name, '.') > 0 THEN CONCAT('REJ-01: Field last_name has a period|exp=none|act=at position ', CAST(LOCATE(last_name, '.') AS CHAR(4)))
            WHEN LOCATE(last_name, '0') > 0 THEN CONCAT('REJ-02: Field last_name has a dash|exp=none|act=at position ', CAST(LOCATE(last_name, '-') AS CHAR(4)))
            ELSE 'P' 
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t037" class="anchor" href="#t037" aria-hidden="true"> </a>
### T037 - No Funky ",/:()&#?;" Characters
Verify text field does not have any funky ",/:()&#?;" characters.  For example, to verify that the field last_name has commas, colons, etc. in table employees:
```sql
SELECT last_name
     , CASE WHEN last_name REGEXP '[,/:()&#?;]' THEN 'FAIL' ELSE 'P' END AS status
FROM demo_hr.employees;
```
<br>


<a id="t038" class="anchor" href="#t038" aria-hidden="true"> </a>
### T038 - Only Allowed Characters In List
Verify text field contains only allowed characters from a specific list.  For example, use the SQL below to verify that the field phone_number in table employees only has characters ".0123456789".  The LIKE expression does the work.  Specifically, the []'s indicating look for these characters, and the ^ means look for any character not in this list.  So it reads: "find any phone numbers containing characters not in [.0123456789]".
```sql
SELECT phone_number
     , CASE WHEN phone_number REGEXP '[^.0123456789]' THEN 'FAIL' ELSE 'P' END AS status
FROM demo_hr.employees;
```
<br>


<a id="t039" class="anchor" href="#t039" aria-hidden="true"> </a>
### T039 - Like Wildcards
Verify text field matches simple like patterns.  For example, use the SQL below to verify that the field phone_number in table employees matches either the US (###.###.####) or international format (011.##.####.#####).  The LIKE command use "%" to represent any number of any character and "\_" to represent any single character.
```sql
SELECT phone_number
      , CASE WHEN phone_number NOT LIKE '%.%'                THEN CONCAT('REJ-01: Verify phone_number contains a ''.''|exp=contains-.|act=', phone_number)
             WHEN phone_number NOT LIKE '___.___.____' 
              AND phone_number NOT LIKE '011.__.____._____%' THEN CONCAT('REJ-02: Verify phone_number like pattern "___.___.____" or "011.__.____._____"|exp=yes|act=', phone_number)
             ELSE 'P'
        END AS status
FROM demo_hr.employees;
```
<br>


<a id="t040" class="anchor" href="#t040" aria-hidden="true"> </a>
### T040 - IsNumeric()
Verify text field is numeric.  For example, use the SQL below to verify that the field zip5 in table employees is numeric.
```sql
SELECT zip5
     , CASE WHEN zip5 REGEXP '[^0-9]' THEN 'FAIL' ELSE 'P' END AS status
FROM demo_hr.employees;
```
<br>


<a id="t041" class="anchor" href="#t041" aria-hidden="true"> </a>
### T041 - IsDate("yyyymmdd")
Verify text field is a date formatted as "yyyymmdd".  For example, use the SQL below to verify that the field some_date_fmt1 in table employees is date format "yyyymmdd".  
<details><summary>More details...</summary> 

 * Although it might be more concise to use a regular expression to implement this validation check, I went ahead and used only the native and thus more universal commands LIKE, REPLACE(), LENGTH(), TRIM(), etc.  Also, it allows for more specific rejection codes below.
* Note in the first WHEN clause the use of multiple REPLACE() commands that take a date like '20210401" and convert all numeric digits to '' such that the actual converted test string is '' to match the expected value of ''.
* Note in the second WHEN clause that the value is confirmed to be 8 characters in length
* Note in the third thru fifth WHEN clauses that each date part (year, month, day) is confirmed to be within an appropriate range.  
* Note that this simple format check is not date-aware; it will not detect leap years or months with < 31 days have the wrong values in place
* Note the use of rejection codes (REJ-01, etc.) at the inner query to clearly return why the validation check failed...run the inner query alone on fail to see details
</details>

```sql
SELECT some_date_fmt1
     , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                 some_date_fmt1,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9','')
                 > ''                                                        THEN CONCAT('REJ-01: Unexpected chars exist (numeric 0-9 only)|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
            WHEN NOT LENGTH(TRIM(some_date_fmt1)) = 8                        THEN CONCAT('REJ-02: Must be 8 Chars|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
            WHEN NOT SUBSTRING(some_date_fmt1,1,4) BETWEEN '1753' AND '9999' THEN CONCAT('REJ-03: Year Not Btw 1753-9999|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
            WHEN NOT SUBSTRING(some_date_fmt1,5,2) BETWEEN '01' AND '12'     THEN CONCAT('REJ-04: Month Not Btw 01-12|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
            WHEN NOT SUBSTRING(some_date_fmt1,7,2) BETWEEN '01' AND '31'     THEN CONCAT('REJ-05: Day Not Btw 01-31|exp=Fmt="yyyymmdd"|act=', some_date_fmt1)
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t042" class="anchor" href="#t042" aria-hidden="true"> </a>
### T042 - IsDate("mm/dd/yyyy")
Verify text field is a date formatted as "mm/dd/yyyy".  For example, use the SQL below to verify that the field some_date_fmt2 in table employees is date format "mm/dd/yyyy".  
<details><summary>More details...</summary> 

* Although it might be more concise to use a regular expression to implement this validation check, I went ahead and used only the native and thus more universal commands LIKE, REPLACE(), LENGTH(), TRIM(), etc.  Also, it allows for more specific rejection codes below.
* Note in the first WHEN clause the use of multiple REPLACE() commands that take a date like '04/01/2021" and convert all numeric digits or the slash character to '' such that the actual converted test string is '' to match the expected value of ''.
* Note in the second WHEN clause that the value is confirmed to be 10 characters in length
* Note in the third thru fifth WHEN clauses that each date part (year, month, day) is confirmed to be within an appropriate range.  
* Note that this simple format check is not date-aware; it will not detect leap years or months with < 31 days have the wrong values in place
* Note the use of rejection codes (REJ-01, etc.) at the inner query to clearly return why the validation check failed...run the inner query alone on fail to see details
</details>

```sql
SELECT some_date_fmt2
     , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                 some_date_fmt2,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'/','')
                 > ''                                                        THEN CONCAT('REJ-01: Unexpected Chars Exist|exp=Fmt="mm/dd/yyyy"|act=', some_date_fmt2)
            WHEN NOT LENGTH(TRIM(some_date_fmt2)) = 10                       THEN CONCAT('REJ-02: Must be 10 Chars|exp=Fmt="mm/dd/yyyy"|act=', some_date_fmt2)
            WHEN NOT SUBSTRING(some_date_fmt2,7,4) BETWEEN '1753' AND '9999' THEN CONCAT('REJ-03: Year Not Btw 1753-9999|exp=Fmt="mm/dd/yyyy"|act=', some_date_fmt2)
            WHEN NOT SUBSTRING(some_date_fmt2,1,2) BETWEEN '01' AND '12'     THEN CONCAT('REJ-04: Month Not Btw 01-12|exp=Fmt="mm/dd/yyyy"|act=', some_date_fmt2)
            WHEN NOT SUBSTRING(some_date_fmt2,4,2) BETWEEN '01' AND '31'     THEN CONCAT('REJ-05: Day Not Btw 01-31|exp=Fmt="mm/dd/yyyy"|act=', some_date_fmt2)
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t043" class="anchor" href="#t043" aria-hidden="true"> </a>
### T043 - IsDate("mm-dd-yyyy")
Verify text field is a date formatted as "mm-dd-yyyy".  For example, use the SQL below to verify that the field some_date_fmt3 in table employees is date format "mm-dd-yyyy".  
<details><summary>More details...</summary> 

* Although it might be more concise to use a regular expression to implement this validation check, I went ahead and used only the native and thus more universal commands LIKE, REPLACE(), LENGTH(), TRIM(), etc.  Also, it allows for more specific rejection codes below.
* Note in the first WHEN clause the use of multiple REPLACE() commands that take a date like '04-01-2021" and convert all numeric digits or the dash character to '' such that the actual converted test string is '' to match the expected value of ''.
* Note in the second WHEN clause that the value is confirmed to be 10 characters in length
* Note in the third thru fifth WHEN clauses that each date part (year, month, day) is confirmed to be within an appropriate range.  
* Note that this simple format check is not date-aware; it will not detect leap years or months with < 31 days have the wrong values in place
* Note the use of rejection codes (REJ-01, etc.) at the inner query to clearly return why the validation check failed...run the inner query alone on fail to see details
</details>

```sql
SELECT some_date_fmt3
     , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                 some_date_fmt3,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'-','')
                 > ''                                                        THEN CONCAT('REJ-01: Unexpected Chars Exist|exp=Fmt="mm-dd-yyyy"|act=', some_date_fmt3)
            WHEN NOT LENGTH(TRIM(some_date_fmt3)) = 10                       THEN CONCAT('REJ-02: Must be 10 Chars|exp=Fmt="mm-dd-yyyy"|act=', some_date_fmt3)
            WHEN NOT SUBSTRING(some_date_fmt3,7,4) BETWEEN '1753' AND '9999' THEN CONCAT('REJ-03: Year Not Btw 1753-9999|exp=Fmt="mm-dd-yyyy"|act=', some_date_fmt3)
            WHEN NOT SUBSTRING(some_date_fmt3,1,2) BETWEEN '01' AND '12'     THEN CONCAT('REJ-04: Month Not Btw 01-12|exp=Fmt="mm-dd-yyyy"|act=', some_date_fmt3)
            WHEN NOT SUBSTRING(some_date_fmt3,4,2) BETWEEN '01' AND '31'     THEN CONCAT('REJ-05: Day Not Btw 01-31|exp=Fmt="mm-dd-yyyy"|act=', some_date_fmt3)
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>


<a id="t044" class="anchor" href="#t044" aria-hidden="true"> </a>
### T044 - IsDate("yyyy-mm-dd")
Verify text field is a date formatted as "yyyy-mm-dd".  For example, use the SQL below to verify that the field some_date_fmt4 in table employees is date format "yyyy-mm-dd".  
<details><summary>More details...</summary> 

 * Although it might be more concise to use a regular expression to implement this validation check, I went ahead and used only the native and thus more universal commands LIKE, REPLACE(), LENGTH(), TRIM(), etc.  Also, it allows for more specific rejection codes below.
* Note in the first WHEN clause the use of multiple REPLACE() commands that take a date like '2021-04-01" and convert all numeric digits or the dash character to '' such that the actual converted test string is '' to match the expected value of ''.
* Note in the second WHEN clause that the value is confirmed to be 10 characters in length
* Note in the third thru fifth WHEN clauses that each date part (year, month, day) is confirmed to be within an appropriate range.  
* Note that this simple format check is not date-aware; it will not detect leap years or months with < 31 days have the wrong values in place
* Note the use of rejection codes (REJ-01, etc.) at the inner query to clearly return why the validation check failed...run the inner query alone on fail to see details
</details>

```sql
SELECT some_date_fmt4
     , CASE WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                 some_date_fmt4,'0',''),'1',''),'2',''),'3',''),'4',''),'5',''),'6',''),'7',''),'8',''),'9',''),'-','')
                 > ''                                                        THEN CONCAT('REJ-01: Unexpected Chars Exist|exp=Fmt="yyyy-mm-dd"|act=', some_date_fmt4)
            WHEN NOT LENGTH(TRIM(some_date_fmt4)) = 10                       THEN CONCAT('REJ-02: Must be 10 Chars|exp=Fmt="yyyy-mm-dd"|act=', some_date_fmt4)
            WHEN NOT SUBSTRING(some_date_fmt4,1,4) BETWEEN '1753' AND '9999' THEN CONCAT('REJ-03: Year Not Btw 1753-9999|exp=Fmt="yyyy-mm-dd"|act=', some_date_fmt4)
            WHEN NOT SUBSTRING(some_date_fmt4,6,2) BETWEEN '01' AND '12'     THEN CONCAT('REJ-04: Month Not Btw 01-12|exp=Fmt="yyyy-mm-dd"|act=', some_date_fmt4)
            WHEN NOT SUBSTRING(some_date_fmt4,9,2) BETWEEN '01' AND '31'     THEN CONCAT('REJ-05: Day Not Btw 01-31|exp=Fmt="yyyy-mm-dd"|act=', some_date_fmt4)
            ELSE 'P'
       END AS status
FROM demo_hr.employees;
```
<br>

