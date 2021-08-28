### Data Validation Examples - MySQL
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
          SELECT 1 AS ord_pos, 'LOCATION_ID'    AS column_nm, 'decimal(4,0)' AS data_typ, 'NOT NULL' AS nullable
    UNION SELECT 2 AS ord_pos, 'STREET_ADDRESS' AS column_nm, 'varchar(40)'  AS data_typ, 'NULL'     AS nullable
    UNION SELECT 3 AS ord_pos, 'POSTAL_CODE'    AS column_nm, 'varchar(12)'  AS data_typ, 'NULL'     AS nullable
    UNION SELECT 4 AS ord_pos, 'CITY'           AS column_nm, 'varchar(30)'  AS data_typ, 'NOT NULL' AS nullable
    UNION SELECT 5 AS ord_pos, 'STATE_PROVINCE' AS column_nm, 'varchar(25)'  AS data_typ, 'NULL'     AS nullable
    UNION SELECT 6 AS ord_pos, 'COUNTRY_ID'     AS column_nm, 'char(2)'      AS data_typ, 'NULL'     AS nullable
)
, actual
AS (
      SELECT
        RIGHT(CONCAT('000', CAST(tut.ORDINAL_POSITION AS CHAR(3))), 3) AS ord_pos
      , tut.column_name                                                AS column_nm
      , CONCAT(COALESCE(tut.data_type, 'unknown'), 
        CASE WHEN tut.data_type IN('varchar','nvarchar')    THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.data_type IN('char','nchar')          THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.data_type ='date'                     THEN CONCAT('(', CAST(tut.DATETIME_PRECISION AS CHAR(10)), ')')
             WHEN tut.data_type ='datetime'                 THEN CONCAT('(', CAST(tut.DATETIME_PRECISION AS CHAR(10)), ')')
             WHEN tut.data_type LIKE '%int%'                THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ')')
             WHEN tut.data_type = 'uniqueidentifier'        THEN '(16)'
             WHEN tut.data_type = 'money'                   THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ')')
             WHEN tut.data_type = 'decimal'                 THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ',', CAST(tut.NUMERIC_SCALE AS CHAR(10)), ')')
             WHEN tut.data_type = 'numeric'                 THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ',', CAST(tut.NUMERIC_SCALE AS CHAR(10)), ')')
             WHEN tut.data_type = 'varbinary'               THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.data_type = 'xml'                     THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.data_type IN('char','nchar')          THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.CHARACTER_MAXIMUM_LENGTH IS NOT NULL  THEN CONCAT('(', CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)), ')')
             WHEN tut.DATETIME_PRECISION IS NOT NULL        THEN CONCAT('(', CAST(tut.DATETIME_PRECISION AS CHAR(10)), ')')
             WHEN tut.NUMERIC_PRECISION IS NOT NULL
              AND tut.NUMERIC_SCALE     IS NULL             THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ')')
             WHEN tut.NUMERIC_PRECISION IS NOT NULL
              AND tut.NUMERIC_SCALE     IS NOT NULL         THEN CONCAT('(', CAST(tut.NUMERIC_PRECISION AS CHAR(10)), ',', CAST(tut.NUMERIC_SCALE AS CHAR(10)), ')')
             ELSE ''
        END) AS data_typ
      , CASE WHEN tut.IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END AS nullable
      FROM       INFORMATION_SCHEMA.COLUMNS  tut
      WHERE tut.table_schema  = 'DEMO_HR'
        AND tut.table_name = 'LOCATIONS'

)
, dut -- Data Under Test 
AS (
      SELECT CASE WHEN (SELECT COUNT(*) FROM actual) = 0 THEN 'REJ-01: Table [locations] does not exist (may be case sensistive name)|exp=exists|act=notExist' 
	              WHEN a.column_nm IS NULL               THEN CONCAT('REJ-01: Expected column is missing from actual schema (may be case sensitive name)|exp=', e.column_nm, '|act=IsMissing')
	              WHEN a.ord_pos <> e.ord_pos            THEN CONCAT('REJ-02: Ordinal Positions at field ', e.column_nm, ' do not match|exp=', CAST(e.ord_pos AS CHAR(3)), '|act=', CAST(a.ord_pos AS CHAR(3)))
	              WHEN a.data_typ <> e.data_typ          THEN CONCAT('REJ-03: Data Types at field ', e.column_nm, ' do not match|exp=', e.data_typ, '|act=', a.data_typ )
	              WHEN a.nullable <> e.nullable          THEN CONCAT('REJ-04: Nullable settings at field ', e.column_nm, ' do not match|exp=', e.nullable, '|act=', a.nullable)
	              ELSE 'P'
	         END AS rej_dtls
	       , 'N/A - Go browse to table structure from tree grid in UI' AS lookup_sql
      FROM      expected e 
      LEFT JOIN actual   a ON a.column_nm = e.column_nm
)

SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
, '"RS-8 Diffs" #1 - Verify TableStructure("BySQL") by comparing snapshot in SQL code vs actual schema/structure for table [locations]' AS tst_descr   
FROM dut WHERE rej_dtls <> 'P';
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
)
, dut -- Data Under Test 
AS (
  SELECT CASE WHEN r.region_id IS NULL            THEN CONCAT('REJ-01: Record is missing from metadata|exp=NotMissing|act=', CAST(m.region_id AS CHAR(4)), ' is missing')
              WHEN r.region_name <> m.region_name THEN CONCAT('REJ-02: Region_Name does not match|exp=', m.region_name, '|act=', r.region_name)
              ELSE 'P'
         END AS status
  FROM      metadata   m 
  LEFT JOIN demo_hr.regions r ON r.region_id = m.region_id
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
    SELECT CAST('jobs' AS CHAR(15)) AS tbl_nm,          job_id, job_title, min_salary, max_salary FROM demo_hr.JOBS  
    UNION ALL 
    SELECT CAST('jobs_snapshot' AS CHAR(15)) AS tbl_nm, job_id, job_title, min_salary, max_salary FROM demo_hr.JOBS_SNAPSHOT 
    ) comb_sets 
    GROUP BY job_id, job_title, min_salary, max_salary
    HAVING COUNT(*) < 2
)
, dut -- Data Under Test 
AS (
  SELECT CONCAT('REJ-01: Mismatch Found: tbl_nm="', tbl_nm, '", job_id="', job_id, '", job_title="', job_title 
         , '", min_salary=', CAST(min_salary AS CHAR(20)), '", max_salary=', CAST(max_salary AS CHAR(20))) AS status
         , 'Too complex, better to go manually run the SQL for "non_matches" CTE sub-table' AS lookup_sql
  FROM non_matches  
)

SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
FROM dut WHERE status <> 'P';
 ```
</details>
<br>
