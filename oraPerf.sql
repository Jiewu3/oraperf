@inc/colors;
PROMPT
PROMPT  &_C_RED Oracle performance tuning scripts main menu &_C_RESET
PROMPT  &_C_RED ************************************************************************* &_C_RESET
PROMPT  &_C_YELLOW 1: &_C_BLUE CPU/Wait in the last minute &_C_RESET
PROMPT  &_C_YELLOW 2: &_C_BLUE CPU/Wait in the last hour &_C_RESET
PROMPT  &_C_YELLOW 3: &_C_BLUE IO stat in the last minute &_C_RESET
PROMPT  &_C_YELLOW 4: &_C_BLUE IO stat in the last hour &_C_RESET
PROMPT  &_C_YELLOW 5: &_C_BLUE ASH activity (OEM activity chart) &_C_RESET
PROMPT  &_C_YELLOW 6: &_C_BLUE ASH top sqls &_C_RESET
PROMPT  &_C_YELLOW 7: &_C_BLUE ASH top sessions &_C_RESET
PROMPT  &_C_YELLOW 8: &_C_BLUE ASH top services &_C_RESET
PROMPT  &_C_YELLOW 9: &_C_BLUE ASH top modules &_C_RESET
PROMPT  &_C_YELLOW 10: &_C_BLUE ASH top actions &_C_RESET
PROMPT  &_C_YELLOW 11: &_C_BLUE ASH top clients &_C_RESET
PROMPT  &_C_YELLOW 12: &_C_BLUE ASH top objects &_C_RESET
PROMPT  &_C_YELLOW 13: &_C_BLUE ASH top files &_C_RESET
PROMPT  &_C_YELLOW 14: &_C_BLUE ASH top PLSQL &_C_RESET
PROMPT  &_C_YELLOW 15: &_C_BLUE Top sqls by #exececutions &_C_RESET
PROMPT  &_C_YELLOW 16: &_C_BLUE Display top sqls in v$sql_monitor &_C_RESET
prompt
PROMPT  &_C_YELLOW 20: &_C_BLUE Display info about a cursor (v$sqlarea) &_C_RESET
PROMPT  &_C_YELLOW 21: &_C_BLUE Display info about a cursor (v$sql) &_C_RESET
PROMPT  &_C_YELLOW 22: &_C_BLUE Display stats about a cursor (v$sqlstats) &_C_RESET
PROMPT  &_C_YELLOW 23: &_C_BLUE Show current execution plan for SQL_ID &_C_RESET
PROMPT  &_C_YELLOW 24: &_C_BLUE Show historic execution plan for SQL_ID from awr&_C_RESET
PROMPT  &_C_YELLOW 25: &_C_BLUE Generate sql_monitor report &_C_RESET
PROMPT  &_C_YELLOW 26: &_C_BLUE Generate active sql_monitor report &_C_RESET
PROMPT  &_C_YELLOW 27: &_C_BLUE Display execution plan history &_C_RESET &_C_RESET
prompt
PROMPT  &_C_YELLOW 30: &_C_BLUE Display Minimum sample time in v$active_session_history &_C_RESET
PROMPT  &_C_YELLOW 31: &_C_BLUE Display top ASH time (count of ASH samples) &_C_RESET
PROMPT  &_C_YELLOW 32: &_C_BLUE Display top ASH time (count of hist ASH samples) &_C_RESET
prompt
PROMPT  &_C_YELLOW 40: &_C_BLUE Find sql_ids from sql_text pattern&_C_RESET
PROMPT  &_C_YELLOW 41: &_C_BLUE Diplay full text of sql_id &_C_RESET
PROMPT  &_C_YELLOW 42: &_C_BLUE Build bind variables and sql &_C_RESET
PROMPT  &_C_YELLOW 45: &_C_BLUE Diplay cursor - full stats &_C_RESET
PROMPT
PROMPT  &_C_YELLOW 50: &_C_BLUE Diplay system wide real-time temp usage &_C_RESET
PROMPT  &_C_YELLOW 51: &_C_BLUE Diplay sqlid of high temp usage &_C_RESET
PROMPT  &_C_YELLOW 55: &_C_BLUE Diplay sqlid of high disk sort &_C_RESET
PROMPT  &_C_YELLOW 56: &_C_BLUE Diplay hourly TEMP usage &_C_RESET
PROMPT  &_C_YELLOW 57: &_C_BLUE Diplay daily TEMP usage &_C_RESET
PROMPT
PROMPT  &_C_YELLOW 60: &_C_BLUE Display table infomation &_C_RESET
prompt
PROMPT  &_C_YELLOW 99: &_C_BLUE Exit &_C_RESET
accept selection PROMPT "&_C_RED Enter option 1-99: &_C_RESET"

set termout off feedback off echo off verify off
set linesize 300
set pagesize 999
set long 2000000
column script new_value v_script  
select case '&selection.' 
       when '1' then '@cpu_wait_last_minute.sql'
	   when '2' then '@cpu_wait_last_hour.sql'
	   when '3' then '@io_stat_last_minute.sql'
	   when '4' then '@io_stat_last_hour.sql'
	   when '5' then '@ash_activity_last_hour.sql'
	   when '6' then '@g_ash_top_sqls.sql'
	   when '7' then '@ash_top_sessions.sql'
	   when '8' then '@ash_top_services.sql'
       when '9' then '@ash_top_modules.sql'
       when '10' then '@ash_top_actions.sql'
	   when '11' then '@ash_top_clients.sql' 
	   when '12' then '@ash_top_objects.sql'
	   when '13' then '@ash_top_files.sql'
	   when '14' then '@ash_top_plsql.sql'
       when '15' then '@g_dash_top_sql_by_exec.sql'
       when '16' then '@g_top_sqls_in_sqlmonitor.sql'
	   when '20' then '@sqlarea.sql'
	   when '21' then '@sql.sql'
	   when '22' then '@sqlstats.sql'
       when '23' then '@explainPlan.sql'
	   when '24' then '@explainPlan_awr.sql'
	   when '25' then '@g_sql_mon_rpt.sql'
	   when '26' then '@g_sql_mon_rpt_active.sql'
       when '27' then '@dash_xplan_hist.sql'
       when '30' then '@display_ash_min_sample_time2.sql'
       when '31' then '@display_ash_top_by_waitclass2.sql'
       when '32' then '@display_hist_ash_top_by_waitclass2.sql'
       when '40' then '@find_sqls2.sql'
       when '41' then '@sql_fulltext.sql'
       when '42' then '@build_bind_vars2.sql'
       when '45' then '@display_cursor_all.sql'
	   when '50' then '@display_rt_temp_usage.sql'
	   when '51' then '@display_sqlid_high_TEMP.sql'
	   when '55' then '@display_sqlid_high_disk_sort.sql'
	   when '56' then '@display_hourly_temp_usage.sql'
	   when '57' then '@display_daily_temp_usage.sql'
       when '60' then '@table_info.sql'
	   when '99' then '@exit.sql'
       else '@oraPerf.sql' --this script
       end as script 
from dual; 

set termout on

@&v_script 