/*
id	tree	name
59	7.		��������
60	7.1.	��������
61	7.2.	�����
62	7.3.	���,����
794	7.4.	�� ��������
*/

select id , tree, name,reverse(SUBSTRING( rt,CHARINDEX('.',rt,2),LEN(rt))) parent
from 
(SELECT [id]
      ,[tree]
      ,[name]
   ,REVERSE ([tree]) rt
   
  FROM [Edelveis].[dbo].[classif]
  ) rtre
  where [tree] like '7.%'
  
  
select * 
from [Edelveis].[dbo].[classif] c
left join (
select id , tree, name,case when CHARINDEX('.',rt,2) = 0 then 
'.'
else 
reverse(SUBSTRING( rt,CHARINDEX('.',rt,2),LEN(rt))) 
end
parent

from 
(SELECT [id]
      ,[tree]
      ,[name]
   ,REVERSE ([tree]) rt
   
  FROM [Edelveis].[dbo].[classif]
  ) rtre
  ) t on c.tree = t.parent
  where c.tree like '7.%'  