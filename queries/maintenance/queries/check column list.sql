declare @t1 table(id int identity, val1 int, val2 int, val3 int)
declare @t2 table(id int identity, val4 char(10), val5 char(10), val6 char(10))
select t1.id, t1.val1, t2.val4 into t from @t1 t1 join @t2 t2 on t1.id=t2.id
select * from INFORMATION_SCHEMA.COLUMNS where Table_name='t'
drop table t