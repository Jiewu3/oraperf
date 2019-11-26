-- Purpose:     show plan for statement in AWR history
set lines 300
set pages 9999
PROMPT
accept _sql_id PROMPT "&_C_RED Enter sql_id: &_C_RESET" 
accept _plan_hash_value PROMPT "&_C_RED Enter plan_hash_value: &_C_RESET"

SELECT * FROM table(dbms_xplan.display_awr('&_sql_id',nvl('&_plan_hash_value',null),null,'ALL'));
--SELECT * FROM table(dbms_xplan.display_awr('&_sql_id',nvl('&_plan_hash_value',null),null,'ADVANCED +ALLSTATS LAST +MEMSTATS LAST'))
--SELECT * FROM table(dbms_xplan.display_awr('&_sql_id',null,null,'ADVANCED +ALLSTATS LAST +MEMSTATS LAST'));

undef _sql_id
@@oraPerf.sql
