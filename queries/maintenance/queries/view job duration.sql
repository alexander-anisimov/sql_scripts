--SELECT 
--        JobName,
--        AVG(hours) AvgHours,
--        AVG(minutes) AvgMinutes,
--        AVG(seconds) AvgSeconds
--FROM (        
    SELECT  
            JobName = j.name, 
            runDate = cast(CONVERT (DATETIME, RTRIM(run_date)) AS date),
            runTime = s.run_time,
            run_duration/10000 Hours, --hours
            run_duration/100%100 Minutes, --minutes
            run_duration%100 Seconds --seconds
    FROM msdb.dbo.sysjobhistory s
    JOIN msdb.dbo.sysjobs j ON j.job_id = s.job_id AND j.[enabled] = 1
    WHERE j.name = 'UserEmailVerification'
    AND s.step_id = 0
    ORDER BY j.name ASC, s.run_date DESC
--) t
--GROUP BY JobName
