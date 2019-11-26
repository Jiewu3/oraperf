set serveroutput on 
define _sql_id=&1
DECLARE
 myReport  CLOB;
 
 l_offset number := 1;

-------------------------------
    procedure printCLOB (p_clob in out nocopy clob) 
    is
       i_offset        number := 1;
       i_amount      integer;
       i_clob_length  number := dbms_lob.getlength(p_clob);
       lc_buffer     varchar2(32767);
      
     begin
     if ( dbms_lob.isopen(p_clob) != 1 ) then
         dbms_lob.open(p_clob, 0);
     end if;
    
    DBMS_OUTPUT.ENABLE (buffer_size => NULL);    
    LOOP
    BEGIN
        i_amount := 32676 ;
        DBMS_LOB.READ ( lob_loc => p_clob, amount => i_amount,  offset => i_offset, buffer => lc_buffer);
        dbms_output.put_line(lc_buffer  );
        i_offset := i_offset + i_amount;
        exception
            when no_data_found then exit;
        end;

    END LOOP;

    dbms_lob.close(p_clob);
    
    exception
       when others then
          dbms_output.put_line('Error : '||sqlerrm);
    end printCLOB;
 ---------------------------

   
BEGIN

  dbms_output.put_line( chr(10) || chr(10) || 'Looking for sql text for &_sql_id : ' || chr(10) || chr(10) );

      BEGIN
      SELECT sql_fulltext INTO myReport FROM gv$sqlarea WHERE sql_id = '&_sql_id' AND ROWNUM = 1; 
        
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('Not found in Cursor Cache');
      END;

  if ( dbms_lob.getlength( myReport ) != 0 )
  Then
    dbms_output.put_line('Found  &_sql_id in cursor cache.');
  ELSE 
        BEGIN
        select sql_text into myReport from dba_hist_sqltext where sql_id = '&_sql_id' and rownum = 1; 
		--select sql_text into myReport from v$sqlstats where sql_id = '&_sql_id' and rownum = 1;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('Not found in AWR');
        END;
    IF ( dbms_lob.getlength( myReport ) != 0 )
    Then
      dbms_output.put_line('Found  &_sql_id in AWR.');
    END IF;  
  END IF;

  IF ( dbms_lob.getlength( myReport ) != 0 )
  THEN
    --DBMS_OUTPUT.PUT_LINE( 'sql text >> #' || myReport || '#' );
    DBMS_OUTPUT.PUT_LINE( '--'  );
    printCLOB( myReport );
    DBMS_OUTPUT.PUT_LINE( '--'  );
  ELSE
    dbms_output.put_line('The sql text for &_sql_id could not be found');
  END IF;

 

  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(Substr(SQLERRM,1,255));
    raise;
END;
/
