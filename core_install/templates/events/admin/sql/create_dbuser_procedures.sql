IF(SELECT COUNT(*) FROM sys.sysprocedure WHERE proc_name = 'lock_user')>0 THEN
    DROP PROCEDURE lock_user;
END IF;

IF(SELECT COUNT(*) FROM sys.sysprocedure WHERE proc_name = 'unlock_user')>0 THEN
    DROP PROCEDURE unlock_user;
END IF;

IF(SELECT COUNT(*) FROM sys.sysprocedure WHERE proc_name = 'drop_user_connections')>0 THEN
    DROP PROCEDURE drop_user_connections;
END IF;

IF(SELECT COUNT(*) FROM sys.sysprocedure WHERE proc_name = 'drop_all_except_user_connections')>0 THEN
    DROP PROCEDURE drop_all_except_user_connections;
END IF;

IF(SELECT COUNT(*) FROM sys.sysprocedure WHERE proc_name = 'drop_all_connections')>0 THEN
    DROP PROCEDURE drop_all_connections;
END IF;

CREATE PROCEDURE lock_user( IN dbuser VARCHAR(50))
    RESULT ( msg varchar(255) )
    ON EXCEPTION RESUME
BEGIN
	CALL sp_iqlocklogin (dbuser,'lock');
	SELECT 'User ' || dbuser || ' locked at ' || DATEFORMAT(NOW(), 'yyyy-mm-dd hh:nn:ss') as msg;
END;


CREATE PROCEDURE unlock_user( IN dbuser VARCHAR(50) )
	RESULT ( msg varchar(255) )
	ON EXCEPTION RESUME
BEGIN
	CALL sp_iqlocklogin(dbuser,'unlock');
	SELECT 'User ' || dbuser || ' unlocked at ' || DATEFORMAT(NOW(), 'yyyy-mm-dd hh:nn:ss') as msg;
END;


CREATE PROCEDURE drop_user_connections( IN dbuser VARCHAR(50))
    RESULT ( msg varchar(32000) )
    ON EXCEPTION RESUME
BEGIN

	declare local temporary table msgTable (
		msg	varchar(32000)	not null
	) in SYSTEM on commit preserve rows;

    
    for loop1 as cursor1 cursor for
        select ConnHandle from sp_iqconnection() where Userid = dbuser
    do
	    execute immediate 'drop connection ' || ConnHandle;
	    INSERT INTO msgTable select 'User ' || dbuser || ' connection with ConnHandle ' || ConnHandle || ' dropped at ' || DATEFORMAT(NOW(), 'yyyy-mm-dd hh:nn:ss');
	end for;
	
	select * from msgTable as msg;
END;

CREATE PROCEDURE drop_all_except_user_connections( IN dbuser VARCHAR(50))
    RESULT ( msg varchar(32000) )
    ON EXCEPTION RESUME
BEGIN
	declare local temporary table msgTable2 (
		msg	varchar(32000)	not null
	) in SYSTEM on commit preserve rows;

    
    for loop2 as cursor2 cursor for
        select ConnHandle, Userid from sp_iqconnection() where Userid != dbuser
    do
	    execute immediate 'drop connection ' || ConnHandle;
	    insert into msgTable2 select 'User ' || Userid || ' connection with ConnHandle ' || ConnHandle || ' dropped at ' || DATEFORMAT(NOW(), 'yyyy-mm-dd hh:nn:ss');
	end for;
	
	select * from msgTable2 as msg;
END;


CREATE PROCEDURE drop_all_connections()
    RESULT ( msg varchar(32000) )
    ON EXCEPTION RESUME
BEGIN

	declare local temporary table msgTable3 (
		msg	varchar(32000)	not null
	) in SYSTEM on commit preserve rows;

    
    for loop3 as cursor3 cursor for
        select ConnHandle, Userid from sp_iqconnection() order by ConnCreateTime
    do
	    execute immediate 'drop connection ' || ConnHandle;
	    insert into msgTable3 select 'User ' || Userid || ' connection with ConnHandle ' || ConnHandle || ' dropped at ' || DATEFORMAT(NOW(), 'yyyy-mm-dd hh:nn:ss');
	end for;
	
	select * from msgTable3 as msg;
END;

