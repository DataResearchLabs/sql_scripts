
------------------------------------------------------------------------------------
-- Data Dictionary Dump:  
-- This SQL script will dump table, column, key, and description design related 
-- metadata so that you can copy-paste or export to Excel as a Data Dictionary.  
------------------------------------------------------------------------------------
-- Platform:          SQL Server
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- GitHub Tool:       https://github.com/DataResearchLabs/data_analysts_toolbox/blob/main/data_dictionary_generator/readme.md
-- YouTube Tutorials: https://www.youtube.com/channel/UCQciXv3xaBykeUFc04GxSXA
----------------------------------------------------------------------------------

-- IMPORTANT
USE AdventureWorksLT2019;  -- <<<<<<<<<<<< CHANGE THIS VALUE to Schema you want to dump
;

-- All variables are consolidated here in the first CTE (Common Table Expression)
-- Each given row is a variable, with the value you change preceding the "AS" command
WITH vars
AS (
  SELECT 
    DB_NAME()  AS v_SchemaName  -- (Do not change this value, it is picked up from changes above)
  , 'NO'       AS v_TablesOnly  -- Change this setting:  YES=Limit To Tables only; NO=Include views too 
)


, baseTbl
AS (
  SELECT TABLE_CATALOG AS SchemaName, table_type, table_name, table_schema
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_CATALOG = (SELECT v_SchemaName FROM vars) 
    AND (    (TABLE_TYPE = 'BASE TABLE')
	     OR  ((SELECT v_TablesOnly FROM vars) = 'NO')  
	    )
)


, metadata
AS (
  SELECT
    bt.SchemaName                                              AS schema_nm
  , bt.table_name                                              AS table_nm
  , CASE WHEN bt.table_type = 'BASE TABLE' THEN 'TBL'
         WHEN bt.table_type = 'VIEW'       THEN 'VW'
		 ELSE 'UK'
    END                                                        AS obj_typ
  , RIGHT('000' + CAST(tut.ORDINAL_POSITION AS VARCHAR(3)), 3) AS ord_pos
  , tut.column_name                                            AS column_nm
  , COALESCE(tut.data_type, 'unknown') + 
    CASE WHEN tut.data_type IN('varchar','nvarchar')    THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
	     WHEN tut.data_type IN('char','nchar')          THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
	     WHEN tut.data_type ='date'                     THEN '(' + CAST(tut.DATETIME_PRECISION AS VARCHAR(10)) + ')'
	     WHEN tut.data_type ='datetime'                 THEN '(' + CAST(tut.DATETIME_PRECISION AS VARCHAR(10)) + ')'
	     WHEN tut.data_type in('bigint','int','smallint', 'tinyint') THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10))  + ')'
	     WHEN tut.data_type = 'uniqueidentifier'        THEN '(16)'
	     WHEN tut.data_type = 'money'                   THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) + ')'
	     WHEN tut.data_type = 'decimal'                 THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) + ',' + CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) + ')'
	     WHEN tut.data_type = 'numeric'                 THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) + ',' + CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) + ')'
	     WHEN tut.data_type = 'varbinary'               THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
	     WHEN tut.data_type = 'xml'                     THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
	     WHEN tut.data_type IN('char','nchar')          THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
	     WHEN tut.CHARACTER_MAXIMUM_LENGTH IS NOT NULL  THEN '(' + CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
		 WHEN tut.DATETIME_PRECISION IS NOT NULL        THEN '(' + CAST(tut.DATETIME_PRECISION AS VARCHAR(10)) + ')'
	     WHEN tut.NUMERIC_PRECISION IS NOT NULL
		  AND tut.NUMERIC_SCALE     IS NULL             THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) + ')'
	     WHEN tut.NUMERIC_PRECISION IS NOT NULL
		  AND tut.NUMERIC_SCALE     IS NOT NULL         THEN '(' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) + ',' + CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) + ')'
		 ELSE ''
    END AS data_typ
  , CASE WHEN tut.IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END AS nullable
  FROM       INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl                    bt  ON bt.SchemaName = tut.TABLE_CATALOG AND bt.table_name = tut.table_name
)

, descr
AS (
  SELECT 
    bt.SchemaName          AS schema_nm
  , bt.table_name          AS table_nm
  , tut.column_name        AS column_nm
  , STRING_AGG(CAST(de.value AS VARCHAR(1024)), '.  ') WITHIN GROUP (ORDER BY de.value) AS description
  FROM       INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl                    bt  ON bt.SchemaName = tut.TABLE_CATALOG AND bt.table_name = tut.table_name
  LEFT JOIN  sys.extended_properties    de  ON de.major_id = OBJECT_ID(bt.table_schema + '.' + bt.table_name) 
                                           AND de.minor_id = tut.ORDINAL_POSITION
										   AND de.name = 'MS_Description'
  GROUP BY bt.SchemaName, bt.table_name, tut.column_name
)


, metadata_keys
AS (
  SELECT schema_nm, table_nm, column_nm
  , STRING_AGG(key_typ, ',') WITHIN GROUP (ORDER BY key_typ) AS is_key 
  FROM (  
    SELECT 
      cons.TABLE_CATALOG AS schema_nm
    , cons.TABLE_NAME    AS table_nm
    , kcu.COLUMN_NAME    AS column_nm
    , CASE WHEN cons.CONSTRAINT_TYPE = 'PRIMARY KEY' THEN 'PK'
           WHEN cons.CONSTRAINT_TYPE = 'UNIQUE'      THEN 'UK'
           WHEN cons.CONSTRAINT_TYPE = 'FOREIGN KEY' THEN 'FK'
		   ELSE 'X'
      END AS key_typ
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS      cons 
    INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
             ON cons.TABLE_CATALOG = kcu.TABLE_CATALOG  
            AND cons.TABLE_NAME = kcu.TABLE_NAME
            AND cons.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
    WHERE cons.TABLE_CATALOG = (SELECT v_SchemaName FROM vars)
      AND cons.table_name IN(SELECT DISTINCT table_name FROM baseTbl)
      AND cons.constraint_type IN('PRIMARY KEY','FOREIGN KEY','UNIQUE') 
    GROUP BY cons.TABLE_CATALOG, cons.TABLE_NAME, kcu.COLUMN_NAME, cons.CONSTRAINT_TYPE
  ) AS t
  GROUP BY schema_nm, table_nm, column_nm
)


SELECT md.schema_nm, md.table_nm, md.obj_typ, md.ord_pos
, COALESCE(mk.is_key, ' ') AS keys
, md.column_nm, md.data_typ, md.nullable
, de.[description]
FROM      metadata      md
LEFT JOIN descr         de ON de.schema_nm = md.schema_nm  AND  de.table_nm = md.table_nm  AND  de.column_nm = md.column_nm
LEFT JOIN metadata_keys mk ON mk.schema_nm = md.schema_nm  AND  mk.table_nm = md.table_nm  AND  mk.column_nm = md.column_nm
ORDER BY schema_nm, table_nm, ord_pos

