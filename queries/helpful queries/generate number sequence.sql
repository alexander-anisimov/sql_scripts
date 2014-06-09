
DECLARE @N int = 1000;

SELECT TOP(@N) ROW_NUMBER() OVER (ORDER BY @N)
FROM master.dbo.spt_values v1 WITH(NOLOCK)
CROSS JOIN master.dbo.spt_values v2 WITH(NOLOCK)