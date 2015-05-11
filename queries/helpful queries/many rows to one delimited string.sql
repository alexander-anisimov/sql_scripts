--http://blogs.msdn.com/b/amitjet/archive/2009/12/11/sql-server-comma-separated-string-to-table.aspx

declare @str nvarchar(4000) = ''

DECLARE @Table1 TABLE (Text NVARCHAR(100))
INSERT INTO @Table1 ( Text )
VALUES  ( N'one'), ( N'two'), ( N'five:)')

select  TOP 10
        @str = @str + cast(Text as varchar) + ',' 
from    @Table1

SELECT @str
SELECT REVERSE(STUFF(REVERSE(@str),1,1,''))
SELECT SUBSTRING(@str, 1, LEN(@str) - 1)
SELECT LEFT(@str, LEN(@str) - 1)




-- способ с подзапросом (работает начиная с 2005)
select
    t.TableID,
    Details = (select convert(varchar(10),td.DetailID) + ', ' from @TableDetails td where t.TableID = td.TableID    for xml path(''))
from
    @Table t