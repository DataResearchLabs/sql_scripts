# SQL Scripts
Useful sql scripts for MSSQL, MySQL, Oracle, PostgreSQL, and Greenplum.  These are based on years of usage and refinement.  These are common scripts used by data analysts, software testers, and other database professionals.<br>
<br>



## [Data Dictionary](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_dictionary_scripts.md)

<img align="right" src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/02_data_dictionary_in_xl.png" width="300px">

The Data Dictionary script and tutorials enable you to easily document an existing database schema.  You can dump the tables, views, column descriptions, data types/lengths/sizes/precision, key constraints, and other information.  Export to Excel for pretty output and simple filtering, searching, and sharing.<br>
<br>
<br>
<br>
<br>


## [Data Validation Scripts](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_validation_scripts.md)

<img align="right" src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/04_data_validation_scripts.png" width="300px">

The Data Validation Framework scripts and tutorials enable you to easily standup a battery of automated data validation tests in your environment.  Use the DVF for prod checkouts, or test and stage regression tests, or dev unit tests, or automated data validation after each data load.  There are nine rule sets depicting 66 sample test cases to demonstrate how to test for row counts, keys, heuristic thresholds, numeric/date/text values, regular expressions, and data or schema diffs.  The basic data validation script demonstrations executes all 66 sample validation tests putting out one line of text with the test id, status, and test description -- a nice simple way to organize your tests.  The advanced data validation scripts execute the same 66 sample validation tests, but pushes output to a table and adds in the execution time in seconds, as well supporting detail rows on fails with the rejection code + reason, the expected value, the actual value, and the SQL to lookup the rejected row so you can copy-paste-execute-and-troubleshoot.<br>
<br>


## [SchemaDiff](https://github.com/DataResearchLabs/sql_scripts/blob/main/schemadiff_scripts.md)

<img align="right" src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/01_schemadiff_side_by_side.png" width="300px">

The SchemaDiff script and tutorials enable you to track changes to your schema over time or between environments.  You'll know exactly what changed last night with a deployment vs. the prior night's stable baseline.  You'll know when folks are changing your development or test environment every morning rather than 15 days later, avoiding all the troubleshooting red herrings.<br>
<br>
<br>
<br>
<br>


***If you like these scripts, please be sure to click the "Star" button above in GitHub.*** <br>
<br>
***Also, be sure to visit or subscribe to our YouTube channel*** www.DataResearchLabs.com!<br>
<br>
<br>
