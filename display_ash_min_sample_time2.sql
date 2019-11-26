
set termout on
PROMPT
PROMPT &_C_YELLOW Oldest sample time in v$active_session_history &_C_RESET
PROMPT

SELECT inst_id, MIN(sample_time) AS min_sample_time
FROM   gv$active_session_history
group by inst_id;


@@oraperf