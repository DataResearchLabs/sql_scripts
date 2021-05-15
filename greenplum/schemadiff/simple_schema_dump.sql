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
-- Platform:          Greenplum Server
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- YouTube Tutorials: https://www.youtube.com/playlist?list=**************************
----------------------------------------------------------------------------------
WITH vars
AS (
  SELECT 'your_schema_name' :: CHARACTER VARYING(50) AS v_SchemaName   -- <<<<<<<<<  Change here
)


, baseTbl
AS (
  SELECT table_schema AS SchemaName, table_type, table_name 
  FROM INFORMATION_SCHEMA.TABLES
  WHERE table_schema = (SELECT v_SchemaName FROM vars) 
)


, metaForTbl
AS (
  SELECT SchemaName
  , table_name  AS TableName
  , '(' || CASE WHEN table_type = 'BASE TABLE' THEN 'Table' 
                WHEN table_type = 'VIEW' THEN 'View' 
                ELSE 'UK' 
		   END 
    || ')' :: CHARACTER VARYING(20) AS ObjectType
  , table_name  AS ObjectName
  , '(Exists)' :: CHARACTER VARYING(20) AS PropertyName 
  , '' :: CHARACTER VARYING(50)        AS PropertyValue
  FROM baseTbl 
)

, metaForCol_dataType
AS (
  SELECT ft.SchemaName, ft.table_name AS TableName
  , 'Column' :: CHARACTER VARYING(15) AS ObjectType
  , tut.column_name AS ObjectName 
  , '2' :: CHARACTER VARYING(10) AS PropertyName
  , tut.data_type
    || CASE WHEN tut.CHARACTER_MAXIMUM_LENGTH IS NOT NULL 
		          OR tut.NUMERIC_PRECISION IS NOT NULL
		          OR tut.NUMERIC_SCALE IS NOT NULL THEN '(' 
		        ELSE ''
	     END
    || CASE WHEN tut.CHARACTER_MAXIMUM_LENGTH  IS NOT NULL THEN CAST(tut.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) 
            ELSE '' 
       END 
    || CASE WHEN tut.DATA_TYPE IN('date','datetime','timestamp') THEN ''
	          WHEN tut.NUMERIC_PRECISION IS NULL  THEN ''
	          ELSE CAST(tut.NUMERIC_PRECISION AS VARCHAR(10)) 
	     END 
    || CASE WHEN tut.NUMERIC_SCALE IS NULL  THEN ''
		        WHEN tut.NUMERIC_SCALE >0       THEN ',' || CAST(tut.NUMERIC_SCALE AS VARCHAR(10)) 
            ELSE '' 
       END
    || CASE WHEN tut.CHARACTER_MAXIMUM_LENGTH IS NOT NULL 
		          OR tut.NUMERIC_PRECISION IS NOT NULL
		          OR tut.NUMERIC_SCALE IS NOT NULL THEN ')'
            ELSE ''
	     END
   :: CHARACTER VARYING(255) AS PropertyValue 
  FROM INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl ft ON ft.SchemaName = tut.TABLE_SCHEMA AND ft.TABLE_NAME = tut.TABLE_NAME
)


, metaForCol_nullable
AS (
  SELECT ft.SchemaName, ft.table_name AS TableName
  , 'Column' :: CHARACTER VARYING(20) AS ObjectType
  , tut.column_name AS ObjectName 
  , '3' :: CHARACTER VARYING(20) AS PropertyName
  , CASE WHEN tut.IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END :: CHARACTER VARYING(20) AS PropertyValue 
  FROM INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl ft ON ft.SchemaName = tut.TABLE_SCHEMA  AND ft.table_name = tut.table_name
)


, metaForCol_ordpos
AS (
  SELECT ft.SchemaName, ft.table_name AS TableName
  , 'Column' :: CHARACTER VARYING(20) AS ObjectType
  , tut.column_name AS ObjectName 
  , '1' :: CHARACTER VARYING(20) AS PropertyName
  , CASE WHEN tut.ORDINAL_POSITION IS NULL THEN ''
	     ELSE LPAD( CAST(tut.ORDINAL_POSITION AS VARCHAR(3)), 3, '0') 
	END AS PropertyValue 
  FROM INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl ft ON ft.SchemaName = tut.TABLE_SCHEMA AND ft.table_name = tut.table_name
)


, metaAllCols
AS (
  SELECT schemaname, tablename, objecttype, objectname
  , 'Properties' :: CHARACTER VARYING(20) AS propertyname
  , STRING_AGG(propertyvalue, ' | ' ORDER BY propertyname, propertyvalue) :: CHARACTER VARYING(255) AS propertyvalue
  FROM (
          SELECT * FROM metaForCol_dataType
    UNION SELECT * FROM metaForCol_nullable
    UNION SELECT * FROM metaForCol_ordpos
  ) t
  GROUP BY schemaname, tablename, objecttype, objectname
)


, metaForKeys
AS (
  SELECT SchemaName, TableName 
  , 'DistribKey' :: CHARACTER VARYING(20) AS ObjectType 
  , 'n/a' :: CHARACTER VARYING(10) AS ObjectName
  , 'FieldList' :: CHARACTER VARYING(10) AS PropertyName
  , COALESCE(distribution_keys,'DISTRIBUTED RANDOMLY') :: CHARACTER VARYING(255) AS PropertyValue 
  FROM 
  ( SELECT pgn.nspname AS SchemaName,
    pgc.relname AS TableName, 
    pga.attname AS distribution_keys
    FROM 
    ( SELECT gdp.localoid 
      , CASE WHEN ( Array_upper(gdp.attrnums, 1) > 0 ) THEN Unnest(gdp.attrnums)
             ELSE NULL 
        END As attnum 
      FROM gp_distribution_policy gdp 
      ORDER BY gdp.localoid 
    ) AS distrokey 
    INNER JOIN pg_class          pgc ON distrokey.localoid = pgc.oid 
    INNER JOIN pg_namespace      pgn ON pgc.relnamespace = pgn.oid 
    LEFT OUTER JOIN pg_attribute pga ON distrokey.attnum = pga.attnum AND distrokey.localoid = pga.attrelid 
    WHERE pgn.nspname = (SELECT v_SchemaName FROM vars)
      AND pgc.relname IN(SELECT DISTINCT table_name FROM baseTbl) 
    ) AS a 
  )


, metaForIdxs
AS (
  SELECT (SELECT v_SchemaName FROM vars) AS SchemaName
  , tablename AS TableName
  , 'Index' :: CHARACTER VARYING(20) AS ObjectType
  , indexname AS ObjectName 
  , 'FieldList' :: CHARACTER VARYING(20) AS PropertyName 
  , REPLACE(SUBSTR(indexdef, POSITION('(' IN indexdef)+ 1), ')', '') :: CHARACTER VARYING(255) AS PropertyValue 
  FROM pg_catalog.pg_indexes
  WHERE schemaname = (SELECT v_SchemaName FROM vars)
    AND tablename IN(SELECT DISTINCT table_name FROM baseTbl) 
)


, allMetadata
AS (
        SELECT * FROM metaAllCols
  UNION SELECT * FROM metaForTbl    /* not first, b/c propertyvalue column all nulls = no data type default = error */
  UNION SELECT * FROM metaForKeys
  UNION SELECT * FROM metaForIdxs
)


SELECT CASE WHEN objecttype IN('(Table)','(View)') THEN schemaname ELSE '' END AS schema_nm
, CASE WHEN objecttype IN('(Table)','(View)') THEN tablename ELSE '' END AS tbl_nm
, objecttype AS obj_typ, objectname AS obj_nm, /*propertyname,*/ propertyvalue AS properties
FROM allMetadata 
ORDER BY schemaname, tablename, objecttype
, CASE WHEN objecttype='Column' THEN propertyvalue ELSE '' END
, objectname, propertyname
