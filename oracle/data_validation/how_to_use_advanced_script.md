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
1. Download the "demo_hr" schema / table definitions from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_validation/demo_data/demo_hr_01_create_tables.sql)</b>.
2. Run the script on an Oracle server and database where you have permissions (local is fine too).
3. Download the "demo_hr" test data population script from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_validation/demo_data/demo_hr_02_populate_tables.sql)</b>.
4. Run the script on the same Oracle server and database.
5. Using Oracle SQL Developer (or equivalent SQL IDE), confirm that the tables exist and the data is populated.
</details>
<br>

### Step 3 - Download & Execute the Advanced "Setup" Script
<details><summary>Expand if you need instructions on how to download and execute the setup script (to build "temp" tables)...</summary><br>
   
1. Download the advanced setup script from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_validation/sql_scripts/dv_advanced_01_setup.sql)</b>.
2. There are **no** configuration changes needed for the script, it will work out of the box against the demo_hr schema created in Step #2 above.
3. Pick an appropriate directory in which to save the script.  Open your SQL Editor pointing to the appropriate Oracle Server and demo_hr schema.
4. Execute the script and confirm the two empty tables ("test_case_results" and "test_case_config") now exist in the demo_hr schema.
</details>
<br>

### Step 4 - Download and Configure the Advanced "Test Cases" Script
<details><summary>Expand if you need instructions on how to download and execute the setup script (to build "temp" tables)...</summary><br>
   
1. Download the advnaced validation setup script from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_validation/sql_scripts/dv_advanced_02_test_cases.sql)</b>.
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

<img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/img/03_data_val_oracle_adv_test_case_ex.png">

Notice the following aspects of the SQL code above:
1. Each data validation test case is written as multiple SQL SELECT statements using a CTE (common table expression).  The format is WITH tbl_nm as sql, tbl_nm_2 as sql, etc.

2. There are two blocks of SQL for every data validation test case: 
    (a) Yellow lines 1674 thru 1694 that you customize for every test case
    (b) Blue lines 1695 thr 1720 (plus line 1673) that are boilerplate and never change -- simply copy paste them over and over to automatically setup the header and detail rows  

3. Line 1673 sets up the entire data validation test case SQL query as an INSERT INTO the "temp" table test_case_results.
   
4. Lines 1674-1679 establish the first subquery "cfg".  This is where you cahnge the test case number (eg: 'T031') and the test case description (ilne 1677) when you refactor these.
   
5. Lines 1680-1690 establish the second subquery "dut" -- the Data Under Test.  Here is where the target table and field are queried and frequently (but not always) where the rejection code logic is applied at the row level (lines 1682-1686).  Notice in this example that not only is the rejection code listed (eg: REJ-01 + details), but the expected result (none exist) and the actual result including the location within the string is returned.  This provides 100% of the information needed to resolve the error...good enough to pass diretly on to the person who will fix the data without an analyst having to manually confirm or research to dial-in the problem first.
   
6. Lines 1691-1694 are where higher level business logic goes (especially when aggregating data or doing multiple passes on a dataset).  In this simpler example, we just filter the "dut" dataset down to only those rows that were rejected (and ignore the vast majority of rows that were "allgood".
   
7. Lines 1695-1704 are the start of the boilerplate code (copy-paste / never change).  This "hdr" sub query is used to ensure that every test case always has a header row in the test results table, regardless of whether there are error details or not.  The test ID, test description, and test status are all written to this one row per test case.
   
8. Lines 1705-1715 are the second boilerplace subquery named "fdtl" -- short for fail details.  Only failed test cases will have rows in this subquery.  It contains the same test ID, test description and status (fail) as the header record (so they sort together in output).  However, these records also tack on additional valuable columns to the right: rej_dtls nad lookup_sql.  Both column names indicate what they are for:
    (a) Rejection details (REJ-ID, rejection description, expected vs. actual values, etc.), and 
    (b) Lookup sql that you can copy-paste-execute to return the exact source row that failed with all its values (you specify as done in line 1688 abovve)
   
9. Finally, lines 1716-1720 are the final boilerplate subquery that ties it all together (last subquery in a CTE has no name).  This simple little query unions the "hdr" row with all "fdtl" rows, if any.  The INSERT INTO at line 1673 picks these all up and write them out to our temp table "test_case_results".
</details>
<br>

### Setp 6 - Execute the Advanced Data Validation Script
<details><summary>Expand if you would like to see how to execute the advanced script, step-by-step...</summary><br>

Here are the steps to execute the advanced script in Oracle SQL Developer (typical output shown in the screenshot below).  
1. Open Oracle SQL Developer (or equivalent SQL Editor)
2. Blue Dot #1 - You must load the advanced validation script "dvf_advanced_02_test_cases.sql" into SQL Developer (or equivalent IDE) -- see Step 4 above.  Be sure to highlight all the code.
3. Blue Dot #2 - Click the "Run Statement" button (or equivalent in other IDEs) to run all 66 data validation test cases as INSERT INTOs, plus the final summary reoprt SELECT.
4. Blue Dot #3 - The output is beautifully laid out for all data validation test cases in a grid.  You can scroll and view the grid details, or export it out to a file using your SQL Editor.  Fields include everything, from test id, test description, and status to test case execution time, start time, rejection details, expected and actual results, and lookup SQL.

<img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/img//04_data_val_oracle_run_results_adv.png">

</details>
<br>

### Next Steps - Build Your Own Validation Test Script(s)
You could just skip reading all the sections above and jump directly down here.  Be sure to expand Step #4 to download a copy of the advanced test case scripts that you will refactor to suit your needs.

Here are my recommendations for writing your validation script(s):
1. **Learn**: You really should expand and read Step 5 above.  It goes into a lot of detail about how the test case script works, what the various blocks of code do, etc.
2. **Reference**: I would suggest that you open the advanced test case script as a reference in notepad or text editor of your choice and position it off on a second monitor to the side.
3. **Main Editor**: Open Oracle SQL Developer with a blank new script that you are going to build out for your tests as follows:
4. **Comment Block**:  Create your own comment block at the top of your script, pulling anything of value from lines 1-44, but tailoring them to your specific scenario
5. **Select Schema**: You will have a schema (database) that is "under test".  Identify it.  List it in the comment block.  Prefix all SQL code with it going forward (below).
6. **Table #1**:  Pick the first table for which you are going to start writing validation cases for.  Could be the first table alphabetically. Could be a highest priority table you want to begin writing validation checks against (biggest bang for the buck).  Could be the simplest table to ease in with baby steps (low-hanging fruit).  You decide.
7. **Rule Set #1 - Row Counts**: Start off with an appropriate "Row Count" test case that applies to the entire table.  Pick one from T001 - T004.  Change the scehma name prefix, the table name, and if appropriate the column names.  Highlight and run it in your SQL editor to validate the SQL.  Change the "tst_id" number to your own.  Change the tst_descr to your own.
8. **Rule Set #8 - Diff Checks**: These diff checks in T059-T061 operate at the table-level just like Rule Set #1 Row Counts, so I suggest grouping them together at the top of each table's validation tests.
9. **Rule Set #2 - Keys**: Next, if and only if there are missing unique key constraints or foreign key constraints, then I'd copy-paste the appropriate test cases T005-T007 into the SQL editor and make appropriate changes (schema name, table names, field names, tst_id, and tst_descr).
10. **Rule Set #3 - Heuristics**: Next, if and only if it is appropriate to test Null Rates for specific fields of "Table #1" then I'd copy test case T008 into the SQL Editor and make all the appropriate changes (and there are a lot...schema name, table name, many column names, copy-paste or delete CASE WHEN rows and SELECT CAST rows for each  column you want to add or remove...see my YouTube video for a demo).<br>
Likewise, if there are particular fields in "Table #1" that you'd like to setup threshold alerts for on frequency of observed values, then you copy-paste-modify T009 the appropriate number of times...once per field.
11. **Rule Set #4-#7**: The bulk of the remaining example validation checks are field by field.  You can write the test cases one table, and one field at a time...mixing and matching from these sample validation checks as needed.  This granular approach can make fails readily apparent.  However, you can alterantively combine dozens of these same checks into a single table-scan pass to greatly improve performance (best practice example in T065).  Your choice.  Bottom line, a lot of copy-paste-modifying SQL code from test cases T010-T058.
12. **Rule Set #9**: Add in any defect regression tests as appropriate
13. **Finishing Touches**: Don't forget to apply the best practice examples in data validation test cases T062-T066

And then repeat items 1-13 above for the next table.  And again for the next table, and so on until you are done.  Your choice whether to write one giant 5-10,000 line script for the entire schema, or break down into separate scripts for each table or logical table grouping. 
