if ( (select object_id from sysevent where event_name like 'drop_idle_dc_user_event') is not null)   then
    drop  event dba.drop_idle_dc_user_event ;

    if ( (select object_id from sysevent where event_name like 'drop_idle_dc_user_event') is not null) then
        message '<<< FAILED to drop event dba.drop_idle_dc_user_event >>>' type   info to client ;
    else
        message '<<< Dropped event dba.drop_idle_dc_user_event >>>' type info to client   ;
    end if ;
end if ;

CREATE EVENT drop_idle_dc_user_event
  SCHEDULE sched_drop_idle_dc_user
    START TIME '00:01 AM' EVERY 60 minutes
  HANDLER
  BEGIN
    CALL dropIdle_dc_Connections();
  END ;
  
  
if ( (select object_id from sysevent where event_name like 'drop_idle_dc_user_event') is not null)  then
   message '<<< Created event dba.drop_idle_dc_user_event>>>' type info to client ;
else
   message '<<< FAILED to create dba.event drop_idle_dc_user_event >>>'   type info to client ;
end if ;
