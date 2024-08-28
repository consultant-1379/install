set option public.login_procedure='dbo.sp_login_environment';
commit;

IF(object_id('sp_eniq_login_environment') is not null) THEN
    DROP PROCEDURE dba.sp_eniq_login_environment;
END IF;

CREATE PROCEDURE dba.sp_eniq_login_environment()
BEGIN
    IF ((select connection_property('CommProtocol') as [CommProtocol]  where  [CommProtocol] in ('TDS','CmdSeq')) is not null) THEN
        IF ( select connection_property('UserID') AS [Conn_User_Name]  where [Conn_User_Name] in ('DC','DWHREP','ETLREP')) is NULL THEN 
            CALL dbo.sp_login_environment(); 
        ELSE 
            CALL dbo.sp_tsql_environment(); 
        END IF;    
    END IF;
END;

IF(object_id('sp_eniq_login_environment') is not null) THEN
        message '<<< Created procedure dba.sp_eniq_login_environment >>>' type info to client ;
        grant execute on dba.sp_eniq_login_environment to public;
END IF;

set option public.login_procedure='dba.sp_eniq_login_environment';
commit;

