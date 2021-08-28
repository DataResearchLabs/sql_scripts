### Data Validation Examples - MS SQL Server
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
#### [Return to Data Validation Home Page](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_validation_scripts.md)


# How to Use the Basic Data Validation Script in MS SQL Server

### Overview
This basic data validation script runs one of each type of data validation test case (T001-T066) shown in the Rule Set markdown (.md) pages.  All the SQL validation test cases run sequentially in SQL Server Management Studio, returning the test id, the test status (pass or fail), and the test description.  Only one row is returned per validation test. To keep the process simple, output is streamed to the console (screen as text, not grids).
<br><br>

### Step 1 - Download & Install Microsoft SQL Server Management Studio (SSMS)
<details><summary>Expand if you want to download and install SSMS...</summary><br>

1. Microsoft provides a powerful SQL editor named "SQL Server Management Studio", or SSMS, for free download and use.  
2. If it is not already installed on your machine (and you're not using another database IDE like Toad), then download from <b>[here](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver15)</b> and install, following the prompts.
</details>
<br>

### Step 2 - Download & Deploy the Demo Data
<details><summary>Expand if you want to download and deploy the "demo_hr" test dataset...</summary><br>

If you'd like to run the test script as-is first, before copy-pasting the concepts out and applying to your own databases, then you will need to download and deploy the demo_hr test dataset.
1. Download the "demo_hr_01_create_database.sql" script from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/mssql/data_validation/demo_data/demo_hr_01_create_database.sql)</b>.
2. Run the script on a SQL Server database where you have permissions (local is fine too).
3. Download the "demo_hr_02_create_tables.sql" script from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/mssql/data_validation/demo_data/demo_hr_02_create_tables.sql)</b>.
4. Run the script on the same SQL Server database.
5. Download the "demo_hr_03_populate_tables.sql" script from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/mssql/data_validation/demo_data/demo_hr_03_populate_tables.sql)</b>.
6. Run the script on the same SQL Server database.
7. Using SSMS (or an equivalent SQL IDE), confirm that the tables exist and the data is populated.
</details>
<br>

### Step 3 - Download the Basic Data Validation Script
<details><summary>Expand if you need instructions on how to download and configure the basic script...</summary><br>
   
1. Download the basic validation script from <b>[here](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/mssql/data_validation/sql_scripts/dv_basic_test_cases.sql)</b>.
2. Pick an appropriate directory in which to save the script.  Open your SQL Editor pointing to the appropriate SQL Server "demo_hr" database.
</details>
<br>

### Step 4 - Review the Basic Data Validation Script
<details><summary>Expand if you would like to see a review of the script layout and what a typical data validation test case looks like ...></summary><br>

The script currently consists of 1,156 lines of SQL code broken down as follows:
* Lines 1-41 are the comment block header, containing notes and definitions
* Lines 42-1,156 are the 66 individual example validation test cases (written as SQL SELECTs)

A typical data validation test has SQL code that looks something like this: <br>  

<img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/img/01_data_val_mssql_example_test_case_sql_code.png">

This test case validates that no carriage return (CR) or line feed (LF) characters exist in the last_name column across all rows. 

Notice the following aspects of the SQL code:
1. Each data validation test case is written as one or more SQL SELECT statements.

2. There is one (or more) **inner queries**  (lines 477-484 above)
    * These return many detail rows with business validation logic applied.  
    * The columns returned vary by validation test case, but typically have a primary key or unique key value returned so you can easily identify which row failed
    * There is also always a status field returned with a unique rejection code (eg: REJ-01 above) with the expected result (no CR or LFs), and the actual result including the position of the bad character in the source field.
    * Note that you can highlight and run just the inner query SELECT(s) to see all relevant rows with specific failure details    

3. There is one **outer query** (lines 473-476 and 485-485)
    * It rolls all the detail rows up to a single summary row with pass or fail judgment.
    * It returns column **tst_id** - the test ID (hard-coded when write script)
    * It returns column **status** - the test result (re-calculated with every test run).  Usually "P" for pass or "FAIL"...or add your own such as "WARN", "SKIP", or "BLOCK"
    * It returns column **tst_dscr** - the data validation test description (hard-coded when write script)
</details>
<br>

### Step 5 - Execute the Basic Data Validation Script
<details><summary>Expand if you would like to see how to execute the basic script, step-by-step...</summary><br>

Here are the steps to execute the basic script in SSMS (typical output shown in the screenshot below).  
1. Open SSMS (or equivalent SQL Editor)
2. Blue Dot #1 - You must load the basic validation script into SSMS (or equivalent IDE)
3. Blue Dot #2 - Be sure to click the "Text Output" toggle button (or equivalent in other IDEs) so that all test cases will output to a single text document on screen (**not** as 66 separate grids)
4. Blue Dot #3 - The output is concisely laid out for all data validation test cases.  The red-boxed test case includes test_id (eg: T001) in column #1, followed by the status (eg: pass or fail) in column #2, and finally ends with the test description on the right in column #3 (because width varies so much want it on the end for better readability).
<img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/img/02_data_val_mssql_run_results1.png">

</details>
<br>

### Next Steps - Build Your Own Validation Test Script(s)
You could just skip reading all the sections above and jump directly down here.  Be sure to expand Step #3 to download a copy of the basic test case script that you will refactor to suit your needs.

Here are my recommendations for writing your validation script(s):
1. **Reference**: I would suggest that you open the basic script as a reference in notepad or text editor of your choice and position it off on a second monitor to the side.
2. **Main Editor**: Open SQL Server Management Studio with a blank new script that you are going to build out for your tests as follows:
3. **Comment Block**:  Create your own comment block at the top of your script, pulling anything of value from lines 1-44, but tailoring them to your specific scenario
4. **Select Schema**: You will have a schema (database) that is "under test".  Identify it.  List it in the comment block.  Prefix all SQL code with it going forward (below).
5. **Table #1**:  Pick the first table for which you are going to start writing validation cases for.  Could be the first table alphabetically. Could be a highest priority table you want to begin writing validation checks against (biggest bang for the buck).  Could be the simplest table to ease in with baby steps (low-hanging fruit).  You decide.
6. **Rule Set #1 - Row Counts**: Start off with an appropriate "Row Count" test case that applies to the entire table.  Pick one from T001 - T004.  Change the scehma name prefix, the table name, and if appropriate the column names.  Highlight and run it in your SQL editor to validate the SQL.  Change the "tst_id" number to your own.  Change the tst_descr to your own.
7. **Rule Set #8 - Diff Checks**: These diff checks in T059-T061 operate at the table-level just like Rule Set #1 Row Counts, so I suggest grouping them together at the top of each table's validation tests.
8. **Rule Set #2 - Keys**: Next, if and only if there are missing unique key constraints or foreign key constraints, then I'd copy-paste the appropriate test cases T005-T007 into the SQL editor and make appropriate changes (schema name, table names, field names, tst_id, and tst_descr).
9. **Rule Set #3 - Heuristics**: Next, if and only if it is appropriate to test Null Rates for specific fields of "Table #1" then I'd copy test case T008 into the SQL Editor and make all the appropriate changes (and there are a lot...schema name, table name, many column names, copy-paste or delete CASE WHEN rows and SELECT CAST rows for each  column you want to add or remove...see my YouTube video for a demo).<br>
Likewise, if there are particular fields in "Table #1" that you'd like to setup threshold alerts for on frequency of observed values, then you copy-paste-modify T009 the appropriate number of times...once per field.
10. **Rule Set #4-#7**: The bulk of the remaining example validation checks are field by field.  You can write the test cases one table, and one field at a time...mixing and matching from these sample validation checks as needed.  This granular approach can make fails readily apparent.  However, you can alterantively combine dozens of these same checks into a single table-scan pass to greatly improve performance (best practice example in T065).  Your choice.  Bottom line, a lot of copy-paste-modifying SQL code from test cases T010-T058.
11. **Rule Set #9**: Add in any defect regression tests as appropriate
12. **Finishing Touches**: Don't forget to apply the best practice examples in data validation test cases T062-T066

And then repeat items 1-12 above for the next table.  And again for the next table, and so on until you are done.  Your choice whether to write one giant 5-10,000 line script for the entire schema, or break down into separate scripts for each table or logical table grouping. 
