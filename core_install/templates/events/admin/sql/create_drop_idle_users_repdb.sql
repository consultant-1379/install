 
 if(object_id('dba.drop_idle_users_repdb') is not null) then
        drop procedure dba.drop_idle_users_repdb;

        if(object_id('dba.drop_idle_users_repdb') is not null) then
                message '<<< FAILED to drop procedure dba.drop_idle_users_repdb >>>' type info to client;
        else
                message '<<< Dropped procedure dba.drop_idle_users_repdb >>>' type info to client;
        end if;

end if;

create procedure dba.drop_idle_users_repdb()
begin
	declare @sql varchar(255);
	declare @sc integer;
	declare @Number bigint;
	declare @NumberDrop bigint;
	declare @Name varchar(255);
	declare @Userid varchar(50);
	declare @LastReqTime datetime;
	declare @ReqType varchar(50);
	declare @NodeAddr varchar(50);
	declare @uptime int;
	declare @uptimeDrop int;
	
    unload select ' ' to '/eniq/log/sw_log/asa/asa_connection.log' append on;              
	unload select '- - - - - - - - - - - - - - - - - - - - - Listing connections - - - - - - - - - - - - - - - - - - - - -' to '/eniq/log/sw_log/asa/asa_connection.log' append on;
	unload select now() to '/eniq/log/sw_log/asa/asa_connection.log' append on;
	unload select ' ' to '/eniq/log/sw_log/asa/asa_connection.log' append on;      
	for loop1 as curs1 cursor for
			select Number,Name,Userid,LastReqTime,ReqType,NodeAddr,datediff(ss,LastReqTime,now()) as [uptime] from sa_conn_info() where [uptime] > 900
	do
			set @Number = Number;
			set @Name = Name;
			set @Userid = Userid;
			set @LastReqTime = LastReqTime;
			set @ReqType = ReqType;
			set @NodeAddr = NodeAddr;
			set @uptime = uptime;
			
			unload select @Number,@Name,@Userid,@LastReqTime,@ReqType,@NodeAddr,@uptime to '/eniq/log/sw_log/asa/asa_connection.log' append on;

			set @sc = SQLCODE;

			if ( @sc <> 0) then
					
					message 'ERROR - SQLCODE from execute was: ' || @sc type info to client;
					message 'SQL was: ' || @sql type info to client;
			else 
					message 'it ran' type info to client;
			end if;
	end for;
	unload select '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -' to '/eniq/log/sw_log/asa/asa_connection.log' append on;
	unload select ' ' to '/eniq/log/sw_log/asa/asa_connection.log' append on;      
	unload select '- - - - - - - - - - - - - - - - - - - - - Dropping connections - - - - - - - - - - - - - - - - - - - - -' to '/eniq/log/sw_log/asa/asa_connection.log' append on;
	unload select ' ' to '/eniq/log/sw_log/asa/asa_connection.log' append on;      
			for loop1 as curs2 cursor for
			select Number,datediff(ss,LastReqTime,now()) as [uptime] from sa_conn_info() where [uptime] > 1800 and name like 'SQL_DBC_%' and ReqType like 'CLOSE'
	do
			set @NumberDrop = Number;
			set @uptimeDrop = uptime;

			set @sql = 'drop connection ' || @NumberDrop;
			execute immediate @sql;
	
			set @sc = SQLCODE;
	
			if ( @sc <> 0) then
				unload select 'ERROR - SQLCODE from execute was: ' || @sc to '/eniq/log/sw_log/asa/asa_connection.log' append on;
				message 'ERROR - SQLCODE from execute was: ' || @sc type info to client;
				message 'SQL was: ' || @sql type info to log;
				message 'SQL was: ' || @sql type info to client;
			else
				unload select 'Connection ' || @NumberDrop || ' was dropped as it was idle for '||@uptimeDrop||' seconds' to '/eniq/log/sw_log/asa/asa_connection.log' append on;
				message 'Connection ' || @NumberDrop || ' was dropped as it was idle for '||@uptimeDrop||' seconds' type info to client;
			end if;


	end for;

end;


commit;

if(object_id('dba.drop_idle_users_repdb') is not null) then
        message '<<< Created procedure dba.drop_idle_users_repdb >>>' type info to client ;
        grant execute on dba.drop_idle_users_repdb to public;
else
        message '' type info to client;
end if;
