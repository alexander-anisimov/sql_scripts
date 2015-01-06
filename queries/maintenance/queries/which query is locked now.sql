SELECT dec.session_id AS 'SPID', dec.most_recent_sql_handle, dest.[text] 
     FROM sys.dm_exec_connections dec
      CROSS APPLY sys.dm_exec_sql_text(dec.most_recent_sql_handle) dest
     WHERE dec.session_id IN (160)