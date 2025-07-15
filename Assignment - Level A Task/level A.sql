use adventureworks2022;

-- 1. List of all customers
SELECT 
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    c.AccountNumber,
    c.TerritoryID
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID;

-- 2. List of all customers where company name ending in N
SELECT 
    c.CustomerID,
    s.Name AS CompanyName,
    c.AccountNumber,
    c.TerritoryID
FROM Sales.Customer c
JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
WHERE s.Name LIKE '%N';


-- 3. List of all customers who live in Berlin or London
SELECT 
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    a.City,
    c.AccountNumber
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
JOIN Person.BusinessEntityAddress bea 
    ON bea.BusinessEntityID = ISNULL(c.PersonID, c.StoreID)
JOIN Person.Address a ON bea.AddressID = a.AddressID
WHERE a.City IN ('Berlin', 'London');


-- 4. List of all customers who live in UK or USA
SELECT 
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    cr.Name AS Country,
    c.AccountNumber
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
JOIN Person.BusinessEntityAddress bea 
    ON bea.BusinessEntityID = ISNULL(c.PersonID, c.StoreID)
JOIN Person.Address a ON bea.AddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name IN ('United States', 'United Kingdom');

-- 5. List of all products sorted by product name
SELECT 
    ProductID,
    Name AS ProductName,
    ProductNumber,
    Color,
    StandardCost,
    ListPrice
FROM Production.Product
ORDER BY Name;


-- 6. List of all products where product name starts with an A
SELECT 
    ProductID,
    Name AS ProductName,
    ProductNumber,
    Color,
    StandardCost,
    ListPrice
FROM Production.Product
WHERE Name LIKE 'A%'
ORDER BY Name;

-- 7. List of customers who ever placed an order
SELECT DISTINCT
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    c.AccountNumber
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
ORDER BY CustomerName;

-- 8. List of customers who live in london and have bought chai
SELECT DISTINCT
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    a.City,
    c.AccountNumber
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
JOIN Person.BusinessEntityAddress bea 
    ON bea.BusinessEntityID = ISNULL(c.PersonID, c.StoreID)
JOIN Person.Address a ON bea.AddressID = a.AddressID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
WHERE a.City = 'London'
  AND pr.Name = 'Chai'
ORDER BY CustomerName;

-- 9. List of customer who never placed an order
SELECT 
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    c.AccountNumber
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
WHERE soh.CustomerID IS NULL
ORDER BY CustomerName;

-- 10. List of customers who ordered Tofu
SELECT DISTINCT
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    c.AccountNumber
FROM Sales.Customer c
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
WHERE pr.Name = 'Tofu'
ORDER BY CustomerName;

-- 11. Details of first order of the system
WITH FirstOrder AS (
    SELECT TOP 1 SalesOrderID, OrderDate, CustomerID
    FROM Sales.SalesOrderHeader
    ORDER BY OrderDate ASC, SalesOrderID ASC
)

SELECT 
    f.SalesOrderID,
    f.OrderDate,
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    c.AccountNumber,
    sod.SalesOrderDetailID,
    pr.ProductID,
    pr.Name AS ProductName,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal
FROM FirstOrder f
JOIN Sales.Customer c ON f.CustomerID = c.CustomerID
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
JOIN Sales.SalesOrderDetail sod ON f.SalesOrderID = sod.SalesOrderID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID;

-- 12. Find the details of most expensive order date
WITH OrderTotals AS (
    SELECT 
        SalesOrderID,
        SUM(LineTotal) AS TotalAmount
    FROM Sales.SalesOrderDetail
    GROUP BY SalesOrderID
),
MaxOrder AS (
    SELECT TOP 1 SalesOrderID, TotalAmount
    FROM OrderTotals
    ORDER BY TotalAmount DESC
)

SELECT 
    mo.SalesOrderID,
    soh.OrderDate,
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, s.Name) AS CustomerName,
    c.AccountNumber,
    sod.SalesOrderDetailID,
    pr.ProductID,
    pr.Name AS ProductName,
    sod.OrderQty,
    sod.UnitPrice,
    sod.LineTotal,
    mo.TotalAmount
FROM MaxOrder mo
JOIN Sales.SalesOrderHeader soh ON mo.SalesOrderID = soh.SalesOrderID
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
JOIN Sales.SalesOrderDetail sod ON mo.SalesOrderID = sod.SalesOrderID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID;

-- 13. For each order get the orderID and Average quantity of items in that order
SELECT
    SalesOrderID,
    AVG(CAST(OrderQty AS int)) AS AverageQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
ORDER BY SalesOrderID;

-- 14. For each order get the OrderID, minimum quantity and maximum quantity for that order
SELECT
    SalesOrderID,
    MIN(OrderQty) AS MinQuantity,
    MAX(OrderQty) AS MaxQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
ORDER BY SalesOrderID;


-- 15. Get a list of all managers and total number of employees who report to them
SELECT 
    mgr.BusinessEntityID AS ManagerID,
    p.FirstName + ' ' + p.LastName AS ManagerName,
    COUNT(emp.BusinessEntityID) AS NumberOfReports
FROM HumanResources.Employee emp
JOIN HumanResources.Employee mgr ON mgr.OrganizationNode = emp.OrganizationNode.GetAncestor(1)
JOIN Person.Person p ON mgr.BusinessEntityID = p.BusinessEntityID
GROUP BY mgr.BusinessEntityID, p.FirstName, p.LastName
ORDER BY NumberOfReports DESC, ManagerName;

-- 16. Get the orderID and the total quantity for each order that has a total quantity of greater than 300.
SELECT SalesOrderID, SUM(OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
HAVING SUM(OrderQty) > 300;

-- 17. List of all orders placed on or after 1996/12/31
SELECT SalesOrderID, OrderDate, CustomerID, TotalDue
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '1996-12-31';

-- 18. List of all orders shipped to Canada
SELECT soh.SalesOrderID, soh.OrderDate, soh.ShipDate, sp.CountryRegionCode, sp.Name AS StateProvinceName
FROM Sales.SalesOrderHeader AS soh
JOIN Person.Address AS a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
WHERE sp.CountryRegionCode = 'CA';


-- 19. List of all orders with order total > 200 
SELECT SalesOrderID, OrderDate, CustomerID, TotalDue
FROM Sales.SalesOrderHeader
WHERE TotalDue > 200;

-- 20. List of all countries and sales made in each country 
SELECT cr.Name AS CountryName, SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS soh
JOIN Person.Address AS a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY TotalSales DESC;

-- 21. List of Customer ContactName and numbers of orders they placed 
SELECT 
    p.FirstName + ' ' + p.LastName AS ContactName,
    COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.Customer AS c
JOIN Person.Person AS p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
GROUP BY p.FirstName, p.LastName
ORDER BY NumberOfOrders DESC;

-- 22. List of Customer Contactnames who have placed more than 3 orders
SELECT 
    p.FirstName + ' ' + p.LastName AS ContactName,
    COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.Customer AS c
JOIN Person.Person AS p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
GROUP BY p.FirstName, p.LastName
HAVING COUNT(soh.SalesOrderID) > 3
ORDER BY NumberOfOrders DESC;

-- 23. List of discontinued products which were ordered between 1/1/1997 and 1/1/1998
SELECT DISTINCT 
    p.ProductID, 
    p.Name AS ProductName, 
    sod.UnitPrice, 
    sod.UnitPriceDiscount
FROM Sales.SalesOrderDetail AS sod
JOIN Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
WHERE soh.OrderDate >= '1997-01-01' 
  AND soh.OrderDate < '1998-01-01'
  AND sod.UnitPriceDiscount > 0;

-- 24. List of employee firstname, lastname, superviser Firstname, Lastname
SELECT 
    emp.BusinessEntityID AS EmployeeID,
    pEmp.FirstName AS EmployeeFirstName,
    pEmp.LastName AS EmployeeLastName,
    pMgr.FirstName AS SupervisorFirstName,
    pMgr.LastName AS SupervisorLastName
FROM HumanResources.Employee AS emp
JOIN Person.Person AS pEmp ON emp.BusinessEntityID = pEmp.BusinessEntityID
LEFT JOIN HumanResources.Employee AS mgr 
    ON mgr.OrganizationNode = emp.OrganizationNode.GetAncestor(1)
LEFT JOIN Person.Person AS pMgr ON mgr.BusinessEntityID = pMgr.BusinessEntityID
ORDER BY pEmp.LastName, pEmp.FirstName;

--25-List of employees ID and total sale conducted by employee.
SELECT 
    e.BusinessEntityID AS EmployeeID,
    p.FirstName,
    p.LastName,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS soh
JOIN HumanResources.Employee AS e ON soh.SalesPersonID = e.BusinessEntityID
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
GROUP BY e.BusinessEntityID, p.FirstName, p.LastName
ORDER BY TotalSales DESC;

-- 26. List of employees whose FirstName contains character a.
SELECT 
    e.BusinessEntityID AS EmployeeID,
    p.FirstName,
    p.LastName
FROM HumanResources.Employee AS e
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
WHERE p.FirstName LIKE '%a%'
ORDER BY p.FirstName, p.LastName;

-- 27. List of managers who have more than four people reporting to them
SELECT 
    mgr.BusinessEntityID AS ManagerID,
    p.FirstName AS ManagerFirstName,
    p.LastName AS ManagerLastName,
    COUNT(emp.BusinessEntityID) AS ReportCount
FROM HumanResources.Employee AS emp
JOIN HumanResources.Employee AS mgr 
    ON emp.OrganizationNode.GetAncestor(1) = mgr.OrganizationNode
JOIN Person.Person AS p ON mgr.BusinessEntityID = p.BusinessEntityID
GROUP BY mgr.BusinessEntityID, p.FirstName, p.LastName
HAVING COUNT(emp.BusinessEntityID) > 4
ORDER BY ReportCount DESC;

-- 28. List of orders and ProductNames
SELECT 
    sod.SalesOrderID,
    p.Name AS ProductName
FROM Sales.SalesOrderDetail AS sod
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
ORDER BY sod.SalesOrderID;

-- 29. List of orders placed by best customer
WITH BestCustomer AS (
    SELECT TOP 1 CustomerID
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
    ORDER BY SUM(TotalDue) DESC
)
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    c.CustomerID,
    p.FirstName,
    p.LastName
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID
JOIN Person.Person AS p ON c.PersonID = p.BusinessEntityID
WHERE soh.CustomerID = (SELECT CustomerID FROM BestCustomer)
ORDER BY soh.OrderDate;


-- 30. List of orders placed by customer who do not have a Fax number
WITH CustomersWithFax AS (
    SELECT DISTINCT pp.BusinessEntityID
    FROM Person.PersonPhone AS pp
    JOIN Person.PhoneNumberType AS pt ON pp.PhoneNumberTypeID = pt.PhoneNumberTypeID
    WHERE pt.Name = 'Fax'
)
SELECT 
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue,
    c.CustomerID,
    p.FirstName,
    p.LastName
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID
JOIN Person.Person AS p ON c.PersonID = p.BusinessEntityID
WHERE p.BusinessEntityID NOT IN (SELECT BusinessEntityID FROM CustomersWithFax)
ORDER BY soh.OrderDate;

-- 31. List of postal codes where the product Tofu was shipped
SELECT DISTINCT a.PostalCode
FROM Sales.SalesOrderDetail AS sod
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
JOIN Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Person.Address AS a ON soh.ShipToAddressID = a.AddressID
WHERE p.Name = 'Tofu'
ORDER BY a.PostalCode;

-- 32. List of product Names that were shipped to France
SELECT DISTINCT p.Name AS ProductName
FROM Sales.SalesOrderHeader AS soh
JOIN Person.Address AS a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
WHERE cr.Name = 'France'
ORDER BY p.Name;

-- 33. List of ProductNames and Categories for the supplier 'Speciality Biscuits, Ltd
SELECT 
    p.Name AS ProductName,
    pc.Name AS CategoryName
FROM Purchasing.Vendor AS v
JOIN Purchasing.ProductVendor AS pv ON v.BusinessEntityID = pv.BusinessEntityID
JOIN Production.Product AS p ON pv.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory AS psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory AS pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE v.Name = 'Speciality Biscuits, Ltd'
ORDER BY CategoryName, ProductName;


-- 34. List of products that were never ordered
SELECT p.ProductID, p.Name AS ProductName
FROM Production.Product AS p
WHERE p.ProductID NOT IN (
    SELECT DISTINCT ProductID
    FROM Sales.SalesOrderDetail
)
ORDER BY p.Name;

-- 35. List of products where units in stock is less than 10 and units on order are 0
SELECT p.ProductID, p.Name, pi.Quantity AS UnitsInStock
FROM Production.Product AS p
JOIN Production.ProductInventory AS pi ON p.ProductID = pi.ProductID
WHERE pi.Quantity < 10
ORDER BY p.Name;

-- 36. List of top 10 countries by sales
SELECT TOP 10
    cr.Name AS Country,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS soh
JOIN Person.Address AS a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY TotalSales DESC;


-- 37. Number of orders each employee has taken for customers with CustomerIDs between A and AO.
SELECT 
    e.BusinessEntityID AS EmployeeID,
    p.FirstName,
    p.LastName,
    COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID
JOIN HumanResources.Employee AS e ON soh.SalesPersonID = e.BusinessEntityID
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
WHERE c.AccountNumber >= 'A' AND c.AccountNumber <= 'AO'
GROUP BY e.BusinessEntityID, p.FirstName, p.LastName
ORDER BY NumberOfOrders DESC;

-- 38. Orderdate of most expensive order
SELECT TOP 1 OrderDate, TotalDue
FROM Sales.SalesOrderHeader
ORDER BY TotalDue DESC;

-- 39. Product name and total revenue from that product
SELECT 
    p.Name AS ProductName,
    SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail AS sod
JOIN Production.Product AS p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalRevenue DESC;

-- 40. Supplierid and number of products offered
SELECT 
    pv.BusinessEntityID AS SupplierID,
    COUNT(DISTINCT pv.ProductID) AS NumberOfProductsOffered
FROM Purchasing.ProductVendor AS pv
GROUP BY pv.BusinessEntityID
ORDER BY NumberOfProductsOffered DESC;

-- 41. Top ten customers based on their business
SELECT TOP 10
    c.CustomerID,
    c.AccountNumber,
    SUM(soh.TotalDue) AS TotalBusiness
FROM Sales.Customer AS c
JOIN Sales.SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, c.AccountNumber
ORDER BY TotalBusiness DESC;


-- 42. What is the total revenue of that Company
SELECT SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader;



























