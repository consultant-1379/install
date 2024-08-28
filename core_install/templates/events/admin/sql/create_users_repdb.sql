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

IF (SELECT count(*) FROM sys.SYSUSERAUTH where name = 'etlrep') = 0
BEGIN
  GRANT CONNECT TO etlrep IDENTIFIED BY @@etlrep_passwd@@
  GRANT MEMBERSHIP IN GROUP dcrw TO etlrep
  GRANT RESOURCE TO etlrep
END

IF (SELECT count(*) FROM sys.SYSUSERAUTH where name = 'dwhrep') = 0
BEGIN
  GRANT CONNECT TO dwhrep IDENTIFIED BY @@dwhrep_passwd@@
  GRANT MEMBERSHIP IN GROUP dcrw TO dwhrep
  GRANT RESOURCE TO dwhrep
END
