if (object_id('dbo.rebuild_idx') is not   null)   then
    drop    procedure dbo.rebuild_idx ;

    if (object_id('dbo.rebuild_idx') is not null) then
        message '<<< FAILED to drop procedure dbo.rebuild_idx >>>' type   info to client ;
    else
        message '<<< Dropped procedure dbo.rebuild_idx >>>' type info to client   ;
    end if ;
end if ;

create procedure dbo.rebuild_idx( in @tablename varchar(257) )
begin
    declare @iname  varchar(128) ;
    declare @itype  varchar(20)  ;
    declare @fqtn   varchar(257) ; -- fully qualified table name
    declare @qt_fqtn    varchar(259) ; -- quoted fully qualified table name
    declare @qt_idxcl   varchar(143) ; -- quoted re-tier index clause
    declare @towner varchar(128) ; -- table owner
    declare @tname  varchar(128) ; -- table name
    declare @cname  varchar(128) ; -- column name
    declare @sql        clob         ;
    declare @tid        bigint       ; -- table_id
    declare @sc     integer      ; -- SQLCODE var
    declare @rebuild   varchar(10); -- Rebuild flag
	declare @temp  varchar(128);  -- temp table name holder
	declare @has_nonTieredHG varchar(128); 
	declare @is_tiered	char(1);
	declare @tier_before	char(1);
	declare @tier_after	char(1);
	declare @rowcount	bigint;	
   
    if (    charindex(',', @tablename) = 0 ) then
       if (    charindex('.', @tablename) = 0 ) then
			set @towner = user_name();
			set @tname  = @tablename;
			set @rebuild = 'N';
		else
			set @towner = substring( @tablename, 1, charindex('.', @tablename)-1);
			set @tname  = substring( @tablename, charindex('.', @tablename)+1);
			set @rebuild = 'N';
		end if ;
    else
        if (    charindex('.', @tablename) = 0 ) then
			set @towner = user_name()   ;
			set @tname = substring( @tablename, 1, charindex(',', @tablename)-1);
			set @rebuild  = substring( @tablename, charindex(',', @tablename)+1);
		else
			set @towner = substring( @tablename, 1, charindex('.', @tablename)-1);
			set @temp  = substring( @tablename,charindex('.', @tablename)+1);
			set @tname = substring( @temp,1 , charindex(',', @temp)-1);
			set @rebuild =  RTRIM(LTRIM(substring( @temp,  charindex(',', @temp)+1)));
		end if ;
    end if ;
	
	set @fqtn = @towner || '.' || @tname ;
    set @qt_fqtn = char(39) ||  @fqtn || char(39) ;

    if ( object_id( @fqtn ) is null ) then
        message 'ERROR - ' || @fqtn || ' does not   exist.' type info to client ;
        message 'Usage: rebuild_idx <owner.table>' type info to client ;
        return 1 ;
    end if ;
    
	set @has_nonTieredHG = (SELECT Value2 FROM sp_iqindexmetadata((SELECT top 1 index_name FROM sys.sysindex WHERE index_name LIKE @tname||'%_HG'), @tname, @towner) WHERE Value1 = 'Maintains Exact Distinct');
	commit;
    
    if ( (upper(@has_nonTieredHG) = 'NO') and (upper(@rebuild) <> 'REBUILD')  ) then
		message 'Table: ' || @towner || '.' || @tname || ' has tiered HGs skipping rebuild_idx.' type info to client ;
		message 'Table: ' || @towner || '.' || @tname || ' has tiered HGs skipping rebuild_idx.' type info to log ;
	else
		message 'Stating rebuild_idx on Table: ' || @towner || '.' || @tname || '.' type info to client ;
		message 'Stating rebuild_idx on Table: ' || @towner || '.' || @tname || '.' type info to log ;
		
		set @tid = (select table_id from sys.systable where table_name = @tname and user_name(creator) = @towner);

		execute immediate 'set @rowcount = (select count(*) from ' || @fqtn || ')' ;

		for loop1 as	curs1 cursor for
			select index_name, index_type from sys.sysindex where table_id =	@tid
		do
			set @iname    = index_name ;
			set @itype    = index_type ;
			
			
			if ( @itype = 'HG' ) then
				set @is_tiered	= (select (case	when substring(Value2,1,1) = 'N' then 'Y' else 'N' end) from sp_iqindexmetadata( @iname, @tname, @towner ) where Value1 = 'Maintains Exact Distinct') ;

				set @tier_before = @is_tiered ; // save the 'before' state

				if ( @is_tiered = 'N' ) then
					set	@qt_idxcl = char(39) ||	'index ' || @iname || '	retier'	|| char(39) ;  // Not tiered HG, then retier!
				else
					set	@qt_idxcl = char(39) ||	'index ' || @iname || char(39) ;	       // else normal rebuild HG index
				end if	;  // end if tiered = 'N'
			else
				set	@qt_idxcl = char(39) ||	'index ' || @iname || char(39) ;	       // else normal rebuild non-HG index
			end if ;	// end if HG

			set @sql = 'sp_iqrebuildindex ' || @qt_fqtn || ',	' || @qt_idxcl ;

			execute immediate	@sql ;		     //	go do it!
			set @sc =	SQLCODE	;

			if ( @sc <> 0 ) then
				message 'ERROR - SQLCODE from execute was: ' || @sc type info to log ;
				message 'ERROR - SQLCODE from execute was: ' || @sc type info to client ;
				message 'SQL was: ' ||	@sql type info to log ;
				message 'SQL was: ' ||	@sql type info to client ;
			end if ;	// end if @sc <> 0

			set @is_tiered = (select (case when substring(Value2,1,1)	= 'N' then 'Y '	else 'N' end) from sp_iqindexmetadata( @iname, @tname, @towner ) where Value1 =	'Maintains Exact Distinct') ;

			set @tier_after =	@is_tiered ;  // save the 'after' state

			if ( @itype = 'HG' ) then
				if ( @tier_before <> @tier_after ) then
					message 'HG index '	|| @fqtn || '.'	|| @iname || ' CHANGED to tiered-HG' type info to log ;
					message 'HG index '	|| @fqtn || '.'	|| @iname || ' CHANGED to tiered-HG' type info to client ;
				else
					if ( @tier_before =	'N' and	@rowcount > 0 )	then  // cannot	convert	un-tiered to tiered HG if rowcount is non-zero.
						message 'WARNING - Unable to convert un-tiered HG index ' || @fqtn || '.' || @iname || '	to tiered HG because rowcount >	0 (' ||	@rowcount || ')' type info to log ;
						message 'WARNING - Unable to convert un-tiered HG index ' || @fqtn || '.' || @iname || '	to tiered HG because rowcount >	0 (' ||	@rowcount || ')' type info to client ;
					end	if ;  // end if	un-tiered and rowcount > 0
				end if	;  // end if before <> after
			end if ;	// end if itype	= HG

	   end for ;  // end for sys.sysindex loop
	   
	   	message 'Finished rebuild_idx on Table: ' || @towner || '.' || @tname || '.' type info to client ;
		message 'Finished rebuild_idx on Table: ' || @towner || '.' || @tname || '.' type info to log ;
	end if; // end if rebuild flag & has tiered
end ;

commit ;

if (object_id('dbo.rebuild_idx') is not   null)   then
   message '<<< Created procedure dbo.rebuild_idx >>>' type info to client ;
   grant execute on dbo.rebuild_idx to public ;
else
   message '<<< FAILED to create procedure dbo.rebuild_idx >>>'   type info to client ;
end if ;
