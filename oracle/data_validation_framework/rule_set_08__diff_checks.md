# Rule Set #8 - Diff Checks (Schema and Data Changes)
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
## Data Validation Examples - Oracle

---

## Table of Contents
 - <a href="#t059">T059 - Table Structure (Schema) Differences</a>
 - <a href="#t060">T060 - Table Data Differences (Static SQL Snapshot)</a>
 - <a href="#t061">T061 - Table Data Diffeernces (Dynamic Table Compare)</a>
<br>


<a id="t059" class="anchor" href="#t059" aria-hidden="true"> </a>
### T059 - Table Structure (Schema) Differences
dddddd.
 ```sql
WITH expected 
AS (
        SELECT 1 AS ord_pos, 'LOCATION_ID'    AS column_nm, 'NUMBER(4)'    AS data_typ, 'NOT NULL' AS nullable FROM dual
  UNION SELECT 2 AS ord_pos, 'STREET_ADDRESS' AS column_nm, 'VARCHAR2(40)' AS data_typ, 'NULL' AS nullable FROM dual
  UNION SELECT 3 AS ord_pos, 'POSTAL_CODE'    AS column_nm, 'VARCHAR2(12)' AS data_typ, 'NULL' AS nullable FROM dual
  UNION SELECT 4 AS ord_pos, 'CITY'           AS column_nm, 'VARCHAR2(30)' AS data_typ, 'NOT NULL' AS nullable FROM dual
  UNION SELECT 5 AS ord_pos, 'STATE_PROVINCE' AS column_nm, 'VARCHAR2(25)' AS data_typ, 'NULL' AS nullable FROM dual
  UNION SELECT 6 AS ord_pos, 'COUNTRY_ID'     AS column_nm, 'CHAR(2)'      AS data_typ, 'NULL' AS nullable FROM dual
  ORDER BY ord_pos
)
, actual
AS (
  SELECT
    atc.column_id   AS ord_pos
  , atc.column_name AS column_nm 
  , (atc.data_type ||
     decode(atc.data_type,
    	 'NUMBER',
    	   decode(atc.data_precision, null, '',
    	     '(' || to_char(atc.data_precision) || decode(atc.data_scale,null,'',0,'',',' || to_char(atc.data_scale) )
    	         || ')' ),
    	 'FLOAT', '(' || to_char(atc.data_precision) || ')',
    	 'VARCHAR2', '(' || to_char(atc.data_length) || ')',
    	 'NVARCHAR2', '(' || to_char(atc.data_length) || ')',
    	 'VARCHAR', '(' || to_char(atc.data_length) || ')',
    	 'CHAR', '(' || to_char(atc.data_length) || ')',
    	 'RAW', '(' || to_char(atc.data_length) || ')',
    	 'MLSLABEL',decode(atc.data_length,null,'',0,'','(' || to_char(atc.data_length) || ')'),
    	 '')
    )                 AS data_typ
  , CASE WHEN atc.nullable = 'Y' THEN 'NULL' ELSE 'NOT NULL' END AS nullable
  FROM       all_tab_columns  atc
  INNER JOIN all_col_comments dcc ON atc.owner = dcc.owner AND atc.table_name = dcc.table_name AND atc.column_name = dcc.column_name
  INNER JOIN all_tab_comments t   ON t.OWNER = atc.owner   AND t.TABLE_NAME = atc.table_name
  WHERE atc.owner = 'HR'
    AND atc.table_name = 'LOCATIONS'
)
, dut -- Data Under Test 
AS (
  SELECT CASE WHEN (SELECT COUNT(*) FROM actual) = 0 THEN 'REJ-01: Table [locations] does not exist (may be case sensistive name)|exp=exists|act=notExist' 
              WHEN a.column_nm IS NULL               THEN 'REJ-01: Expected column is missing from actual schema (may be case sensitive name)|exp=' || e.column_nm || '|act=IsMissing' 
              WHEN a.ord_pos <> e.ord_pos            THEN 'REJ-02: Ordinal Positions at field ' || e.column_nm || ' do not match|exp=' || CAST(e.ord_pos AS VARCHAR2(3)) || '|act=' || CAST(a.ord_pos AS VARCHAR2(3))
              WHEN a.data_typ <> e.data_typ          THEN 'REJ-03: Data Types at field ' || e.column_nm || ' do not match|exp=' || e.data_typ || '|act=' || a.data_typ 
              WHEN a.nullable <> e.nullable          THEN 'REJ-04: Nullable settings at field ' || e.column_nm || ' do not match|exp=' || e.nullable || '|act=' || a.nullable 
              ELSE 'P'
         END AS status
  FROM      expected e 
  LEFT JOIN actual   a ON a.column_nm = e.column_nm
)

SELECT CASE WHEN COUNT(*) = 0 THEN 'P' ELSE 'FAIL' END status
FROM dut WHERE status <> 'P';
 ```
<br>


