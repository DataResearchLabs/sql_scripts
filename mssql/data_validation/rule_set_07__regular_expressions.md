### Data Validation Examples - MS SQL Server
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
#### [Return to Data Validation Home Page](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_validation_scripts.md)
<br>

# Rule Set #7 - Regular Expressions

## Table of Contents
 - <a href="#t045">T045 - RegExp("IsPhoneNumber")</a>
 - <a href="#t046">T046 - RegExp("IsSSN")</a>
 - <a href="#t047">T047 - RegExp("IsZip5")</a>
 - <a href="#t048">T048 - RegExp("IsZip5or9")</a>
 - <a href="#t049">T049 - RegExp("IsZip9")</a>
 - <a href="#t050">T050 - RegExp("OnlyText")</a>
 - <a href="#t051">T051 - RegExp("OnlyNumeric")</a>
 - <a href="#t052">T052 - RegExp("NoLeadTrailSpaces")</a>
 - <a href="#t053">T053 - RegExp("NoWhitespaces")</a>
 - <a href="#t054">T054 - RegExp("OnlyLowerCase")</a>
 - <a href="#t055">T055 - RegExp("OnlyUpperCase")</a>
 - <a href="#t056">T056 - RegExp("TitleCase")</a>
 - <a href="#t057">T057 - RegExp("EmailAddress")</a>
 - <a href="#t058">T058 - RegExp("IsUrl")</a>
<br>


<a id="t045" class="anchor" href="#t045" aria-hidden="true"> </a>
### T045 - RegExp("IsPhoneNumber")
Verify text field is a phone number format.  For example, to verify that field phone_number of table employees is either US or international format:
 ```sql
 SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
 FROM (
   -- NOTE: Use RegEx pattern "^\+(\d+\s?)+$" for international phone numbers
  SELECT phone_number
       , CASE WHEN NOT REGEXP_LIKE(phone_number, '[0-9]{3}[-. ][0-9]{3}[-. ][0-9]{4}') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t046" class="anchor" href="#t046" aria-hidden="true"> </a>
### T046 - RegExp("IsSSN")
Verify text field is a valid social security number (SSN) format.  For example, to verify that field fake_ssn of table employees is a valid SSN format:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT fake_ssn
       , CASE WHEN NOT REGEXP_LIKE(fake_ssn, '^[0-9]{3}-[0-9]{2}-[0-9]{4}$') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t047" class="anchor" href="#t047" aria-hidden="true"> </a>
### T047 - RegExp("IsZip5")
Verify text field is a valid zipcode 5-digit format.  For example, to verify that field zip5 of table employees is a valid format:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT zip5
       , CASE WHEN NOT REGEXP_LIKE(zip5, '^[0-9]{5}$') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t048" class="anchor" href="#t048" aria-hidden="true"> </a>
### T048 - RegExp("IsZip5or9")
Verify text field is a valid zipcode 5- or 9-digit format.  For example, to verify that field zip5or9 of table employees is a valid format:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT zip5or9
       , CASE WHEN NOT REGEXP_LIKE(zip5or9, '^[[:digit:]]{5}(-[[:digit:]]{4})?$') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t049" class="anchor" href="#t049" aria-hidden="true"> </a>
### T049 - RegExp("IsZip9")
Verify text field is a valid zipcode 9-digit format.  For example, to verify that field zip9 of table employees is a valid format:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT zip9
       , CASE WHEN NOT REGEXP_LIKE(zip9, '^[[:digit:]]{5}[-/.][[:digit:]]{4}$') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t050" class="anchor" href="#t050" aria-hidden="true"> </a>
### T050 - RegExp("OnlyText")
Verify text field is text / only contains alpha characters.  For example, to verify that field last_name of table employees is text only:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT last_name
       , CASE WHEN NOT REGEXP_LIKE(last_name, '^[a-zA-Z ]+$') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t051" class="anchor" href="#t051" aria-hidden="true"> </a>
### T051 - RegExp("OnlyNumeric")
Verify text field numeric characters only.  For example, to verify that field zip5 of table employees is numeric digits only:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT zip5
       , CASE WHEN NOT REGEXP_LIKE(zip5, '^[0-5]+$') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t052" class="anchor" href="#t052" aria-hidden="true"> </a>
### T052 - RegExp("NoLeadTrailSpaces")
Verify text field has no leading or trailing spaces.  For example, to verify that field last_name of table employees is fully trimmed:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT last_name
       , CASE WHEN REGEXP_LIKE(last_name, '(^\s)|(\s$)') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t053" class="anchor" href="#t053" aria-hidden="true"> </a>
### T053 - RegExp("NoWhitespaces")
Verify text field has no whitespace (spaces, non breaking spaces, carriage return, line feed, etc.).  For example, to verify that field job_id of table employees has no whitespace:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT job_id
       , CASE WHEN REGEXP_LIKE(job_id, '(\s)+') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t054" class="anchor" href="#t054" aria-hidden="true"> </a>
### T054 - RegExp("OnlyLowerCase")
Verify text field has only lower case characters.  For example, (not really practical, but as a demo) to verify that the 3rd and 4th characters in the field first_name of table employees are lower case:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT first_name
       , CASE WHEN NOT REGEXP_LIKE(SUBSTR(first_name,3,2), '^[a-z]+$') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t055" class="anchor" href="#t055" aria-hidden="true"> </a>
### T055 - RegExp("OnlyUpperCase")
Verify text field has only upper case characters.  For example, to verify that all characters are uppercase in the field first_name of table employees:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT email
       , CASE WHEN NOT REGEXP_LIKE(SUBSTR(email,3,2), '^[A-Z]+$') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t056" class="anchor" href="#t056" aria-hidden="true"> </a>
### T056 - RegExp("TitleCase")
Verify text field is title case format (where the first letter of every word is upper case, and the rest are lower case).  For example, to verify that the field first_name of table employees has proper casing:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
 	SELECT first_name, SUBSTR(first_name,1,1) AS first_letter
       , CASE WHEN NOT REGEXP_LIKE(SUBSTR(first_name,1,1), '([A-Z])') THEN 'REJ-01: Field first_name first character not upper case|exp=Like"[A-Z]"|act=' || first_name 
              WHEN first_name NOT LIKE '% %'                          THEN 'P'  -- Only one word, so no space + first character to check for uppercase
              WHEN NOT REGEXP_LIKE(first_name, '(\s[A-Z]){1}')        THEN 'REJ-02: Field first_name failed RegExpression check|exp=Like"(\s[A-Z]){1}"|act=' || first_name 
              ELSE 'P'
         END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t057" class="anchor" href="#t057" aria-hidden="true"> </a>
### T057 - RegExp("EmailAddress")
Verify text field is a properly formatted email address.  For example, to verify that the field email_address of table employees is properly formatted:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT email_address
       , CASE WHEN NOT REGEXP_LIKE(email_address, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


<a id="t058" class="anchor" href="#t058" aria-hidden="true"> </a>
### T058 - RegExp("IsUrl")
Verify text field is a properly formatted URL.  For example, to verify that the field url of table departments is properly formatted with "http://" or "https://":
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT url
       , CASE WHEN NOT REGEXP_LIKE(url, '(http)(s)?(:\/\/)') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.departments
)
WHERE status <> 'P';
 ```
<br>

