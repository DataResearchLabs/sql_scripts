# How to Use the Basic Data Validation Script in Oracle
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
---

### Overview
This basic data validation script runs one of each type of data validation test case (T001-T066) shown in the Rule Set markdown (.md) pages.  All the SQL validation test cases run sequentially in Oracle SQL Developer, returning the test id, the test status (pass or fail), and the test desription.  Only one row is returned per validation test. To keep the process simple, output is streamed to the console (screen as text, not grids).
<br>


### Download
The basic validation script can be downloaded from [here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_validation_framework/sql_scripts/dvf_basic_script.sql).
<br>


### Script Composition 
The script currently consists of 1,064 lines of SQL code broken down as follows:
* Lines 1-44 are the comment block header, containing notes and definitions
* Lines 45-1,064 are the 66 individual example validation test cases (written as SQL SELECTs)
<br>


### What does the SQL Code Behind a Typical Validation Test Case Look Like?
A typical data validation test has SQL code that looks something like this: <br>  

<img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/04_data_val_oracle_example_test_case_sql_code.png">

This test case validates that no carriage return (CR) or line feed (LF) characters exist in the last_name column across all rows. 

Notice the following aspects of the SQL code:
1. Each data validation test case is written as one or more SQL SELECT statements.

2. There is one (or more) **inner queries**  (lines 453-459 above)
    * These return many detail rows with business validation logic applied.  
    * The columns returned vary by validation test case, but typically have a primary key or unique key value returned so you can easily identify which row faile
    * There is also always a status field returned with a unique rejection code (eg: REJ-01 above) with the expected result (no CR or LFs), and the actual result including the position of the bad character in the source field.
    * Note that you can highlight and run just the inner query SELECT(s) to see all relevant rows with specific failure details    

3. There is one **outer query** (lines 449-452 and 461-462)
    * It rolls all the detail rows up to a single summary row with pass or fail judgment.
    * It returns column **tst_id** - the test ID (hard-coded when write script)
    * It returns column **status** - the test result (re-calculated with every test run).  Usually "P" for pass or "FAIL"...or add your own such as "WARN", "SKIP", or "BLOCK"
    * It returns column **tst_dscr** - the data validation test description (hard-coded when write script)


### What do the Run Results Look Like?
When you run the script in Oracle SQL Developer ([free download here](https://www.oracle.com/tools/downloads/sqldev-downloads.html)), the following output is returned:



