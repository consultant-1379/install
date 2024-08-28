if (object_id('dba.forceLockTableList') is not   null)   then
    drop procedure dba.forceLockTableList ;

    if (object_id('dba.forceLockTableList') is not null) then
        message '<<< FAILED to drop procedure dba.forceLockTableList >>>' type   info to client ;
    else
        message '<<< Dropped procedure dba.forceLockTableList >>>' type info to client   ;
    end if ;
end if ;

create procedure dba.forceLockTableList(in @tablenamelist clob  ) ON EXCEPTION RESUME
BEGIN
        
	declare @towner varchar(52);
	declare @tname  varchar(255);
	declare @connhandle     int;
	declare @sql        	clob;
	declare @sc             int;
	declare @table_name varchar(128);
	
	
	for loop1 as    curs1 cursor for
		SELECT row_value FROM sa_split_list( @tablenamelist )      
	do
		
		set @table_name = row_value;
		if ( charindex('.', @table_name) = 0 ) then
			set @towner = 'dc';
			set @tname  = @table_name;
		else
			set @towner = substring( @table_name, 1, charindex('.', @table_name)-1);
			set @tname  = substring( @table_name, charindex('.', @table_name)+1);
		end if ;
		
		set @sql='lock table '||@towner||'.'||@tname||' with hold in exclusive mode; ';
		execute immediate @sql;
		set @sc=sqlcode;
		
		while @sc != 0 loop
			IF (SELECT count(*) FROM SYSTAB WHERE table_name=@tname AND creator=(select user_id from SYSUSER where user_name=@towner) and table_type_str like 'BASE' ) > 0 then
				for loop2 as    curs2 cursor for
					select distinct c.connhandle  as connhandle from sp_iqlocks() l,sp_iqconnection() c where l.table_name like @tname and l.creator like @towner and c.connhandle=l.conn_id
				do
					set @connhandle = connhandle;
					set @sql = 'drop connection '|| @connhandle||';';
					execute immediate @sql;
				end for ;
				
				
				set @sql='lock table '||@towner||'.'||@tname||' with hold in exclusive mode WAIT ''00:00:05''; ';
				execute immediate @sql;
				set @sc=sqlcode;
				
			ELSE
				set @sc=0;
			END IF;
		end loop ;
	end for ;
END;

if (object_id('dba.forceLockTableList') is not   null)   then
   message '<<< Created procedure dba.forceLockTableList>>>' type info to client ;
   grant execute on dba.forceLockTableList to public ;
else
   message '<<< FAILED to create procedure dba.forceLockTableList >>>'   type info to client ;
end if ;

