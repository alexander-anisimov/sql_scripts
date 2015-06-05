use msdb;
go

create queue blocked_process_report_queue;
go

create service blocked_process_report_service
    on queue blocked_process_report_queue
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);

create event notification blocked_process_report_notification
    on server
    for BLOCKED_PROCESS_REPORT
    to service N'blocked_process_report_service',
          N'current database';
go  

sp_configure 'show advanced options', 1 ;
GO
RECONFIGURE ;
GO
sp_configure 'blocked process threshold', 20 ;
GO
RECONFIGURE ;






use msdb;
waitfor(
   receive cast(message_body as xml), * 
   from  blocked_process_report_queue);