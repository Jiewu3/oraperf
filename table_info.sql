COLUMN owner             format a20 wrap           heading "Table|Owner"
COLUMN table_name        format a20 wrap           heading "Table|Name"
COLUMN column_name       format a30 wrap           heading "Column|Name"
COLUMN Tablespace_name   format a20 wrap           heading "Tablespace|Name"
COLUMN num_rows          format 9,999,999          Heading "Numer|Of|Rows"
COLUMN blocks            format 9,999,999          Heading "Numer|Of|Blocks"
COLUMN empty_blocks      format 9,999,999          Heading "Numer|Of|Empty|Blocks"
COLUMN avg_row_len       format 9,999,999          Heading "Average|Row|Length"
COLUMN sample_size       format 999,999,999        Heading "Sample|Size"
COLUMN last_analyzed     heading "Date|Last|Analyzed"

SET PAGES 9999 LINES 200 VERIFY OFF FEEDBACK OFF

PROMPT
PROMPT &_C_YELLOW.######################################## &_C_RESET
PROMPT &_C_YELLOW.######################################## &_C_RESET
accept _OWNER_NAME prompt "Owner name : "
accept _TABLE_NAME prompt "Table name : "

SELECT   owner, table_name, tablespace_name, num_rows, blocks, empty_blocks,
         avg_row_len, sample_size, last_analyzed
    FROM dba_tables
   WHERE owner LIKE UPPER ('&_OWNER_NAME')
     AND table_name LIKE UPPER ('&_TABLE_NAME')
ORDER BY owner, table_name;

SELECT
    index_name, column_name, column_position
FROM DBA_IND_COLUMNS
WHERE
    INDEX_OWNER = '&_OWNER_NAME'
    AND TABLE_NAME = '&_TABLE_NAME'
ORDER BY
    table_name,
    index_name,
    column_position
    ;
    
select  column_name, num_buckets, histogram
from    dba_tab_columns
where   owner LIKE UPPER ('&_OWNER_NAME')
AND table_name LIKE UPPER ('&_TABLE_NAME') 
and histogram<>'NONE'
order by column_name
;

PROMPT &_C_YELLOW.######################################## &_C_RESET
accept _COLUMN_NAME prompt "Column name : "

SELECT endpoint_number,
       chr(to_number(SUBSTR(hex_values, 2,2),'XX'))
        || chr(to_number(SUBSTR(hex_values, 4,2),'XX'))
        || chr(to_number(SUBSTR(hex_values, 6,2),'XX'))
        || chr(to_number(SUBSTR(hex_values, 8,2),'XX'))
        || chr(to_number(SUBSTR(hex_values,10,2),'XX'))
        || chr(to_number(SUBSTR(hex_values,12,2),'XX'))
        || chr(to_number(SUBSTR(hex_values,14,2),'XX'))
        || chr(to_number(SUBSTR(hex_values,16,2),'XX'))
        || chr(to_number(SUBSTR(hex_values,18,2),'XX'))
        || chr(to_number(SUBSTR(hex_values,20,2),'XX'))
        || chr(to_number(SUBSTR(hex_values,22,2),'XX'))
        || chr(to_number(SUBSTR(hex_values,24,2),'XX')) as COLUMN_VALUE,
       endpoint_number - NVL (prev_endpoint, 0) frequency     
  FROM (SELECT endpoint_number,
               NVL (LAG (endpoint_number, 1) OVER (ORDER BY endpoint_number),0) prev_endpoint,
               TO_CHAR(endpoint_value,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')hex_values
          FROM dba_tab_histograms
         WHERE owner= UPPER ('&_OWNER_NAME')
                AND table_name= UPPER ('&_TABLE_NAME') 
                AND column_name=UPPER('&_COLUMN_NAME')
)
ORDER BY endpoint_number;

UNDEFINE _OWNER_NAME
UNDEFINE _TABLE_NAME
UNDEFINE _COLUMN_NAME

CLEAR COLUMNS

@@oraPerf.sql