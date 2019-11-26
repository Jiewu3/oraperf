set feedback off echo off verify off 
PROMPT
accept _inst_id PROMPT "&_C_RED Enter instance id: &_C_RESET" 
accept _sql_id PROMPT "&_C_RED Enter sql_id: &_C_RESET" 
accept _sql_exec_id default null PROMPT "&_C_RED Enter sql_exec_id [default null]: &_C_RESET"
accept _level default 'ALL' PROMPT "&_C_RED Enter report level [BASIC, TYPICAL, or ALL(default)]: &_C_RESET" 

set lines 1000
set pages 0
SET LONG 1000000
SET longchunksize 1000000
set termout off
spool sql_monitor_report_active.html
SELECT dbms_sqltune.report_sql_monitor(inst_id => &_inst_id, sql_id=>'&_sql_id',sql_exec_id=>&_sql_exec_id,type=>'ACTIVE', report_level=>'&_level') AS report FROM dual;

spool off
-- SQL> SELECT sql_exec_start, sql_id, status, sql_text from v$sql_monitor where username='LETTERS_GEN' and sql_text like '%ROWNO%' order by sql_exec_start desc;

--SQL_EXEC_START	     SQL_ID	   STATUS	       SQL_TEXT
-------------------- ------------- ------------------- -----------------------------------------
--18-JUN-2014 19:11:15 arcuk4z51n6z4 EXECUTING	       SELECT	Z.ROWNO,
--18-JUN-2014 19:05:50 bg7yfhxqv0mk8 DONE (ALL ROWS)     SELECT	Z.ROWNO,
--18-JUN-2014 19:04:54 bg7yfhxqv0mk8 DONE (ALL ROWS)
--18-JUN-2014 18:49:45 gyt0ftw2nszqa DONE (ALL ROWS)     SELECT	Z.ROWNO,

undef _sql_id
undef _sql_exec_id
undef _level
set termout on
@@oraPerf.sql
