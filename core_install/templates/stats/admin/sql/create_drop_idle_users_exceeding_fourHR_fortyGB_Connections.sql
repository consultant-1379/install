if(object_id('dba.drop_idle_users_exceeding_fourHR_fortyGB_Connections') is not null) then
        drop procedure dba.drop_idle_users_exceeding_fourHR_fortyGB_Connections;

        if(object_id('dba.drop_idle_users_exceeding_fourHR_fortyGB_Connections') is not null) then
                message '<<< FAILED to drop procedure dba.drop_idle_users_exceeding_fourHR_fortyGB_Connections >>>' type info to client;
        else
                message '<<< Dropped procedure dba.drop_idle_users_exceeding_fourHR_fortyGB_Connections >>>' type info to client;
        end if;

end if;

create procedure dba.drop_idle_users_exceeding_fourHR_fortyGB_Connections()
begin
        declare @ConnHandle bigint;
        declare @sql clob;
        declare @sc integer;
        declare @ConnHandleToExclude bigint;
        declare @ConnectionMatch varchar(10);
        declare @DropConnection varchar(10);

        for loop1 as curs1 cursor for
                select conn.ConnHandle from sp_iqconnection() conn, sp_iqversionuse() ver where conn.IQConnID = ver.IQConnID and DATEDIFF(mi,conn.LastReqTime,now()) >= 180 and MaxKBRelease >= 41943040
        do
                set @ConnHandle = ConnHandle;
                set @DropConnection = 'Y';
                if ( select count(*) from sp_iqcontext() where Userid = 'DBA' and CmdLine like '%extract_data%' or CmdLine like '%LOAD TABLE%' ) > 0 then
                    for loop2 as curs2 cursor for
                            select ConnHandle as ConnHandleToExclude from sp_iqcontext() where Userid = 'DBA' and CmdLine like '%extract_data%' or CmdLine like '%LOAD TABLE%'
                    do
                        set @ConnHandleToExclude = ConnHandleToExclude;
                        if ( @ConnHandleToExclude = @ConnHandle ) then
                            set @ConnectionMatch = 'Y';
                            set @DropConnection = 'N';
                        else
                            set @ConnectionMatch = 'N';
                        end if;
                        
                    end for;
                    
                    if ( (@ConnectionMatch = 'N') and (@DropConnection = 'Y') )  then
                            set @sql = 'drop connection ' || @ConnHandle;
                            execute immediate @sql;

                            set @sc = SQLCODE;

                            if ( @sc <> 0) then
                                message 'ERROR - SQLCODE from execute was: ' || @sc type info to log;
                                message 'ERROR - SQLCODE from execute was: ' || @sc type info to client;
                                message 'SQL was: ' || @sql type info to log;
                                message 'SQL was: ' || @sql type info to client;
                            else
                                message 'Connection ' || @ConnHandle || ' was dropped as it was idle for 3 hours and was consuming over 40 GB of memory' type info to log;
                                message 'Connection ' || @ConnHandle || ' was dropped as it was idle for 3 hours and was consuming over 40 GB of memory' type info to client;
                            end if;
                    end if;
                else
                    set @sql = 'drop connection ' || @ConnHandle;
                    execute immediate @sql;

                    set @sc = SQLCODE;

                    if ( @sc <> 0) then
                            message 'ERROR - SQLCODE from execute was: ' || @sc type info to log;
                            message 'ERROR - SQLCODE from execute was: ' || @sc type info to client;
                            message 'SQL was: ' || @sql type info to log;
                            message 'SQL was: ' || @sql type info to client;
                    else
                            message 'Connection ' || @ConnHandle || ' was dropped as it was idle for 3 hours and was consuming over 40 GB of memory' type info to log;
                            message 'Connection ' || @ConnHandle || ' was dropped as it was idle for 3 hours and was consuming over 40 GB of memory' type info to client;
                    end if;

                end if;


        end for;

end;

commit;

if(object_id('dba.drop_idle_users_exceeding_fourHR_fortyGB_Connections') is not null) then
        message '<<< Created procedure dba.drop_idle_users_exceeding_fourHR_fortyGB_Connections >>>' type info to client ;
        grant execute on dba.drop_idle_users_exceeding_fourHR_fortyGB_Connections to public;
else
        message '' type info to client;
end if;

