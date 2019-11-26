prompt &_C_YELLOW in io_stat_last_hour.sql &_C_RESET
SET LINESIZE 300
SET TERMOUT OFF
col wait_class for a16

COLUMN global_name NEW_VALUE global_name
COLUMN day NEW_VALUE day

SELECT global_name, to_char(sysdate,'yyyy-mm-dd') AS day
FROM global_name
/

TTITLE '&global_name / &day' SKIP 2


SET TERMOUT ON
break on begin_time
select begin_time,
       n.wait_class, m.time_waited, m.wait_count, 10*m.time_waited/nullif(m.wait_count,0) avgms -- convert centisecs to ms
from   v$waitclassmetric_history  m,
       v$system_wait_class n
where m.wait_class_id=n.wait_class_id
  and n.wait_class in ('User I/O', 'System I/O')
order by begin_time
/
  
col name for a25


select begin_time, m.intsize_csec,
       n.name ,
       round(m.time_waited,3) time_waited,
       m.wait_count,
       round(10*m.time_waited/nullif(m.wait_count,0),3) avgms
from v$eventmetric m,
     v$event_name n
where m.event_id=n.event_id
  and n.name in (
                  'db file parallel write',
                  'db file sequential read',
                  'db file scattered read',
                  'direct path read',
                  'direct path read temp',
                  'direct path write',
                  'direct path write temp',
                  'log file sync',
                  'log file parallel write'
)
order by begin_time
/  


select
       begin_time,
       event_name,
       round((time_ms_end-time_ms_beg)/nullif(count_end-count_beg,0),3) avg_ms
from (
select
       to_char(s.BEGIN_INTERVAL_TIME,'DD-MON-YY HH24:MI')  begin_time,
       event_name,
       total_waits count_end,
       time_waited_micro/1000 time_ms_end,
       Lag (e.time_waited_micro/1000)
              OVER( PARTITION BY e.event_name ORDER BY s.snap_id) time_ms_beg,
       Lag (e.total_waits)
              OVER( PARTITION BY e.event_name ORDER BY s.snap_id) count_beg
from
       DBA_HIST_SYSTEM_EVENT e,
       DBA_HIST_SNAPSHOT s
where
         s.snap_id=e.snap_id
         and s.begin_interval_time>sysdate-1/12
   and e.event_name in (
                  'db file parallel write',
                  'db file sequential read',
                  'db file scattered read',
                  'direct path read',
                  'direct path read temp',
                  'direct path write',
                  'direct path write temp',
                  'log file sync',
                  'log file parallel write')
order by begin_interval_time
)
order by begin_time
/
  
TTITLE OFF

CLEAR COLUMNS

@@oraPerf.sql