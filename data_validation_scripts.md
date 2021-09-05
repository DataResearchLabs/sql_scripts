# Multiple Platform Data Validation Scripts
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)

## What is Data Validation Testing?
<img align="right" src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/04_data_validation_scripts.png" width="500px">
"Data Validation Testing" ensures that the data you work with is accurate and complete, that any necesary transformations occur without loss, that your processes can handle incorrect data, and the final output is correct.<br>
<br>

## How Can You Use Data Validation Testing?

- **Test/Stage Regression**: You could setup a more extensive set of data validation tests and schedule them to run daily.  If it take 45 minutes to run 1,200 tests to thoroughly exercise the business logic of an entire schema, running it daily is a good trade-off.  You'll be surprised at the number of times where out-of-the-blue you catch some odd application bug based on data rules.
- **Manual QA**: When it makes sense, you can build a data validation test script that you manually run during the QA process at the appropriate gates/milestones.
- **Dev BVTs**: You could setup a lean/fast validation script that runs as a Build Verification Test every time developers check-in code...a baseline set of rules that should never be violoated.
- **Production Checkouts**: You can use data validation testing for after prod deplosy using carefully crafted read-only SELECTs so as to not impact performance.  
- **Baked Into Applications**: Where appropriate, you can build data validation tests directly into your ETL or data pipeline code.
<br>

## Note
Because each database platform has its own unique flavor of SQL, this page is just a central landing page to redirect you to the appropriate database platform's specific pages.<br>
<br>

<table>

<tr>
<td align="center" valign="top" rowspan=3>
  <br>
  <img align="enter" src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/db_icons/mssql_icon.png" width="96px">
</td>
<td rowspan=3 width=325>

## MS SQL Server
* [Rule Set 01 - Row Counts](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/rule_set_01__row_counts.md)<br>
* [Rule Set 02 - Keys](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/rule_set_02__keys.md)<br>
* [Rule Set 03 - Heuristic Thresholds](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/rule_set_03__heuristic_thresholds.md)<br>
* [Rule Set 04 - Numeric Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/rule_set_04__numeric_values.md)<br>
* [Rule Set 05 - Date Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/rule_set_05__date_values.md)<br>
* [Rule Set 06 - Text Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/rule_set_06__text_values.md)<br>
* [Rule Set 07 - Reg Expr's](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/rule_set_07__regular_expressions.md)<br>
* [Rule Set 08 - Diff Checks](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/rule_set_08__diff_checks.md)<br>
* [Rule Set 09 - Defect Regression](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/rule_set_09__defect_regression.md)<br>
* [Best Practices](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/best_practices.md)<br>
* [Basic Validation Script](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/how_to_use_basic_script.md)<br>
* [Advanced Validation Script](https://github.com/DataResearchLabs/sql_scripts/blob/main/mssql/data_validation/how_to_use_advanced_script.md)<br>
</td>
 
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=M6SkiWLVo8I" target="_blank">
  <img src="http://img.youtube.com/vi/M6SkiWLVo8I/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=QMGBlETW_fk" target="_blank">
  <img src="http://img.youtube.com/vi/QMGBlETW_fk/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=_cGX5Se344Y" target="_blank">
  <img src="http://img.youtube.com/vi/_cGX5Se344Y/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td></tr>
<tr><td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=zQpu1EGuZZk" target="_blank">
  <img src="http://img.youtube.com/vi/zQpu1EGuZZk/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=owheYxwTC80" target="_blank">
  <img src="http://img.youtube.com/vi/owheYxwTC80/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=E0D4sbhKpMc" target="_blank">
  <img src="http://img.youtube.com/vi/E0D4sbhKpMc/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
</tr><tr>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=J0uE2LnOLXI" target="_blank">
  <img src="http://img.youtube.com/vi/J0uE2LnOLXI/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=EYO2n2h8XTY" target="_blank">
  <img src="http://img.youtube.com/vi/EYO2n2h8XTY/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td></td>  
</tr>  
  

  
<tr>
<td align="center" valign="top" rowspan=3>
  <br>
  <img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/db_icons/mysql_icon.png" width="115px">
</td>
<td rowspan=3 width=325>

## MySQL
* [Rule Set 01 - Row Counts](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/rule_set_01__row_counts.md)<br>
* [Rule Set 02 - Keys](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/rule_set_02__keys.md)<br>
* [Rule Set 03 - Heuristic Thresholds](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/rule_set_03__heuristic_thresholds.md)<br>
* [Rule Set 04 - Numeric Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/rule_set_04__numeric_values.md)<br>
* [Rule Set 05 - Date Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/rule_set_05__date_values.md)<br>
* [Rule Set 06 - Text Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/rule_set_06__text_values.md)<br>
* [Rule Set 07 - Reg Expr's](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/rule_set_07__regular_expressions.md)<br>
* [Rule Set 08 - Diff Checks](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/rule_set_08__diff_checks.md)<br>
* [Rule Set 09 - Defect Regression](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/rule_set_09__defect_regression.md)<br>
* [Best Practices](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/best_practices.md)<br>
* [Basic Validation Script](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/how_to_use_basic_script.md)<br>
* [Advanced Validation Script](https://github.com/DataResearchLabs/sql_scripts/blob/main/mysql/data_validation/how_to_use_advanced_script.md)<br>
</td>
 
<td colspan=3>
</td>
</tr><tr>
<td colspan=3>
</td>
</tr><tr>
<td colspan=3>
</td>
</tr>  
  
  
<tr>
<td align="center" valign="top" rowspan=3>
  <br>
  <img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/db_icons/oracle_icon.png" width="90px">
</td>
<td rowspan=3 width=325>

## Oracle
* [Rule Set 01 - Row Counts](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/rule_set_01__row_counts.md)<br>
* [Rule Set 02 - Keys](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/rule_set_02__keys.md)<br>
* [Rule Set 03 - Heuristic Thresholds](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/rule_set_03__heuristic_thresholds.md)<br>
* [Rule Set 04 - Numeric Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/rule_set_04__numeric_values.md)<br>
* [Rule Set 05 - Date Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/rule_set_05__date_values.md)<br>
* [Rule Set 06 - Text Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/rule_set_06__text_values.md)<br>
* [Rule Set 07 - Regular Expressions](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/rule_set_07__regular_expressions.md)<br>
* [Rule Set 08 - Diff Checks](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/rule_set_08__diff_checks.md)<br>
* [Rule Set 09 - Defect Regression](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/rule_set_09__defect_regression.md)<br>
* [Best Practices](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/best_practices.md)<br>
* [Basic Validation Script](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/how_to_use_basic_script.md)<br>
* [Advanced Validation Script](https://github.com/DataResearchLabs/sql_scripts/blob/main/oracle/data_validation/how_to_use_advanced_script.md)<br>
</td>
 
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=paoEJaGirqg" target="_blank">
  <img src="http://img.youtube.com/vi/paoEJaGirqg/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=j4Rh2IcZhig" target="_blank">
  <img src="http://img.youtube.com/vi/j4Rh2IcZhig/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=phO5KUfoPM4" target="_blank">
  <img src="http://img.youtube.com/vi/phO5KUfoPM4/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td></tr>
<tr><td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=62wtTY0D-z0" target="_blank">
  <img src="http://img.youtube.com/vi/62wtTY0D-z0/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=G1UskEv7jSs" target="_blank">
  <img src="http://img.youtube.com/vi/G1UskEv7jSs/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=BctndgrH330" target="_blank">
  <img src="http://img.youtube.com/vi/BctndgrH330/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
</tr><tr>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=GKKnigeTXAY" target="_blank">
  <img src="http://img.youtube.com/vi/GKKnigeTXAY/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td>
  <kbd>
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=Wp-_Q7CNSx4" target="_blank">
  <img src="http://img.youtube.com/vi/Wp-_Q7CNSx4/0.jpg" alt="Video Tutorial" width="200" />
  </a>
  </kbd>
</td>
<td></td>  
</tr>  

  
  
<tr>
<td align="center" valign="top" rowspan=3>
  <br>
  <img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/db_icons/pgsql_icon1.png" width="115px">
</td>
<td rowspan=3>

## PostgreSQL
* [Rule Set 01 - Row Counts](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/rule_set_01__row_counts.md)<br>
* [Rule Set 02 - Keys](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/rule_set_02__keys.md)<br>
* [Rule Set 03 - Heuristic Thresholds](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/rule_set_03__heuristic_thresholds.md)<br>
* [Rule Set 04 - Numeric Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/rule_set_04__numeric_values.md)<br>
* [Rule Set 05 - Date Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/rule_set_05__date_values.md)<br>
* [Rule Set 06 - Text Values](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/rule_set_06__text_values.md)<br>
* [Rule Set 07 - Reg Expr's](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/rule_set_07__regular_expressions.md)<br>
* [Rule Set 08 - Diff Checks](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/rule_set_08__diff_checks.md)<br>
* [Rule Set 09 - Defect Regression](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/rule_set_09__defect_regression.md)<br>
* [Best Practices](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/best_practices.md)<br>
* [Basic Validation Script](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/how_to_use_basic_script.md)<br>
* [Advanced Validation Script](https://github.com/DataResearchLabs/sql_scripts/blob/main/postgresql/data_validation/how_to_use_advanced_script.md)<br>
</td>
 
<td colspan=3>
</td>
</tr><tr>
<td colspan=3>
</td>
</tr><tr>
<td colspan=3>
</td>
</tr>  


<tr>
<td align="center" valign="top" rowspan=3  width=150>
  <br>
  <img align="enter" src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/db_icons/gp_icon.png" width="96px">
</td>
<td colspan="4" >

## Greenplum
* Use the Postgresql scripts above<br>
</td>
</tr>
  
</table>
<br>
<br>


***If you like these scripts, be sure to click the "Star" button above in GitHub.*** <br>
<br>
***Also, be sure to visit or subscribe to our YouTube channel*** www.DataResearchLabs.com!<br>
<br>
<br>
