# Multiple Platform Data Dictionary Scripts
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)

## Overview
There are many reasons you may need a SQL script that captures table, view, column, and key properties.  
It all boils down to comparing different states to quickly identify what changed, or what is different.


* Maybe you need to quickly isolate what got missed in the migrations from DEV to TEST environments.  
* Maybe you need to quickly identify what changed between this release (AFTER) and the prior release (BEFORE).  
* Maybe you want to run the script daily and output state snapshots to text files so that in the event of an emergency you can quickly identify what changed between given dates.

Using your favorite text diff-ing tool, here is what two sample schemas (PPMO-OldSchema vs. DEV-NewSchema) might look like side-by-side (red markup lines added):
<img src="https://github.com/DataResearchLabs/sql_scripts/blob/main/img/01_schemadiff_side_by_side.png" width="900px">
