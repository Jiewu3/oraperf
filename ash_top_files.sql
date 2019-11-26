SET ECHO OFF
REM Description.: Display top files for the period specified as parameter.
REM Parameters..: &1 period begin
REM               &2 period end
REM
REM               The two parameters supports three main formats:
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
REM ***************************************************************************

SET TERMOUT ON LINESIZE 120 SCAN ON VERIFY OFF FEEDBACK OFF

VARIABLE t1 VARCHAR2(250)
VARIABLE t2 VARCHAR2(250)
UNDEFINE _btime
UNDEFINE _etime

PROMPT
prompt &_C_YELLOW in ash_top_objects.sql &_C_RESET
accept _btime PROMPT "&_C_RED Enter begin time [default sysdate - (1/24/60)*5 5 minutes ago]: &_C_RESET" default "sysdate - (1/24/60)*5"
accept _etime PROMPT "&_C_RED Enter end time [default now]: &_C_RESET" default sysdate

COLUMN begin_timestamp FORMAT A30 HEADING "Period Begin"
COLUMN end_timestamp FORMAT A30 HEADING "Period End"
COLUMN ash_samples FORMAT 9,999,999,999 HEADING "Total Sample Count"
COLUMN activity_pct FORMAT 990.0 HEADING "Activity%"
COLUMN file_name FORMAT A60 TRUNC HEADING "Name"
COLUMN tablespace_name FORMAT A30 HEADING "Tablespace"
COLUMN avg_time_waited FORMAT 9,999,999 HEADING "Avg Wait Time [ms]"

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

SELECT :t1 AS begin_timestamp, :t2 AS end_timestamp, count(*) AS ash_samples
FROM v$active_session_history
WHERE sample_time > to_timestamp(:t1,'YYYY-MM-DD_HH24:MI:SSXFF')
AND sample_time <= to_timestamp(:t2,'YYYY-MM-DD_HH24:MI:SSXFF')
AND wait_class = 'User I/O';

SELECT ash.activity_pct,
       f.file_name,
       f.tablespace_name,
       ash.avg_time_waited
FROM (
  SELECT round(100 * ratio_to_report(sum(1)) OVER (), 1) AS activity_pct,
         current_file#,
         round(avg(time_waited)/1000,0) AS avg_time_waited 
  FROM v$active_session_history
  WHERE sample_time > to_timestamp(:t1,'YYYY-MM-DD_HH24:MI:SSXFF')
  AND sample_time <= to_timestamp(:t2,'YYYY-MM-DD_HH24:MI:SSXFF')
  AND wait_class = 'User I/O'
  GROUP BY current_file#
  ORDER BY sum(1) DESC
) ash, dba_data_files f
WHERE rownum <= 10
AND ash.current_file# = f.file_id(+);

UNDEFINE _btime
UNDEFINE _etime

TTITLE OFF

CLEAR COLUMNS

@@oraPerf.sql
