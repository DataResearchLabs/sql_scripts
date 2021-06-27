# How to Use the Basic Data Validation Script in Oracle
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
---

### Overview
This basic data validation script runs one of each type of data validation test case (T001-T066) shown in the Rule Set markdown (.md) pages.  All the SQL validation test cases run sequentially in Oracle SQL Developer, returning the test id, the test status (pass or fail), and the test desription.  Only one row is returned per validation test. To keep the process simple, output is streamed to the console (screen as text, not grids).


### Download
The basic validation script can be downloaded from [here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_validation_framework/sql_scripts/dvf_basic_script.sql).


### Script Composition 
The script currently consists of 1,064 lines of SQL code broken down as follows:
* Lines 1-44 are the comment block header, containing notes and definitions
* Lines 45-1,064 are the 66 individual example validation test cases (written as SQL SELECTs)


### What does a Typical Validation Test Case Look Like?
A typical data validation test looks something like the SQL code below for test case T031.  This test case validates that no carriage return (CR) or line feed (LF) characters exist in the last_name column. 

```sql
SELECT 'T031' AS tst_id
      , CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'P' END AS status
      , '"RS-6 Text" #11 - Verify No_CRLF_Chars() where [last_name] has no Carriage Returns (CHAR-13) or Line Feeds (CHAR-10) in table [employees]' AS tst_descr   
FROM (
  SELECT CASE WHEN INSTR(last_name, CHR(10))  > 0 THEN 'REJ-01: Field last_name has a Line Feed (CHR-10)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(10)) AS VARCHAR2(4))
 	        WHEN INSTR(last_name, CHR(13))  > 0 THEN 'REJ-02: Field last_name has a Carriage Return (CHR-13)|exp=none|act=at position ' || CAST(INSTR(last_name, CHR(13)) AS VARCHAR2(4))
 	        ELSE 'P'
 	   END AS status
  FROM demo_hr.employees
)
WHERE status <> 'P';
```
Notice the following aspects of the SQL code:
1. Each data validation test case is written as one or more SQL SELECT statements.
2. There is one (or more) **inner queries**
    * These return all rows with business validation logic applied.  
    * Highlight and run just the inner query SELECT(s) to see all relevant rows with specific failure details
    * In the example above, the inner status field returns rejection codes detailing the ID of the rejection, the expected result (no CR or LFs), and the actual result including the position of the bad character in the source field.
3. There is one **outer query** (or wrapper)
    * It rolls all the detail rows up to a single row with pass or fail judgment.
    * It returns column **tst_id** - the test ID (hard-coded when write script)
    * It returns column **status** - the test result (re-calculated with every test run).  Usually "P" for pass or "FAIL"...or add your own such as "WARN", "SKIP", or "BLOCK"
    * It returns column **tst_dscr** - the data validation test description (hard-coded when write script)




