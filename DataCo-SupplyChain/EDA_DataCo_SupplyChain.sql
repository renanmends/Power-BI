-- Análise Exploratória de Dados: DataCo Supply Chain

-------------------------------------------------------------------------------------------------------
-- Qual foi a receita e o lucro realizado por ano? Compare os resultados ano após ano.

WITH Results AS (
		SELECT YEAR(TR.Order_Date) AS Order_Year,
		ROUND(SUM(OI.Order_Item_Total), 2) AS Total_Net_Sales,
		ROUND(SUM(OI.Order_Item_Profit), 2) AS Total_Profit
		FROM Order_Item OI
		INNER JOIN Transactions_Orders TR
			ON TR.ID_Order_Item = OI.ID_Order_Item
		WHERE TR.Delivery_Status NOT LIKE 'Shipping canceled'
		GROUP BY YEAR(TR.Order_Date)
)
SELECT Order_Year, Total_Net_Sales,
	   FORMAT((Total_Net_Sales - LAG(Total_Net_Sales, 1) OVER (ORDER BY Order_Year)) 
	   / LAG(Total_Net_Sales, 1) OVER (ORDER BY Order_Year), 'P') AS Growth_Net_Sales_Percentage,
	   Total_Profit,
	   FORMAT((Total_Profit - LAG(Total_Profit, 1) OVER (ORDER BY Order_Year))
	   / LAG(Total_Profit, 1) OVER (ORDER BY Order_Year), 'P') AS Growth_Profit_Percentage
FROM Results

---------------------------------------------------------------------------------------------------------
-- Quais os 30 produtos que mais foram pedidos?

SELECT TOP 30 PR.ID_Product, PR.Product_Name, PR.Product_Price,
			  SUM(Order_Item_Quantity) AS Order_Quantity
FROM Order_Item OI
INNER JOIN Products PR
	ON PR.ID_Product = OI.ID_Product
INNER JOIN Transactions_Orders TR
	ON TR.ID_Order_Item = OI.ID_Order_Item
WHERE TR.ID_Order_Item NOT LIKE 'Shipping canceled'
GROUP BY PR.ID_Product, PR.Product_Name, PR.Product_Price
ORDER BY Order_Quantity DESC;

---------------------------------------------------------------------------------------------------------
-- Quais os 30 produtos que mais foram pedidos por ano?

SELECT TOP 30 YEAR(TR.Order_Date) AS Ano, PR.ID_Product, PR.Product_Name, PR.Product_Price,
			  SUM(Order_Item_Quantity) AS Order_Quantity
FROM Order_Item OI
INNER JOIN Products PR
	ON PR.ID_Product = OI.ID_Product
INNER JOIN Transactions_Orders TR
	ON TR.ID_Order_Item = OI.ID_Order_Item
WHERE YEAR(TR.Order_Date) = 2017 -- Defina o ano
	  AND TR.ID_Order_Item NOT LIKE 'Shipping canceled'
GROUP BY YEAR(TR.Order_Date), PR.ID_Product, PR.Product_Name, PR.Product_Price
ORDER BY Order_Quantity DESC;

---------------------------------------------------------------------------------------------------------
-- Quais produtos possuem a maiores margens de lucro?

SELECT TOP 30 PR.ID_Product, PR.Product_Name, PR.Product_Price,
			  ROUND(SUM(Order_Item_Profit) / SUM(Order_Item_Quantity), 2) AS Profit_Average_Per_Product,
			  ROUND((SUM(Order_Item_Profit) / SUM(Order_Item_Quantity)) / PR.Product_Price, 2) AS Profit_Ratio
FROM Order_Item OI
INNER JOIN Products PR
	ON PR.ID_Product = OI.ID_Product
INNER JOIN Transactions_Orders TR
	ON TR.ID_Order_Item = OI.ID_Order_Item
WHERE Order_Item_Profit > 0
	  AND TR.Delivery_Status NOT LIKE 'Shipping canceled'
GROUP BY PR.ID_Product, PR.Product_Name, PR.Product_Price
ORDER BY Profit_Ratio DESC;

-----------------------------------------------------------------------------------------------------------
-- TOP 30 Clientes que mais fizeram pedidos

SELECT TOP 30 CT.ID_Customer, CONCAT(CT.Customer_First_Name, ' ', CT.Customer_Last_Name) AS Customer_Name,
			  CT.Customer_Segment, CT.Customer_Country, COUNT(OD.ID_Order) AS Order_Quantity_Customer,
			  ROUND(SUM(Sales), 2) AS Sales_Per_Customer
FROM Orders OD
INNER JOIN Customer CT
	ON CT.ID_Customer = OD.ID_Customer
INNER JOIN Order_Item OI
	ON OI.ID_Order = OD.ID_Order
INNER JOIN Transactions_Orders TR
	ON TR.ID_Order = OD.ID_Order
WHERE TR.Delivery_Status NOT LIKE 'Shipping canceled'
GROUP BY CT.ID_Customer, CT.Customer_First_Name, CT.Customer_Last_Name, Customer_Segment, CT.Customer_Country
ORDER BY Sales_Per_Customer DESC;

-----------------------------------------------------------------------------------------------------------
-- Países com maiores quantidades de pedidos e porcentagem sobre o total

DECLARE @total_orders NUMERIC;
SET @total_orders = (
	SELECT COUNT(DISTINCT(OD.Id_Order))
	FROM Orders OD
	INNER JOIN Transactions_Orders TR
		ON TR.ID_Order = OD.Id_Order
	WHERE NOT TR.Delivery_Status = 'Shipping canceled'
);

SELECT Order_Country, COUNT(DISTINCT(OD.ID_Order)) Order_Quantity,
	   CAST(ROUND((COUNT(DISTINCT(OD.ID_Order)) / @total_orders)*100, 2) AS FLOAT) AS Total_Percentage_Quantity
FROM Orders OD
INNER JOIN Transactions_Orders TR
	ON TR.ID_Order = OD.Id_Order
-- WHERE TR.Delivery_Status NOT IN ('Shipping canceled') or
WHERE NOT TR.Delivery_Status = 'Shipping canceled'
GROUP BY Order_Country
ORDER BY Order_Quantity DESC;

----------------------------------------------------------------------------------------------------------
-- Quais os departamentos que mais fizeram vendas? Qual a porcentagem dessas vendas sobre o total?

DECLARE @total_sales NUMERIC;
SET @total_sales = (
	SELECT SUM(Order_Item_Total)
	FROM Order_Item OI
	INNER JOIN Transactions_Orders TR
		ON TR.ID_Order_Item = OI.ID_Order_Item
	WHERE NOT TR.Delivery_Status = 'Shipping canceled'
	)

SELECT DP.ID_Department, DP.Department_Name,
	   ROUND(SUM(Order_Item_Total), 2) AS Sales_Per_Department,
	   ROUND((SUM(Order_Item_Total) / @total_sales)*100, 2) AS Total_Percentage_Sales
FROM Department DP
INNER JOIN Order_Item OI
	ON OI.ID_Department = DP.ID_Department
INNER JOIN Transactions_Orders TR
	ON TR.ID_Order_Item = OI.ID_Order_Item
WHERE NOT TR.Delivery_Status = 'Shipping canceled'
GROUP BY DP.ID_Department, DP.Department_Name
ORDER BY Sales_Per_Department DESC;

---------------------------------------------------------------------------------------
-- Quantidade de pedidos por tipo de entrega

SELECT Shipping_Mode, COUNT(DISTINCT(ID_Order)) AS Order_Quantity
FROM Transactions_Orders
WHERE Delivery_Status NOT IN ('Shipping canceled')
GROUP BY Shipping_Mode
ORDER BY Order_Quantity;

--------------------------------------------------------------------------------------------------------
-- Qual a quantidade de pedidos por status de entrega em cada ano. 
-- Apresente a porcentagem de pedidos de cada status de entrega em relação ao total de pedidos por ano.

SELECT Order_Year, Delivery_Status, Order_Quantity,
	   FORMAT((CAST((Order_Quantity) AS FLOAT) / SUM(Order_Quantity) OVER (PARTITION BY Order_Year)), 'P') AS Total_Percentage_Per_Year
FROM (
	SELECT YEAR(Order_Date) AS Order_Year, Delivery_Status,
		   COUNT(DISTINCT(ID_Order)) AS Order_Quantity
	FROM Transactions_Orders
	WHERE Delivery_Status NOT LIKE 'Shipping canceled'
	GROUP BY YEAR(Order_Date), Delivery_Status
) AS Transactions
ORDER BY Order_Year

----------------------------------------------------------------------------------------------------------
-- Tempo médio de entrega de um pedido por cada tipo de entrega

SELECT Shipping_Mode,
       AVG(DATEDIFF(day, Order_Date, Shipping_Date)) AS AVG_Shipping_Days
FROM Transactions_Orders
GROUP BY Shipping_Mode
ORDER BY AVG_Shipping_Days DESC;

----------------------------------------------------------------
-- Taxa de desconto concedida por tipo de pagamento e produto

SELECT PR.ID_Product, PR.Product_Name, OD.Order_Payment,
	   ROUND(AVG(OI.Order_Item_Discount / OI.Order_Item_Quantity), 2) AS AVG_Discount_Per_Quantity
FROM Products PR
INNER JOIN Order_Item OI
	ON OI.ID_Product = PR.ID_Product
INNER JOIN Orders OD
	ON OD.ID_Order = OI.ID_Order
INNER JOIN Transactions_Orders TR
	ON TR.ID_Order_Item = OI.ID_Order_Item
WHERE NOT TR.Delivery_Status = 'Shipping canceled'
GROUP BY PR.ID_Product, PR.Product_Name, OD.Order_Payment;

------------------------------------------------------------------------------------------------------
-- Comparativo entre o preço de um produto e a média da categoria de produtos na qual esse produto pertence

WITH Product_Category_Price AS (
	SELECT ID_Product, Product_Name, Product_Price, PR.ID_Product_Category, PC.Category_Name,
		   ROUND(AVG(Product_Price)
				OVER (PARTITION BY PR.ID_Product_Category
				), 2) AS AVG_Price_Category
	FROM Products PR
	INNER JOIN Products_Category PC
		ON PC.ID_Product_Category = PR.ID_Product_Category
)
SELECT * ,
	CASE
		WHEN Product_Price > AVG_Price_Category
			THEN 'Higher than the average'
		WHEN Product_Price < AVG_Price_Category
			THEN 'Lower than the average'
		ELSE 'Equal to the average'
	END AS AVG_Price_Comparative
FROM Product_Category_Price
ORDER BY ID_Product;