# Multiple Platform Data Dictionary Scripts
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)

## What is a Data Dictionary?
<img align="right" src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/02_data_dictionary_in_xl.png" width="500px">
A "Data Dictionary" is simply a list of tables and views, their column properties such as name, ordinal position, data type/length/size/precision, allows nulls, and of course the column description.  A good data dictionary also indicates which columns are a part of a primary key, foreign key, unique key, or distribution key (Greenplum).<br>
<br>
Data dictionaries can be used to train new employees how your system is setup.  They can be used as a baseline for new projects, an "as-built" set of documentation from which to start.  They can be used as close-out documentation to wrap-up a project and push it out into Excel on a wiki or Sharepoint, etc.


## Overview
Sure, there are many tools out there which will automatically build a data dictionary for you from an existing schema. Some of those tools include Visual Studio, Toad, Oracle SQL Developer, etc.  However, sometimes you just want to run a script to fetch the data dictionary.  Perhaps you want to modify the script to log the data dictionary out nightly to a database table or to files to watch and notify on changes.  Maybe you just want to pull a large schema and dump it into Excel where you can foramt it to look pretty then use filter to quickly sift through hundreds of tables and thousands of columns.  Regardless of your need, the following multi-plaform scripts should have you covered.<br>
<br>
<br>
The following sections walk you thru using the scripts.  At the bottom of the article is a grid with all the available database platforms, their matchings scripts and YouTube tutorials if you'd prefer just watching how to use them.<br>
<br>


## Using the Script
#### STEP 1. Download Script
In the table at the bottom of this article, find your preferred database platform and click the appropriate "Script" link.  This brings up the raw text file in the browser, minus any special HTML formatting so that you can simply copy the script then paste it into a new text file or directly to a SQL editor.  Alternatively you could clone the repository to your local workstation (pull everything using Git for source control), or click the green Code button and download the repository as a zip file.


<img align="right" src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/03_data_dictionary_edit_and_run_script.png" width="500x">


#### STEP 2. Run Script


**First**, open your SQL Editor (MySQL Workbench, Toad, etc.).<br>
**Next**, open the SQL script as shown below and follow the numbered steps (blue dots in screenshot) to configure and run the script:


**1. Schema/Database Name:** Select the schema or database name; "sakila" in the example.<br>
**2. Tables Only?** Set the "v_TablesOnly" var to either "YES" for tables only, or "NO" (default) to also include views<br>
**3. Execute** Click the appropriate button in your IDE to run the script<br>
<br>


#### STEP 3. View Results & Export
Once the SQL script is done executing, you should have hundreds or perhaps even thousands of rows of Data Dictionary metadata depending on the size of your schema.  Go ahead and export this to either a CSV file or directly into Microsoft Excel.  From there you can format the data dictionary to make it look pretty and add filters to make it quickly searchable.  See the YouTube tutorials below for more details.


## Scripts & Tutorials by Platform
Links to the script source code as well as video tutorials are listed below, by platform (MSSQL, Oracle, MySQL, etc.):
<br>
<br>

<table>

<tr>
<td align="center" valign="top">
  <br>
  <img align="enter" src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/db_icons/gp_icon.png" width="96px">
</td>
<td>


## Greenplum
* [Greenplum "Data Dictionary" Script](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/greenplum/data_dictionary/data_dict_dump.sql)<br>
* [Greenplum "Data Dictionary" Tutorial](http://www.youtube.com/watch?feature=player_embedded&v=0BymfeSzqkw)<br>
</td>
<td>
<kbd>
<a href="http://www.youtube.com/watch?feature=player_embedded&v=0BymfeSzqkw" target="_blank">
<img src="http://img.youtube.com/vi/0BymfeSzqkw/0.jpg" alt="Overview Video" width="200" />
</a>
</kbd>
</td>
</tr>



<tr>
<td align="center" valign="top">
  <br>
  <img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/db_icons/mssql_icon.png" width="96px">
</td>
<td>


## MS SQL Server
* [MSSQL "Data Dictionary" Script](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/mssql/data_dictionary/data_dict_dump.sql)<br>
* [MSSQL "Data Dictionary" Tutorial](http://www.youtube.com/watch?feature=player_embedded&v=Y6ZUdLBOufY)<br>
</td>
<td>
<kbd>
<a href="http://www.youtube.com/watch?feature=player_embedded&v=Y6ZUdLBOufY" target="_blank">
  <br>
  <img src="http://img.youtube.com/vi/Y6ZUdLBOufY/0.jpg" alt="Overview Video" width="200" />
</a>
</kbd>
</td>
</tr>



<tr>
<td align="center" valign="top">
  <br>
  <img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/db_icons/mysql_icon.png" width="105px">
</td>
<td>


## MySQL
* [MySQL "Data Dictionary" Script](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/mysql/data_dictionary/data_dict_dump.sql)<br>
* [MySQL "Data Dictionary" Tutorial](http://www.youtube.com/watch?feature=player_embedded&v=bfpS2LTEVbY)<br>
</td>
<td>
<kbd>
<a href="http://www.youtube.com/watch?feature=player_embedded&v=bfpS2LTEVbY" target="_blank">
<img src="http://img.youtube.com/vi/bfpS2LTEVbY/0.jpg" alt="Overview Video" width="200" />
</a>
</kbd>
</td>
</tr>



<tr>
  <td align="center" valign="top">
  <br>
  <img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/db_icons/oracle_iconX.png" width="102px">
</td>
<td>
    
    
## Oracle
* [Oracle "Data Dictionary" Script](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/oracle/data_dictionary/data_dict_dump.sql)<br>
* [Oracle "Data Dictionary" Tutorial](http://www.youtube.com/watch?feature=player_embedded&v=Ic5dafweq1E)<br>
</td>
<td>
<kbd>
<a href="http://www.youtube.com/watch?feature=player_embedded&v=Ic5dafweq1E" target="_blank">
<img src="http://img.youtube.com/vi/Ic5dafweq1E/0.jpg" alt="Overview Video" width="200" />
</a>
</kbd>
</td>
</tr>


<tr>
<td align="center" valign="top">
  <br>
  <img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/db_icons/pgsql_icon.png" width="125px">
</td>
<td>
    
    
## PostgreSQL
* [PostgreSQL "Data Dictionary" Script](https://raw.githubusercontent.com/DataResearchLabs/sql_scripts/main/postgresql/data_dictionary/data_dict_dump.sql)<br>
* [PostgreSQL "Data Dictionary" Tutorial](http://www.youtube.com/watch?feature=player_embedded&v=ekLK46G_r28)<br>
</td>
<td>
<kbd>
<a href="http://www.youtube.com/watch?feature=player_embedded&v=ekLK46G_r28" target="_blank">
<img src="http://img.youtube.com/vi/ekLK46G_r28/0.jpg" alt="Overview Video" width="200" />
</a>
</kbd>
</td>
</tr>
</table>

<br>
<br>
<br>
***If you like these scripts, be sure to click the "Star" button above in GitHub.*** <br>
<br>
***Also, be sure to visit or subscribe to our YouTube channel*** www.DataResearchLabs.com!<br>
<br>
<br>

