if (object_id('dba.dropIdle_dc_Connections') is not   null)   then
    drop    procedure dba.dropIdle_dc_Connections ;

    if (object_id('dba.dropIdle_dc_Connections') is not null) then
        message '<<< FAILED to drop procedure dba.dropIdle_dc_Connections >>>' type   info to client ;
    else
        message '<<< Dropped procedure dba.dropIdle_dc_Connections >>>' type info to client   ;
    end if ;
end if ;

create procedure dba.dropIdle_dc_Connections()
begin
    declare @ConnHandle     bigint;
    declare @idletime       bigint;
    declare @Userid         varchar(56);
    declare @IQconnID       bigint;
    declare @sql            clob;
    declare @sc             integer;
         
    for loop1 as    curs1 cursor for
        select ConnHandle, DATEDIFF(mi,LastReqTime,now()) as idletime, Userid, IQconnID from  sp_iqconnection() where Userid='dc'
    do
        set @ConnHandle  = ConnHandle ; 
        set @idletime = idletime ;
        set @UserID = Userid;
        set @IQconnID = IQconnID;
        
        
        if ( @idletime >= @@timeout@@ ) then
            set @sql = 'drop connection '|| @ConnHandle ;
            execute immediate @sql;          
            set @sc = SQLCODE ;
    
            if ( @sc <> 0 ) then
                message 'ERROR - SQLCODE from execute was: ' || @sc type info to log ;
                message 'ERROR - SQLCODE from execute was: ' || @sc type info to client ;
                message 'SQL was: ' || @sql type info to log ;
                message 'SQL was: ' || @sql type info to client ;
            else
                message 'A connection (ConnHandle: '|| @ConnHandle ||', IQconnID: '|| @IQconnID ||') was dropped as it was idle for '||@idletime||' minutes for ' || @UserID || ' database user.' type info to client ;
                message 'A connection (ConnHandle: '|| @ConnHandle ||', IQconnID: '|| @IQconnID ||') was dropped as it was idle for '||@idletime||' minutes for ' || @UserID || ' database user.' type info to log ;
            end if ; 
        end if ; 
    end for ;
end;

commit ;

if (object_id('dba.dropIdle_dc_Connections') is not   null)   then
   message '<<< Created procedure dba.dropIdle_dc_Connections>>>' type info to client ;
   grant execute on dba.dropIdle_dc_Connections to public ;
else
   message '<<< FAILED to create procedure dba.dropIdle_dc_Connections >>>'   type info to client ;
end if ;
