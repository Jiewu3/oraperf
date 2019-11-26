SET LINESIZE 300
SET TERMOUT OFF
col cpu_count for a8

COLUMN global_name NEW_VALUE global_name
COLUMN day NEW_VALUE day

SELECT global_name, to_char(sysdate,'yyyy-mm-dd') AS day
FROM global_name;

TTITLE 'cpu_wait_last_minute.sql' SKIP 1 '&global_name / &day' SKIP 2

SET TERMOUT ON

with CPU_WAIT_STAT as (select begin_time,
    intsize_csec/100 AS duration,
    decode(n.wait_class,'User I/O','User I/O',
                        'System I/O','System I/O',
                        'Commit','Commit',
                        'Application','Application',
                        'Configuration','Configuration',
                        'Administrative','Administrative',
                        'Concurrency','Concurrency',
                        'Cluster','Cluster',
                        'Scheduler','Scheduler',
                        'Network','Network',
                        'Other', 'other') metric_name,
    sum(round(m.time_waited/m.INTSIZE_CSEC,3)) VALUE
from  v$waitclassmetric  m,
      v$system_wait_class n
where m.wait_class_id=n.wait_class_id
    and n.wait_class != 'Idle'
group by  decode(n.wait_class,'User I/O','User I/O', 
                        'System I/O','System I/O',
                        'Commit','Commit', 
                        'Application','Application',
                        'Configuration','Configuration',
                        'Administrative','Administrative',
                        'Concurrency','Concurrency',
                        'Cluster','Cluster',
                        'Scheduler','Scheduler',
                        'Network','Network',
                        'Other', 'other'), BEGIN_TIME, intsize_csec
union 
SELECT begin_time, 
    intsize_csec/100 AS duration,
    metric_name , value
  FROM v$metric   -- statistic values of the last hour captured by AWR infrastructure
  WHERE group_id = (SELECT group_id FROM v$metricgroup WHERE name = 'System Metrics Long Duration')
  AND metric_name IN ('Host CPU Usage Per Sec', 
                      'CPU Usage Per Sec', 
                      'Background CPU Usage Per Sec',
                      'Current OS Load')
)
SELECT begin_time, 
         duration,
         (SELECT value FROM v$osstat WHERE stat_name = 'NUM_CPUS') AS num_cpus,
         (SELECT value FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES') AS num_cpu_cores,
         (select value from v$parameter where name='cpu_count' ) AS cpu_count,
         sum(case when metric_name = 'Host CPU Usage Per Sec' then value/100 else 0 end) AS host_cpu, 
         sum(case when metric_name = 'CPU Usage Per Sec' then value/100 else 0 end) AS db_fg_cpu, 
         sum(case when metric_name = 'Background CPU Usage Per Sec' then value/100 else 0 end) AS db_bg_cpu,
         sum(case when metric_name = 'Current OS Load' then value else 0 end) AS os_load,
         sum(case when metric_name = 'User I/O' then value else 0 end) AS User_IO,
         sum(case when metric_name = 'System I/O' then value else 0 end) AS System_IO,
         sum(case when metric_name = 'Application' then value else 0 end) AS Application,
         sum(case when metric_name = 'Commit' then value else 0 end) AS Commit,
         sum(case when metric_name = 'Configuration' then value else 0 end) AS Configuration,
         sum(case when metric_name = 'Administrative' then value else 0 end) AS Administrative,
         sum(case when metric_name = 'Concurrency' then value else 0 end) AS Concurrency,
         sum(case when metric_name = 'Cluster' then value else 0 end) AS "Cluster",
         sum(case when metric_name = 'Scheduler' then value else 0 end) AS Scheduler,
         sum(case when metric_name = 'Network' then value else 0 end) AS Network,
         sum(case when metric_name = 'Other' then value else 0 end) AS Other
FROM CPU_WAIT_STAT   
group by begin_time, duration;

TTITLE OFF

CLEAR COLUMNS

@@oraPerf.sql