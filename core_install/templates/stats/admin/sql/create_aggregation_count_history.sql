if (object_id('dba.Aggregation_Count_History') is null)   then
    create table dba.Aggregation_Count_History(
        db_object varchar(150),
        counter_name varchar(200),
        counter_count int,
        access_date date,
        feature_name varchar(300)
        );


    if (object_id('dba.Aggregation_Count_History') is null) then
        message '<<< FAILED to create table dba.Aggregation_Count_History >>>' type   info to client ;
    else
        message '<<< Created table dba.Aggregation_Count_History >>>' type info to client   ;
    end if ;
end if ;

