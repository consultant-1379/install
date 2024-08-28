IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_dwhdb_iq_sys_main_size_normal')>0 THEN
    DROP EVENT check_dwhdb_iq_sys_main_size_normal;
END IF;
IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_iq_system_main_size_panic')>0 THEN
    DROP EVENT check_iq_system_main_size_panic;
END IF;
IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_dwhdb_size_panic')>0 THEN
    DROP EVENT check_dwhdb_size_panic;
END IF;
IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_dwhdb_size_normal')>0 THEN
    DROP EVENT check_dwhdb_size_normal;
END IF;
IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_dwhdb_iq_sys_main_monitor')>0 THEN
    DROP EVENT check_dwhdb_iq_sys_main_monitor;
END IF;
IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_dwhdb_iq_main_monitor')>0 THEN
    DROP EVENT check_dwhdb_iq_main_monitor;
END IF;

IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_iq_system_main_size_panic')>0 THEN
    DROP EVENT check_iq_system_main_size_panic;
END IF;

IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_iq_main_size_panic')>0 THEN
    DROP EVENT check_iq_main_size_panic;
END IF;

CREATE EVENT check_dwhdb_iq_sys_main_monitor
    SCHEDULE sched_check_dwhdb_iq_sys_main START TIME '00:00 AM' EVERY 15 MINUTES
    ENABLE
HANDLER
BEGIN
    DECLARE iq_system_main_used_percentage INT;
    DECLARE logged_datetime TIMESTAMP;
    DECLARE EngineDisableFlag INT;
    DECLARE EngineNoLoadFlag INT;
    DECLARE LOCAL TEMPORARY TABLE temp_dwhdb_usage (
        logged_datetime TIMESTAMP,
        connection_count INT,
        other_versions VARCHAR(50)
    );
    INSERT INTO temp_dwhdb_usage LOCATION 'dwhdb.dwhdb' 'SELECT logged_datetime, connection_count, other_versions FROM show_db_usage()';
    SET iq_system_main_used_percentage =  (select Usage from sp_iqdbspace() where DBSpaceName='IQ_SYSTEM_MAIN');
    SET logged_datetime = (SELECT logged_datetime FROM temp_dwhdb_usage);
    SET EngineDisableFlag=(select setting from sys.sysoptions where "option" like 'EngineDisableFlag');
    SET EngineNoLoadFlag=(select setting from sys.sysoptions where "option" like 'EngineNoLoadFlag');
    IF(EngineDisableFlag =1) THEN
        set option public.EngineDisableFlag=1; 
    ELSE
        set option public.EngineDisableFlag=0;
        set EngineDisableFlag = 0;
    END IF;
    IF(EngineNoLoadFlag =1) THEN
        set option public.EngineNoLoadFlag=1; 
    ELSE
        set option public.EngineNoLoadFlag=0;
        set EngineNoLoadFlag=0;
    END IF;
    IF (iq_system_main_used_percentage < 70.0) THEN
       CALL xp_cmdshell('echo ' || logged_datetime || ' INFO: IQ_SYSTEM_MAIN is Normal. IQ_SYSTEM_MAIN_USED_percentage :' || iq_system_main_used_percentage || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
       IF(EngineDisableFlag>0) THEN
          CALL xp_cmdshell('engine start');
          set option public.EngineDisableFlag=0;
       END IF;
       IF(EngineNoLoadFlag>0) THEN
          CALL xp_cmdshell('engine -e changeProfile Normal');
          set option public.EngineNoLoadFlag=0;
       END IF;
       ALTER EVENT check_iq_system_main_size_panic DISABLE;
       TRIGGER EVENT check_dwhdb_iq_main_monitor;
    END IF;
    IF (iq_system_main_used_percentage >= 70.0 and iq_system_main_used_percentage < 80.0) THEN
       CALL xp_cmdshell('echo ' || logged_datetime || ' WARNING: IQ_SYSTEM_MAIN is getting full. IQ_SYSTEM_MAIN_USED_percentage :' || iq_system_main_used_percentage || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
       IF(EngineDisableFlag>0) THEN
          CALL xp_cmdshell('engine start');
          set option public.EngineDisableFlag=0;
       END IF;
       IF(EngineNoLoadFlag>0) THEN
          CALL xp_cmdshell('engine -e changeProfile Normal');
          set option public.EngineNoLoadFlag=0;
       END IF;
       ALTER EVENT check_iq_system_main_size_panic DISABLE;
       TRIGGER EVENT check_dwhdb_iq_main_monitor;
    END IF;
    IF (iq_system_main_used_percentage >= 80.0 and iq_system_main_used_percentage < 89.0) THEN
       CALL xp_cmdshell('echo ' || logged_datetime || ' WARNING: IQ_SYSTEM_MAIN is almost full,Engine will set to NoLoads profile. IQ_SYSTEM_MAIN_USED_percentage :' || iq_system_main_used_percentage || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
       IF(EngineDisableFlag>0) THEN
          CALL xp_cmdshell('engine start');
          set option public.EngineDisableFlag=0;
       END IF;
       IF(EngineNoLoadFlag<1) THEN
          CALL xp_cmdshell('engine -e changeProfile NoLoads');
          set option public.EngineNoLoadFlag=1;
       END IF;
       ALTER EVENT check_iq_system_main_size_panic ENABLE;
    END IF;
    IF (iq_system_main_used_percentage >= 89.0) THEN
       CALL xp_cmdshell('/usr/bin/echo  ' || logged_datetime || ' INFO: IQ_SYSTEM_MAIN is full !!Stopping engine,IQ_SYSTEM_MAIN_USED_percentage :' || iq_system_main_used_percentage || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
       ALTER EVENT check_iq_system_main_size_panic ENABLE;
       IF(EngineDisableFlag<1) THEN
          CALL xp_cmdshell('engine stop');       
          set option public.EngineDisableFlag=1;
       END IF;
    END IF;                  
END;

CREATE EVENT check_iq_system_main_size_panic
    SCHEDULE sched_check_iq_system_main_size_panic START TIME '00:00 AM' EVERY 1 MINUTES
    DISABLE
HANDLER
BEGIN    
    TRIGGER EVENT check_dwhdb_iq_sys_main_monitor
END;

CREATE EVENT check_dwhdb_iq_main_monitor
    ENABLE
HANDLER
BEGIN
    DECLARE mainspace_used_percentage INT;
    DECLARE conncount UNSIGNED INT;
    DECLARE otherversions VARCHAR(50);
    DECLARE logged_datetime TIMESTAMP;
    DECLARE EngineDisableFlag INT;
    DECLARE EngineNoLoadFlag INT;
    DECLARE LOCAL TEMPORARY TABLE temp_dwhdb_usage (
        logged_datetime TIMESTAMP,
        connection_count INT,
        other_versions VARCHAR(50)
    );
    INSERT INTO temp_dwhdb_usage LOCATION 'dwhdb.dwhdb' 'SELECT logged_datetime, connection_count, other_versions FROM show_db_usage()';
    SET mainspace_used_percentage =  (select Usage from sp_iqdbspace() where DBSpaceName='IQ_MAIN');
    SET EngineDisableFlag=(select setting from sys.sysoptions where "option" like 'EngineDisableFlag');
    SET EngineNoLoadFlag=(select setting from sys.sysoptions where "option" like 'EngineNoLoadFlag');
    IF(EngineDisableFlag =1) THEN
        set option public.EngineDisableFlag=1; 
    ELSE
        set option public.EngineDisableFlag=0;
        set EngineDisableFlag = 0;
    END IF;
    IF(EngineNoLoadFlag =1) THEN
        set option public.EngineNoLoadFlag=1; 
    ELSE
        set option public.EngineNoLoadFlag=0;
        set EngineNoLoadFlag=0;
    END IF;
    SET conncount = (SELECT connection_count FROM temp_dwhdb_usage);
    SET otherversions = (SELECT other_versions FROM temp_dwhdb_usage);
    SET logged_datetime = (SELECT logged_datetime FROM temp_dwhdb_usage);
    IF (mainspace_used_percentage < 85.0) THEN
       CALL xp_cmdshell('echo ' || logged_datetime || ' INFO: IQ_MAIN usage is normal  >> /eniq/log/sw_log/iq/dwhdb_usage.log'); 
       ALTER EVENT check_iq_main_size_panic DISABLE;
    END IF;
    IF (mainspace_used_percentage >= 85.0 and mainspace_used_percentage < 89.0) THEN
       CALL xp_cmdshell('echo ' || logged_datetime || ' WARNING: IQ_MAIN is getting full. MainSpaceUsed: ' || mainspace_used_percentage|| ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
       ALTER EVENT check_iq_main_size_panic DISABLE;
    END IF;
    IF (mainspace_used_percentage >= 90.0 and mainspace_used_percentage < 94.0) THEN
       CALL xp_cmdshell('echo ' || logged_datetime || ' WARNING: IQ_MAIN is almost full, Engine will set to NoLoads profile. MainSpaceUsed: ' || mainspace_used_percentage ||' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
       IF(EngineDisableFlag>0) THEN
          CALL xp_cmdshell('engine start');
          set option public.EngineDisableFlag=0;
       END IF;
       IF(EngineNoLoadFlag<1) THEN
          CALL xp_cmdshell('engine -e changeProfile NoLoads');
          set option public.EngineNoLoadFlag=1;
       END IF;
       ALTER EVENT check_iq_main_size_panic ENABLE;
    END IF;

    IF (mainspace_used_percentage >= 95.0) THEN
       CALL xp_cmdshell('/usr/bin/echo ' || logged_datetime || ' SEVERE: IQ_MAIN is full! Disabling Engine. MainSpaceUsed: ' || mainspace_used_percentage ||' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
       IF(EngineDisableFlag<1) THEN
         CALL xp_cmdshell('engine stop');
          set option public.EngineDisableFlag=1;
       END IF;
       ALTER EVENT check_iq_main_size_panic ENABLE;
    END IF;
END;

CREATE EVENT check_iq_main_size_panic
    SCHEDULE sched_check_iq_main_size_panic START TIME '00:00 AM' EVERY 1 MINUTES
    DISABLE
HANDLER
BEGIN
    TRIGGER EVENT check_dwhdb_iq_sys_main_monitor
END;
