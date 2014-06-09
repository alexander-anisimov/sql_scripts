SELECT top 1 number
FROM master.dbo.spt_values v1 WITH(NOLOCK)
where number between 1 and 6 and Type = 'P'
order by NEWID()