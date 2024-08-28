IF (SELECT count(*) FROM SYSPROCEDURE WHERE creator = '3' AND proc_name = 'sp_unload_table_from_cache') = 1 THEN
    IF (SELECT count(*) FROM sys.SYSUSERAUTH where name = 'cache_proc_user') = 0 THEN
        CREATE USER cache_proc_user;
        GRANT SERVER OPERATOR TO cache_proc_user;
    END IF;

    DROP PROCEDURE IF EXISTS cache_proc_user.sp_unload_table_from_cache;

    CREATE PROCEDURE cache_proc_user.sp_unload_table_from_cache( owner_name varchar(128), table_name varchar(128) )
    SQL SECURITY DEFINER
    BEGIN
        CALL dbo.sp_unload_table_from_cache( owner_name, table_name );
    END;

    GRANT EXECUTE ON cache_proc_user.sp_unload_table_from_cache TO DBA, DC ;
END IF;
