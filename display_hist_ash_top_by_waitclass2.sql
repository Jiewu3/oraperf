--------------------------------------------------------------------------------
--
-- File name:   dashtop.sql
-- Purpose:     Display top ASH time (count of ASH samples) grouped by your
--              specified dimensions
--              
-- Author:      Tanel Poder
-- Copyright:   (c) http://blog.tanelpoder.com
--              
-- Usage:       
--     @dashtop <grouping_cols> <filters> <fromtime> <totime>
--
-- Example:
--     @dashtop username,sql_id session_type='FOREGROUND' sysdate-1/24 sysdate
--
-- Other:
--     This script uses only the AWR's DBA_HIST_ACTIVE_SESS_HISTORY, use
--     @dashtop.sql for accessiong the V$ ASH view
--              
--------------------------------------------------------------------------------
--PROMPT 
--accept _grouping_cols PROMPT "&_C_RED Enter grouping columns (i.e. username, sql_id): &_C_RESET"
PROMPT
accept _filters PROMPT "&_C_RED Enter filters (i.e. wait_class='Cluster' or 1=1): &_C_RESET"
PROMPT
accept _fromtime PROMPT "&_C_RED Enter from time (example 2015/10/29 14:10:00): &_C_RESET"
PROMPT
accept _totime PROMPT "&_C_RED Enter end time (example 2015/10/29 14:30:00): &_C_RESET"
PROMPT
PROMPT &_C_YELLOW display_hist_ash_top_by_waitclass.sql  &_C_RESET

COL "%This" FOR A6
--COL p1     FOR 99999999999999
--COL p2     FOR 99999999999999
--COL p3     FOR 99999999999999
COL p1text FOR A20 word_wrap
COL p2text FOR A20 word_wrap
COL p3text FOR A20 word_wrap
COL p1hex  FOR A17
COL p2hex  FOR A17
COL p3hex  FOR A17
COL event  FOR A30
COL sql_opname FOR A15
COL top_level_call_name FOR A25
col first_seen for a22
col last_seen for a22
col username for a16

SELECT * FROM (
    SELECT /*+ LEADING(a) USE_HASH(u) */
        LPAD(ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 100)||'%',5,' ') "%This"
      , username, sql_id	  
      , 10 * COUNT(*)                                                      "TotalSeconds"
      , 10 * SUM(CASE WHEN wait_class IS NULL           THEN 1 ELSE 0 END) "CPU"
      , 10 * SUM(CASE WHEN wait_class ='User I/O'       THEN 1 ELSE 0 END) "User I/O"
      , 10 * SUM(CASE WHEN wait_class ='Application'    THEN 1 ELSE 0 END) "Application"
      , 10 * SUM(CASE WHEN wait_class ='Concurrency'    THEN 1 ELSE 0 END) "Concurrency"
      , 10 * SUM(CASE WHEN wait_class ='Commit'         THEN 1 ELSE 0 END) "Commit"
      , 10 * SUM(CASE WHEN wait_class ='Configuration'  THEN 1 ELSE 0 END) "Configuration"
      , 10 * SUM(CASE WHEN wait_class ='Cluster'        THEN 1 ELSE 0 END) "Cluster"
      , 10 * SUM(CASE WHEN wait_class ='Idle'           THEN 1 ELSE 0 END) "Idle"
      , 10 * SUM(CASE WHEN wait_class ='Network'        THEN 1 ELSE 0 END) "Network"
      , 10 * SUM(CASE WHEN wait_class ='System I/O'     THEN 1 ELSE 0 END) "System I/O"
      , 10 * SUM(CASE WHEN wait_class ='Scheduler'      THEN 1 ELSE 0 END) "Scheduler"
      , 10 * SUM(CASE WHEN wait_class ='Administrative' THEN 1 ELSE 0 END) "Administrative"
      , 10 * SUM(CASE WHEN wait_class ='Queueing'       THEN 1 ELSE 0 END) "Queueing"
      , 10 * SUM(CASE WHEN wait_class ='Other'          THEN 1 ELSE 0 END) "Other"
      , TO_CHAR(MIN(sample_time), 'YYYY-MM-DD HH24:MI:SS') first_seen
      , TO_CHAR(MAX(sample_time), 'YYYY-MM-DD HH24:MI:SS') last_seen
    FROM
        (SELECT
             a.*
           , TO_CHAR(CASE WHEN session_state = 'WAITING' THEN p1 ELSE null END, '0XXXXXXXXXXXXXXX') p1hex
           , TO_CHAR(CASE WHEN session_state = 'WAITING' THEN p2 ELSE null END, '0XXXXXXXXXXXXXXX') p2hex
           , TO_CHAR(CASE WHEN session_state = 'WAITING' THEN p3 ELSE null END, '0XXXXXXXXXXXXXXX') p3hex
        FROM dba_hist_active_sess_history a) a
      , dba_users u
    WHERE
        a.user_id = u.user_id (+)
    AND session_type='FOREGROUND'
	AND &_filters
    AND sample_time BETWEEN to_date('&_fromtime', 'YYYY/MM/DD HH24:MI:SS') AND to_date('&_totime', 'YYYY/MM/DD HH24:MI:SS')
    AND snap_id IN (SELECT snap_id FROM dba_hist_snapshot WHERE sample_time BETWEEN to_date('&_fromtime', 'YYYY/MM/DD HH24:MI:SS') AND to_date('&_totime', 'YYYY/MM/DD HH24:MI:SS')) -- for partition pruning
    GROUP BY username, sql_id
    ORDER BY
        "TotalSeconds" DESC, username, sql_id
)
WHERE
    ROWNUM <= 20;
	
undef _grouping_cols
undef _filters
undef _fromtime
undef _totime

@@oraperf.sql
