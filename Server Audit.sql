USE [master]

-- SERVER TRIGGERS VIEW
SELECT * FROM sys.server_triggers 

-- TABLE
CREATE TABLE LogHistory 
	(ID					INT IDENTITY(1,1),
	[Date]				DATETIME,
	[ServerName]		SYSNAME,
	[Login]				SYSNAME,
	[EventType]			SYSNAME,
	[SPID]				INT,
	[ClientHost]		SYSNAME NULL,
	[Tool]				SYSNAME NULL)

-- TRIGGER
CREATE TRIGGER ServerLogonHistory ON ALL SERVER FOR LOGON 
AS
DECLARE @eventdata XML
SET @eventdata = EventData()
INSERT INTO master.dbo.LogHistory ([Date], [ServerName], [Login], [EventType], [SPID], [ClientHost], [Tool])
VALUES (
		@eventdata.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime'),
		@eventdata.value('(/EVENT_INSTANCE/ServerName)[1]', 'sysname'),
		@eventdata.value('(/EVENT_INSTANCE/LoginName)[1]', 'sysname'),
		@eventdata.value('(/EVENT_INSTANCE/EventType)[1]', 'sysname'),
		@eventdata.value('(/EVENT_INSTANCE/SPID)[1]', 'int'),
		@eventdata.value('(/EVENT_INSTANCE/ClientHost)[1]', 'sysname'),
		APP_NAME()
		)

-- SERVER LOG VIEW
SELECT * FROM master.dbo.LogHistory

-- DROP SERVER TRIGGER
DROP TRIGGER ServerLogonHistory ON ALL SERVER