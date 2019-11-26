set termout off
alter session set nls_date_format='DD-MM-YY HH24MI';
set termout on

column sample_time for a32
column sum_max_mb format 999,999,999;
column temporary_tablespace format A20
WITH
pivot1 AS
(
SELECT
trunc(ash.sample_time,'HH') sample_time,
ash.SESSION_ID,
ash.SESSION_SERIAL#,
ash.SQL_ID,
ash.sql_exec_id,
U.temporary_tablespace,
max(temp_space_allocated)/(1024*1024) max_temp_mb
FROM  GV$ACTIVE_SESSION_HISTORY ash, dba_users U
WHERE
ash.user_id = U.user_id
and ash.session_type = 'FOREGROUND'
and ash.temp_space_allocated > 0
GROUP BY
trunc(ash.sample_time,'HH'),
ash.SESSION_ID,
ash.SESSION_SERIAL#,
ash.SQL_ID,
ash.sql_exec_id,
U.temporary_tablespace
union
SELECT
trunc(hash.sample_time,'HH') sample_time,
hash.SESSION_ID,
hash.SESSION_SERIAL#,
hash.SQL_ID,
hash.sql_exec_id,
U.temporary_tablespace,
max(temp_space_allocated)/(1024*1024) max_temp_mb
FROM  DBA_HIST_ACTIVE_SESS_HISTORY hash, dba_users U
WHERE
hash.user_id = U.user_id
and hash.session_type = 'FOREGROUND'
and hash.temp_space_allocated > 0
GROUP BY
trunc(hash.sample_time,'HH'),
hash.SESSION_ID,
hash.SESSION_SERIAL#,
hash.SQL_ID,
hash.sql_exec_id,
U.temporary_tablespace
)
SELECT  temporary_tablespace, sample_time, sum(max_temp_mb) sum_max_mb
from pivot1
GROUP BY sample_time, temporary_tablespace
ORDER BY temporary_tablespace, sample_time;

undef startt
undef endt


@@oraPerf