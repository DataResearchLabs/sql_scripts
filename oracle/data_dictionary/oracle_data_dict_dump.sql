select
  atc.owner TAB_OWNER,
  atc.table_name TAB_NAME,
  atc.column_id,
  atc.column_name,
  (atc.data_type ||
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
  ) full_data_type,
  /*  data_type, data_length, data_precision, data_scale,  */
  atc.nullable, atc.data_default, dcc.comments
from
  all_tab_columns atc,
  all_col_comments dcc,
  all_tab_comments t
where
  atc.owner = 'SCHEMA'  -- <<<<<<<<<< Change here
--and atc.table_name IN('aaa','bbb','ccc')
  and atc.owner = dcc.owner
  and atc.table_name = dcc.table_name
  and atc.column_name = dcc.column_name
  and t.OWNER = atc.owner
  and t.TABLE_NAME = atc.table_name
  and t.TABLE_TYPE = 'TABLE'
order by
  atc.owner, atc.table_name, atc.column_id
