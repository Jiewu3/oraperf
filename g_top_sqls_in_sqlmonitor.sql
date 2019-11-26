col status for a20
col username for a15
col sid for 999999
col serial# for 999999
col sql_id for a15
col sql_text for a30 wrap
col sqltext for a30 wrap
col sql_exec_id for 999999999999
col sql_exec_start for a21
col elapsed_sec for 999999,999
col CPU_sec for 999999999
col buffer_gets for 999999999
col phys_reads_MB for 999999999
col phys_writes_MB for 999999999

col percent head '%' for 99990.99
col star for A10 head ''
break on inst_id skip 1
PROMPT
PROMPT &_C_YELLOW.######################################## &_C_RESET
PROMPT  &_C_YELLOW.Top 40 sql in gv$sql_monitor &_C_RESET
PROMPT &_C_YELLOW.######################################## &_C_RESET
SELECT inst_id, status, username, sid, serial#, sql_id, sql_exec_id, sqltext, sql_exec_start, elapsed_sec, CPU_sec, buffer_gets, phys_reads_MB, Phys_writes_MB
FROM
       (SELECT inst_id,
         status,
         username,
		 sid,
		 session_serial# AS serial#,
         sql_id,
         sql_exec_id,
		 substr(sql_text,0, 120) AS sqltext,
         TO_CHAR(sql_exec_start,'dd-mon-yyyy hh24:mi:ss') AS sql_exec_start,
         ROUND(elapsed_time/1000000) AS elapsed_sec,
         ROUND(cpu_time    /1000000) AS CPU_sec,
         buffer_gets,
         ROUND(physical_read_bytes /(1024*1024)) AS phys_reads_MB,
         ROUND(physical_write_bytes/(1024*1024)) AS Phys_writes_MB,
         ROW_NUMBER() over (partition by inst_id order by elapsed_time desc) rnk
       FROM gv$sql_monitor
       ORDER BY inst_id, elapsed_time DESC
       )
WHERE rnk<=20;

PROMPT
PROMPT &_C_YELLOW.######################################## &_C_RESET
PROMPT  &_C_YELLOW.Top pga usage &_C_RESET 
PROMPT &_C_YELLOW.######################################## &_C_RESET
accept _minutes prompt "Last minutess [5] : " default 5;
accept _top prompt "Top  Rows    [10] : " default 10;

select SQL_ID,round(PGA_MB,1) PGA_MB,percent,rpad('*',percent*10/100,'*') star
from
(
select SQL_ID,sum(DELTA_PGA_MB) PGA_MB ,(ratio_to_report(sum(DELTA_PGA_MB)) over ())*100 percent,rank() over(order by sum(DELTA_PGA_MB) desc) rank
from
(
select SESSION_ID,SESSION_SERIAL#,sample_id,SQL_ID,SAMPLE_TIME,IS_SQLID_CURRENT,SQL_CHILD_NUMBER,PGA_ALLOCATED,
greatest(PGA_ALLOCATED - first_value(PGA_ALLOCATED) over (partition by SESSION_ID,SESSION_SERIAL# order by sample_time rows 1 preceding),0)/power(1024,2) "DELTA_PGA_MB"
from
v$active_session_history
where
IS_SQLID_CURRENT='Y'
and sample_time > sysdate-&_minutes/14400
order by 1,2,3,4
)
group by sql_id
having sum(DELTA_PGA_MB) > 0
)
where rank < (&_top+1)
order by rank;

PROMPT
PROMPT &_C_YELLOW.######################################## &_C_RESET
PROMPT  &_C_YELLOW.Top temp space usage &_C_RESET
PROMPT &_C_YELLOW.######################################## &_C_RESET 
accept _minutes prompt "Last minutess [5] : " default 5;
accept _top prompt "Top  Rows    [10] : " default 10;
 
select SQL_ID,TEMP_MB,percent,rpad('*',percent*10/100,'*') star
from
(
select SQL_ID,sum(DELTA_TEMP_MB) TEMP_MB ,(ratio_to_report(sum(DELTA_TEMP_MB)) over ())*100 percent,rank() over(order by sum(DELTA_TEMP_MB) desc) rank
from
(
select SESSION_ID,SESSION_SERIAL#,sample_id,SQL_ID,SAMPLE_TIME,IS_SQLID_CURRENT,SQL_CHILD_NUMBER,temp_space_allocated,
greatest(temp_space_allocated - first_value(temp_space_allocated) over (partition by SESSION_ID,SESSION_SERIAL# order by sample_time rows 1 preceding),0)/power(1024,2) "DELTA_TEMP_MB"
from
v$active_session_history
where
IS_SQLID_CURRENT='Y'
and sample_time > sysdate-&_minutes/14400
order by 1,2,3,4
)
group by sql_id
having sum(DELTA_TEMP_MB) > 0
)
where rank < (&_top+1)
order by rank;

col status clear
col username clear
col sid clear
col serial# clear
col sql_id clear
col sql_exec_id clear
col sql_exec_start clear
col buffer_gets clear
col elapsed_sec clear
col CPU_sec clear
col phys_reads_MB clear
col phys_writes_MB clear

col percent clear
col star clear

undef _seconds
undef _top

@@oraPerf.sql