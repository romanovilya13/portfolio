WITH SalesCTE AS (
  SELECT 
    p.CategoryID,
    DATEFROMPARTS(YEAR(s.SaleDate), MONTH(s.SaleDate), 1) AS SaleMonth,
    SUM(s.Quantity * p.Price) AS TotalSales
  FROM 
    Sales s
  INNER JOIN 
    Products p ON s.ProductID = p.ProductID
  WHERE 
    s.SaleDate >= DATEADD(year, -2, GETDATE())
  GROUP BY 
    p.CategoryID, 
    DATEFROMPARTS(YEAR(s.SaleDate), MONTH(s.SaleDate), 1)
)
SELECT 
  c.CategoryName,
  s.SaleMonth,
  s.TotalSales,
  SUM(s.TotalSales) OVER (PARTITION BY c.CategoryName ORDER BY s.SaleMonth) AS RunningTotal,
  LAG(s.TotalSales, 1, 0) OVER (PARTITION BY c.CategoryName ORDER BY s.SaleMonth) AS PrevMonthSales,
  (s.TotalSales - LAG(s.TotalSales, 1, 0) OVER (PARTITION BY c.CategoryName ORDER BY s.SaleMonth)) / LAG(s.TotalSales, 1, 0) OVER (PARTITION BY c.CategoryName ORDER BY s.SaleMonth) * 100 AS GrowthRate
FROM 
  SalesCTE s
INNER JOIN 
  Categories c ON s.CategoryID = c.CategoryID
ORDER BY 
  c.CategoryName, 
  s.SaleMonth;

/*В этом запросе я использую следующие элементы:
 • Common Table Expression (CTE) SalesCTE для группировки продаж по категориям и месяцам за последние 2 года.
 • DATEFROMPARTS для создания даты начала месяца из даты продажи.
 • INNER JOIN для соединения таблиц Sales и Products по полю ProductID.
 • WHERE для фильтрации продаж за последние 2 года.
 • GROUP BY для группировки продаж по категориям и месяцам.
 • SUM для расчета общей суммы продаж для каждой группы.
 • OVER для расчета running total (накопленной суммы) продаж для каждой категории.
 • LAG для расчета продаж за предыдущий месяц для каждой категории.
 • GrowthRate для расчета темпов роста продаж для каждой категории.
В результате запроса получается отчет, который показывает продажи по категориям продуктов в разбивке по месяцам за последние 2 года, а также running total, продажи за предыдущий месяц и темпы роста продаж для каждой категории.*/
