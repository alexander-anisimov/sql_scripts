SELECT

SUM(qs.max_elapsed_time) as elapsed_time,

SUM(qs.total_worker_time) as worker_time

into T1 FROM (

       select top 100000       *       from

       sys.dm_exec_query_stats qs

       where qs.last_execution_time > (CURRENT_TIMESTAMP - '01:00:00.000')

       order by qs.total_worker_time desc

       --order by qs.max_elapsed_time desc

) as qs;

select top 100

(qs.max_elapsed_time) as elapsed_time,

(qs.total_worker_time) as worker_time,

qp.query_plan,

st.text,

dtb.name,

qs.*,

st.dbid

INTO T2

FROM

sys.dm_exec_query_stats qs

CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp

CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st

left outer join sys.databases as dtb on st.dbid = dtb.database_id

where qs.last_execution_time > (CURRENT_TIMESTAMP - '01:00:00.000')

order by qs.total_worker_time desc

--order by qs.max_elapsed_time desc;

select

(T2.elapsed_time*100/T1.elapsed_time) as percent_elapsed_time,

(T2.total_worker_time*100/T1.worker_time) as percent_worker_time,

T2.*

from

T2 as T2

INNER JOIN T1 as T1

ON 1=1

order by T2.total_worker_time desc

--order by T2.max_elapsed_time desc;

drop table T2;

drop table T1;