/*
--Examples
select * from dbo.fn_get_unused_procedure_noofdaysago(0)
where ProcedureName = 'Your Procedure Name'

--Other Examples
--Complete lists
select * from dbo.fn_get_unused_procedure_noofdaysago(0)
--Procedure doesn't used for more than or equals to last 7 days
select * from dbo.fn_get_unused_procedure_noofdaysago(7)
--Procedure doesn't used for more than or equals to last 30 days
select * from dbo.fn_get_unused_procedure_noofdaysago(30)
--Procedure doesn't used for more than or equals to last 100 days
select * from dbo.fn_get_unused_procedure_noofdaysago(100)
--Procedure doesn't used for more than or equals to last 180 days (approx 6 months)
select * from dbo.fn_get_unused_procedure_noofdaysago(180)
--Procedure doesn't used for more than or equals to last 365 days (approx 1 year)
select * from dbo.fn_get_unused_procedure_noofdaysago(365)
*/



create function fn_get_unused_procedure_noofdaysago
(@lastaccessed_daysago int = 0)
returns @returntable table(ProcedureId int,ProcedureName varchar(max),LastExecutionTime datetime,ExecutionCount int,LastExecutedDaysAgo int)
as
begin

;with getprocaccessedlists
as
(
select ISNULL(deps.database_id,-1) database_id,p.object_id,p.name
,ISNULL(deps.type,'P') type,ISNULL(deps.type_desc,'SQL_STORED_PROCEDURE') type_desc
,ISNULL(deps.last_execution_time,'1900-01-01') last_execution_time,ISNULL(deps.execution_count,-1) execution_count
,p.create_date,p.modify_date  
from sys.dm_exec_procedure_stats deps
	right outer join sys.procedures p on deps.object_id = p.object_id
)
Insert Into @returntable
select object_id ,name ,last_execution_time,execution_count,datediff(dd,last_execution_time,getdate()) last_execution_daysago
from getprocaccessedlists
where (datediff(dd,last_execution_time,getdate()) >= @lastaccessed_daysago)
order by last_execution_daysago,name

return;

end
go


--Examples
select * from dbo.fn_get_unused_procedure_noofdaysago(0)
where ProcedureName = 'Your Procedure Name'

--Other Examples
--Complete lists
select * from dbo.fn_get_unused_procedure_noofdaysago(0)
--Procedure doesn't used for more than or equals to last 7 days
select * from dbo.fn_get_unused_procedure_noofdaysago(7)
--Procedure doesn't used for more than or equals to last 30 days
select * from dbo.fn_get_unused_procedure_noofdaysago(30)
--Procedure doesn't used for more than or equals to last 100 days
select * from dbo.fn_get_unused_procedure_noofdaysago(100)
--Procedure doesn't used for more than or equals to last 180 days (approx 6 months)
select * from dbo.fn_get_unused_procedure_noofdaysago(180)
--Procedure doesn't used for more than or equals to last 365 days (approx 1 year)
select * from dbo.fn_get_unused_procedure_noofdaysago(365)



