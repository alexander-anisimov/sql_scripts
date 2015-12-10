-- VIEW JOBS AND INCLUDED STEPS
SELECT j.name AS 'JobName', s.step_name, s.command, j.job_id
FROM dbo.sysjobsteps AS s
	INNER JOIN dbo.sysjobs AS j ON j.job_id = s.job_id
WHERE j.name IN ('job1', 'job2')
ORDER BY j.job_id, s.step_id

-- START RUN ALL JOBS
DECLARE @JobID	UNIQUEIDENTIFIER, 
		@max	INT = (SELECT COUNT(*) FROM dbo.sysjobs WHERE [enabled] = 1),
		@i		INT = 1
		
WHILE (@i <= @max)
BEGIN
	SET @JobID = (SELECT job_id FROM (SELECT ROW_NUMBER() OVER (ORDER BY job_id) AS [RANK], job_id FROM dbo.sysjobs WHERE [enabled] = 1) AS t WHERE t.[RANK] = @i)

	-- SELECT @JobID AS 'JobID'

	EXEC sp_start_job @job_id = @JobID

	SET @i = @i + 1
END

-- VIEW HISTORY WITH FAILED
SELECT j.name, s.step_name, s.[message] 
FROM dbo.sysjobhistory AS s
	INNER JOIN dbo.sysjobs AS j ON j.job_id = s.job_id
WHERE s.run_status = 0

-- RUNNING JOBS
exec msdb.dbo.sp_help_job @execution_status=1

-- JOB HISTORY BY DATE
DECLARE @StartDate	DATETIME = '2015-11-26 00:00:01.000',
		@EndDate	DATETIME = '2015-11-26 23:59:59.000'

SELECT	t.JobName, 
		t.RunDateTime AS 'StartTime',
		DATEADD(MINUTE, t.RunDurationMinutes, t.RunDateTime) AS 'EndTime',
		t.RunDurationMinutes
FROM 
(
SELECT DISTINCT j.name as 'JobName',
				msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
				CAST(((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) AS INT) as 'RunDurationMinutes'
FROM msdb.dbo.sysjobs AS j
	INNER JOIN msdb.dbo.sysjobhistory AS h ON j.job_id = h.job_id
WHERE j.[enabled] = 1
	AND msdb.dbo.agent_datetime(run_date, run_time) BETWEEN @StartDate AND @EndDate
) AS t
ORDER BY RunDateTime, JobName DESC