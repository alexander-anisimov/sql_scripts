-- Database mail log - recipients, subject
SELECT TOP 100 recipients, sent_status, profile_id, [subject], sent_date
FROM msdb.dbo.sysmail_allitems
WHERE [subject] = 'Trade Data File Upload Report'
	--AND recipients LIKE '%email%'
ORDER BY sent_date DESC
