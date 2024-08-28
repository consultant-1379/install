
CREATE OR REPLACE PROCEDURE  sp_iqlocklogin( 
	in @user_name varchar(20), 
	in @lock_state varchar(20) )
  
begin 
 
--creating locked_users login policy if it does not exist

IF not EXISTS (SELECT o.login_policy_id, P.login_policy_name, o.login_option_name, o.login_option_value 
				FROM SYS.SYSLOGINPOLICYOPTION o, SYS.SYSLOGINPOLICY p
				WHERE o.login_policy_id = p.login_policy_id AND p.login_policy_name != 'root' AND p.login_policy_name like 'locked_users')
THEN
	create LOGIN POLICY locked_users locked=on; 
END IF;

--creating unlocked_users login policy if it does not exist

IF  not EXISTS (SELECT o.login_policy_id, P.login_policy_name, o.login_option_name, o.login_option_value 
				FROM SYS.SYSLOGINPOLICYOPTION o, SYS.SYSLOGINPOLICY p
				WHERE o.login_policy_id = p.login_policy_id AND p.login_policy_name != 'root' AND p.login_policy_name like 'unlocked_users')
THEN
	create LOGIN POLICY unlocked_users locked=off
END IF;
 
 
 
-- Locking user name provided
IF @lock_state = 'lock' THEN 
	execute immediate with quotes on 'ALTER USER '  ||@user_name||'  LOGIN POLICY locked_users'  
END IF; 
	
	
-- Unlocking user name provided
IF @lock_state = 'unlock' THEN 
	execute immediate with quotes on 'ALTER USER '||@user_name||' LOGIN POLICY unlocked_users' 
END IF;

END 
GO

