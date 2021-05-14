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
-- Platform:          Oracle 11g or later
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- YouTube Tutorials: https://www.youtube.com/channel/UCQciXv3xaBykeUFc04GxSXA
----------------------------------------------------------------------------------

-- All variables are consolidated here in the first CTE (Common Table Expression)
-- Each given row is a variable, with the value you change preceding the "AS" command
WITH vars
AS (
  SELECT 'HR' AS v_SchemaName  -- <<<<<<<<<<<< CHANGE THIS VALUE to Schema you want to dump
  FROM dual
)


, baseTbl
AS (
  SELECT owner, table_type, table_name /*, comments */ 
  FROM SYS.ALL_TAB_COMMENTS
  WHERE table_name NOT LIKE 'BIN%' -- Leave this as is to ignore the Oracle10g and forard Recycle Bin tables
    AND owner = (SELECT v_SchemaName FROM vars) 
)

, metaForTbl
AS (
  SELECT t.owner  AS SchemaName
  , t.table_name  AS TableName
  , '(' || CASE WHEN t.table_type = 'TABLE' THEN 'Table' WHEN t.table_type = 'VIEW' THEN 'View' ELSE 'UK' END || ')' AS ObjectType
  , t.table_name  AS ObjectName
  , '(Exists)' AS PropertyName 
  , ' ' AS PropertyValue
  FROM baseTbl t
)

, metaForCol_dataType
AS (
  SELECT tut.owner AS SchemaName, tut.table_name AS TableName, 'Column' AS ObjectType, tut.column_name AS ObjectName 
  , '2' AS PropertyName
  , tut.data_type || '(' 
    || CASE WHEN tut.data_length    IS NOT NULL THEN        CAST(tut.data_length AS VARCHAR2(10)) ELSE '' END 
    || CASE WHEN tut.data_precision IS NOT NULL THEN ',' || CAST(tut.data_precision AS VARCHAR2(10)) ELSE '' END
    || CASE WHEN tut.data_scale     IS NOT NULL THEN ',' || CAST(tut.data_scale AS VARCHAR2(10)) ELSE '' END
    || ')' AS PropertyValue 
  FROM SYS.ALL_TAB_COLUMNS tut
  INNER JOIN baseTbl ft ON ft.owner = tut.owner AND ft.table_name = tut.table_name
)

, metaForCol_nullable
AS (
  SELECT tut.owner AS SchemaName, tut.table_name AS TableName, 'Column' AS ObjectType, tut.column_name AS ObjectName 
  , '3' AS PropertyName, CASE WHEN tut.nullable = 'Y' THEN 'NULL' ELSE 'NOT NULL' END AS PropertyValue 
  FROM SYS.ALL_TAB_COLUMNS tut
  INNER JOIN baseTbl ft ON ft.owner = tut.owner AND ft.table_name = tut.table_name
)

, metaForCol_ordpos
AS (
  SELECT tut.owner AS SchemaName, tut.table_name AS TableName, 'Column' AS ObjectType, tut.column_name AS ObjectName 
  , '1' AS PropertyName, LPAD(CAST(tut.column_id AS VARCHAR2(3)), 3, '0') AS PropertyValue 
  FROM SYS.ALL_TAB_COLUMNS tut
  INNER JOIN baseTbl ft ON ft.owner = tut.owner AND ft.table_name = tut.table_name
)

, metaAllCols
AS (
  SELECT schemaname, tablename, objecttype, objectname, 'Properties' AS propertyname
  , LISTAGG(propertyvalue, ' | ') 
    WITHIN GROUP (ORDER BY propertyname, propertyvalue) AS propertyvalue
  FROM (
          SELECT * FROM metaForCol_dataType
    UNION SELECT * FROM metaForCol_nullable
    UNION SELECT * FROM metaForCol_ordpos
  ) t
  GROUP BY schemaname, tablename, objecttype, objectname
)

, metaForKeys
AS (
  SELECT cons.owner AS SchemaName, cols.table_name AS TableName
  , CASE WHEN cons.constraint_type = 'P' THEN 'PKey'
         WHEN cons.constraint_type = 'U' THEN 'UKey'
         WHEN cons.constraint_type = 'R' THEN 'FKey'
    END AS ObjectType
  , cons.constraint_name AS ObjectName
  , 'FieldList' AS PropertyName 
  , LISTAGG(cols.column_name, ',') WITHIN GROUP (ORDER BY cols.position) AS PropertyValue 
  FROM all_constraints cons 
    INNER JOIN all_cons_columns cols ON cons.constraint_name = cols.constraint_name AND cons.owner = cols.owner 
  WHERE cons.table_name IN(SELECT DISTINCT table_name FROM baseTbl)
    AND cons.constraint_type IN('P','R','U') 
  GROUP BY cons.owner, cols.table_name, cons.constraint_type, cons.constraint_name
)

, metaForIdxs
AS (
SELECT tut.table_owner AS SchemaName, tut.table_name AS TableName
, 'Index' AS ObjectType, tut.index_name AS ObjectName 
, 'FieldList' AS PropertyName 
, LISTAGG(tut.column_name, ',') WITHIN GROUP (ORDER BY tut.column_position) AS PropertyValue 
FROM ALL_IND_COLUMNS tut
  INNER JOIN baseTbl ft ON ft.owner = tut.index_owner AND ft.table_name = tut.table_name
GROUP BY tut.table_owner, tut.table_name, tut.index_name
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


