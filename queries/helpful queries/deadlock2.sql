-- 2open another query window (2) and run these commands
begin tran 
update employees set firstname = 'Bob' 
update products set supplierid = 1

--5go back to query window (2) and run these commands to undo changes
rollback