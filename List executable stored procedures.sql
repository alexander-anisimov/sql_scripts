select
 object_name(cast(pa1.value as int), cast(pa2.value as int)) as 'stored procedure'
from
 sys.dm_exec_requests r join
 sys.dm_exec_cached_plans p on p.plan_handle = r.plan_handle cross apply
 sys.dm_exec_plan_attributes(r.plan_handle) pa1 cross apply
 sys.dm_exec_plan_attributes(r.plan_handle) pa2
where
 p.objtype = 'proc' and pa1.attribute = N'objectid' and pa2.attribute = N'dbid';