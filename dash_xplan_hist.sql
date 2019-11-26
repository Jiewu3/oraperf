set termout on
alter session set nls_date_format='DD-MM-YY HH24:MI:SS';

accept _sql_id prompt 'Enter sql_id: '
accept startt prompt 'Enter start time [ DD-MM-YY HH24:MI ]: '
accept endt prompt 'Enter end time [ DD-MM-YY HH24:MI ]: '

PROMPT
PROMPT &_C_YELLOW Diaplay execution plan history for sql_id &_C_RESET
PROMPT &_C_YELLOW Note: also include exec plan from v$ash in the last hour &_C_RESET
PROMPT &_C_YELLOW display_dash_execution_plan.sql &_C_RESET

col av for 9999999
col mx for 9999999
col mn for 9999999
break on instance_number skip 1
 
SELECT
        sql_id,
        instance_number,
        sql_exec_id,
		sql_plan_hash_value,
--  start_time,
		sql_exec_start,
        MAX(delta_in_seconds) elapsed_time
FROM ( SELECT
              sql_id,
              instance_number,
              sql_exec_id,
			  sql_plan_hash_value,
--            CAST(sample_time AS DATE)     end_time,-- sample time 10 secs increments
--            CAST(sql_exec_start AS DATE)  start_time,
			  sample_time, sql_exec_start,
              ((CAST(sample_time    AS DATE)) -
               (CAST(sql_exec_start AS DATE))) * (3600*24) delta_in_seconds
           FROM
              dba_hist_active_sess_history
           WHERE sql_id='&_sql_id'
		   and sample_time between to_date ('&startt','DD-MM-YY HH24:MI') and to_date ('&endt','DD-MM-YY HH24:MI')
        union
		SELECT
              sql_id,
              inst_id as instance_number,
              sql_exec_id,
			  sql_plan_hash_value,
--            CAST(sample_time AS DATE)     end_time,-- sample time 10 secs increments
--            CAST(sql_exec_start AS DATE)  start_time,
			  sample_time, sql_exec_start,
              ((CAST(sample_time    AS DATE)) -
               (CAST(sql_exec_start AS DATE))) * (3600*24) delta_in_seconds
           FROM
              gv$active_session_history
           WHERE sql_id='&_sql_id'
		   and sample_time > (select max(sample_time) - interval '1' hour from gv$active_session_history)
        )
--OUP BY sql_id,sql_exec_id,sql_plan_hash_value,start_time
GROUP BY sql_id,instance_number,sql_exec_id,sql_plan_hash_value,sql_exec_start
order by instance_number,sql_exec_start
/

undef startt
undef endt


@@oraPerf

