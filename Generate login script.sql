SELECT 'IF(SUSER_ID('+QUOTENAME(p.name,'''')+') IS NULL)BEGIN CREATE LOGIN '+QUOTENAME(p.name)+
       CASE WHEN p.type_desc = 'SQL_LOGIN'
            THEN ' WITH PASSWORD = '+CONVERT(NVARCHAR(MAX),L.password_hash,1)+' HASHED'
            ELSE ' FROM WINDOWS'
       END + ';/*'+p.type_desc+'*/ END;'
       COLLATE SQL_Latin1_General_CP1_CI_AS
  FROM sys.server_principals AS p
  LEFT JOIN sys.sql_logins AS L
    ON p.principal_id = L.principal_id
 WHERE p.type_desc IN ('SQL_LOGIN','WINDOWS_GROUP','WINDOWS_LOGIN')
   AND p.name NOT IN ('SA')
   AND p.name NOT LIKE '##%##';
