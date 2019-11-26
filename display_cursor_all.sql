set feedback off echo off verify off
PROMPT

accept _sql_id PROMPT "&_C_RED Enter sql_id: &_C_RESET" 

set lines 600
set pages 9999
SET LONG 999999
SET longchunksize 900

SELECT * FROM TABLE(DBMS_XPLAN.display_cursor(sql_id=>'&_sql_id', cursor_child_no=>NULL, format=>'ALLSTATS LAST +cost +bytes +peeked_binds +outline')); 

undef _sql_id


@@oraPerf.sql
