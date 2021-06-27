# How to Use the Basic Data Validation Script Framework in Oracle
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
---

### Overview
The basic script runs one of each type of data validation test case (T001-T066) shown in the Rule Set markdown (.md) pages.  Yuo run all the SQL test cases together at one time from Oracle SQL Developer.  Output (results) from each test case are streamed to the screen.  

Every data validation test will display one row of output containing the following columns:

* **tst_id**: The data validation Test ID
* **status**: The data validation test result.  Usually "P" for pass or "FAIL".  However, you can invent your own status values too, such as "WARN", "SKIP", or "BLOCK"
* **tst_dscr**: The data validation test description.

