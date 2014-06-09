-- three ways to calculate median value
-- 1.
SELECT DISTINCT BasketSizeKey,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY CheckAmount)
OVER(PARTITION BY BasketSizeKey) AS median
FROM dbo.FactCheck;

-- 2.
WITH Counts AS
(
SELECT BasketSizeKey, COUNT(*) AS cnt
FROM dbo.FactCheck
GROUP BY BasketSizeKey
),
RowNums AS
(
SELECT BasketSizeKey, CheckAmount,
ROW_NUMBER() OVER(PARTITION BY BasketSizeKey ORDER BY CheckAmount) AS n
FROM dbo.FactCheck
)
SELECT C.BasketSizeKey, AVG(1. * R.CheckAmount) AS median
FROM Counts AS C
INNER JOIN RowNums AS R
on C.BasketSizeKey = R.BasketSizeKey
WHERE n IN ( ( C.cnt + 1 ) / 2, ( C.cnt + 2 ) / 2 )
GROUP BY C.BasketSizeKey;

-- 3.
WITH C AS
(
SELECT BasketSizeKey,
COUNT(*) AS cnt,
(COUNT(*) - 1) / 2 AS offset_val,
2 - COUNT(*) % 2 AS fetch_val
FROM dbo.FactCheck
GROUP BY BasketSizeKey
)
SELECT BasketSizeKey, AVG(1. * CheckAmount) AS median
FROM C
CROSS APPLY ( SELECT O.CheckAmount
FROM dbo.FactCheck AS O
where O.BasketSizeKey = C.BasketSizeKey
order by O.CheckAmount
OFFSET C.offset_val ROWS FETCH NEXT C.fetch_val ROWS ONLY ) AS A
GROUP BY BasketSizeKey;