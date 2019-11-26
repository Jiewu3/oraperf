@inc/input_vars_init;
 
REM ############### COMMON FORMATTING #######################

-----------------------------------------
--    params check:

accept _sqlid prompt "&_C_RED Enter sql_id: &_C_RESET"
accept _chn prompt "&_C_RED Enter child number[0]: &_C_RESET" default 0
col _child new_val _child noprint
set termout off timing off
set linesize 999
select
   case
      when translate('&_chn','x0123456789','x') is null 
         then nvl('&_chn','%')
      else '%'
   end "_CHILD"
from dual;
-----------------------------------------
set termout on
 
prompt &_C_MAGENTA ###############################################################################################&_C_RESET
prompt &_C_MAGENTA ###   Show SQL text, child cursors and execution stats for SQL_ID &_C_RED &_sqlid child &_chn &_C_RESET
prompt &_C_MAGENTA ###############################################################################################&_C_RESET

prompt 
prompt &_C_MAGENTA ################### SHOW SQL TEXT ###########################&_C_RESET
@sql_textf &_sqlid
 
prompt &_C_MAGENTA ################## SHOW  V$SQL ##############################&_C_RESET
col proc_name           for a30
col P_schema            for a20
set pagesize 9999 
select
    s.sql_id
   ,s.CHILD_NUMBER                                                      sql_child_number
   ,s.address                                                           parent_handle
   ,s.child_address                                                     object_handle
   ,s.PLAN_HASH_VALUE                                                   plan_hv
   ,s.hash_value                                                        hv
   ,s.SQL_PROFILE                                                       sql_profile
   ,decode(s.EXECUTIONS,0,0, s.ELAPSED_TIME/1e6/s.EXECUTIONS)           elaexe
   ,s.EXECUTIONS                                                        cnt
   ,s.FETCHES                                                           fetches
   ,s.END_OF_FETCH_COUNT                                                end_of_fetch_count
   ,s.FIRST_LOAD_TIME                                                   first_load_time
   ,s.PARSE_CALLS                                                       parse_calls
   ,decode(s.executions,0,0, s.DISK_READS    /s.executions)             disk_reads
   ,decode(s.executions,0,0, s.BUFFER_GETS   /s.executions)             buffer_gets
   ,decode(s.executions,0,0, s.DIRECT_WRITES /s.executions)             direct_writes
   ,decode(s.executions,0,0, s.APPLICATION_WAIT_TIME/1e6/s.executions)  app_wait
   ,decode(s.executions,0,0, s.CONCURRENCY_WAIT_TIME/1e6/s.executions)  concurrency
   ,decode(s.executions,0,0, s.USER_IO_WAIT_TIME    /1e6/s.executions)  io_wait
   ,decode(s.executions,0,0, s.PLSQL_EXEC_TIME      /1e6/s.executions)  plsql_t
   ,decode(s.executions,0,0, s.java_exec_time       /1e6/s.executions)  java_exec_t
   ,s.ROWS_PROCESSED                                                    row_processed
   ,s.OPTIMIZER_MODE                                                    opt_mode
   ,s.OPTIMIZER_COST                                                    cost
   ,s.OPTIMIZER_ENV_HASH_VALUE                                          env_hash
   ,s.PARSING_SCHEMA_NAME                                               P_schema
   ,decode(s.executions,0,0, s.CPU_TIME/1e6/s.executions)               CPU_TIME
   ,s.PROGRAM_ID
   ,(select object_name from dba_objects o where o.object_id=s.PROGRAM_ID) proc_name
   ,s.PROGRAM_LINE#                                                        proc_line
from v$sql s
where
    sql_id = ('&_sqlid')
and child_number like '&_child'
order by
    sql_id,
    hash_value,
    child_number
/
REM ##################### END V$SQL ##############################
 
prompt &_C_MAGENTA ################### PLSQL OBJECT ##############################&_C_RESET
col owner           for a15
col object_name     for a30
col text            for a120
 
select
   a.SQL_ID,a.SQL_PROFILE
  ,p.owner,p.object_name
  ,s.line
  ,rtrim(rtrim(s.text,chr(10)),chr(32)) text
from
    v$sqlarea a
    left join dba_procedures p
              on a.PROGRAM_ID=p.OBJECT_ID
    left join dba_source s
              on p.owner=s.owner
              and p.OBJECT_NAME=s.name
              and s.line between a.PROGRAM_LINE#-5 and a.PROGRAM_LINE#+5
where a.SQL_ID='&_sqlid'
/
REM ################### EXECUTIONS IN SQL_MONITOR ######################
prompt &_C_MAGENTA ################### EXECUTIONS IN SQL_MONITOR ######################&_C_RESET
-- @if.sql "'&_O_RELEASE'>'11.2'" then
@if.sql "'&_O_RELEASE'>'11.2'"
   col error_message       for a40
--   @rtsm/execs "&_sqlid" "&_child"
   @rtsm/execs "&_sqlid"
/* end if */
REM ###########################   clearing ############################
col SQL_PROFILE     clear
col owner           clear
col object_name     clear
col text            clear
-- col error_message   clear
@inc/input_vars_undef;

@rtdiag_2.sql