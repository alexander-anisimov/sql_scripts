set nocount on;

declare @CDC_change_list xml,
        @sql nvarchar(max);

set @CDC_change_list = N'
<CDC>
  <CDCInstance>
    <InstanceName>dbo_customer</InstanceName>
    <rows>
      <row>
        <start_lsn>AADMyAAAG8oAFQ==</start_lsn>
        <seqval>AADMyAAAG8oAFA==</seqval>
        <operationid>2</operationid>
        <name>abc company</name>
        <state>md</state>
      </row>
      <row>
        <start_lsn>AADMyAAAG/IABA==</start_lsn>
        <seqval>AADMyAAAG/IAAg==</seqval>
        <operationid>4</operationid>
        <name>abc company</name>
        <state>pa</state>
      </row>
    </rows>
  </CDCInstance>
  <CDCInstance>
    <InstanceName>dbo_customer1</InstanceName>
    <rows>
      <row>
        <start_lsn>AADMyAAAJeQALQ==</start_lsn>
        <seqval>AADMyAAAJeQALA==</seqval>
        <operationid>2</operationid>
        <name>abc company</name>
        <state>md</state>
      </row>
    </rows>
  </CDCInstance>
  <CDCInstance>
    <InstanceName>dbo_customer0</InstanceName>
    <rows>
      <row>
        <start_lsn>xxxxxxx==</start_lsn>
        <seqval>yyyyyy==</seqval>
        <operationid>2</operationid>
        <id>XYZ company</id>
        <field1>XX</field1>
      </row>
    </rows>
  </CDCInstance>
  <CDCInstance>
    <InstanceName>dbo_customer2</InstanceName>
    <rows>
      <row>
        <start_lsn>AADMyAAAc5QAFQ==</start_lsn>
        <seqval>AADMyAAAc5QAFA==</seqval>
        <operationid>2</operationid>
        <name>xyz company</name>
        <state>de</state>
        <status>st1</status>
      </row>
      <row>
        <start_lsn>AADMyAAAc6oABQ==</start_lsn>
        <seqval>AADMyAAAc6oAAg==</seqval>
        <operationid>1</operationid>
        <name>xyz company</name>
        <state>de</state>
        <status>st1</status>
      </row>
    </rows>
  </CDCInstance>
</CDC>';

select @sql = N'
select x.t.value(''../../InstanceName[1]'', ''nvarchar(max)'')  as InstanceName,
       x.t.value(''start_lsn[1]'',          ''binary(10)'')     as start_lsn,
       x.t.value(''seqval[1]'',             ''binary(10)'')     as seqval,
       x.t.value(''operationid[1]'',        ''int'')            as operationid';

with cte as
(   select distinct x.t.value('local-name(.)', 'nvarchar(max)') as NodeName
    from @CDC_change_list.nodes('/CDC/CDCInstance/rows/row/*') as x(t)
)
select @sql = @sql +
(
  select N',
     x.t.value(''' + c.NodeName + N'[1]'', ''nvarchar(max)'') as ' + c.NodeName
  from cte c
  where c.NodeName not in (N'InstanceName', N'start_lsn', N'seqval', N'operationid')
  for xml path(''), type
).value('.', 'nvarchar(max)');

select @sql = @sql + N' 
from @CDC_change_list.nodes(''/CDC/CDCInstance/rows/row'') as x(t)';

exec sp_executesql @sql, N'@CDC_change_list xml', @CDC_change_list;