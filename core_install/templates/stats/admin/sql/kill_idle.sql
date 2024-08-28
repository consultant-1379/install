if exists (select 1
	   from   sys.sysevent a
	   join	  sys.sysuserperm b on a.creator = b.user_id
	   where  a.event_name = 'kill_idle' and b.user_name = 'DBA') then
	drop event kill_idle;
end if;

create event kill_idle
	schedule kill_idle start time '00:00 AM' every 15 minutes
handler
begin
	declare local temporary table iq_connTable (
		Number			unsigned bigint	null,
		IQconnID		unsigned bigint	null,
		IQCmdType		char(32)	null,
		LastIQCmdTime		datetime	null,
		IQCursors		unsigned int	null,
		LowestIQCursorState	char(16)	null,
		IQthreads		unsigned int	null,
		TxnID			unsigned bigint	null,
		ConnCreateTime		datetime	null,
		TempWorkSpace		unsigned bigint	null,
		TempTableSpace		unsigned bigint	null,
		satoiq_count		unsigned bigint	null,
		iqtosa_count		unsigned bigint	null,
		MPXServerName           varchar(128)    null,
                LSID                    unsigned bigint null,
                INCConnName             varchar(255)    null,
                INCConnSuspended        char(2)         null,	
		primary key(Number),
	) in SYSTEM on commit preserve rows;

	execute immediate 'iq utilities main into iq_connTable command statistics 20000';

	for loop1 as cursor1 cursor for
	    select	i.Number,
			u.user_name
	    from	iq_connTable i
	    join	sysuserperm u
	    on		connection_property('Userid',i.Number) = u.user_name
	    where	i.IQCmdType = 'NONE'					-- No current command.
	    and		i.MPXServerName = 0						-- Not a dbremote connection.
--	    and		i.IQthreads = 1						-- Only 1 thread.
	    and		minutes(i.LastIQCmdTime,current timestamp) >= 30	-- Hardcoded time limit.
--	    and		u.dbaauth = 'N'						-- Don't kill DBA's
	    and		i.LowestIQCursorState = 'NONE'				-- Active fetching?
            and         u.user_name = 'dcpublic'                            	-- kill only dcpublic connections 

	do
	    message 'kill_idle: drop connection ' || Number || ' (' || user_name || ')' to log;
	    execute immediate 'drop connection ' || Number;
	end for;
end;
