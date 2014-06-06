-- INT
SELECT	'1 + 1' AS 'Expression',
		1 + 1 AS 'Value',
		SQL_VARIANT_PROPERTY(1 + 1,'BaseType') AS 'Base Type'

-- VARCHAR
SELECT	'''1'' + ''1''' AS 'Expression',
		'1' + '1' AS 'Value',
		SQL_VARIANT_PROPERTY('1' + '1','BaseType') AS 'Base Type'