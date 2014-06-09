select getdate() [Время снимка], 
l.rsc_text [Описание], 
d.name [База данных], 
isnull(i.name,'') [Индекс],
isnull(o.name,isnull(o1.name,isnull(o2.name,''))) [Объект], 
rsc_objid, 
case when rsc_type=1 then 'Resource (not used)' 
when rsc_type=2 then 'Database' 
when rsc_type=3 then 'File' 
when rsc_type=4 then ' Index' 
when rsc_type=5 then 'Table/Proc/View' 
when rsc_type=6 then 'Page' 
when rsc_type=7 then 'Key' 
when rsc_type=8 then ' Extent' 
when rsc_type=9 then ' RID (Row ID)' 
when rsc_type=10 then ' Application' 
else '' end [Объект блокировки],
case when req_mode=0 then 'No access is granted to the resource. Serves as a placeholder' 
when req_mode=1 then N'Sch-S (Schema stability). Запрет модификаци' 
when req_mode=2 then N' Sch-M (Schema modification). Модификация объекта' 
when req_mode=3 then N' S (Shared). Разрешение раздельного доступа.' 
when req_mode=4 then N' U (Update). Обновляемая' 
when req_mode=5 then N' X (Exclusive). Монопольный доступ.' 
when req_mode=6 then N' IS (Intent Shared). ' 
when req_mode=7 then N' IU (Intent Update). ' 
when req_mode=8 then N' IX (Intent Exclusive). ' 
when req_mode=9 then N' SIU (Shared Intent Update). ' 
when req_mode=10 then N' SIX (Shared Intent Exclusive).' 
when req_mode=11 then N' UIX (Update Intent Exclusive).' 
when req_mode=12 then N' BU. Used by bulk operations.' 
when req_mode=13 then N' RangeS_S (Shared Key-Range and Shared Resource lock). ' 
when req_mode=14 then N' RangeS_U (Shared Key-Range and Update Resource lock). ' 
when req_mode=15 then N' RangeI_N (Insert Key-Range and Null Resource lock). ' 
when req_mode=16 then N' RangeI_S. Key-Range Conversion lock, created by an overlap of RangeI_N and S locks.' 
when req_mode=17 then N' RangeI_U. Key-Range Conversion lock, created by an overlap of RangeI_N and U locks.' 
when req_mode=18 then N' RangeI_X. Key-Range Conversion lock, created by an overlap of RangeI_N and X locks.' 
when req_mode=19 then N' RangeX_S. Key-Range Conversion lock, created by an overlap of RangeI_N and RangeS_S. locks.' 
when req_mode=20 then N' RangeX_U. Key-Range Conversion lock, created by an overlap of RangeI_N and RangeS_U locks.' 
when req_mode=21 then N' RangeX_X (Exclusive Key-Range and Exclusive Resource lock). ' 
else ''end [Тип блокировки],
case when req_status=1 then 'Granted' 
when req_status=2 then 'Converting' 
when req_status=3 then 'Waiting' 
else '' end [Статус],
req_refcnt [Количество обращений], 
req_lifetime [Время жизни], 
rtrim(p.hostname)+': '+rtrim(p.program_name)+'('+cast(p.spid as varchar(5))+')' [Процесс], 
p.waitresource [Ожидаемый ресурс], 
isnull(rtrim(plock.hostname)+': '+rtrim(plock.program_name),'') [Заблокированный Процесс], 
isnull(plock.waitresource,'') [Ожидаемый ресурс2], 
case when req_ownertype=1 then 'Transaction' 
when req_ownertype=2 then 'Cursor' 
when req_ownertype=3 then 'Session' 
when req_ownertype=4 then 'ExSession' 
else '' end [Тип владельца],
p.spid, 
p.blocked 
from sys.syslockinfo l(nolock) 
left join sys.sysdatabases d (nolock) on d.dbid=l.rsc_dbid 
left join sys.sysprocesses p (nolock) on p.spid=l.req_spid 
left join sys.sysprocesses plock (nolock) on plock.spid=p.blocked 
--Тут вписывается рабочая бд 
left join admiral.dbo.sysobjects o (nolock) on o.id=l.rsc_objid 

left join tempdb.dbo.sysobjects o1 (nolock) on o1.id=l.rsc_objid 
left join sys.sysobjects o2 (nolock) on o2.id=l.rsc_objid 
left join sys.sysindexes i (nolock) on i.id=l.rsc_indid
where p.blocked <> 0
--where p.spid = 439
order by 12