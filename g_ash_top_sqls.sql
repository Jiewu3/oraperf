SET ECHO OFF
REM Description.: Display top SQL statements at the system level or session
REM               level for the period specified as parameter. 
REM Notes.......: To run this script the Diagnostic Pack license is required. 
REM Parameters..: &1 period begin
REM               &2 period end
REM               &3 either "all" or the sid of the session to focus on
REM               &4 either "all" or the serial# of the session to focus on
REM
REM               The first two parameters supports three main formats:
REM               - Timestamp without day: HH24:MI:SSXFF
REM               - Timestamp with day: YYYY-MM-DD_HH24:MI:SSXFF
REM               - Expression: any SQL expression that returns a DATE value
REM
REM               Caution: the expression, to be recognized by SQL*Plus as a
REM                        single parameter, cannot contain spaces.
REM
REM               Examples:
REM               - 23:15:35             (today at 23:15:35.000000000)
REM               - 2014-10-13_23:15     (13 Oct 2014 at 23:15:00.000000000)
REM               - sysdate              (now)
REM               - sysdate-(1/24/60)*10 (10 minutes ago)
REM
REM The first two input parameters are more flexible and support 
REM an expression + Added information about period and number of ASH samples 
REM ***************************************************************************

SET TERMOUT ON LINESIZE 300 pages 999 SCAN ON VERIFY OFF FEEDBACK OFF

VARIABLE t1 VARCHAR2(250)
VARIABLE t2 VARCHAR2(250)
UNDEFINE _btime
UNDEFINE _etime
UNDEFINE _sid
UNDEFINE _serial

PROMPT
prompt &_C_YELLOW in ash_top_sqls.sql &_C_RESET
prompt "&_C_CYAN Time formats can be: &_C_RESET"
prompt "&_C_CYAN> 23:15:35             (today at 23:15:35.000000000)&_C_RESET"
prompt "&_C_CYAN> 2014-10-13_23:15     (13 Oct 2014 at 23:15:00.000000000)&_C_RESET"
prompt "&_C_CYAN> sysdate              (now)&_C_RESET"
prompt "&_C_CYAN> sysdate-(1/24/60)*10 (10 minutes ago)&_C_RESET"
accept _btime PROMPT "&_C_RED Enter begin time [default sysdate - (1/24/60)*5 5 minutes ago]: &_C_RESET" default "sysdate - (1/24/60)*5"
accept _etime PROMPT "&_C_RED Enter end time [default now]: &_C_RESET" default sysdate
accept _sid PROMPT "&_C_RED Enter session_id [default all]: &_C_RESET" default all
accept _serial PROMPT "&_C_RED Enter serial# [default all]: &_C_RESET" default all

SET TERMOUT OFF

COLUMN begin_timestamp FORMAT A30 HEADING "Period Begin"
COLUMN end_timestamp FORMAT A30 HEADING "Period End"
COLUMN ash_samples FORMAT 9,999,999,999 HEADING "Total Sample Count"
COLUMN activity_pct FORMAT 990.0 HEADING "Activity%"
COLUMN db_time FORMAT 9,999,999 HEADING "DB Time"
COLUMN cpu_pct FORMAT 990.0 HEADING "CPU%"
COLUMN user_io_pct FORMAT 990.0 HEADING "UsrIO%"
COLUMN wait_pct FORMAT 990.0 HEADING "Wait%"
COLUMN session_id FORMAT 999999 TRUNCATE HEADING "SID"
COLUMN session_serial# FORMAT 999999 TRUNCATE HEADING "Serial#"
COLUMN username FORMAT A16 TRUNCATE HEADING "User"
COLUMN sql_id FORMAT A13 HEADING "SQL Id"
COLUMN sql_opname FORMAT A12 TRUNCATE HEADING "SQL Type"
COLUMN program FORMAT A24 TRUNCATE HEADING "Program"
COLUMN module FORMAT A24 TRUNCATE HEADING "Module"
COLUMN In_SqlMon FORMAT A9
DECLARE
  FUNCTION validate(p_value IN VARCHAR2) RETURN VARCHAR2 IS
    c_format_mask_date CONSTANT VARCHAR2(24) := 'YYYY-MM-DD_HH24:MI:SS';
    c_format_mask_timestamp CONSTANT VARCHAR2(24) := c_format_mask_date || 'XFF';
  BEGIN
    -- Check if the input value can be parsed by adding as prefix the current day.
    -- The followings are examples of valid values:
    --  * HH24:MI:SSXFF (e.g. 23:15:35.123456789)
    --  * HH24:MI:SS    (e.g. 23:15:35)
    --  * HH24:MI       (e.g. 23:15)
    --  * HH24          (e.g. 23)
    BEGIN
      RETURN to_char(to_timestamp(to_char(sysdate, 'YYYY-MM-DD_') || p_value, c_format_mask_timestamp), c_format_mask_timestamp);
    EXCEPTION
      WHEN others THEN NULL;
    END;

    -- Check if the input value can be parsed as is.
    -- The followings are examples of valid values:
    --  * YYYY-MM-DD_HH24:MI:SSXFF (e.g. 2014-10-13_23:15:35.123456789)
    --  * YYYY-MM-DD_HH24:MI:SS    (e.g. 2014-10-13_23:15:35)
    --  * YYYY-MM-DD_HH24:MI       (e.g. 2014-10-13_23:15)
    --  * YYYY-MM-DD_HH24          (e.g. 2014-10-13_23)
    --  * YYYY-MM-DD               (e.g. 2014-10-13)
    BEGIN
      RETURN to_char(to_timestamp(p_value, c_format_mask_timestamp), c_format_mask_timestamp);
    EXCEPTION
      WHEN others THEN NULL;
    END;

    -- Check if the input value is a valid expression.
    -- The followings are examples of valid expressions:
    --  * systimestamp-1/24/60 (one minute ago)
    --  * systimestamp         (now)
    --  * sysdate-(1/24/60)*10 (10 minutes ago)
    --  * sysdate              (now)
    DECLARE
      l_ret VARCHAR2(21);
    BEGIN
      EXECUTE IMMEDIATE 'SELECT to_char(' || p_value || ', ''' || c_format_mask_date || ''') FROM dual' INTO l_ret;
      RETURN l_ret;
    EXCEPTION
      WHEN others THEN NULL;
    END;

    RAISE_APPLICATION_ERROR (-20000, 'Invalid input value: "' || p_value || '"', FALSE);
  END validate;
BEGIN
 :t1 := validate('&_btime');
 :t2 := validate('&_etime');
END;
/

SET TERMOUT ON

SELECT :t1 AS begin_timestamp, :t2 AS end_timestamp, count(*) AS ash_samples
FROM v$active_session_history
WHERE sample_time > to_timestamp(:t1,'YYYY-MM-DD HH24:MI:SSXFF')
AND sample_time <= to_timestamp(:t2,'YYYY-MM-DD HH24:MI:SSXFF')
AND sql_id IS NOT NULL
AND session_id = decode(lower('&_sid'), 'all', session_id, to_number('&_sid')) 
AND session_serial# = decode(lower('&_serial'), 'all', session_serial#, to_number('&_serial'));

break on inst_id skip 1

SELECT ash.inst_id inst_id, ash.activity_pct,
       ash.db_time,
       round(ash.cpu_time / ash.db_time * 100, 1) AS cpu_pct,
       round(ash.user_io_time / ash.db_time * 100, 1) AS user_io_pct,
       round(ash.wait_time / ash.db_time * 100, 1) AS wait_pct,
       ash.session_id,
       ash.session_serial#,
       username,
       ash.sql_id,
       nvl(aa.name, ash.sql_opcode) AS sql_opname,
       program,
       module,
       case when exists ( select 1 from gv$sql_monitor where sql_id=ash.sql_id) then 'YES' else 'NO' end AS IN_SqlMon
FROM (
  SELECT inst_id,
         round(100 * ratio_to_report(sum(1)) OVER (partition by inst_id), 1) AS activity_pct,
         rank() over ( partition by inst_id order by sum(1) desc) rank,
         sum(1) AS db_time,
         sum(decode(session_state, 'ON CPU', 1, 0)) AS cpu_time,
         sum(decode(session_state, 'WAITING', decode(wait_class, 'User I/O', 1, 0), 0)) AS user_io_time,
         sum(decode(session_state, 'WAITING', 1, 0)) - sum(decode(session_state, 'WAITING', decode(wait_class, 'User I/O', 1, 0), 0)) AS wait_time,
         session_id,
         session_serial#,
         u.username AS username,
         sql_id,
         sql_opcode,
         program,
         module
  FROM gv$active_session_history ash, dba_users u
  WHERE ash.user_id=u.user_id
  AND sample_time > to_timestamp(:t1,'YYYY-MM-DD_HH24:MI:SSXFF')
  AND sample_time <= to_timestamp(:t2,'YYYY-MM-DD_HH24:MI:SSXFF')
  AND sql_id IS NOT NULL
  AND session_id = decode(lower('&_sid'), 'all', session_id, to_number('&_sid')) 
  AND session_serial# = decode(lower('&_serial'), 'all', session_serial#, to_number('&_serial')) 
  GROUP BY inst_id,session_id, session_serial#, u.username, sql_id, sql_opcode, program, module
  --ORDER BY inst_id, sum(1) DESC
) ash, audit_actions aa
WHERE   ash.rank<= 10 AND ash.sql_opcode = aa.action(+);

UNDEFINE _btime
UNDEFINE _etime
UNDEFINE _sid
UNDEFINE _serial

TTITLE OFF

CLEAR COLUMNS

@@oraPerf.sql
