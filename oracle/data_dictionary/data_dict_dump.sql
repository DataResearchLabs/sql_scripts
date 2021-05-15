
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


SELECT
  atc.owner       AS SCHEMA_NM
, atc.table_name  AS TBL_NM
, atc.column_id   AS COL_ORD_POS
, atc.column_name AS COL_NM
, (atc.data_type ||
    decode(atc.data_type,
      'NUMBER',
         /* scale is not null or both scale and precision are null */
         decode(atc.data_precision, null, '',
          '(' || to_char(atc.data_precision) || decode(atc.data_scale,null,'',0,'',',' || to_char(atc.data_scale) )
              || ')' ),
      'FLOAT', '(' || to_char(atc.data_precision) || ')',
         /* Float: Scale is Null & Precision is not Null */
      'VARCHAR2', '(' || to_char(atc.data_length) || ')',
      'NVARCHAR2', '(' || to_char(atc.data_length) || ')',
      'VARCHAR', '(' || to_char(atc.data_length) || ')',
      'CHAR', '(' || to_char(atc.data_length) || ')',
      'RAW', '(' || to_char(atc.data_length) || ')',
      'MLSLABEL',decode(atc.data_length,null,'',0,'','(' || to_char(atc.data_length) || ')'),
      '')
  )                 AS COL_DATA_TYP
, atc.nullable      AS COL_IS_NULLABLE
, atc.data_default  AS COL_DFLT_VAL
, dcc.comments      AS COL_DESCRIP
FROM       all_tab_columns  atc
INNER JOIN all_col_comments dcc ON atc.owner = dcc.owner AND atc.table_name = dcc.table_name AND atc.column_name = dcc.column_name
INNER JOIN all_tab_comments t   ON t.OWNER = atc.owner   AND t.TABLE_NAME = atc.table_name
WHERE atc.owner = (SELECT vars.v_SchemaName FROM vars)
  AND (    (t.TABLE_TYPE = 'TABLE')
       OR  ((SELECT v_TablesOnly FROM vars) = 'NO')  
      )
ORDER BY atc.owner, atc.table_name, atc.column_id
