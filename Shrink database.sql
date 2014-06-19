-- 1 Step
DBCC shrinkfile (tempdev,5000)

-- View open transactions
DBCC opentran

-- Clean others
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
DBCC FREESYSTEMCACHE ('ALL')
DBCC FREESESSIONCACHE

-- 2 Step
DBCC shrinkfile (tempdev,5000)