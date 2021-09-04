### Data Validation Examples - Postgresql
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
#### [Return to Data Validation Home Page](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_validation_scripts.md)

# Rule Set #8 - Diff Checks (Schema and Data Changes)

## Table of Contents
 - <a href="#t059">T059 - Table Structure (Schema) Differences</a>
 - <a href="#t060">T060 - Table Data Differences (Static SQL Snapshot)</a>
 - <a href="#t061">T061 - Table Data Differences (Dynamic Table Compare)</a>
<br>


Note: the SQL code in these sample validations can get long, so they are wrapped in expandable tags, just click "See the SQL code..." to see it.

<a id="t059" class="anchor" href="#t059" aria-hidden="true"> </a>
### T059 - Table Structure (Schema) Differences
This validation check monitors the schema (column names and properties) of table Locations, tripping an alert (Fail) any time the real table no longer matches the static copy embedded in the SQL as a snapshot.

<details><summary>More details and the SQL code...</summary><br>
 
* The first common table expression (CTE) or subquery is named "expected".  It is a static snapshot of what the locaton table's schema should look like, including the ordinal position, the column name, the data type, and whether the column is nullable.  To re-factor the SQL below, this is the only section that you'd heavily edit.
* The second CTR or subquery is named "actual".  It is a dynamic snapshot of the location table's current structure based on Oracle system tables.  It derives a compact data type with length, scale, and precision appended.  The only minor re-factoring of this CTE you'd need ni order to re-use this on your projects would be the owner and table names in the WHERE clause; everything else should remain unchanged.
* The third CTR or subquery is named "dut", short for data under test.  This is where the business logic is applied to derive rejection codes (eg: table does not exist, or expected column is missing or has a property that changed).
* Finally, the simple SELECT at the bottom returns "P" for pass if there are no differences (rejections) found, or "FAIL" if there were.
                    
 ```sql
WITH expected 
AS (
        SELECT 1 AS ord_pos, 'location_id'    AS column_nm, 'integer(32)'           AS data_typ, 'NOT NULL' AS nullable
  UNION SELECT 2 AS ord_pos, 'street_address' AS column_nm, 'character varying(40)' AS data_typ, 'NULL' AS nullable
  UNION SELECT 3 AS ord_pos, 'postal_code'    AS column_nm, 'character varying(12)' AS data_typ, 'NULL' AS nullable
  UNION SELECT 4 AS ord_pos, 'city'           AS column_nm, 'character varying(30)' AS data_typ, 'NOT NULL' AS nullable
  UNION SELECT 5 AS ord_pos, 'state_province' AS column_nm, 'character varying(25)' AS data_typ, 'NULL' AS nullable
  UNION SELECT 6 AS ord_pos, 'country_id'     AS column_nm, 'character(2)'          AS data_typ, 'NULL' AS nullable
  ORDER BY ord_pos
)
, actual_base_tbl
AS (
  SELECT table_schema AS SchemaName
  , table_catalog
  , table_type, table_name, table_schema
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = 'demo_hr' 
    AND TABLE_TYPE = 'BASE TABLE'
)
, actual
AS (
  SELECT
    RIGHT('000' || CAST(tut.ORDINAL_POSITION AS VARCHAR(3)), 3) AS ord_pos
  , tut.column_name                                            AS column_nm
  , COALESCE(tut.data_type, 'unknown') || 
    CASE WHEN tut.DATA_TYPE IN('varchar','nvarchar')    THEN '(' || CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) || ')'
         WHEN tut.DATA_TYPE IN('char','nchar')          THEN '(' || CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) || ')'
         WHEN tut.DATA_TYPE ='date'                     THEN '(' || CAST(tut.DATETIME_PRECISION AS VARCHAR(10)) || ')'
         WHEN tut.DATA_TYPE ='datetime'                 THEN '(' || CAST(tut.DATETIME_PRECISION AS VARCHAR(10)) || ')'
         WHEN tut.DATA_TYPE LIKE '%int%'                THEN '(' || CAST(tut.NUMERIC_PRECISION AS VARCHAR(10))  || ')'
         WHEN tut.DATA_TYPE = 'uniqueidentifier'        THEN '(16)'
         WHEN tut.DATA_TYPE = 'money'                   THEN '(' || CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) || ')'
         WHEN tut.DATA_TYPE = 'decimal'                 THEN '(' || CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) || ',' || CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) || ')'
         WHEN tut.DATA_TYPE = 'numeric'                 THEN '(' || CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) || ',' || CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) || ')'
         WHEN tut.DATA_TYPE = 'varbinary'               THEN '(' || CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) || ')'
         WHEN tut.DATA_TYPE = 'xml'                     THEN '(' || CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) || ')'
         WHEN tut.DATA_TYPE IN('char','nchar')          THEN '(' || CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) || ')'
         WHEN tut.CHARACTER_MAXIMUM_LENGTH IS NOT NULL  THEN '(' || CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) || ')'
         WHEN tut.DATETIME_PRECISION IS NOT NULL        THEN '(' || CAST(tut.DATETIME_PRECISION AS VARCHAR(10)) || ')'
         WHEN tut.NUMERIC_PRECISION IS NOT NULL
          AND tut.NUMERIC_SCALE     IS NULL             THEN '(' || CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) || ')'
         WHEN tut.NUMERIC_PRECISION IS NOT NULL
          AND tut.NUMERIC_SCALE     IS NOT NULL         THEN '(' || CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) || ',' || CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) || ')'
         ELSE ''
    END AS data_typ
  , CASE WHEN tut.IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END AS nullable
  FROM       INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN actual_base_tbl            bt  ON bt.table_catalog = tut.TABLE_CATALOG AND bt.table_name = tut.table_name
  WHERE tut.table_name = 'locations'
)
, dut -- Data Under Test 
AS (
  SELECT CASE WHEN (SELECT COUNT(*) FROM actual) = 0        THEN 'REJ-01: Table [locations] does not exist (may be case sensistive name)|exp=exists|act=notExist' 
              WHEN a.column_nm IS NULL                      THEN 'REJ-01: Expected column is missing from actual schema (may be case sensitive name)|exp=' || e.column_nm || '|act=IsMissing' 
              WHEN CAST(a.ord_pos AS INTEGER) <> e.ord_pos  THEN 'REJ-02: Ordinal Positions at field ' || e.column_nm || ' do not match|exp=' || CAST(e.ord_pos AS VARCHAR(3)) || '|act=' || CAST(a.ord_pos AS VARCHAR(3))
              WHEN a.data_typ <> e.data_typ                 THEN 'REJ-03: Data Types at field ' || e.column_nm || ' do not match|exp=' || e.data_typ || '|act=' || a.data_typ 
              WHEN a.nullable <> e.nullable                 THEN 'REJ-04: Nullable settings at field ' || e.column_nm || ' do not match|exp=' || e.nullable || '|act=' || a.nullable 
              ELSE 'P'
         END AS status
  FROM      expected e 
  LEFT JOIN actual   a ON a.column_nm = e.column_nm
)

SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
FROM dut WHERE status <> 'P';
 ```
</details>
<br>


<a id="t060" class="anchor" href="#t060" aria-hidden="true"> </a>
### T060 - Table Data Differences (Static SQL Snapshot)
This validation check monitors the table's data, tripping an alert (Fail) any time the real table data no longer matches the static data embedded in the SQL as a snapshot.

<details><summary>More details and the SQL code...</summary><br>
 
* The first common table expression (CTE) or subquery is named "metadata".  It is a static snapshot of what the region table's expected data should contains.  To re-use this for your purposes, you'd heavily change this SQL around to match the columns and values and rows of data you want to validate.
* The second CTR or subquery is named "dut", short for data under test.  It dynamically compares the static data content (expected) above against the actual regions table data using a left join to spot missing rows, and comparing all field values (there's only one, region_name) one by one.  Any differences found will be tagged with its own rejection code (eg: REJ-02: Region Name does not match).  The expected and actual values are also listed in the inner query results.
* Finally, the simple SELECT at the bottom returns "P" for pass if there are no differences found, or "FAIL" if there were.
                    
```sql
WITH metadata 
AS (
        SELECT 1 AS region_id, 'Europe' AS region_name
  UNION SELECT 2 AS region_id, 'Americas' AS region_name
  UNION SELECT 3 AS region_id, 'Asia' AS region_name 
  UNION SELECT 4 AS region_id, 'Middle East and Africa' AS region_name 
  ORDER BY region_id
)
, dut -- Data Under Test 
AS (
  SELECT CASE WHEN r.region_id IS NULL            THEN 'REJ-01: Record is missing from metadata|exp=NotMissing|act=' || m.region_id || ' is missing' 
              WHEN r.region_name <> m.region_name THEN 'REJ-02: Region_Name does not match|exp=' || m.region_name || '|act=' || r.region_name 
              ELSE 'P'
         END AS status
  FROM      metadata   m 
  LEFT JOIN demo_hr.regions r ON r.region_id = m.region_id
  ORDER BY m.region_id
)

SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
FROM dut WHERE status <> 'P';
 ```
</details>
<br>


<a id="t061" class="anchor" href="#t061" aria-hidden="true"> </a>
### T061 - Table Data Differences (Dynamic Table Compare)
This validation check monitors the table's data, tripping an alert (Fail) any time the target table data no longer matches the baseline table data.  This check requires that two tables (1-source/baseline, and 2-target) be identical structure **and** identical data.  It then does a group by and count across every field.  Anywhere the row count is 2 means the tables match, anywhere the count is a 1 means a mismatch.

<details><summary>More details and the SQL code...</summary><br>
 
* The first common table expression (CTE) or subquery is named "non_matches".  It is does most of the heavy lifting.  This is where the target table 'jobs' and the baseline table 'jobs_snapshot' are grouped by all fields (except the tbl_nm which must be different).  Where the COUNT(*) is less than two after grouping fields and UNION ALL to combine the two sets, that is where the differences exist.
* The second CTR or subquery is named "dut", short for data under test.  It formats the output so differences are easy to spot (a concatenated string with column names and values.
* Finally, the simple SELECT at the bottom returns "P" for pass if there are no differences found, or "FAIL" if there were.
 
 ```sql
WITH non_matches
AS (
  SELECT MAX(tbl_nm) AS tbl_nm, job_id, job_title, min_salary, max_salary, COUNT(*) AS match_count_found
  FROM (
  SELECT CAST('jobs' AS VARCHAR(15)) AS tbl_nm,          job_id, job_title, min_salary, max_salary FROM demo_hr.JOBS  
  UNION ALL 
  SELECT CAST('jobs_snapshot' AS VARCHAR(15)) AS tbl_nm, job_id, job_title, min_salary, max_salary FROM demo_hr.JOBS_SNAPSHOT 
  ) comb_sets 
  GROUP BY job_id, job_title, min_salary, max_salary
  HAVING COUNT(*) < 2
)
, dut -- Data Under Test 
AS (
  SELECT 'REJ-01: Mismatch Found: tbl_nm="' || tbl_nm ||'", job_id="' || job_id || '", job_title="' || job_title 
    || '", min_salary=' || CAST(min_salary AS VARCHAR(20)) || '", max_salary=' || CAST(max_salary AS VARCHAR(20)) AS status
  FROM      non_matches  
  ORDER BY 1
)

SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
FROM dut WHERE status <> 'P';
 ```
</details>
<br>
