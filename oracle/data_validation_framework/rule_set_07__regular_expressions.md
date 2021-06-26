# Rule Set #7 - Regular Expressions
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

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
  SELECT CASE WHEN NOT REGEXP_LIKE(phone_number, '[0-9]{3}[-. ][0-9]{3}[-. ][0-9]{4}') THEN 'FAIL' ELSE 'P' END AS status
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
  SELECT CASE WHEN NOT REGEXP_LIKE(fake_ssn, '^[0-9]{3}-[0-9]{2}-[0-9]{4}$') THEN 'FAIL' ELSE 'P' END AS status
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
  SELECT CASE WHEN NOT REGEXP_LIKE(zip5, '^[0-9]{5}$') THEN 'FAIL' ELSE 'P' END AS status
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
  SELECT CASE WHEN NOT REGEXP_LIKE(zip5or9, '^([[:digit:]]{5})(-[[:digit:]]{4})?$') THEN 'FAIL' ELSE 'P' END AS status
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
  SELECT CASE WHEN NOT REGEXP_LIKE(zip9, '^[[:digit:]]{5}[-/.][[:digit:]]{4}$') THEN 'FAIL' ELSE 'P' END AS status
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
  SELECT CASE WHEN NOT REGEXP_LIKE(last_name, '^[a-zA-Z ]+$') THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
 ```
<br>


