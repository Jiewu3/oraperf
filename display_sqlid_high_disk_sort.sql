set termout off
alter session set nls_date_format='DD-MM-YY HH24:MI:SS';
set termout on

accept startt prompt 'Enter start time [ DD-MM-YYYY HH24:MI ]: '
accept endt prompt 'Enter end time [ DD-MM-YYYY HH24:MI ]: '

PROMPT
PROMPT &_C_YELLOW Diaplay sql_id of high disk sort &_C_RESET
PROMPT &_C_YELLOW Note: using gv$active_session_history &_C_RESET
PROMPT &_C_YELLOW display_sqlis_high_disk_sort.sql &_C_RESET

COLUMN module format A20
COLUMN sql_opname format A20
COLUMN etime_secs FORMAT 999,999.9
COLUMN etime_mins FORMAT 999,999.9
COLUMN user_id FORMAT 999999
COLUMN sid FORMAT 99999
COLUMN serial# FORMAT 99999
COLUMN username FORMAT A25
COLUMN inst_id FORMAT 99
COLUMN sql_opname FORMAT A10
COLUMN sql_id FORMAT A13
COLUMN sql_exec_id FORMAT 9999999999
COLUMN max_temp_mb FORMAT 999,999,999
COLUMN sql_start_time FORMAT A26
COLUMN sql_end_time FORMAT A26
 
 
SELECT ASH.inst_id,
  ASH.user_id,
  ASH.session_id sid,
  ASH.session_serial# serial#,
  ASH.sql_id,
  ASH.sql_exec_id,
  ASH.sql_opname,
  ASH.module,
  MIN(sample_time) sql_start_time,
  MAX(sample_time) sql_end_time,
  ((CAST(MAX(sample_time) AS DATE)) - (CAST(MIN(sample_time) AS DATE))) * (3600*24) etime_secs ,
  ((CAST(MAX(sample_time) AS DATE)) - (CAST(MIN(sample_time) AS DATE))) * (60*24) etime_mins ,
  MAX(temp_space_allocated)/(1024*1024) max_temp_mb
FROM gv$active_session_history ASH
WHERE ASH.session_type = 'FOREGROUND'
AND ASH.sql_id        IS NOT NULL
AND sample_time BETWEEN to_timestamp('&startt', 'DD-MM-YYYY HH24:MI') AND to_timestamp('&endt', 'DD-MM-YYYY HH24:MI')
  --and  ASH.sql_id = SQL_ID
GROUP BY ASH.inst_id,
  ASH.user_id,
  ASH.session_id,
  ASH.session_serial#,
  ASH.sql_id,
  ASH.sql_opname,
  ASH.sql_exec_id,
  ASH.module
HAVING MAX(temp_space_allocated)/(1024*1024) > 128
--order by max_temp_mb desc
union
SELECT HASH.instance_number,
  HASH.user_id,
  HASH.session_id sid,
  HASH.session_serial# serial#,
  HASH.sql_id,
  HASH.sql_exec_id,
  HASH.sql_opname,
  HASH.module,
  MIN(sample_time) sql_start_time,
  MAX(sample_time) sql_end_time,
  ((CAST(MAX(sample_time) AS DATE)) - (CAST(MIN(sample_time) AS DATE))) * (3600*24) etime_secs ,
  ((CAST(MAX(sample_time) AS DATE)) - (CAST(MIN(sample_time) AS DATE))) * (60*24) etime_mins ,
  MAX(temp_space_allocated)/(1024*1024) max_temp_mb
FROM dba_hist_active_sess_history HASH
WHERE HASH.session_type = 'FOREGROUND'
AND HASH.sql_id        IS NOT NULL
AND sample_time BETWEEN to_timestamp('&startt', 'DD-MM-YYYY HH24:MI') AND to_timestamp('&endt', 'DD-MM-YYYY HH24:MI')
  --and  ASH.sql_id = SQL_ID
GROUP BY HASH.instance_number,
  HASH.user_id,
  HASH.session_id,
  HASH.session_serial#,
  HASH.sql_id,
  HASH.sql_opname,
  HASH.sql_exec_id,
  HASH.module
HAVING MAX(temp_space_allocated)/(1024*1024) > 128
order by max_temp_mb desc
;

undef startt
undef endt7


@@oraPerf