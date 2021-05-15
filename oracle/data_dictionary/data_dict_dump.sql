
------------------------------------------------------------------------------------
-- Data Dictionary Dump:  
-- This SQL script will dump table, column, and description design related metadata
-- so that you can copy-paste or export to Excel as a Data Dictionary.  
------------------------------------------------------------------------------------
-- Platform:          Oracle
-- Author:            DataResearchLabs
-- GitHub:            https://github.com/DataResearchLabs/sql_scripts
-- YouTube Tutorials: https://www.youtube.com/channel/UCQciXv3xaBykeUFc04GxSXA
----------------------------------------------------------------------------------

-- All variables are consolidated here in the first CTE (Common Table Expression)
-- Each given row is a variable, with the value you change preceding the "AS" command
WITH vars
AS (
  SELECT 
    'HR'   AS v_SchemaName  -- <<<<<<<<<<<< CHANGE THIS VALUE to Schema you want to dump
  , 'NO'   AS v_TablesOnly  -- YES=Limit To Tables only; NO=Include views too 
  FROM dual
)

, meta_data
AS (
	SELECT
	  atc.owner       AS SCHEMA_NM
	, atc.table_name  AS TABLE_NM
	, atc.column_id   AS ORD_POS
	, atc.column_name AS COLUMN_NM 
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
	  )                 AS DATA_TYP
	, CASE WHEN atc.nullable = 'Y' THEN 'NULL' ELSE 'NOT NULL' END AS NULLABLE
	, dcc.comments  AS DESCRIPTION
	FROM       all_tab_columns  atc
	INNER JOIN all_col_comments dcc ON atc.owner = dcc.owner AND atc.table_name = dcc.table_name AND atc.column_name = dcc.column_name
	INNER JOIN all_tab_comments t   ON t.OWNER = atc.owner   AND t.TABLE_NAME = atc.table_name
	WHERE atc.owner = (SELECT vars.v_SchemaName FROM vars)
	  AND (    (t.TABLE_TYPE = 'TABLE')
	       OR  ((SELECT v_TablesOnly FROM vars) = 'NO')  
	      )
)


, meta_for_keys
AS (
	SELECT SCHEMA_NM, TABLE_NM, COLUMN_NM
	, LISTAGG(IS_KEY, ', ') 
	  WITHIN GROUP(ORDER BY IS_KEY DESC) AS IS_KEY
	FROM (
	  SELECT cons.owner    AS SCHEMA_NM
	  , cols.table_name    AS TABLE_NM
	  , cols.column_name   AS COLUMN_NM
	  , CASE WHEN cons.constraint_type = 'P' THEN 'PK'
	         WHEN cons.constraint_type = 'U' THEN 'UK'
	         WHEN cons.constraint_type = 'R' THEN 'FK'
	    END                AS IS_KEY
	  FROM all_constraints cons 
	    INNER JOIN all_cons_columns cols ON cons.constraint_name = cols.constraint_name AND cons.owner = cols.owner 
	  WHERE cons.owner = (SELECT vars.v_SchemaName FROM vars)
	    AND cons.table_name IN(SELECT DISTINCT TABLE_NM FROM meta_data)
	    AND cons.constraint_type IN('P','R','U') 
	  GROUP BY cons.owner, cols.table_name, cols.column_name, cons.constraint_type
   ) t
   GROUP BY SCHEMA_NM, TABLE_NM, COLUMN_NM
)


SELECT md.SCHEMA_NM, md.TABLE_NM
, COALESCE(pk.IS_KEY, ' ') AS KEYS
, md.ORD_POS AS ORD
, md.COLUMN_NM, md.DATA_TYP, md.NULLABLE, md.DESCRIPTION
FROM      meta_data     md
LEFT JOIN meta_for_keys pk ON pk.SCHEMA_NM = md.SCHEMA_NM AND pk.TABLE_NM = md.TABLE_NM AND pk.COLUMN_NM = md.COLUMN_NM
ORDER BY md.SCHEMA_NM, md.TABLE_NM, md.ORD_POS

