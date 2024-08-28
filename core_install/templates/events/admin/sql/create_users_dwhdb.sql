IF (SELECT count(*) FROM sys.SYSUSERAUTH where name = 'dcro') = 0
BEGIN
  GRANT CONNECT TO dcro
  GRANT GROUP TO dcro
END

IF (SELECT count(*) FROM sys.SYSUSERAUTH where name = 'dcrw') = 0
BEGIN
  GRANT CONNECT TO dcrw
  GRANT GROUP TO dcrw
END

IF (SELECT count(*) FROM sys.SYSUSERAUTH where name = 'dc') = 0
BEGIN
  GRANT CONNECT TO dc IDENTIFIED BY '@@dc_passwd@@'
  GRANT RESOURCE TO dc
  GRANT CREATE ON IQ_MAIN TO dc
  GRANT MEMBERSHIP IN GROUP dcrw TO dc
  GRANT EXECUTE on sp_iqindexmetadata to dc
END

IF (SELECT count(*) FROM sys.SYSUSERAUTH where name = 'dcbo') = 0
BEGIN
  GRANT CONNECT TO dcbo IDENTIFIED BY '@@dcbo_passwd@@'
  GRANT MEMBERSHIP IN GROUP dcro TO dcbo
END

IF (SELECT count(*) FROM sys.SYSUSERAUTH where name = 'dcpublic') = 0
BEGIN
  GRANT CONNECT TO dcpublic IDENTIFIED BY '@@dcpublic_passwd@@'
END
