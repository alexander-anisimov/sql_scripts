use distribution

select agent_id,sum(UndelivCmdsInDistDB) as Undeliv,sum(DelivCmdsInDistDB) as Deliv
from MSdistribution_status ds with(nolock)
where agent_id not in (select id from MSdistribution_agents da where subscriber_db ='virtual')
group by agent_id

DECLARE	@return_value int

EXEC	@return_value = [dbo].[check_subscriptions]
		@publisher = [srv-jira],
		@publisher_db = [jira4.0],
		@publication = [jira-pub],
		@subscriber = [srv-bi\sql2008_r2],
		@subscriber_db = [jira4.0],
		@subscription_type = 0

EXEC	@return_value = sp_replmonitorsubscriptionpendingcmds
		@publisher = [srv-jira],
		@publisher_db = [jira4.0],
		@publication = [jira-pub],
		@subscriber = [srv-bi\sql2008_r2],
		@subscriber_db = [jira4.0],
		@subscription_type = 0
