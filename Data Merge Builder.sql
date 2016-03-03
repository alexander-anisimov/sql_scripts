/*
USEAGE:

exec dbo.sp_DataMergeBuilder
    @table   = 'schema.TableName'  -- 
,   @includeData = 1 -- use 0 for a simple listing of all columns with a null
,   @whereClause = ''  --  add a where clause in case you want to filter the table data
*/

use master;
go
if object_id('dbo.sp_DataMergeBuilder','P') is null
	exec sys.sp_executesql N'create proc dbo.sp_DataMergeBuilder as return 0;'
go
alter procedure dbo.sp_DataMergeBuilder
	@table			sysname
,	@includeData	bit				= 0
,	@whereClauseô	nvarchar(1000)	= ''
as
/*
————————————————————————————————————————————————————————————————————————————————————————————————————
							© 2000-15 · NightOwl Development · All rights Reserved
————————————————————————————————————————————————————————————————————————————————————————————————————
Purpose	:	Generates bolier plate merge statement for use in creating a generic merge statement.
Returns	:	merge script for the specified table
Notes	:	this is a work in progress
History	:
   Date		Developer		Work Item		Modification
——————————	——————————————	——————————	————————————————————————————————————————————————————————————
2011-12-30	P. Hunter		0			Object created.
————————————————————————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@baseName	sysname
,	@cmd		nvarchar(max)	= ''
,	@crlf		char(2)			= char(13) + char(10)
,	@data		nvarchar(max)	= ''
,	@dbName		sysname			= db_name()
,	@errMsg		nvarchar(1000)
,	@hasIdent	bit				= 0
,	@maxColumn	int
,	@objectId	int
,	@propName	sysname
,	@rows		int
,	@tab		char(1)			= char(9)
,	@userName	sysname			= '''' + suser_sname() + ''''
,	@xml		xml
;

set @cmd = 'use ' + @dbName + ';
select	@objectId	= object_id
	,	@baseName	= t.name
	,	@propName	= schema_name(t.schema_id) + ''.'' + t.name
	,	@maxColumn	= t.max_column_id_used
	,	@hasIdent	= (select count(1) from sys.identity_columns ic where ic.object_id = t.object_id)
from	sys.tables t
where	t.object_id = object_id(@table);';

exec sys.sp_executesql
			@cmd
		,	N'@objectId int out, @basename sysname out, @propName sysname out, @maxColumn int out, @table sysname, @hasIdent bit out'
		,	@objectId out, @baseName out, @propName out, @maxColumn out, @table, @hasIdent out;

if @objectId is null
begin
	set @errMsg = 'The table name "' + isnull(@table, 'nothing provided') + '" could not be located in the ' + @dbName + 'database.';
	raiserror(@errMsg, 15, 1);
end;

create table #excludeColumns
(	name sysname primary key
,	defaultValue sysname
);
insert	#excludeColumns ( name, defaultValue )
values	( 'CreatedBy'	, @userName)
	,	( 'CreatedDate' , 'getdate()')
	,	( 'CreatedOn'	, 'getdate()')
	,	( 'ModifiedBy'	, @userName)
	,	( 'ModifiedDate', 'getdate()')
	,	( 'ModifiedOn'	, 'getdate()')
	,	( 'UpdatedBy'	, @userName)
	,	( 'UpdatedDate' , 'getdate()')
	,	( 'UpdatedOn'	, 'getdate()')
	;

create table #columns
(	column_id	smallint primary key
,	name		sysname
,	isIdentity	bit
,	isNullable	bit
,	isExcluded	bit
,	tabs		tinyint
,	remdr		tinyint
,	minId		smallint
,	maxId		smallint
,	lastMerge	smallint
,	maxTabs		tinyint
,	typeName	sysname
,	definition	nvarchar(max)
);

set @cmd = 'use ' + @dbName + ';
insert	#columns
select	s.column_id
	,	s.name
	,	s.is_identity
	,	s.is_nullable
	,	isExcluded	= case s.name when x.name then 1 else 0 end
	,	tabs		= (a.maxTabs - ((len(s.name)) / 4))
	,	remdr		= (len(s.name) % 4)
	,	a.minId
	,	a.maxId
	,	a.lastMerge
	,	a.maxTabs
	,	typeName	= t.name
	,	definition	= case left(d.definition, 2)
						when ''(('' then replace(replace(d.definition, ''(('', ''''), ''))'', '''')
						else replace(substring(definition, 2, len(d.definition) - 2), ''(1)'', ''1'')
					  end
from	sys.columns		s
join	sys.types		t
		on	s.user_type_id	 = t.user_type_id
		and	s.system_type_id = t.system_type_id
		and	t.name	not like ''%binary''
left
join	#excludeColumns x
		on	x.name = s.name
left
join	sys.default_constraints d
		on	d.parent_object_id = s.object_id
		and	d.parent_column_id = s.column_id
outer
apply(	select	minId		= min(c.column_id)
			,	maxId		= max(c.column_id)
			,	lastMerge	= max(case c.name when ec.name then 0 else c.column_id end)
			,	maxTabs		= max(len(c.name) + 4) / 4
		from	sys.columns c
		left
		join	#excludeColumns ec
				on	ec.name = c.name
		where	c.object_id		= s.object_id
		and		c.is_computed	= 0
	)	a
where	s.object_id		= @objectId
and		s.is_computed	= 0';

exec sys.sp_executesql @cmd, N'@objectId int', @objectId;

--	build the join criteria to prefer a "natural" unique key over a surogate key (identity) where available
create table #join
(	script	nvarchar(max)
,	rowId	int identity primary key		
);

set @cmd = 'use ' + @dbName + ';
insert	#join ( script )
select	script	= case i.key_ordinal
					when 1 then ''		on	tgt.''
					else ''		and	tgt.''
				  end + c.name + replicate(@tab, c.tabs) + ''= src.'' + c.name
from	#columns	c
join(	select	joinOn	= rank() over (order by i.index_id)
			,	ic.*
		from	sys.index_columns ic
		join	sys.indexes i
				on	i.object_id = ic.object_id
				and	i.index_id	= ic.index_id
				and	i.is_unique	= 1
		where	ic.object_id = @objectId
	) i	on	i.column_id = c.column_id
		and	i.joinOn	= 1;';

exec sys.sp_executesql @cmd, N'@objectId int, @tab char(1)', @objectId, @tab;

--	they want to include data, this checks to see if there is data to extract...
if @includeData = 1
begin
	set @cmd = 'select top 1 @includeData = count(1) from ' + @dbName + '.' + @propName
	exec sys.sp_executesql @cmd, N'@includeData bit out', @includeData out;
end;

create table #cteData
(	script	nvarchar(max)
,	id	int identity primary key
);

/*
**	extract the data for the table - OR - create a stub of the columns to be used...
*/
--	first, define the cte with column names
insert	#cteData ( script )
select	case c.column_id
			when m.minId
				then 'with cte_' + @baseName + @crlf + @tab + '(' + @tab + c.name
			else @tab + ',' + @tab + c.name
				+ case c.column_id when m.maxId then @crlf + @tab + ')' + @crlf + '  as' + @crlf + '(' else '' end
		end
from	#columns	c
cross
apply(	select	minId = min(c.column_id)
			,	maxId = max(c.column_id)
		from	#columns c
		where	c.name not in (select name from #excludeColumns)
	)	m
left
join	#excludeColumns	x
		on x.name = c.name
where	x.name is null
order by c.column_id;

if @includeData = 1
begin
	--	now extract the data for the table...
	set @cmd = '';

	--	build a dynamic query that builds the extract command
	select	@cmd	= @cmd
					+ case c.column_id when 1
						then @crlf + 'select	script = ''	select '' + replace(replace('
						else ' + '', '' + '
					  end + 'isnull('
					+ case
						when c.typeName		like '%char'	then '''#|#'' + ' + c.name + ' + ''#|#'''
						when c.typeName		like '%date%'
							or c.typeName	like '%time%'	then '''#|#'' + convert(varchar(50), ' + c.name + ', 121) + ''#|#'''
						when c.typeName		like '%int'
							or c.typeName	like 'bit' 
							or c.typeName	like 'dec%' 
							or c.typeName	like 'num%' 
							or c.typeName	like 'flo%' 
							or c.typeName	like 'rea%'		then 'convert(varchar(50), ' + c.name + ')'
						else c.name
					  end
					+ ', ''null'')'
	from	#columns	c
	cross
	apply(	select	minId = min(c.column_id)
				,	maxId = max(c.column_id)
			from	#columns c
			where	c.name not in (select name from #excludeColumns)
		)	m
	left
	join	#excludeColumns	x
			on x.name = c.name
	where	x.name is null
	order by c.column_id;

	set	@cmd = @cmd + ', '''''''' ,'''''''''''' ), ''#|#'','''''''') + ''' + @crlf + @tab + @tab + 'union all'''

	set @cmd = 'use ' + @dbName + ';' + @crlf
			 + 'insert	#cteData ( script )' + @cmd + @crlf
			 + 'from	' + @propName + @crlf
			 + case when @whereClause > '' then @whereClause + + @crlf else '' end
			 + 'order by ' + (select top 1 name from #columns order by isIdentity desc, column_id) + ';'

	--	execute the resulting query
	exec sys.sp_executesql @cmd;

	set @rows = @@rowcount;

	update	#cteData
	set		script = replace(script, @tab + @tab + 'union all', ')')
	where	Id = (select max(id) from #cteData);
end;

if @includeData = 0		--	build a stub select statement or...
or @rows = 0			--	no rows generated from the data
begin
	--	either there's no data to include or the data isn't suppoed to be included
	set @includeData = 0;

	--	create a stub for each column 
	insert	#cteData ( script )
	select	script	= case c.column_id
						when m.minId
							then '	select'
						else '		,'
						end + @tab + c.name + replicate(@tab, c.tabs) + '= null'
					+ case c.column_id when m.maxId then @crlf + ')' else '' end
	from	#columns	c
	cross
	apply(	select	minId = min(c.column_id)
				,	maxId = max(c.column_id)
			from	#columns c
			where	c.name not in (select name from #excludeColumns)
		)	m
	left
	join	#excludeColumns	x
			on x.name = c.name
	where	x.name is null
	order by c.column_id;
end;

/*
**	begin building the output script...
*/
create table #output
(	script	nvarchar(max)
,	rowId	int identity primary key		
);

if @hasIdent = 1
begin
	insert	#output	(	script	)
	select	script	= '--	This table has an identity column so preserve those number on insert'
	union all
	select	script	= 'set identity_insert ' + @propName + ' on;' + @crlf + 'go';
end;

--	setup the stub cte that will hold the data to be merged
insert	#output	(	script	)
select	script	= '--	create cte containing the source data to be merged into the target table...';

--	provide the cteData data or "fake data"
insert	#output	(	script	)
select	script
from	#cteData
order by Id;

--	create top half of except clause to get the differences between the cte and target table
insert	#output	(	script	)
select	script	= '--	using an EXCEPT statement generates the true diferences between the cte source and the target table you want to merge into...';

--	create top half of except clause to get the differences between the cte and target table
insert	#output	(	script	)
select	script	= case c.column_id
					when c.minId
						then 'merge	' + @propName + '	tgt' + @crlf
							+ 'using(	select'
						else replicate(@tab, 3) + ','
				  end + @tab + c.name
				+ case c.column_id
					when c.lastMerge
						then @crlf + '		from	cte_'+ @baseName + @crlf
							+ case @includeData
								when 0 then '		where	' + (select top 1 name from #columns c
																 order by c.isIdentity desc, c.column_id) + ' is not null' + @crlf
								else ''
							  end
							+ '			EXCEPT	--	return only true differences'
					else '' end
from	#columns c
where	c.isExcluded = 0;

--	create bottom half of except clause to get the differences between the cte and target table
insert	#output	(	script	)
select	script	= case c.column_id
					when c.minId
						then '		select'
						else replicate(@tab, 3) + ','
				  end + @tab + c.name
				+ case c.column_id
					when c.lastMerge
						then @crlf + '		from	'+ @propName + @crlf
							+ '	)	src'
					else '' end
from	#columns c
where	c.isExcluded = 0;

--	add the join criteria
insert	#output	(	script	)
select	script
from	#join j;


--	create the update portion
insert	#output	(	script	)
select	script	= case c.column_id
					when b.minId
						then 'when	matched' + @crlf
							+ 'then	update' + @crlf
							+ '		set	'
					else replicate(@tab, 3) + ','
				  end + @tab + c.name + replicate(@tab, c.tabs) + '= '
				+ case c.name
					when x.name then x.defaultValue
					else 'src.' + c.name
				  end
from	#columns c
cross
join(	select	minId = min(column_id)
			,	maxId = max(column_id)
		from	#columns m
		where	m.name		 not like 'Created[BD][ya]%'
		and		m.isIdentity = 0 ) b
left
join	#excludeColumns x
		on	x.name = c.name
where	c.name		 not like 'Created[BD][ya]%'
and		c.isIdentity = 0
order by c.column_id;

--	create the top part of the insert
insert	#output	(	script	)
select	script	= case c.column_id
					when c.minId
						then 'when	not matched' + @crlf
							+ 'then	insert' + @crlf
							+ '			('
					else replicate(@tab, 3) + ','
				  end + @tab + c.name
				+ case c.column_id when c.maxId then @crlf + '			)' else '' end
from	#columns c
left
join	#excludeColumns x
		on	x.name = c.name
order by c.column_id;

--	create the bottom/values part of the insert
insert	#output	(	script	)
select	script	= case c.column_id
					when c.minId
						then '		values' + @crlf
							+ '			('
					else replicate(@tab, 3) + ','
				  end + @tab
				+ case
					when c.name = x.name
						then x.defaultValue + '	--	'  + c.name
					when c.definition > ''
						then 'isnull(src.' + c.name + ', ' + c.definition + ')' 
					else 'src.' + c.name end
				+ case c.column_id when c.maxId then @crlf + '			);' else '' end
from	#columns c
left
join	#excludeColumns x
		on	x.name = c.name
order by c.column_id;

--	complete the script with a batch separator
insert	#output	(	script	) values ( 'go' );

if @hasIdent = 1
begin
	insert	#output	(	script	)
	select	script	= '--	reset the identity engine and reseed the identity value'
	union all
	select	script	= 'set identity_insert ' + @propName + ' off;' + @crlf + 'go'
	union all
	select	script	= 'dbcc checkident(''' + @propName + ''', reseed);' + @crlf + 'go' + @crlf;
end;

--	return the results
select script from #output o order by o.rowId;
go
