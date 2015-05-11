--ANALYTIC FUNCTIONS     
 

-- you probably should execute one query at a time so you can follow along and understand 

-- create a table that has a column for ordering the data 
CREATE TABLE #numbers (nbr INT 
                      ,tempus DATE -- used for ordering the data 
); -- insert some sample data 
INSERT INTO #numbers 
(tempus,nbr) 
VALUES 
 ('1/1/2018',1) 
,('2/2/2018',2) 
,('3/3/2018',3) 
,('4/4/2018',4) 
,('5/5/2018',5) 
,('6/6/2018',6) 
,('7/7/2018',7) 
,('8/8/2018',8) 
,('9/9/2018',9) 
; -- run an ordinary query ordering by the tempus columns 
SELECT nbr, tempus 
FROM #numbers 
ORDER BY tempus;
-- return the nbr value in the following row 
-- the first row retrieved has a NULL for the previous nbr 
-- the last row retrieved has a NULL for the following nbr 
SELECT nbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus) AS prevNbr 
      ,LEAD(nbr, 1) OVER (ORDER BY tempus) AS nextNbr 
FROM #numbers 
ORDER BY tempus;

-- show the nbr value in the current row and in the previous row 
-- change the sort order of the overall query to see what happens 
SELECT nbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus) AS prevNbr 
      ,LEAD(nbr, 1) OVER (ORDER BY tempus) AS nextNbr 
FROM #numbers 
ORDER BY tempus desc;

-- no surprises in the previous query 
-- now change the sort order for the LEAD 
-- the LEAD is now functionally providing the same results as the LAG 
SELECT nbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus) AS prevNbr 
      ,LEAD(nbr, 1) OVER (ORDER BY tempus desc) AS nextNbr 
FROM #numbers 
ORDER BY tempus;

-- change the LEAD to a LAG 
-- a descending LAG works like an ascending LEAD 
SELECT nbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus) AS prevNbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus desc) AS nextNbr 
FROM #numbers 
ORDER BY tempus;

-- return the first value 
SELECT nbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus) AS prevNbr 
      ,LEAD(nbr, 1) OVER (ORDER BY tempus) AS nextNbr 
      ,FIRST_VALUE(nbr) OVER (ORDER BY tempus) AS firstNbr 
FROM #numbers 
ORDER BY tempus;

-- return the last value 
-- notice how it is really the last value so far 
SELECT nbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus) AS prevNbr 
      ,LEAD(nbr, 1) OVER (ORDER BY tempus) AS nextNbr 
      ,FIRST_VALUE(nbr) OVER (ORDER BY tempus) AS firstNbr 
      ,LAST_VALUE(nbr) OVER (ORDER BY tempus) AS lastNbr 
FROM #numbers 
ORDER BY tempus;

-- modify the code to always return the last value 
SELECT nbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus) AS prevNbr 
      ,LEAD(nbr, 1) OVER (ORDER BY tempus) AS nextNbr 
      ,FIRST_VALUE(nbr) OVER (ORDER BY tempus) AS firstNbr 
      ,LAST_VALUE(nbr) OVER (ORDER BY tempus ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS lastNbr 
FROM #numbers 
ORDER BY tempus;

-- this returns the same results as the previous query

SELECT nbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus) AS prevNbr 
      ,LEAD(nbr, 1) OVER (ORDER BY tempus) AS nextNbr 
      ,FIRST_VALUE(nbr) OVER (ORDER BY tempus) AS firstNbr 
      ,LAST_VALUE(nbr) OVER (ORDER BY tempus ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS lastNbr 
FROM #numbers 
ORDER BY tempus;

-- apply the boundary condition to FIRST_VALUE to see what happens 
SELECT nbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus) AS prevNbr 
      ,LEAD(nbr, 1) OVER (ORDER BY tempus) AS nextNbr 
      ,FIRST_VALUE(nbr) OVER (ORDER BY tempus ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS firstNbr 
      ,LAST_VALUE(nbr) OVER (ORDER BY tempus ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS lastNbr 
FROM #numbers 
ORDER BY tempus;

-- fix the previous query to always show the very first value 
SELECT nbr 
      ,LAG (nbr, 1) OVER (ORDER BY tempus) AS prevNbr 
      ,LEAD(nbr, 1) OVER (ORDER BY tempus) AS nextNbr 
      ,FIRST_VALUE(nbr) OVER (ORDER BY tempus ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS firstNbr -- UNBOUNDED FOLLOWING can be used instead of CURRENT ROW 
      ,LAST_VALUE(nbr) OVER (ORDER BY tempus ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS lastNbr 
FROM #numbers 
ORDER BY tempus; 

DROP TABLE #numbers;



CREATE TABLE #sales ( 
    amount INT 
   ,tempus DATETIME 
); INSERT INTO #sales 
(amount, tempus) 
VALUES 
( 10, CAST('01/31/2014' AS DATETIME)) 
,( 20, CAST('02/28/2014' AS DATETIME)) 
,( 30, CAST('03/31/2014' AS DATETIME)) 
,( 40, CAST('04/30/2014' AS DATETIME)) 
,( 50, CAST('05/31/2014' AS DATETIME)) 
,( 60, CAST('06/30/2014' AS DATETIME)) 
,( 70, CAST('07/31/2014' AS DATETIME)) 
,( 80, CAST('08/31/2014' AS DATETIME)) 
,( 90, CAST('09/30/2014' AS DATETIME)) 
,(100, CAST('10/31/2014' AS DATETIME)) 
,(110, CAST('11/30/2014' AS DATETIME)) 
,(120, CAST('12/31/2014' AS DATETIME)) 
,(130, CAST('01/31/2015' AS DATETIME)) 
,(100, CAST('02/28/2015' AS DATETIME)) 
,(110, CAST('03/31/2015' AS DATETIME)) 
,(120, CAST('04/30/2015' AS DATETIME)) 
,(120, CAST('05/31/2015' AS DATETIME)) 
,(100, CAST('06/30/2015' AS DATETIME)) 
,(150, CAST('07/31/2015' AS DATETIME)) 
,(155, CAST('08/31/2015' AS DATETIME)) 
,( 80, CAST('09/30/2015' AS DATETIME)) 
,(160, CAST('10/31/2015' AS DATETIME)) 
,(165, CAST('11/30/2015' AS DATETIME)) 
,(170, CAST('12/31/2015' AS DATETIME)) 
; SELECT tempus 
      ,amount 
      ,AVG(amount) OVER ( 
                          ORDER BY tempus 
                          ROWS 11 PRECEDING 
                        ) 
FROM #sales;

SELECT tempus 
      ,amount 
      ,AVG(amount) OVER ( 
                          ORDER BY tempus 
                          ROWS 11 PRECEDING 
                        ) 
      ,SUM(amount) OVER ( 
                          ORDER BY tempus 
                          ROWS 11 PRECEDING 
                        ) 
FROM #sales;

USE AdventureWorksDW2014 
GO -- official Microsoft examples from the SQL Server 2014 Update for Developers Training Kit 
-- http://www.microsoft.com/en-us/download/details.aspx?id=41704 
-- find the number of days since each product was last ordered 
SELECT rs.ProductKey, rs.OrderDateKey, rs.SalesOrderNumber, 
       rs.OrderDateKey - (SELECT TOP(1) prev.OrderDateKey 
                          FROM dbo.FactResellerSales AS prev 
                          WHERE rs.ProductKey = prev.ProductKey 
                          AND prev.OrderDateKey <= rs.OrderDateKey 
                          AND prev.SalesOrderNumber < rs.SalesOrderNumber 
                          ORDER BY prev.OrderDateKey DESC, 
                          prev.SalesOrderNumber DESC) 
       AS DaysSincePrevOrder 
FROM dbo.FactResellerSales AS rs 
ORDER BY rs.ProductKey, rs.OrderDateKey, rs.SalesOrderNumber;

-- use LAG to simplify the query and speed it up 
SELECT ProductKey, OrderDateKey, SalesOrderNumber, 
       OrderDateKey - LAG(OrderDateKey) 
                      OVER (PARTITION BY ProductKey 
                            ORDER BY OrderDateKey, 
                            SalesOrderNumber) 
AS DaysSincePrevOrder 
FROM dbo.FactResellerSales AS rs 
ORDER BY ProductKey, OrderDateKey, SalesOrderNumber;

 

--FUNCTIONS 

-- find the last day of the current month 

SELECT DATEADD(D, -1, DATEADD(M, DATEDIFF(M, 0, CURRENT_TIMESTAMP) + 1, 0)); -- one of several DATEADD techniques 
SELECT EOMONTH(CURRENT_TIMESTAMP);  -- much easier the new way
-- locale aware date formatting 
SELECT FORMAT(CURRENT_TIMESTAMP, 'D', 'en-US'), FORMAT(CURRENT_TIMESTAMP, 'D', 'en-gb'), FORMAT(CURRENT_TIMESTAMP, 'D', 'de-de');



SELECT LOG(10); -- use natural log to find number of years to obtain 10x growth assuming 100% growth compounded continuously 

SELECT LOG10(10);

SELECT LOG(10,2); – now you can specify a different base such as 2 shown here



SELECT IIF ( 2 > 1, 'true', 'false') 
     , IIF ( 1 > 2, 'true', 'false');

-- if you uncomment the next line and execute it, it will generate an error message 
--SELECT CAST('XYZ' AS INT); -- error message because the CAST obviously can't work 
SELECT TRY_CONVERT(INT,'XYZ'); -- returns NULL 

SELECT ISNUMERIC('1')       , ISNUMERIC('A')       , ISNUMERIC('.'); -- 1, 0, 1 
SELECT TRY_PARSE('1' AS INT), TRY_PARSE('A' AS INT), TRY_PARSE('.' AS INT); -- 1, NULL, NULL


--OFFSET and FETCH

USE AdventureWorks2014 -- or AdventureWorks2012 
GO 

-- look at the SalesTaxRate table to understand the data 
SELECT StateProvinceID, Name, TaxRate 
FROM Sales.SalesTaxRate;

-- if we want to know the highest tax rates, an ORDER BY is helpful 
SELECT StateProvinceID, Name, TaxRate 
FROM Sales.SalesTaxRate 
ORDER BY TaxRate DESC;

-- if we want to limit the results to the top 10, we can use non-ANSI TOP 
SELECT TOP 10 StateProvinceID, Name, TaxRate 
FROM Sales.SalesTaxRate 
ORDER BY TaxRate DESC;

-- change to ANSI SQL 
SELECT StateProvinceID, Name, TaxRate 
FROM Sales.SalesTaxRate 
ORDER BY TaxRate DESC 
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- modify the OFFSET to get the second 10 rows 
SELECT StateProvinceID, Name, TaxRate 
FROM Sales.SalesTaxRate 
ORDER BY TaxRate DESC 
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

-- FETCH requires OFFSET, but OFFSET can be used alone 
-- OFFSET without FETCH specifies the starting point without having a boundary 
SELECT StateProvinceID, Name, TaxRate 
FROM Sales.SalesTaxRate 
ORDER BY TaxRate DESC 
OFFSET 10 ROWS;



--SEQUENCES

USE AdventureWorks2014 -- or AdventureWorks2012 
GO CREATE SEQUENCE dbo.SeqDemoId AS INT 
START WITH 1 
INCREMENT BY 10;



CREATE TABLE dbo.SeqDemoTable 
( SomeId INT PRIMARY KEY CLUSTERED 
  DEFAULT (NEXT VALUE FOR dbo.SeqDemoId), 
  SomeString NVARCHAR(25) 
); 

INSERT INTO dbo.SeqDemoTable (SomeString) VALUES (N'demo');

SELECT * FROM dbo.SeqDemoTable;



DROP TABLE dbo.SeqDemoTable;

DROP SEQUENCE dbo.SeqDemoId;

 

--THROW

BEGIN TRY 
    SELECT 1 / 0; 
END TRY 
BEGIN CATCH 
    PRINT 'Divide by 0'; 
END CATCH;

-- BEGIN TRY 
    SELECT 1 / 0; 
END TRY 
BEGIN CATCH 
    PRINT 'Divide by 0'; 
    THROW -- use this if you still want to see the error message 
END CATCH;