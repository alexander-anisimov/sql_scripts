DECLARE @TraceID INT
DECLARE @ON BIT
DECLARE @RetVal INT
SET @ON = 1

-- Create trace
exec @RetVal = sp_trace_create @TraceID OUTPUT, 2, N'e:\TraceFile'

-- Get TraceID
print 'This trace is Trace ID = ' + CAST(@TraceID AS NVARCHAR)
print 'Return value = ' + CAST(@RetVal AS NVARCHAR)

-- 10 = RPC:Completed
exec sp_trace_setevent @TraceID, 10, 1, @ON     -- Textdata
exec sp_trace_setevent @TraceID, 10, 3, @ON     -- DatabaseID
exec sp_trace_setevent @TraceID, 10, 12, @ON    -- SPID
exec sp_trace_setevent @TraceID, 10, 13, @ON    -- Duration
exec sp_trace_setevent @TraceID, 10, 14, @ON    -- StartTime
exec sp_trace_setevent @TraceID, 10, 15, @ON    -- EndTime
exec sp_trace_setevent @TraceID, 10, 11, @ON    -- LoginName
exec sp_trace_setevent @TraceID, 10, 8, @ON     -- HostName
exec sp_trace_setevent @TraceID, 10, 10, @ON     -- ApplicationName
exec sp_trace_setevent @TraceID, 10, 34, @ON     -- ObjectName

-- 12 = SQL:BatchCompleted
exec sp_trace_setevent @TraceID, 12, 1, @ON      -- Textdata
exec sp_trace_setevent @TraceID, 12, 3, @ON      -- DatabaseID
exec sp_trace_setevent @TraceID, 12, 12, @ON     -- SPID
exec sp_trace_setevent @TraceID, 12, 13, @ON     -- Duration
exec sp_trace_setevent @TraceID, 12, 14, @ON     -- StartTime
exec sp_trace_setevent @TraceID, 12, 15, @ON     -- EndTime
exec sp_trace_setevent @TraceID, 12, 11, @ON     -- LoginName
exec sp_trace_setevent @TraceID, 12, 8, @ON      -- HostName
exec sp_trace_setevent @TraceID, 12, 10, @ON     -- ApplicationName
exec sp_trace_setevent @TraceID, 12, 34, @ON     -- ObjectName

-- 45 = SP:StmtCompleted
exec sp_trace_setevent @TraceID, 45, 1, @ON      -- Textdata
exec sp_trace_setevent @TraceID, 45, 3, @ON      -- DatabaseID
exec sp_trace_setevent @TraceID, 45, 12, @ON     -- SPID
exec sp_trace_setevent @TraceID, 45, 13, @ON     -- Duration
exec sp_trace_setevent @TraceID, 45, 14, @ON     -- StartTime
exec sp_trace_setevent @TraceID, 45, 15, @ON     -- EndTime
exec sp_trace_setevent @TraceID, 45, 11, @ON     -- LoginName
exec sp_trace_setevent @TraceID, 45, 8, @ON      -- HostName
exec sp_trace_setevent @TraceID, 45, 10, @ON     -- ApplicationName
exec sp_trace_setevent @TraceID, 45, 34, @ON     -- ObjectName

-- Filters
exec sp_trace_setfilter @TraceID, 1, 1, 6, N'%AcGoldMembership%'  -- TextData LIKE '%AcGoldMembership%
exec sp_trace_setfilter @TraceID, 1, 1, 6, N'%AcSilverMembership%' -- TextData LIKE '%AcSilverMembership%'
exec sp_trace_setfilter @TraceID, 1, 0, 7, N'%SELECT%'  -- TextData NOT LIKE '%SELECT%'

-- Trace manage
exec sp_trace_setstatus 2, 1        -- Start the trace
exec sp_trace_setstatus 2, 0        -- Stop the trace
exec sp_trace_setstatus 2, 2        -- Close the trace file and delete the trace settings

-- get traces
SELECT * FROM sys.traces AS t

-- get log
SELECT TextData, ObjectName, DB_NAME(DatabaseID) AS 'DBName', ServerName, HostName, LoginName, ApplicationName, StartTime, EndTime FROM fn_trace_gettable(N'e:\TraceFile.trc' , DEFAULT)

-- column_id on trace
SELECT * FROM sys.trace_columns AS t
