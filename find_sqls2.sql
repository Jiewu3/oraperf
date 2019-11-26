SET TERMOUT ON LINESIZE 300 pages 999 SCAN ON VERIFY OFF FEEDBACK OFF

PROMPT Find SQL and report whether it was Offloaded and I/O saved.
accept _sql_id PROMPT "&_C_RED Enter sql_id(defaul blank): &_C_RESET" 
accept _sql_text PROMPT "&_C_RED Enter sql_text search pattern: &_C_RESET"

set pagesize 999
set lines 190
col sql_text format a70 trunc
col child format 99999
col execs format 9,999
col avg_etime format 99,999.99
col "IO_SAVED_%" format 999.99
col avg_px format 999
col offload for a7

select sql_id, child_number child, plan_hash_value plan_hash, executions execs, 
(elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions)/
decode(px_servers_executions,0,1,px_servers_executions/decode(nvl(executions,0),0,1,executions)) avg_etime, 
px_servers_executions/decode(nvl(executions,0),0,1,executions) avg_px,
decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES,0,'No','Yes') Offload,
decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES,0,0,100*(IO_CELL_OFFLOAD_ELIGIBLE_BYTES-IO_INTERCONNECT_BYTES)
/decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES,0,1,IO_CELL_OFFLOAD_ELIGIBLE_BYTES)) "IO_SAVED_%",
sql_text, to_char(LAST_ACTIVE_TIME,'dd-mon-yy HH24:MI') last_active_time
from v$sql s
where upper(sql_text) like upper(nvl(q'[&_sql_text]',sql_text))
and sql_text not like 'BEGIN :sql_text := %'
and sql_text not like '%IO_CELL_OFFLOAD_ELIGIBLE_BYTES%'
and sql_text not like '/* SQL Analyze(%'
and sql_id like CASE WHEN '&&_sql_id' = 'last' THEN 
  (select prev_sql_id from v$session where sid = (SELECT sid FROM v$mystat WHERE rownum=1))
ELSE
  nvl('&&_sql_id',sql_id)
END
order by 1, 2, 3;

undefine _sql_id
undefine _sql_text

@@oraPerf.sql