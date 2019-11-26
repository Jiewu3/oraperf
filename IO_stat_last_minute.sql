@inc/colors;
prompt &_C_YELLOW in io_stat_last_minute.sql &_C_RESET
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

select begin_time,
       n.wait_class, m.time_waited, m.wait_count, 10*m.time_waited/nullif(m.wait_count,0) avgms -- convert centisecs to ms
from   v$waitclassmetric  m,
       v$system_wait_class n
where m.wait_class_id=n.wait_class_id
  and n.wait_class in ('User I/O', 'System I/O')
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
/  

  
TTITLE OFF

CLEAR COLUMNS

@@oraPerf.sql