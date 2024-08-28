set option public.Allow_nulls_by_default = 'On';
set option public.Divide_by_zero_error = 'Off';
set option public.Chained = 'Off';
set option public.First_day_of_week = 1;
set option public.Auto_commit = 'On';
set option public.Default_Disk_Striping = 'On';
set option public.Date_First_Day_Of_Week = 1;
set option public.Force_No_Scroll_Cursors = 'On';
set option public.Query_Temp_Space_Limit = 0 ;
set option public.Conversion_error='Off';
set option public.Minimize_storage='On';
set option public.temp_reserved_dbspace_mb = 300 ;
set option public.main_reserved_dbspace_mb = 300 ;
set option public.default_dbspace = 'IQ_MAIN' ;
set option PUBLIC.Query_Plan = 'OFF' ;
set option public.mpx_max_unused_pool_size = @@max_unused@@ ;
set option public.mpx_max_connection_pool_size = @@max_connection@@ ;
set option public.Max_Hash_Rows = @@max_hash_rows@@ ;
set option public.IQ_SYSTEM_MAIN_RECOVERY_THRESHOLD=10;

--setting the password min length to 2
set option public.MIN_PASSWORD_LENGTH = 2;

--turning off 15.2 compatibility
set option public.CREATE_HG_WITH_EXACT_DISTINCTS='OFF';
set option public.Revert_To_V15_Optimizer='OFF';
set option public.FP_NBIT_IQ15_Compatibility='OFF'; 

---WA for EQEV-23015
set option public.Sort_Pinnable_Cache_Percent = 10;
set option public.Hash_Pinnable_Cache_Percent = 10;

---WA for EQEV-20368
set option public.dml_options14=8;
set option public.Core_Options14=256;

--setting timeout for GTR 
set option public.MPX_LIVENESS_TIMEOUT=300;

---WA for IQ incident 506779
set option public.Core_Options71 = 0;

---WA for incident 515304 (TR89268) 
set option public.FP_NBIT_Autosize_Limit=2097152;

--setting grant to dc for stored procedures
IF (SELECT count(*) FROM sys.SYSUSER where user_name = 'dc') = 1
BEGIN
    GRANT EXECUTE on sp_iqindexmetadata to dc
END;

--EQEV-26055 Setting 1MB per thread memory 
set option public.CORE_Options97=1; 

--Adding step to ensure failover is set on multiplex
IF (select count(*) from sp_iqmpxinfo() where server_name like 'dwh_reader_1' and coordinator_failover  not like 'dwh_reader_1') = 1
BEGIN
   ALTER MULTIPLEX SERVER dwh_reader_1 ASSIGN AS FAILOVER SERVER
END;

