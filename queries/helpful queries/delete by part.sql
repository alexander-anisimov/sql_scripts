WHILE 1 = 1
BEGIN
DELETE TOP (1000) FROM Sales.MyOrderDetails
WHERE productid = 12;
IF @@rowcount < 1000 BREAK;
END

select * from Test
SET ROWCOUNT 2
WHILE EXISTS(SELECT * FROM Test)
BEGIN
	DELETE del
		FROM  Test del
END
DROP TABLE Test

SET ROWCOUNT 0

;WITH C AS (
	SELECT TOP (1000) * FROM Sales.MyOrderDetails ORDER BY ID
	)
<<<<<<< HEAD
DELETE FROM C
=======
DELETE FROM C
>>>>>>> update script for part delete
