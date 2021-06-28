# How to Use the Advanced Data Validation Scripts in Oracle
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
---

### Overview
The advanced data validation scripts runs the exact same 66 test cases (T001-T066) as the basic script.  
However, this pair of scripts is more sophisticated as follows:
1. Output is written to a "temp" table during the test execution phase, then returned as a single SELECT grid at the end
2. There are two scripts, one to generate the "temp" tables and one to execute the test cases
3. The output is more comprehensive than just test id, status, and description.  The output also includes detailed rejection codes, expected results, and actual results behind every fail.
<br><br>

### Step 1 - Download & Install Oracle SQL Developer
<details><summary>Expand if you want to download and install Oracle SQL Developer...</summary><br>

1. Oracle provides a powerful SQL editor named "Oracle SQL Developer" for free download and use.  
2. If it is not already installed on your machine (and you're not using another database IDE like Toad), then download from <b>[here](https://www.oracle.com/tools/downloads/sqldev-downloads.html)</b> and install, following the prompts.
</details>
<br>

### Step 2 - Download & Deploy the Demo Data
<details><summary>Expand if you want to download and deploy the "demo_hr" test dataset...</summary><br>

If you'd like to run the test script as-is first, before copy-pasting the concepts out and applying to yuor own databases, then you will need to download and deploy the demo_hr test dataset.
1. Download the "demo_hr" schema / table definitions from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_validation_framework/demo_data/demo_hr_01_create_tables.sql)</b>.
2. Run the script on an Oracle server and database where you have permissions (local is fine too).
3. Download the "demo_hr" test data population script from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_validation_framework/demo_data/demo_hr_02_populate_tables.sql)</b>.
4. Run the script on the same Oracle server and database.
5. Using Oracle SQL Developer (or equivalent SQL IDE), confirm that the tables exist and the data is populated.
</details>
<br>

### Step 3 - Download & Execute the Advanced "Setup" Script
<details><summary>Expand if you need instructions on how to download and execute the setup script (to build "temp" tables)...</summary><br>
   
1. Download the advanced setup script from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_validation_framework/sql_scripts/dvf_advanced_01_setup.sql)</b>.
2. There are **no** configuration changes needed for the script, it will work out of the box against the demo_hr schema created in Step #2 above.
3. Pick an appropriate directory in which to save the script.  Open your SQL Editor pointing to the appropriate Oracle Server and demo_hr schema.
4. Execute the script and confirm the two empty tables ("test_case_results" and "test_case_config") now exist in the demo_hr schema.
</details>
<br>

### Step 4 - Download and Configure the Advanced "Test Cases" Script
<details><summary>Expand if you need instructions on how to download and execute the setup script (to build "temp" tables)...</summary><br>
   
1. Download the advnaced validation setup script from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_validation_framework/sql_scripts/dvf_advanced_02_test_cases.sql)</b>.
2. Make the appropriate changes to lines 70-71 to insert parameter names and values your script needs nito the "test_case_config" table.  Note that you will keep coming back here to expand the list as you write SQL code for your test cases below. You'll notice yourself repeating hard-coded values and want to centralize them in one spot here in this table.
</details>
<br>

### Step 5 - Review the Advanced "Test Cases" Script
<details><summary>Expand if you would like to see a review of the script layout and what each data validation test case looks like ...></summary><br>

The script currently consists of 3,674 lines of SQL code (3x bigger than the basic script) and is broken down as follows:
* Lines 1-63 are the comment block header, containing notes and definitions
* Lines 64-75 are to populate the configuration table with parameter names and values
* Lines 76-3,612 are the 66 individual example validation test cases (written as SQL SELECTs with a lot of boilerplate code)
* Lines 3,613-3,637 are used to calculate the test case execution time -- very handy for tuning the data validation performance (if a test runs long, speed it up by only checking the past 1-5 days, or refactor the SQL, or combine with other tests into one large single pass table scan query).  Also, you can monitor the test case execution time over weeks and months to spot system performance issues (eg: need an archiving strategy b/c table getting too large, or need a covering index for where clause condition, etc.)
* Lines 3,638-3,674 are used to organize and post the test case results as a "report" (splits out expected and actual values into own column, etc.)
<br>

A typical data validation test has SQL code that looks something like this one -- T031 which checks for carriage return or line feed characters in field last_name: <br>  

<img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/06_data_val_oracle_adv_test_case_ex.png">

Notice the following aspects of the SQL code above:
1. Each data validation test case is written as multiple SQL SELECT statements using a CTE (common table expression).  The format is WITH tbl_nm as sql, tbl_nm_2 as sql, etc.

2. There are two blocks of SQL for every data validation test case: 
    (a) Yellow lines 1674 thru 1694 that you customize for every test case
    (b) Blue lines 1695 thr 1720 (plus line 1673) that are boilerplate and never change -- simply copy paste them over and over to automatically setup the header and detail rows  

3. Line 1673 sets up the entire data validation test case SQL query as an INSERT INTO the "temp" table test_case_results.
   
4. Lines 1674 thru 1679 establish the first subquery "cfg".  This is where you cahnge the test case number (eg: 'T031') and the test case description (ilne 1677) when you refactor these.
   
5. Lines 1680 thru 1690 establish the second subquery "dut" -- the Data Under Test.  Here is where the target table and field are queried and frequently (but not always) where the rejection code logic is applied at the row level (lines 1682-1686).  Notice in this example that not only is the rejection code listed (eg: REJ-01 + details), but the expected result (none exist) and the actual result including the location within the string is returned.  This provides 100% of the information needed to resolve the error...good enough to pass diretly on to the person who will fix the data without an analyst having to manually confirm or research to dial-in the problem first.
   
6. Lines 1691 thru 1694 are where higher level business logic goes (especially when aggregating data or doing multiple passes on a dataset).  In this simpler example, we just filter the "dut" dataset down to only those rows that were rejected (and ignore the vast majority of rows that were "allgood".
   
7. 
   

   
   3. There is one **outer query** (lines 449-452 and 461-462)
    * It rolls all the detail rows up to a single summary row with pass or fail judgment.
    * It returns column **tst_id** - the test ID (hard-coded when write script)
    * It returns column **status** - the test result (re-calculated with every test run).  Usually "P" for pass or "FAIL"...or add your own such as "WARN", "SKIP", or "BLOCK"
    * It returns column **tst_dscr** - the data validation test description (hard-coded when write script)
</details>
<br>

### Setp 5 - Execute the Basic Data Validation Script
Here are the steps to execute the basic script in Oracle SQL Developer (typical output show in the screenshot below).  
1. Open Oracle SQL Developer (or equivalent SQL Editor)
2. Blue Dot #1 - You must load the basic validation script into SQL Developer (or equivalent IDE)
3. Blue Dot #2 - Be sure to click the "Run script" button (or equivalent in other IDEs) so that all test cases will output to a single text document on screen (**not** as 66 separate grids)
4. Blue Dot #3 - The output is concisely laid out for all data validation test cases.  The red-boxed test case includes test_id (eg: T001) in column #1, followed by the status (eg: pass or fail) in column #2, and finally ends with the test description on the right in column #3 (because width varies so much want it on the end for better readability).
<img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/05_data_val_oracle_run_results1.png">
