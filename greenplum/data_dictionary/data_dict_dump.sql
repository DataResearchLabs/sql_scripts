------------------------------------------------------------------------------------
-- Data Dictionary Dump:  
-- This SQL script will dump table, column, key, and description design related 
-- metadata so that you can copy-paste or export to Excel as a Data Dictionary.  
------------------------------------------------------------------------------------
-- Platform:          Greenplum
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- YouTube Tutorials: https://www.youtube.com/channel/UCQciXv3xaBykeUFc04GxSXA
----------------------------------------------------------------------------------
WITH vars
AS (
  SELECT 
    'acq_cms' :: CHARACTER VARYING(50) AS v_SchemaName  -- <<<<<<<<<<<<<<<< Set to the schema you wish to document
  , 'NO'      :: CHARACTER VARYING(10) AS v_TablesOnly  -- YES=Limit To Tables only; NO=Include views too 
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
    , tut.data_type || 
      CASE WHEN tut.data_type IN('varchar','char')        THEN '(' || tut.CHARACTER_MAXIMUM_LENGTH || ')'
	         WHEN tut.data_type IN('date','time')           THEN '(3)'
	         WHEN tut.data_type = 'datetime'                THEN '(8)'
  	       WHEN tut.data_type = 'timestamp'               THEN '(4)'
	         WHEN tut.data_type LIKE '%int%'                THEN '(' || tut.NUMERIC_PRECISION || ')'
	         WHEN tut.data_type = 'decimal'                 THEN '(' || tut.NUMERIC_PRECISION || ',' || tut.NUMERIC_SCALE || ')'
	         WHEN tut.CHARACTER_MAXIMUM_LENGTH IS NOT NULL  THEN '(' || tut.CHARACTER_MAXIMUM_LENGTH || ')'
           WHEN tut.DATETIME_PRECISION IS NOT NULL        THEN '(' || tut.DATETIME_PRECISION || ')'
  	       WHEN tut.NUMERIC_PRECISION IS NOT NULL
	          AND tut.NUMERIC_SCALE     IS NULL             THEN '(' || tut.NUMERIC_PRECISION || ')'
	         WHEN tut.NUMERIC_PRECISION IS NOT NULL
	          AND tut.NUMERIC_SCALE     IS NOT NULL         THEN '(' || tut.NUMERIC_PRECISION || ',' || tut.NUMERIC_SCALE || ')'
		   ELSE ''
    END AS data_typ 
  , CASE WHEN tut.IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END AS nullable
  FROM       INFORMATION_SCHEMA.COLUMNS tut
  INNER JOIN baseTbl                    bt  ON bt.table_catalog = tut.TABLE_CATALOG AND bt.table_name = tut.table_name
)


, meta_for_keys
AS (
  SELECT schema_nm, table_nm
  , COALESCE(distribution_keys,'DISTRIBUTED RANDOMLY') :: CHARACTER VARYING(255) AS column_nm
  , 'DK' :: CHARACTER VARYING(10) AS is_key
  FROM 
  ( SELECT pgn.nspname AS schema_nm,
    pgc.relname AS table_nm, 
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

, col_descr
AS (
  SELECT schema_nm
  , REPLACE(table_nm, schema_nm || '.', '') AS table_nm
  , column_nm, column_descr
  FROM (
    SELECT 
      ns.nspname              AS schema_nm
    , (a.attrelid :: regclass) :: VARCHAR(150) AS table_nm
    , a.attname               AS column_nm
    , d.description           AS column_descr
    FROM      pg_catalog.pg_attribute   a
    LEFT JOIN pg_catalog.pg_class       c  ON a.attrelid = c.oid
    LEFT JOIN pg_catalog.pg_namespace   ns ON c.relnamespace = ns.oid
    LEFT JOIN pg_catalog.pg_description d  ON d.objoid = a.attrelid AND d.objsubid = a.attnum
    WHERE a.attnum > 0
      AND NOT a.attisdropped  
  ) t
  WHERE schema_nm = (SELECT v_SchemaName FROM vars) 
    AND REPLACE(table_nm, schema_nm || '.', '') IN(SELECT DISTINCT table_name FROM baseTbl)
)

, combined_data
AS (
  SELECT md.schema_nm
  , md.table_nm
  , md.obj_typ
  , md.ord_pos AS ord
  , COALESCE(dk.is_key, ' ')  AS is_key
  , md.column_nm
  , md.data_typ
  , md.nullable
  , cd.column_descr 
  FROM      metadata      md
  LEFT JOIN col_descr     cd ON cd.schema_nm = md.schema_nm AND cd.table_nm = md.table_nm AND cd.column_nm = md.column_nm
  LEFT JOIN meta_for_keys dk ON dk.schema_nm = md.schema_nm AND dk.table_nm = md.table_nm AND dk.column_nm = md.column_nm
)

SELECT *
FROM combined_data
ORDER BY schema_nm, table_nm, ord
