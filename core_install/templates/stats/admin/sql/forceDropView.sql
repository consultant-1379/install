
if (object_id('dba.forceDropView') is not   null)   then
    drop procedure dba.forceDropView ;

    if (object_id('dba.forceDropView') is not null) then
        message '<<< FAILED to drop procedure dba.forceDropView >>>' type   info to client ;
    else
        message '<<< Dropped procedure dba.forceDropView >>>' type info to client   ;
    end if ;
end if ;

create procedure dba.forceDropView(in @vname varchar(255) , in @vowner varchar(56) default 'dc' ) 
ON EXCEPTION RESUME
BEGIN
        
        declare @connhandle     int;
        declare @sql        	clob;
        declare @sc             int;


		set @sql='DROP VIEW '||@vowner||'.'||@vname||';';
		execute immediate @sql;
		set @sc=sqlcode;
		while @sc != 0 loop
			IF (SELECT count(*) FROM SYSVIEWS WHERE viewname=@vname AND vcreator=@vowner ) > 0 then
				for loop3 as curs3 cursor for
					select distinct c.connhandle  as connhandle from sp_iqlocks() l,sp_iqconnection() c where l.table_name like @vname and l.creator like @vowner and c.connhandle=l.conn_id
				do
					set @connhandle = connhandle;
					set @sql = 'drop connection '|| @connhandle||';';
					execute immediate @sql;
				end for ;
				set @sql='DROP VIEW '||@vowner||'.'||@vname||';';
				execute immediate @sql;
				set @sc=sqlcode;
			ELSE
				set @sc=0;
			END IF;
		end loop ;

END;

if (object_id('dba.forceDropView') is not   null)   then
   message '<<< Created procedure dba.forceDropView >>>' type info to client ;
   grant execute on dba.forceDropView to public ;
else
   message '<<< FAILED to create procedure dba.forceDropView >>>'   type info to client ;
end if ;

