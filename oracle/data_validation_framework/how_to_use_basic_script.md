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
* Lines 45-1,064 are the seaprate validation test cases written as SQL SELECTs

Each data validation test will display one row of output containing the following columns:
* **tst_id**: The data validation Test ID
* **status**: The data validation test result.  Usually "P" for pass or "FAIL".  However, you can invent your own status values too, such as "WARN", "SKIP", or "BLOCK"
* **tst_dscr**: The data validation test description.
