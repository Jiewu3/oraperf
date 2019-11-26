SET TERMOUT ON LINESIZE 300 pages 999 SCAN ON VERIFY OFF FEEDBACK OFF

PROMPT
prompt &_C_YELLOW in g_dash_top_sql_by_exec.sql &_C_RESET


COLUMN sql_id FORMAT A13 HEADING "SQL Id"
COLUMN sql_text FORMAT A80 WRAP HEADING "SQL Type"
COLUMN In_SqlMon FORMAT A9

break on inst_id skip 1

SELECT inst_id,
       sql_id,
       sql_text,
       executions,
       elapsed_time,
       per_exec,
       case when exists ( select 1 from gv$sql_monitor where sql_id=a.sql_id) then 'YES' else 'NO' end AS IN_SqlMon
FROM (
  SELECT inst_id,
         sql_id,
         sql_text,
         executions,
         elapsed_time,
         elapsed_time/executions/1000 as per_exec,
         rank() over ( partition by inst_id order by executions desc) rank
  FROM gv$sqlstats s
  WHERE sql_id IS NOT NULL
  --ORDER BY inst_id, sum(1) DESC
) a
WHERE   a.rank<= 10;

SELECT inst_id,
       sql_id,
       sql_text,
       executions,
       elapsed_time,
       per_exec,
       case when exists ( select 1 from gv$sql_monitor where sql_id=a.sql_id) then 'YES' else 'NO' end AS IN_SqlMon
FROM (
  SELECT inst_id,
         sql_id,
         sql_text,
         executions,
         elapsed_time,
         elapsed_time/executions/1000 as per_exec,
         rank() over ( partition by inst_id order by elapsed_time/executions desc) rank
  FROM gv$sqlstats s
  WHERE sql_id IS NOT NULL and executions >0
  --ORDER BY inst_id, sum(1) DESC
) a
WHERE   a.rank<= 10;

UNDEFINE _btime
UNDEFINE _etime
UNDEFINE _sid
UNDEFINE _serial

CLEAR COLUMNS

@@oraPerf.sql
