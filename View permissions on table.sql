-- GRANT
GRANT UPDATE, DELETE, INSERT ON OBJECT::dbo.Table1 TO myUser;
GRANT DELETE ON OBJECT::dbo.Table2 TO myUser;
GRANT UPDATE, DELETE ON OBJECT::dbo.Table3 TO myUser;

-- VIEW
exec sp_table_privileges @table_name = 'Table1'; 
exec sp_table_privileges @table_name = 'Table2'; 
exec sp_table_privileges @table_name = 'Table3'; 