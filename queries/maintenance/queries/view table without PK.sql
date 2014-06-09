select Name from sys.tables t 
where not exists (select * from sys.key_constraints pk where type = 'PK' and t.object_id = pk.parent_object_id)
