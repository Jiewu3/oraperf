SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF;
COL inst_child FOR A21;
BREAK ON inst_child SKIP 2;
accept _sqlid prompt 'enter sql_id: '
REM accept _chn prompt 'enter child number[%]: ' default %
prompt eXplain the execution plan for sqlid &_sqlid
PRO Current Execution Plans (last execution)
PRO
PRO Captured while still in memory. Metrics below are for the last execution of each child cursor.
PRO If STATISTICS_LEVEL was set to ALL at the time of the hard-parse then A-Rows column is populated.
PRO
set longc 2000000
set long 999999

--select * from table(dbms_xplan.display_cursor('&_sqlid',CASE WHEN '&_chn' = '%' THEN null ELSE '&_chn' END,'ALLSTATS LAST +PEEKED_BINDS +PARTITION'));
--select * from table(dbms_xplan.display_cursor('&_sqlid',CASE WHEN '&_chn' = '%' THEN null ELSE '&_chn' END,'ALL'));
--ADVANCED
select DBMS_LOB.substr(sql_fulltext, 3000) from v$sql where sql_id = '&_sqlid';
SELECT RPAD('Inst: '||v.inst_id, 9)||' '||RPAD('Child: '||v.child_number, 11) inst_child, t.plan_table_output
 FROM gv$sql v,
 TABLE(DBMS_XPLAN.DISPLAY('gv$sql_plan_statistics_all', NULL, 'ADVANCED ALLSTATS LAST', 'inst_id = '||v.inst_id||' AND sql_id = '''||v.sql_id||''' AND child_number = '||v.child_number)) t
 WHERE v.sql_id = '&_sqlid'
 AND v.loaded_versions > 0;
@oraPerf.sql