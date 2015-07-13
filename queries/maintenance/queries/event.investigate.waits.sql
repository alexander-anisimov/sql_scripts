create EVENT SESSION [InvestigateWaits] on server add EVENT sqlos.wait_info (
ACTION(package0.collect_current_thread_id
    , package0.event_sequence
    , package0.last_error
    , package0.process_id
    , sqlos.scheduler_address
    , sqlos.scheduler_id
    , sqlos.system_thread_id
    , sqlserver.client_app_name
    , sqlserver.client_connection_id
    , sqlserver.client_hostname
    , sqlserver.client_pid
    , sqlserver.context_info
    , sqlserver.database_name
    , sqlserver.is_system
    , sqlserver.nt_username
    , sqlserver.plan_handle
    , sqlserver.query_hash
    , sqlserver.query_plan_hash
    , sqlserver.request_id
    , sqlserver.session_id
    , sqlserver.session_nt_username
    , sqlserver.session_resource_group_id
    , sqlserver.session_resource_pool_id
    , sqlserver.session_server_principal_name
    , sqlserver.sql_text
    , sqlserver.transaction_id
    , sqlserver.transaction_sequence
    , sqlserver.tsql_frame
    , sqlserver.tsql_stack
    , sqlserver.username) 
where ([package0].[equal_uint64]([wait_type], (223)))) add TARGET package0.ring_buffer
    with (
            MAX_MEMORY = 51200 KB
            , EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
            , MAX_DISPATCH_LATENCY = 5 SECONDS
            , MAX_EVENT_SIZE = 0 KB
            , MEMORY_PARTITION_MODE = NONE
            , TRACK_CAUSALITY = off
            , STARTUP_STATE = off
            )
go