--1open a query window (1) and run these commands
begin tran 
update products set supplierid = 2

-- 3go back to query window (1) and run these commands
update employees set firstname = 'Greg'

--At this point SQL Server will select one of the process as a deadlock victim and roll back the statement

--4issue this command in query window (1) to undo all of the changes
rollback