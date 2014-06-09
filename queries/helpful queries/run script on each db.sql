-- following script run command on each db
exec sp_msforeachdb '
use [?];  
select db_name()'