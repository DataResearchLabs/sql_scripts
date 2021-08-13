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
    SELECT phone_number
         , CASE WHEN phone_number NOT LIKE '[0-9][0-9][0-9][-. ][0-9][0-9][0-9][-. ][0-9][0-9][0-9][0-9]' THEN 'FAIL' ELSE 'P' END AS status
    FROM demo_hr..employees
) t
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
       , CASE WHEN fake_ssn NOT LIKE '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
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
       , CASE WHEN zip5 NOT LIKE '[0-9][0-9][0-9][0-9][0-9]' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
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
       , CASE WHEN zip5or9 NOT LIKE '[0-9][0-9][0-9][0-9][0-9]'
	              AND zip5or9 NOT LIKE '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
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
       , CASE WHEN zip9 NOT LIKE '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
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
       , CASE WHEN last_name LIKE '%[^a-zA-Z ]%' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
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
       , CASE WHEN zip5 LIKE '%[^0-9.]%' THEN 'FAIL' ELSE 'P' END AS status
 	FROM demo_hr..employees
) t
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
       , CASE WHEN last_name LIKE ' %' OR last_name LIKE '% ' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
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
       , CASE WHEN job_id LIKE '% %'
                OR job_id LIKE '%' + CHAR(13) + '%'
                OR job_id LIKE '%' + CHAR(10) + '%' 
                OR job_id LIKE '%' + CHAR(9) + '%'
                OR job_id LIKE '%' + CHAR(160) + '%' THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
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
       , CASE WHEN SUBSTRING(first_name COLLATE SQL_Latin1_General_CP1_CS_AS, 3, 2) <> LOWER(SUBSTRING(first_name COLLATE SQL_Latin1_General_CP1_CS_AS, 3, 2))  
	      THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
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
       , CASE WHEN SUBSTRING(email COLLATE SQL_Latin1_General_CP1_CS_AS, 3, 2) <> UPPER(SUBSTRING(email COLLATE SQL_Latin1_General_CP1_CS_AS, 3, 2)) 
              THEN 'FAIL' ELSE 'P' END AS status
  FROM demo_hr..employees
) t
WHERE status <> 'P';
 ```
<br>


<a id="t056" class="anchor" href="#t056" aria-hidden="true"> </a>
### T056 - RegExp("TitleCase")
Verify text field is title case format (where the first letter of every word is upper case, and the rest are lower case).  For example, to verify that the field first_name of table employees has proper casing:
 ```sql
SELECT CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
FROM (
  SELECT first_name, SUBSTRING(first_name,1,1) AS first_letter
  , CASE WHEN first_name COLLATE SQL_Latin1_General_CP1_CS_AS NOT LIKE '[A-Z]%'       THEN 'REJ-01: Field first_name first character not uppercase|exp=Like"[A-Z]%"|act=' + first_name 
         WHEN first_name COLLATE SQL_Latin1_General_CP1_CS_AS LIKE '[A-Z]%[^a-z]%'    THEN 'REJ-02: Field first_name characters in first word after first character not lowercase|exp=all lower case"|act=' + first_name
         WHEN first_name NOT LIKE '% %'                                               THEN 'P'  -- Only one word, so no space + first character to check for uppercase
         WHEN first_name COLLATE SQL_Latin1_General_CP1_CS_AS LIKE '% [^A-Z]%'        THEN 'REJ-03: Field first_name first character after space is not uppercase|exp=IsUCASE|act=' + first_name 
         WHEN first_name COLLATE SQL_Latin1_General_CP1_CS_AS LIKE '% [A-Z][^a-z]%'   THEN 'REJ-04: Field first_name characters after space + one letter are not lowercase|exp=IsUCASE|act=' + first_name 
         ELSE 'P'
    END AS status
  FROM demo_hr..employees
) t
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
  , CASE WHEN email_address IS NULL                                     THEN 'REJ-01: Field email_address is NULL'
         WHEN email_address = ''                                        THEN 'REJ-02: Field email_address is blank'
         WHEN email_address LIKE '%["(),:;<>\]%'                        THEN 'REJ-03: Field email_address contains bad characters ["(),:;<>\]'
         WHEN SUBSTRING(email_address, CHARINDEX('@', email_address), len(email_address)) LIKE '%[!#$%&*+/=?^`_{|]%'
              THEN 'REJ-04: Field email_address company name after @ contains bad characters [!#$%&*+/=?^`_{|]'
         WHEN LEFT(email_address,1) LIKE '[-_.+]'                       THEN 'REJ-05: Field email_address should not start with [-_.+] characters'
         WHEN RIGHT(email_address,1) LIKE '[-_.+]'                      THEN 'REJ-06: Field email_address should not end with [-_.+] characters'
         WHEN email_address LIKE '%[%' OR email_address LIKE '%]%'      THEN 'REJ-07: Field email_address should not contain [ or ] characters'
         WHEN email_address LIKE '%@%@%'                                THEN 'REJ-08: Field email_address should not contain more than one @ character'
         WHEN email_address LIKE '[_]%@[_]%@[_]%'                       THEN 'REJ-09: Field email_address should not have leading underscores at any segment (gmail blocks)'
         ELSE 'P' 
    END AS status
  FROM demo_hr..employees
) t
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
  , CASE WHEN url NOT LIKE'http://%' 
          AND url NOT LIKE'https://%'                                  THEN 'REJ-01: Field url is missing "http://" and "https://"|exp=Like"http(s)://"|act=' + url 
         WHEN url NOT LIKE '%[A-Z0-9][.][A-Z0-9]%[A-Z0-9]%'            THEN 'REJ-02: Field is not alphanumeric + "." + alphanumeric + "/" + alphanumeric|exp=aaaa.aaa|act=' + url 
       --WHEN url NOT LIKE '%[A-Z0-9][.][A-Z0-9]%[A-Z0-9][/][A-Z0-9]%' THEN 'REJ-03: Field is not alphanumeric + "." + alphanumeric + "/" + alphanumeric|exp=aaaa.aaa/aaa|act=' + url 
         ELSE'P' 
    END AS status
  FROM demo_hr..departments
) t
WHERE status <> 'P';
 ```
<br>

