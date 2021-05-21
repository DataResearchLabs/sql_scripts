------------------------------------------------------------------------------------
-- Data Dictionary Dump:  
-- This SQL script will dump table, column, key, and description design related 
-- metadata so that you can copy-paste or export to Excel as a Data Dictionary.  
------------------------------------------------------------------------------------
-- Platform:          PostgreSQL
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- YouTube Tutorials: https://www.youtube.com/channel/UCQciXv3xaBykeUFc04GxSXA
----------------------------------------------------------------------------------
WITH vars
AS (
  SELECT 
    'public'     AS v_SchemaName  -- Set to the schema whose tables you want in the Data Dictionary
  , 'NO'         AS v_TablesOnly  -- YES=Limit To Tables only; NO=Include views too 
)

, baseTbl
AS (
  SELECT table_schema AS SchemaName
  , table_catalog
  , table_type, table_name, table_schema
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = (SELECT v_SchemaName FROM vars) 
    AND (    (TABLE_TYPE = 'BASE TABLE')
	     OR  ((SELECT v_TablesOnly FROM vars) = 'NO')  
	    )
)

, metadata
AS (
	SELECT
	  bt.SchemaName     AS schema_nm
	, bt.table_name     AS table_nm
	, CASE WHEN bt.TABLE_TYPE = 'BASE TABLE' THEN 'TBL'
	       WHEN bt.TABLE_TYPE = 'VIEW'  THEN 'VW'
	       ELSE 'UK'
	  END AS obj_typ
	, tut.ordinal_position   AS ord_pos
	, tut.column_name        AS column_nm 
    , CONCAT(tut.data_type, 
      CASE WHEN tut.data_type IN('varchar','char')            THEN CONCAT('(', tut.CHARACTER_MAXIMUM_LENGTH, ')')
	       WHEN tut.data_type IN('date','time')           THEN CONCAT('(3)')
	       WHEN tut.data_type = 'datetime'                THEN CONCAT('(8)')
	       WHEN tut.data_type = 'timestamp'               THEN CONCAT('(4)')
	       WHEN tut.data_type LIKE '%int%'                THEN CONCAT('(', tut.NUMERIC_PRECISION, ')')
	       WHEN tut.data_type = 'decimal'                 THEN CONCAT('(', tut.NUMERIC_PRECISION, ',', tut.NUMERIC_SCALE, ')')
	       WHEN tut.CHARACTER_MAXIMUM_LENGTH IS NOT NULL  THEN CONCAT('(', tut.CHARACTER_MAXIMUM_LENGTH, ')')
		   WHEN tut.DATETIME_PRECISION IS NOT NULL    THEN CONCAT('(', tut.DATETIME_PRECISION, ')')
	       WHEN tut.NUMERIC_PRECISION IS NOT NULL
		    AND tut.NUMERIC_SCALE     IS NULL         THEN CONCAT('(', tut.NUMERIC_PRECISION, ')')
	       WHEN tut.NUMERIC_PRECISION IS NOT NULL
	        AND tut.NUMERIC_SCALE     IS NOT NULL         THEN CONCAT('(', tut.NUMERIC_PRECISION, ',', tut.NUMERIC_SCALE, ')')
		   ELSE ''
    END ) AS data_typ 
  , CASE WHEN tut.IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END AS nullable
  FROM       INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl                    bt  ON bt.table_catalog = tut.TABLE_CATALOG AND bt.table_name = tut.table_name
)

, meta_for_keys
AS (
  SELECT schema_nm, table_nm, column_nm
  , STRING_AGG(is_key, ',' ORDER BY is_key) AS is_key
  FROM (
    SELECT cons.TABLE_SCHEMA AS schema_nm
    , cons.TABLE_NAME        AS table_nm
    , kcu.COLUMN_NAME        AS column_nm
    , CASE WHEN cons.constraint_type = 'PRIMARY KEY' THEN 'PK'
           WHEN cons.constraint_type = 'UNIQUE'      THEN 'UK'
           WHEN cons.constraint_type = 'FOREIGN KEY' THEN 'FK'
      END AS is_key
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS      cons 
    INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
       ON cons.TABLE_SCHEMA = kcu.TABLE_SCHEMA  
      AND cons.TABLE_NAME = kcu.TABLE_NAME
  	  AND cons.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
    WHERE cons.table_schema = (SELECT v_SchemaName FROM vars) 
      AND cons.table_name IN(SELECT DISTINCT table_name FROM baseTbl)
      AND cons.constraint_type IN('PRIMARY KEY','FOREIGN KEY','UNIQUE') 
    GROUP BY cons.TABLE_SCHEMA, cons.TABLE_NAME, kcu.COLUMN_NAME, cons.constraint_type
  ) t
  GROUP BY schema_nm, table_nm, column_nm
)

, col_comm
AS (
	SELECT c.TABLE_SCHEMA AS schema_nm
	, c.TABLE_NAME        AS table_nm
	, c.COLUMN_NAME       AS column_nm
	, pgd.DESCRIPTION     AS column_descr
	FROM pg_catalog.pg_statio_all_tables   AS st
	INNER JOIN pg_catalog.PG_DESCRIPTION   AS pgd ON pgd.objoid = st.relid
	INNER JOIN INFORMATION_SCHEMA.COLUMNS  AS c   ON pgd.objsubid = c.ordinal_position
	                                             AND c.table_schema = st.schemaname
	                                             AND c.table_name = st.relname
	WHERE c.table_schema = (SELECT v_SchemaName FROM vars) 
	  AND c.table_name IN(SELECT DISTINCT table_name FROM baseTbl)
)

SELECT md.SCHEMA_NM, md.TABLE_NM, md.OBJ_TYP
, md.ORD_POS AS ord
, COALESCE(pk.is_key, ' ') AS is_key
, md.COLUMN_NM, md.DATA_TYP, md.NULLABLE, c.column_descr 
FROM      metadata      md
LEFT JOIN meta_for_keys pk ON pk.SCHEMA_NM = md.SCHEMA_NM AND pk.TABLE_NM = md.TABLE_NM AND pk.COLUMN_NM = md.COLUMN_NM
LEFT JOIN col_comm      c  ON c.SCHEMA_NM  = md.SCHEMA_NM AND c.TABLE_NM  = md.TABLE_NM AND c.COLUMN_NM  = md.COLUMN_NM
ORDER BY md.SCHEMA_NM, md.TABLE_NM, md.ORD_POS
