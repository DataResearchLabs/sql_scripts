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
-- Platform:          Microsoft SQL Server
-- Author:            DataResearchLabs
-- GitHub:            https://www.github.com/DataResearchLabs
-- YouTube Tutorials: https://www.youtube.com/playlist?list=PLVHoUDdbskUSlZTVZmllGTdSuvyI4LBiE
----------------------------------------------------------------------------------

-- IMPORTANT
USE AdventureWorksLT2019;  -- <<<<<<<<<<<< CHANGE THIS VALUE to Schema you want to dump
;


WITH vars
AS (
  SELECT DB_NAME() AS v_SchemaName
)

, baseTbl
AS (
  SELECT TABLE_CATALOG AS SchemaName, table_type, table_name 
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_CATALOG = (SELECT v_SchemaName FROM vars) 
)

, metaForTbl
AS (
  SELECT t.SchemaName
  , t.table_name  AS TableName
  , '(' + CASE WHEN t.table_type = 'BASE TABLE' THEN 'Table' WHEN t.table_type = 'VIEW' THEN 'View' ELSE 'UK' END + ')' AS ObjectType
  , t.table_name  AS ObjectName
  , '(Exists)' AS PropertyName 
  , ' ' AS PropertyValue
  FROM baseTbl t
)

, metaForCol_dataType
AS (
  SELECT ft.SchemaName, ft.table_name AS TableName, 'Column' AS ObjectType, tut.column_name AS ObjectName 
  , '2' AS PropertyName
  , tut.data_type + '(' 
    + CASE WHEN tut.CHARACTER_MAXIMUM_LENGTH  IS NOT NULL THEN       CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) ELSE '' END 
    + CASE WHEN tut.DATA_TYPE IN('date','datetime')       THEN ',' + CAST(tut.DATETIME_PRECISION AS VARCHAR(10)) 
	       WHEN tut.NUMERIC_PRECISION IS NULL             THEN ''
		   ELSE ',' + CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) 
	  END 
    + CASE WHEN tut.NUMERIC_SCALE IS NOT NULL             THEN ',' + CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) ELSE '' END
    + ')' AS PropertyValue 
  FROM INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl ft ON ft.SchemaName = tut.TABLE_CATALOG AND ft.table_name = tut.table_name
)

, metaForCol_nullable
AS (
  SELECT ft.SchemaName, ft.table_name AS TableName, 'Column' AS ObjectType, tut.column_name AS ObjectName 
  , '3' AS PropertyName, CASE WHEN tut.IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END AS PropertyValue 
  FROM INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl ft ON ft.SchemaName = tut.TABLE_CATALOG  AND ft.table_name = tut.table_name
)

, metaForCol_ordpos
AS (
  SELECT ft.SchemaName, ft.table_name AS TableName, 'Column' AS ObjectType, tut.column_name AS ObjectName 
  , '1' AS PropertyName, RIGHT('000' + CAST(tut.ORDINAL_POSITION AS VARCHAR(3)), 3) AS PropertyValue 
  FROM INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl ft ON ft.SchemaName = tut.TABLE_CATALOG AND ft.table_name = tut.table_name
)

, metaAllCols
AS (
  SELECT schemaname, tablename, objecttype, objectname, 'Properties' AS propertyname
  /* NOTE: STRING_AGG was added in SQL Server 2017 and forward.
     If you have and older version, use FOR XML PATH approach here: https://stackoverflow.com/questions/15477743/listagg-in-sqlserver
  */
  , STRING_AGG(propertyvalue, ' | ') 
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
  SELECT cons.TABLE_CATALOG AS SchemaName, cons.TABLE_NAME AS TableName
  , CASE WHEN cons.constraint_type = 'PRIMARY KEY' THEN 'PKey'
         WHEN cons.constraint_type = 'UNIQUE' THEN 'UKey'
         WHEN cons.constraint_type = 'FOREIGN KEY' THEN 'FKey'
    END AS ObjectType
  , cons.constraint_name AS ObjectName
  , 'FieldList' AS PropertyName 
  /* NOTE: STRING_AGG was added in SQL Server 2017 and forward.
     If you have and older version, use FOR XML PATH approach here: https://stackoverflow.com/questions/15477743/listagg-in-sqlserver
  */
  , STRING_AGG(kcu.COLUMN_NAME, ',') WITHIN GROUP (ORDER BY kcu.ORDINAL_POSITION) AS PropertyValue 
  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS      cons 
  INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
     ON cons.TABLE_CATALOG = kcu.TABLE_CATALOG  
    AND cons.TABLE_NAME = kcu.TABLE_NAME
	AND cons.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
  WHERE cons.table_name IN(SELECT DISTINCT table_name FROM baseTbl)
    AND cons.constraint_type IN('PRIMARY KEY','FOREIGN KEY','UNIQUE') 
  GROUP BY cons.TABLE_CATALOG, cons.TABLE_NAME, cons.CONSTRAINT_TYPE, cons.CONSTRAINT_NAME
)

, metaForIdxs
AS (
SELECT (SELECT v_SchemaName FROM vars) AS SchemaName, o.name AS TableName
, 'Index' AS ObjectType, i.name AS ObjectName 
, 'FieldList' AS PropertyName 
  /* NOTE: STRING_AGG was added in SQL Server 2017 and forward.
     If you have and older version, use FOR XML PATH approach here: https://stackoverflow.com/questions/15477743/listagg-in-sqlserver
  */
, STRING_AGG(o.name, ',') WITHIN GROUP (ORDER BY ic.column_store_order_ordinal) AS PropertyValue 
FROM sys.indexes               i
  INNER JOIN sys.objects       o  ON i.object_id = o.object_id
  INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id  
                                 AND  ic.index_id = i.index_id
WHERE i.[Type] = 2
  AND i.is_unique = 0
  AND i.is_primary_key = 0
  AND o.[type] = 'U'
GROUP BY o.name, i.name
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


