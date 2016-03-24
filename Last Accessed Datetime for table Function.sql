/*
This function is used to get the complete table lists are particular table and its last access datetime.
The last access may be the select/insert/update/delete.
*/
create function fn_get_when_table_lastaccessed
(@TableName varchar(max))
returns  @returntable table (TableName varchar(max),LastAccessed datetime)
as
begin

if @TableName = '*'
	set @TableName = ''

set @TableName = nullif(@TableName,'')

;with cte as
(
select SCHEMA_NAME(B.schema_id) +'.'+object_name(b.object_id) as tbl_name,
(select MAX(last_accessed) from (values (last_user_seek),(last_user_scan),(last_user_lookup)) as tvc(last_accessed)) as last_accessed_datetime FROM sys.dm_db_index_usage_stats a
right outer join sys.tables b on a.object_id =  b.object_id
where b.name = isnull(@TableName, b.name)
)
Insert into @returntable
select tbl_name,max(last_accessed_datetime) as last_accessed_datetime  from cte 
group by tbl_name
order by last_accessed_datetime desc , 1

return;

end 
GO

--complete table list
select * from dbo.fn_get_when_table_lastaccessed('*')
--particular table
select * from dbo.fn_get_when_table_lastaccessed('usermaster')