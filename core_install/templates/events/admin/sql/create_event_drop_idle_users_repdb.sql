if((select object_id from sysevent where event_name like 'event_drop_idle_users_repdb') is not null) then
    drop event dba.event_drop_idle_users_repdb;


    if ((select object_id from sysevent where event_name like 'event_drop_idle_users_repdb') is not null) then
        message '<<< FAILED to drop event dba.event_drop_idle_users_repdb >>>' type info to client
    else
        message '<<< Dropped event dba.event_drop_idle_users_repdb>>>' type info to client;
    end if;
end if;


CREATE EVENT dba.event_drop_idle_users_repdb
    SCHEDULE sched_drop_idle_users_repdb
        START TIME '00:01 AM' EVERY 15 minutes
    HANDLER
   begin
		call dba.drop_idle_users_repdb();
	end;
    

if((select object_id from sysevent where event_name like 'event_drop_idle_users_repdb') is not null) then
    message '<<< Created event dba.event_drop_idle_users_repdb >>>' type info to client;
else
    message '<<< FAILED  to create event dba.event_drop_idle_users_repdb>>>' type info to client;

end if;

