set termout on
accept startt prompt 'Enter start time [ DD-MM-YYYY HH24:MI ]: '
accept endt prompt 'Enter end time [ DD-MM-YYYY HH24:MI ]: '

col SAMPLE_TIME for a30
col SQL_PLAN_OPERATION for a20

PROMPT
PROMPT &_C_YELLOW Diaplay sql_id of high TEMP usage &_C_RESET
PROMPT &_C_YELLOW Note: using gv$active_session_history union DBA_HIST_ACTIVE_SESS_HISTORY &_C_RESET
PROMPT &_C_YELLOW display_sqlis_high_TEMP.sql &_C_RESET

with temp_hash as (
SELECT instance_number inst_id, session_id, sql_exec_id,
sql_id,
sql_plan_hash_value,
sql_plan_operation,
sql_plan_line_id,
temp_space_allocated,
sample_time
FROM   dba_hist_active_sess_history
WHERE  dbid = (SELECT dbid FROM   v$database)
AND sample_time BETWEEN To_date('21-MAY-2019 09:00', 'dd-mon-yyyy hh24:mi')
                                  AND To_date('21-MAY-2019 15:00', 'dd-mon-yyyy hh24:mi')
union
SELECT inst_id, session_id, sql_exec_id,
sql_id,
sql_plan_hash_value,
sql_plan_operation,
sql_plan_line_id,
temp_space_allocated,
sample_time
FROM   gv$active_session_history
WHERE  sample_time BETWEEN To_date('&startt', 'dd-mm-yyyy hh24:mi')
                                  AND To_date('&endt', 'dd-mm-yyyy hh24:mi')
)
SELECT *
FROM   (SELECT Rank() over (ORDER BY SUM(Nvl(temp_space_delta, 0)) DESC) position,
               inst_id, sample_time, sql_id,
               sql_plan_hash_value,
               sql_plan_operation,
               sql_plan_line_id,
               Count(DISTINCT sql_exec_id) total_execs,
               Trunc(SUM(Nvl(temp_space_delta, 0))/1024/1024)||'m' temp_usage
        FROM   (SELECT inst_id, sample_time, sql_exec_id,
                       sql_id,
                       sql_plan_hash_value,
                       sql_plan_operation,
                       sql_plan_line_id,
                       temp_space_allocated - Nvl(Lag(temp_space_allocated, 1)
                       over (
                         PARTITION BY inst_id, sql_exec_id, sql_id, session_id
                         ORDER BY sample_time), 0)
                       temp_space_delta
                FROM   temp_hash)
        GROUP  BY inst_id, sample_time, sql_id,
                  sql_plan_operation,
                  sql_plan_hash_value,
                  sql_plan_line_id)
WHERE  position <= 20
--where sql_id='8s3t6gprzb68y'
ORDER  BY position;

@@oraPerf
