------------------------------------------------------------------------------------
-- Simple Schema Dump:  
-- This SQL script will dump table, column, key, and index design related metadata
-- so that you can copy-paste or export to a text file.  
-- Even better, you can make other snapshots over time (same database schema earlier
-- points in time), OR in different environments (DEV, PPMO, STAGE, PROD).  Then,
-- using your favorite free Text File Diff Tool (DiffMerge, ExamDiff, etc.) you
-- can compare snapshots to quick isolate and identify what changed over time 
-- or is different between environments.
------------------------------------------------------------------------------------
-- Platform:          MySQL Server
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- YouTube Tutorials: https://www.youtube.com/playlist?list=PLVHoUDdbskUT0kz-4aB68EsollbmelcjT
----------------------------------------------------------------------------------
USE sakila   -- <<<<<<<<<<<<<  Change schema here
;

WITH vars
AS (
  SELECT DATABASE() AS v_SchemaName
)

, baseTbl
AS (
  SELECT table_schema AS SchemaName, table_type, table_name 
  FROM INFORMATION_SCHEMA.TABLES
  WHERE table_schema = (SELECT v_SchemaName FROM vars) 
)

, metaForTbl
AS (
  SELECT t.SchemaName
  , t.table_name  AS TableName
  , CONCAT( '('
         , CASE WHEN t.table_type <=> 'BASE TABLE' THEN 'Table' 
                WHEN t.table_type <=> 'VIEW' THEN 'View' 
                ELSE 'UK' 
		   END 
	     , ')'
	) AS ObjectType
  , t.table_name  AS ObjectName
  , '(Exists)' AS PropertyName 
  , ' ' AS PropertyValue
  FROM baseTbl t
)

, metaForCol_dataType
AS (
  SELECT ft.SchemaName, ft.table_name AS TableName, 'Column' AS ObjectType, tut.column_name AS ObjectName 
  , '2' AS PropertyName
  , CONCAT(COALESCE(tut.data_type, 'unknown')
    , '(' 
    , CASE WHEN tut.CHARACTER_MAXIMUM_LENGTH  IS NOT NULL THEN CAST(tut.CHARACTER_MAXIMUM_LENGTH AS CHAR(10)) ELSE '' END 
    , CASE WHEN tut.DATA_TYPE IN('date','datetime','timestamp') THEN CAST(tut.DATETIME_PRECISION AS CHAR(10))
	       WHEN tut.NUMERIC_PRECISION IS NULL  THEN ''
		   ELSE CONCAT(CAST(tut.NUMERIC_PRECISION AS CHAR(10))) 
	  END 
    , CASE WHEN tut.NUMERIC_SCALE IS NOT NULL  THEN CONCAT(',', CAST(tut.NUMERIC_SCALE AS CHAR(10))) ELSE '' END
    , ')'
    ) AS PropertyValue 
  FROM INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl ft ON ft.SchemaName = tut.TABLE_SCHEMA AND ft.TABLE_NAME = tut.TABLE_NAME
)

, metaForCol_nullable
AS (
  SELECT ft.SchemaName, ft.table_name AS TableName, 'Column' AS ObjectType, tut.column_name AS ObjectName 
  , '3' AS PropertyName, CASE WHEN tut.IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END AS PropertyValue 
  FROM INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl ft ON ft.SchemaName = tut.TABLE_SCHEMA  AND ft.table_name = tut.table_name
)

, metaForCol_ordpos
AS (
  SELECT ft.SchemaName, ft.table_name AS TableName, 'Column' AS ObjectType, tut.column_name AS ObjectName 
  , '1' AS PropertyName
  , LPAD(CAST(tut.ORDINAL_POSITION AS CHAR(3)), 3, 0) AS PropertyValue 
  FROM INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl ft ON ft.SchemaName = tut.TABLE_SCHEMA AND ft.table_name = tut.table_name
)

, metaAllCols
AS (
  SELECT schemaname, tablename, objecttype, objectname, 'Properties' AS propertyname
  , GROUP_CONCAT(propertyvalue ORDER BY propertyname, propertyvalue SEPARATOR ' | ') AS propertyvalue
  FROM (
          SELECT * FROM metaForCol_dataType
    UNION SELECT * FROM metaForCol_nullable
    UNION SELECT * FROM metaForCol_ordpos
  ) t
  GROUP BY schemaname, tablename, objecttype, objectname
)

, metaForKeys
AS (
  SELECT cons.TABLE_SCHEMA AS SchemaName, cons.TABLE_NAME AS TableName
  , CASE WHEN cons.constraint_type = 'PRIMARY KEY' THEN 'PKey'
         WHEN cons.constraint_type = 'UNIQUE' THEN 'UKey'
         WHEN cons.constraint_type = 'FOREIGN KEY' THEN 'FKey'
         ELSE 'X'
    END AS ObjectType
  , cons.constraint_name AS ObjectName
  , 'FieldList' AS PropertyName 
  , GROUP_CONCAT(kcu.COLUMN_NAME ORDER BY kcu.ORDINAL_POSITION SEPARATOR ',') AS PropertyValue 
  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS      cons 
  INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
     ON cons.TABLE_SCHEMA = kcu.TABLE_SCHEMA  
    AND cons.TABLE_NAME = kcu.TABLE_NAME
	AND cons.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
  WHERE cons.table_schema = (SELECT v_SchemaName FROM vars) 
    AND cons.table_name IN(SELECT DISTINCT table_name FROM baseTbl)
    AND cons.constraint_type IN('PRIMARY KEY','FOREIGN KEY','UNIQUE') 
  GROUP BY cons.TABLE_SCHEMA, cons.TABLE_NAME, cons.CONSTRAINT_TYPE, cons.CONSTRAINT_NAME
)

, metaForIdxs
AS (
SELECT (SELECT v_SchemaName FROM vars) AS SchemaName
, table_name AS TableName
, 'Index' AS ObjectType
, index_name AS ObjectName 
, 'FieldList' AS PropertyName 
, GROUP_CONCAT(column_name ORDER BY seq_in_index SEPARATOR ',') AS PropertyValue 
FROM information_schema.statistics
WHERE table_schema = (SELECT v_SchemaName FROM vars)
GROUP BY table_name, index_name
)

, allMetadata
AS (
        SELECT * FROM metaForTbl
  UNION SELECT * FROM metaAllCols
  UNION SELECT * FROM metaForKeys
  UNION SELECT * FROM metaForIdxs
)

SELECT CASE WHEN objecttype IN('(Table)','(View)') THEN schemaname ELSE ' ' END AS schema_nm
, CASE WHEN objecttype IN('(Table)','(View)') THEN tablename ELSE ' ' END AS tbl_nm
, objecttype AS obj_typ, objectname AS obj_nm, /*propertyname,*/ propertyvalue AS properties
FROM allMetadata 
ORDER BY schemaname, tablename, objecttype
, CASE WHEN objecttype='Column' THEN propertyvalue ELSE ' ' END
, objectname, propertyname


