IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_dwhdb_iq_sys_main_size_normal')>0 THEN
    DROP EVENT check_dwhdb_iq_sys_main_size_normal;
END IF;

IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_iq_system_main_size_panic')>0 THEN
    DROP EVENT check_iq_system_main_size_panic;
END IF;

IF(SELECT COUNT(*) FROM sys.sysevent WHERE event_name = 'check_dwhdb_size_panic')>0 THEN
    DROP EVENT check_dwhdb_size_panic;
END IF;


CREATE EVENT check_dwhdb_iq_sys_main_size_normal
    SCHEDULE sched_check_dwhdb_size_normal START TIME '00:00 AM' EVERY 15 MINUTES
    ENABLE
HANDLER
BEGIN
    DECLARE mainspace_used_percentage INT;
    DECLARE iq_system_main_used_percentage INT;
    DECLARE conncount UNSIGNED INT;
    DECLARE otherversions VARCHAR(50);
    DECLARE logged_datetime TIMESTAMP;
    DECLARE Server_Mode VARCHAR(50);


    DECLARE LOCAL TEMPORARY TABLE temp_dwhdb_usage (
        logged_datetime TIMESTAMP,
        connection_count INT,
        other_versions VARCHAR(50)
    );

    SET Server_Mode = (select [value] from sp_iqstatus() where name like ' Server mode:') ;

    IF ( Server_Mode != 'IQ Multiplex Write Server' ) then

      INSERT INTO temp_dwhdb_usage LOCATION 'dwhdb.dwhdb' 'SELECT logged_datetime, connection_count, other_versions FROM show_db_usage()';


      SET iq_system_main_used_percentage = (select Usage from sp_iqdbspace() where DBSpaceName='IQ_SYSTEM_MAIN');
      SET mainspace_used_percentage =  (select Usage from sp_iqdbspace() where DBSpaceName='IQ_MAIN');
      SET conncount = (SELECT connection_count FROM temp_dwhdb_usage);
      SET otherversions = (SELECT other_versions FROM temp_dwhdb_usage);
      SET logged_datetime = (SELECT logged_datetime FROM temp_dwhdb_usage);



         IF (mainspace_used_percentage >= 85.0) THEN
          CALL xp_cmdshell('echo ' || logged_datetime || ' WARNING: DWHDB is getting full. ConnCount: ' || conncount || ' MainSpaceUsed: ' || mainspace_used_percentage||'% OtherVersions: ' || otherversions || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
         END IF;

         IF (mainspace_used_percentage >= 90.0) THEN
          CALL xp_cmdshell('echo ' || logged_datetime || ' WARNING: DWHDB is almost full, Engine will set to NoLoads profile. ConnCount: ' || conncount || ' MainSpaceUsed: ' || mainspace_used_percentage ||'% OtherVersions: ' || otherversions || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
          CALL xp_cmdshell('engine -e changeProfile NoLoads');
          ALTER EVENT check_dwhdb_size_panic ENABLE;
         END IF;

         IF (mainspace_used_percentage > 85.0 and mainspace_used_percentage < 90.0) THEN
          CALL xp_cmdshell('echo ' || logged_datetime || ' INFO: DWHDB getting normal, resetting Engine status to NORMAL ! ConnCount: ' || conncount || ' MainSpaceUsed: ' || mainspace_used_percentage ||'% OtherVersions: ' || otherversions || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
          ALTER EVENT check_dwhdb_size_panic DISABLE;
          CALL xp_cmdshell('engine start');
         END IF;

         IF (iq_system_main_used_percentage >= 80.0) THEN
         CALL xp_cmdshell('echo ' || logged_datetime || ' WARNING: IQ_SYSTEM_MAIN is getting full. IQ_SYSTEM_MAIN_USED_percentage :' || iq_system_main_used_percentage || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
         END IF;

         IF (iq_system_main_used_percentage >= 85.0) THEN
         CALL xp_cmdshell('echo ' || logged_datetime || ' WARNING: IQ_SYSTEM_MAIN is almost full,Engine will set to NoLoads profile. IQ_SYSTEM_MAIN_USED_percentage :' || iq_system_main_used_percentage || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
         CALL xp_cmdshell('engine -e changeProfile NoLoads');
         ALTER EVENT check_iq_system_main_size_panic ENABLE;
         END IF;

         IF (iq_system_main_used_percentage > 80.0 and iq_system_main_used_percentage < 85.0) THEN
         CALL xp_cmdshell('/usr/bin/echo  ' || logged_datetime || ' INFO: IQ_SYSTEM_MAIN getting normal, resetting Engine status to NORMAL,IQ_SYSTEM_MAIN_USED_percentage :' || iq_system_main_used_percentage || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
         ALTER EVENT check_iq_system_main_size_panic DISABLE;
         CALL xp_cmdshell('engine start');
         END IF;
    END IF;
END;


CREATE EVENT check_iq_system_main_size_panic
    SCHEDULE sched_check_iq_system_main_size_panic START TIME '00:00 AM' EVERY 1 MINUTES
    DISABLE
HANDLER
BEGIN
    DECLARE iq_system_main_used_percentage INT;
    DECLARE logged_datetime TIMESTAMP;
    DECLARE Server_Mode VARCHAR(50);

    SET iq_system_main_used_percentage = (select Usage from sp_iqdbspace() where DBSpaceName='IQ_SYSTEM_MAIN');
    SET logged_datetime = (SELECT logged_datetime FROM show_db_usage());
    SET Server_Mode = (select [value] from sp_iqstatus() where name like ' Server mode:') ;

    IF ( Server_Mode != 'IQ Multiplex Write Server' ) then
       IF (iq_system_main_used_percentage >= 90.0) THEN
          CALL xp_cmdshell('/usr/bin/echo ' || logged_datetime || ' SEVERE: IQ_SYSTEM_MAIN is full,Exceed Threshold value.Disabling Engine. IQ_MAIN_SYSTEM_USED_percentage : ' || iq_system_main_used_percentage ||' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
          CALL xp_cmdshell('engine stop');
       END IF;
   END IF;
END;


CREATE EVENT check_dwhdb_size_panic
    SCHEDULE sched_check_dwhdb_size_panic START TIME '00:00 AM' EVERY 1 MINUTES
    DISABLE
HANDLER
BEGIN
    DECLARE mainspace_used_percentage INT;
    DECLARE conncount UNSIGNED INT;
    DECLARE otherversions VARCHAR(50);
    DECLARE logged_datetime TIMESTAMP;
    DECLARE Server_Mode VARCHAR(50);

    DECLARE LOCAL TEMPORARY TABLE temp_dwhdb_usage (
        logged_datetime TIMESTAMP,
        connection_count INT,
        other_versions VARCHAR(50)
    );

    SET Server_Mode = (select [value] from sp_iqstatus() where name like ' Server mode:') ;

    IF ( Server_Mode != 'IQ Multiplex Write Server' ) then
      INSERT INTO temp_dwhdb_usage LOCATION 'dwhdb.dwhdb' 'SELECT logged_datetime, connection_count, other_versions FROM show_db_usage()';

      SET mainspace_used_percentage = (select Usage from sp_iqdbspace() where DBSpaceName='IQ_MAIN');
      SET conncount = (SELECT connection_count FROM temp_dwhdb_usage);
      SET otherversions = (SELECT other_versions FROM temp_dwhdb_usage);
      SET logged_datetime = (SELECT logged_datetime FROM temp_dwhdb_usage);

      IF (mainspace_used_percentage >= 95.0) THEN
        CALL xp_cmdshell('/usr/bin/echo ' || logged_datetime || ' SEVERE: DWHDB is full! Disabling Engine. ConnCount: ' || conncount || ' MainSpaceUsed: ' || mainspace_used_percentage ||'% OtherVersions: ' || otherversions || ' >> /eniq/log/sw_log/iq/dwhdb_usage.log');
        CALL xp_cmdshell('engine stop');
      END IF;
    END IF;
END;

