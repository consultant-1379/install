if((select object_id from sysevent where event_name like 'drop_idle_users_exceeding_fourHR_fortyGB_event') is not null) then
	drop event dba.drop_idle_users_exceeding_fourHR_fortyGB_event;


	if ((select object_id from sysevent where event_name like 'drop_idle_users_exceeding_fourHR_fortyGB_event') is not null) then
		message '<<< FAILED to drop event dba.drop_idle_users_exceeding_fourHR_fortyGB_event >>>' type info to client
	else
		message '<<< Dropped event dba.drop_idle_users_exceeding_fourHR_fortyGB_event>>>' type info to client;
	end if;
end if;


CREATE EVENT drop_idle_users_exceeding_fourHR_fortyGB_event
	SCHEDULE sched_drop_idle_users_exceeding_limits
		START TIME '00:01 AM' EVERY 15 minutes
	HANDLER
	BEGIN
		CALL drop_idle_users_exceeding_fourHR_fortyGB_Connections();
	END;
	

if((select object_id from sysevent where event_name like 'drop_idle_users_exceeding_fourHR_fortyGB_event') is not null) then
	message '<<< Created event dba.drop_idle_users_exceeding_fourHR_fortyGB_event >>>' type info to client;
else
	message '<<< FAILED  to create event dba.drop_idle_users_exceeding_fourHR_fortyGB_event>>>' type info to client;

end if;

