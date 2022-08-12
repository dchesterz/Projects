--The goal is to create a table with the sales and purchases and see if there was any discrepancy between those numbers

CREATE TABLE #Orders
(
       OrderDate DATE
	  ,OrderMonth DATE
	  ,OrderType VARCHAR (32)
      ,TotalDue MONEY
	  ,OrderRank INT
)

--Insert sales data:

INSERT INTO #Orders
(
       OrderDate
	  ,OrderMonth
	  ,OrderType
      ,TotalDue
	  ,OrderRank
)
SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	  ,OrderType = 'Sales'
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)

FROM AdventureWorks2019.Sales.SalesOrderHeader --sales data

CREATE TABLE #AvgOrderMinusTop10
(
	  OrderMonth DATE
	  ,OrderType VARCHAR (32)
      ,TotalDue MONEY
)

--Insert sales data:
INSERT INTO #AvgOrderMinusTop10
(
       OrderMonth
	  ,OrderType
      ,TotalDue
)
SELECT
OrderMonth,
OrderType = 'Sales',
TotalDue = SUM(TotalDue)

FROM #Orders
WHERE OrderRank > 10
GROUP BY OrderMonth


--Empty out #Orders table

TRUNCATE TABLE #Orders

--Insert purchase data:

INSERT INTO #Orders
(
       OrderDate
	  ,OrderMonth
	  ,OrderType
      ,TotalDue
	  ,OrderRank
)
SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	  ,OrderType = 'Purchase'
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)

FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader --purchase data


--Insert purchase data:

INSERT INTO #AvgOrderMinusTop10
(
OrderMonth,
OrderType,
TotalDue
)
SELECT
OrderMonth,
OrderType = 'Purchase',
TotalDue = SUM(TotalDue)
FROM #Orders
WHERE OrderRank > 10
GROUP BY OrderMonth

--Checking to see if there is any discrepancy
WITH MainTable AS
(
SELECT 
	   A.OrderMonth
	  ,TotalSales = A.TotalDue
      ,TotalPurchases = B.TotalDue

FROM #AvgOrderMinusTop10 A
	JOIN #AvgOrderMinusTop10 B
		ON A.OrderMonth = B.OrderMonth
			AND B.OrderType = 'Purchase'

WHERE A.OrderType = 'Sales'
)

SELECT 
	 *,
	 DiffInNumbers = TotalSales - TotalPurchases
FROM MainTable



DROP TABLE #Orders
DROP TABLE #AvgSalesMinusTop10
