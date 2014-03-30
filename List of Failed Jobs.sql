SELECT	JJ.instance_id, 
			sj.job_id, 
			sj.name AS JOB_NAME, 
			sjt.step_name, 
			JJ.run_status, 
			JJ.sql_message_id, 
			JJ.sql_severity, 
			JJ.message, 
			JJ.exec_date, 
			JJ.run_duration, 
			JJ.server, 
			sjt.output_file_name, 
			JJ.run_code
FROM 
	(SELECT  ssh.instance_id, sjh.job_id, sjh.step_id, sjh.sql_message_id, sjh.sql_severity, sjh.message, 
				(CASE sjh.run_status 
						WHEN 0 THEN 'Failed' 
						WHEN 1 THEN 'Succeeded' 
						WHEN 2 THEN 'Retry' 
						WHEN 3 THEN 'Canceled' 
						WHEN 4 THEN 'In progress' END
				) AS run_status, 
				SUBSTRING(CAST(sjh.run_date AS VARCHAR(8)), 5, 2) 
					+ '/' + SUBSTRING(CAST(sjh.run_date AS VARCHAR(8)), 7, 2) 
					+ '/' + SUBSTRING(CAST(sjh.run_date AS VARCHAR(8)), 1, 4) 
					+ ' ' + SUBSTRING(REPLICATE('0', 6 - LEN(CAST(sjh.run_time AS varchar))) + CAST(sjh.run_time AS VARCHAR), 1, 2) + ':' 
					+ SUBSTRING(REPLICATE('0', 6 - LEN(CAST(sjh.run_time AS VARCHAR))) + CAST(sjh.run_time AS VARCHAR), 3,  2) 
					+ ':' + SUBSTRING(REPLICATE('0', 6 - LEN(CAST(sjh.run_time AS varchar))) + CAST(sjh.run_time AS VARCHAR), 5, 2) AS exec_date, 
					sjh.run_duration,  sjh.run_status AS run_code, sjh.retries_attempted, sjh.server
	 FROM msdb.dbo.sysjobhistory AS sjh 
		INNER JOIN (SELECT job_id, step_id, MAX(instance_id) AS instance_id
						FROM msdb.dbo.sysjobhistory AS sjh
						GROUP BY job_id, step_id
						) AS ssh ON sjh.instance_id = ssh.instance_id
		WHERE(sjh.run_status <> 1)
	) AS JJ 
	INNER JOIN msdb.dbo.sysjobs AS sj ON JJ.job_id = sj.job_id 
	INNER JOIN msdb.dbo.sysjobsteps AS sjt ON JJ.job_id = sjt.job_id AND JJ.step_id = sjt.step_id