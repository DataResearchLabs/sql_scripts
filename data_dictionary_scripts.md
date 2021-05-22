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


## Running the Script
#### STEP 1. Download Script
In the table at the bottom of this article, find your preferred database platform and click the appropriate "Script" link.  This brings up the raw text file in the browser, minus any special HTML formatting so that you can simply copy the script then paste it into a new text file or directly to a SQL editor.  Alternatively you could clone the repository to your local workstation (pull everything using Git for source control), or click the green Code button and download the repository as a zip file.


<img align="right" src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/03_data_dictionary_edit_and_run_script.png" width="500x">
#### STEP 2. Run Script


**First**, open your SQL Editor (MySQL Workbench, Toad, etc.).  **Next**, open the SQL script as shown below and follow the numbered steps (blue dots in screenshot) to configure and run the script:


**1. Schema/Database Name:** Select the schema or database name; "sakila" in the example.<br>
**2. Tables Only?** Set the "v_TablesOnly" var to either "YES" for tables only, or "NO" (default) to also include views<br>
**3. Execute** Click the appropriate button in your IDE to run the script<br>







