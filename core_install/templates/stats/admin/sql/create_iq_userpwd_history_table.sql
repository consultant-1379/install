if (object_id('dba.IQ_UserPwd_History') is not null)  then
    
    if (COL_LENGTH('dba.IQ_UserPwd_History','password') <= 30) then
        alter table dba.IQ_UserPwd_History modify password varchar(180);
        message '<<< Modified column length in dba.IQ_UserPwd_History  >>>' type   info to client ;
    end if;
    
    if (COL_LENGTH('dba.IQ_UserPwd_History','password_encrypted') is null) then
        alter table dba.IQ_UserPwd_History
        add password_encrypted varchar(5) default 'N';
        message '<<< dba.IQ_UserPwd_History updated with new column  >>>' type   info to client ;
    else
        message '<<< dba.IQ_UserPwd_History already exists therefore skipping dba.IQ_UserPwd_History table creation >>>' type   info to client ;	
    end if;

end if;

if (object_id('dba.IQ_UserPwd_History') is null)   then
    create table dba.IQ_UserPwd_History(
        user_name varchar(20),
        password varchar(180),
        password_creation_time timestamp,
        password_encrypted varchar(5) default 'N'
        );


    if (object_id('dba.IQ_UserPwd_History') is null) then
        message '<<< FAILED to create table dba.IQ_UserPwd_History >>>' type   info to client ;
    else
        message '<<< Created table dba.IQ_UserPwd_History >>>' type info to client   ;
    end if ;
end if ;
