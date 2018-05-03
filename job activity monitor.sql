/*
        Shows the progress of any running SQL Agent jobs
*/
DECLARE @Actions TABLE
(
        ActionID       int
        , ActionText   varchar(50)
);
INSERT INTO @Actions (ActionID, ActionText)
VALUES (1, 'Quit with success')
     , (2, 'Quit with failure')
     , (3, 'Go to next step')
     , (4, 'Go to step on_success_step_id');
DECLARE @can_see_all_running_jobs int = 1;
DECLARE @job_owner sysname = 'sa';
DECLARE @job_id uniqueidentifier;
DECLARE @job_states TABLE
(
    job_state_id       int NOT NULL
    , job_state_desc   varchar(30) NOT NULL
);
INSERT INTO @job_states (job_state_id, job_state_desc)
VALUES (0, 'Not idle or suspended')
     , (1, 'Executing')
     , (2, 'Waiting for Thread')
     , (3, 'Between Retries')
     , (4, 'Idle')
     , (5, 'Suspended')
     , (6, 'Waiting for Step to Finish')
     , (7, 'Performing Completion Actions');
DECLARE @xp_results TABLE 
(
      job_id                uniqueidentifier NOT NULL
    , last_run_date         int              NOT NULL
    , last_run_time         int              NOT NULL
    , next_run_date         int              NOT NULL
    , next_run_time         int              NOT NULL
    , next_run_schedule_id  int              NOT NULL
    , requested_to_run      int              NOT NULL
    , request_source        int              NOT NULL
    , request_source_id     sysname          COLLATE database_default NULL
    , running               int              NOT NULL
    , current_step          int              NOT NULL
    , current_retry_attempt int              NOT NULL
    , job_state             int              NOT NULL
);
INSERT INTO @xp_results
EXECUTE master.dbo.xp_sqlagent_enum_jobs 
    @can_see_all_running_jobs
    , @job_owner
    , @job_id;
SELECT 
    JobName = j.name
    , states.job_state_desc
    , LastRunDateTime = CASE 
        WHEN COALESCE(xr.last_run_date, 0) > 0 
            THEN msdb.dbo.agent_datetime(xr.last_run_date, xr.last_run_time) 
        ELSE NULL 
        END
    , xr.current_step
    , step_name = (
        SELECT '' + sjs.step_name 
        FROM dbo.sysjobsteps sjs 
        WHERE sjs.job_id = j.job_id 
            AND sjs.step_id = xr.current_step 
        FOR XML PATH ('')
        )
    , SQLStatement = SUBSTRING(t.text
            , ISNULL(r.statement_start_offset / 2 + 1,0)
            , CASE WHEN ISNULL(r.statement_end_offset, 0) = -1 
                THEN LEN(t.text) 
                ELSE ISNULL(r.statement_end_offset / 2, 0) 
                END - ISNULL(r.statement_start_offset / 2, 0)) 
    , [On Success Action] = ASuccess.ActionText 
    , [On Fail Action] = AFail.ActionText 
    , [Blocked By] = r.blocking_session_id
    , [Estimated Completion] = CASE WHEN r.estimated_completion_time = 0 
                THEN 'UNKNOWN' 
                ELSE CONVERT(VARCHAR(50), DATEADD(MILLISECOND, r.estimated_completion_time, GETDATE()), 120) 
                END
    , [Duration in Minutes] = DATEDIFF(MINUTE, r.start_time, GETDATE())
    , r.last_wait_type
    , r.start_time
FROM msdb.dbo.sysjobs j 
    INNER JOIN @xp_results xr ON j.job_id = xr.job_id
    INNER JOIN msdb.dbo.sysjobsteps js ON xr.job_id = js.job_id AND xr.current_step = js.step_id
    LEFT JOIN @job_states states on xr.job_state = states.job_state_id
    LEFT JOIN sys.dm_exec_sessions s ON SUBSTRING(s.[program_name],30,34) = master.dbo.fn_varbintohexstr(j.job_id)
        AND SUBSTRING(s.[program_name], 72, LEN(s.[program_name]) - 72) = xr.current_step
    LEFT JOIN sys.dm_exec_requests r on s.session_id = r.session_id
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
    LEFT JOIN @Actions AFail ON js.on_fail_action = AFail.ActionID
    LEFT JOIN @Actions ASuccess ON js.on_success_action = ASuccess.ActionID
WHERE j.enabled = 1 /* enabled jobs only */
    AND xr.running = 1 /* running jobs only */
ORDER BY j.name;
