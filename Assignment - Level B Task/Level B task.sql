USING AdventureWorks2022;

--Procedure 1
GO
CREATE OR ALTER PROCEDURE Sales.InsertOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity SMALLINT,
    @Discount REAL = 0
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @AvailableStock INT, @ReorderLevel SMALLINT, @ProductUnitPrice MONEY;
        DECLARE @OrderExists BIT = 0;
        IF EXISTS (SELECT 1 FROM Sales.SalesOrderHeader WHERE SalesOrderID = @OrderID)
            SET @OrderExists = 1;
        ELSE
        BEGIN
            PRINT 'Failed to place the order. Order ID does not exist.';
            ROLLBACK;
            RETURN -1;
        END;
        SELECT 
            @AvailableStock = ISNULL(SUM(pi.Quantity), 0),
            @ReorderLevel = p.ReorderPoint,
            @ProductUnitPrice = p.ListPrice
        FROM Production.Product p
        LEFT JOIN Production.ProductInventory pi ON p.ProductID = pi.ProductID
        WHERE p.ProductID = @ProductID
        GROUP BY p.ReorderPoint, p.ListPrice;
        IF @ProductUnitPrice IS NULL
        BEGIN
            PRINT 'Failed to place the order. Product does not exist.';
            ROLLBACK;
            RETURN -1;
        END;
        IF @AvailableStock < @Quantity
        BEGIN
            PRINT 'Failed to place the order. Insufficient stock. Available: ' + CAST(@AvailableStock AS VARCHAR);
            ROLLBACK;
            RETURN -1;
        END;
        SET @UnitPrice = ISNULL(@UnitPrice, @ProductUnitPrice);
        INSERT INTO Sales.SalesOrderDetail (SalesOrderID, ProductID, UnitPrice, OrderQty, UnitPriceDiscount)
        VALUES (@OrderID, @ProductID, @UnitPrice, @Quantity, @Discount);
        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'Failed to place the order. Please try again.';
            ROLLBACK;
            RETURN -1;
        END;
        UPDATE Production.ProductInventory
        SET Quantity = Quantity - @Quantity,
            ModifiedDate = GETDATE()
        WHERE ProductID = @ProductID AND LocationID = 1;
        IF @AvailableStock - @Quantity <= @ReorderLevel
        BEGIN
            PRINT 'Warning: ProductID ' + CAST(@ProductID AS VARCHAR) + ' stock is at or below reorder level.';
        END;
        PRINT 'Order detail inserted successfully.';
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        PRINT 'Error: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;

--Procedure 2
GO
CREATE OR ALTER PROCEDURE Sales.UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity SMALLINT = NULL,
    @Discount REAL = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @CurrentQuantity SMALLINT, @QuantityDifference SMALLINT, @AvailableStock INT;
        SELECT @CurrentQuantity = OrderQty
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;
        IF @CurrentQuantity IS NULL
        BEGIN
            PRINT 'OrderID or ProductID does not exist.';
            ROLLBACK;
            RETURN -1;
        END;
        IF @Quantity IS NOT NULL AND @Quantity <> @CurrentQuantity
        BEGIN
            SET @QuantityDifference = @Quantity - @CurrentQuantity;
            SELECT @AvailableStock = ISNULL(SUM(Quantity), 0)
            FROM Production.ProductInventory
            WHERE ProductID = @ProductID;
            IF @QuantityDifference > 0 AND @AvailableStock < @QuantityDifference
            BEGIN
                PRINT 'Insufficient stock to increase quantity. Available: ' + CAST(@AvailableStock AS VARCHAR);
                ROLLBACK;
                RETURN -1;
            END;
        END;
        UPDATE Sales.SalesOrderDetail
        SET 
            UnitPrice = ISNULL(@UnitPrice, UnitPrice),
            OrderQty = ISNULL(@Quantity, OrderQty),
            UnitPriceDiscount = ISNULL(@Discount, UnitPriceDiscount),
            ModifiedDate = GETDATE()
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;
        IF @Quantity IS NOT NULL AND @QuantityDifference <> 0
        BEGIN
            UPDATE Production.ProductInventory
            SET Quantity = Quantity - @QuantityDifference,
                ModifiedDate = GETDATE()
            WHERE ProductID = @ProductID AND LocationID = 1;
        END;
        PRINT 'Order details updated successfully.';
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        PRINT 'Error: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;

--Procedure 3
GO
CREATE OR ALTER PROCEDURE Sales.GetOrderDetails
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID)
    BEGIN
        SELECT 
            SalesOrderID,
            ProductID,
            UnitPrice,
            OrderQty,
            UnitPriceDiscount
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID;
    END
    ELSE
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist.';
        RETURN 1;
    END;
END;

--Procedure 4
GO
CREATE OR ALTER PROCEDURE Sales.DeleteOrderDetails
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @OrderQty SMALLINT;
        SELECT @OrderQty = OrderQty
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;
        IF @OrderQty IS NULL
        BEGIN
            PRINT 'Invalid OrderID or ProductID.';
            ROLLBACK;
            RETURN -1;
        END;
        DELETE FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;
        UPDATE Production.ProductInventory
        SET Quantity = Quantity + @OrderQty,
            ModifiedDate = GETDATE()
        WHERE ProductID = @ProductID AND LocationID = 1;
        PRINT 'Order detail deleted and inventory restored.';
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        PRINT 'Error: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;

-- Function 1: MM/DD/YYYY
GO
CREATE OR ALTER FUNCTION dbo.FormatDateMMDDYYYY (@InputDate DATETIME)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CONVERT(VARCHAR(10), @InputDate, 101);
END;


-- Function 2: YYYY/MM/DD
GO
CREATE OR ALTER FUNCTION dbo.FormatDateYYYYMMDD (@InputDate DATETIME)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CONVERT(VARCHAR(10), @InputDate, 112);
END;

--test functions
GO
SELECT dbo.FormatDateMMDDYYYY('2004-09-15 23:30:07.920') AS MMDDYYYY,
       dbo.FormatDateYYYYMMDD('2004-09-15 23:30:07.920') AS YYYYMMDD;


-- View 1
GO
CREATE OR ALTER VIEW Sales.vwCustomerOrders
AS
SELECT 
    CASE 
        WHEN p.FirstName IS NOT NULL THEN p.FirstName + ' ' + p.LastName
        WHEN s.Name IS NOT NULL THEN s.Name
        ELSE 'Unknown Customer'
    END AS CompanyName,
    sod.SalesOrderID AS OrderID,
    soh.OrderDate,
    sod.ProductID,
    pr.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    sod.OrderQty * sod.UnitPrice AS Total
FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Production.Product pr ON sod.ProductID = pr.ProductID
    INNER JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
    LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID;

-- View 2
GO
CREATE OR ALTER VIEW Sales.vwCustomerOrdersYesterday
AS
SELECT 
    CASE 
        WHEN p.FirstName IS NOT NULL THEN p.FirstName + ' ' + p.LastName
        WHEN s.Name IS NOT NULL THEN s.Name
        ELSE 'Unknown Customer'
    END AS CompanyName,
    sod.SalesOrderID AS OrderID,
    soh.OrderDate,
    sod.ProductID,
    pr.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    sod.OrderQty * sod.UnitPrice AS Total
FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    INNER JOIN Production.Product pr ON sod.ProductID = pr.ProductID
    INNER JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
    LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
WHERE CAST(soh.OrderDate AS DATE) = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);

-- View 3
GO
CREATE OR ALTER VIEW Production.MyProducts
AS
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.ListPrice AS UnitPrice,
    ISNULL(v.Name, 'No Vendor') AS CompanyName,
    ISNULL(c.Name, 'No Category') AS CategoryName
FROM Production.Product p
    LEFT JOIN Purchasing.ProductVendor pv ON p.ProductID = pv.ProductID
    LEFT JOIN Purchasing.Vendor v ON pv.BusinessEntityID = v.BusinessEntityID
    LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory c ON ps.ProductCategoryID = c.ProductCategoryID
WHERE p.SellEndDate IS NULL OR p.SellEndDate > GETDATE();


-- Trigger 1
GO
CREATE OR ALTER TRIGGER Sales.InsteadOfDeleteOrders
ON Sales.SalesOrderHeader
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM Sales.SalesOrderDetail
        WHERE SalesOrderID IN (SELECT SalesOrderID FROM deleted);

        DELETE FROM Sales.SalesOrderHeader
        WHERE SalesOrderID IN (SELECT SalesOrderID FROM deleted);
        PRINT 'Order(s) deleted successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Error deleting order: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;


-- Trigger 2
GO
CREATE OR ALTER TRIGGER Sales.CheckStockOnOrderDetails
ON Sales.SalesOrderDetail
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (
            SELECT 1
            FROM inserted i
            LEFT JOIN Production.ProductInventory pi ON i.ProductID = pi.ProductID AND pi.LocationID = 1
            GROUP BY i.ProductID, i.OrderQty
            HAVING ISNULL(SUM(pi.Quantity), 0) < i.OrderQty
        )
        BEGIN
            PRINT 'Order cannot be completed because of insufficient stock.';
            RETURN;
        END;

        INSERT INTO Sales.SalesOrderDetail (SalesOrderID, ProductID, UnitPrice, OrderQty, UnitPriceDiscount)
        SELECT SalesOrderID, ProductID, UnitPrice, OrderQty, UnitPriceDiscount
        FROM inserted;
        UPDATE pi
        SET Quantity = pi.Quantity - i.OrderQty,
            ModifiedDate = GETDATE()
        FROM Production.ProductInventory pi
        INNER JOIN inserted i ON pi.ProductID = i.ProductID
        WHERE pi.LocationID = 1;
    END TRY
    BEGIN CATCH
        PRINT 'Error processing order: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;



GO
DECLARE @TestOrderID INT = (SELECT TOP 1 SalesOrderID FROM Sales.SalesOrderHeader ORDER BY SalesOrderID DESC);
DECLARE @TestProductID INT = (SELECT TOP 1 ProductID FROM Production.Product WHERE ListPrice > 0 ORDER BY ProductID);
PRINT 'Testing with OrderID: ' + CAST(@TestOrderID AS VARCHAR) + ', ProductID: ' + CAST(@TestProductID AS VARCHAR);

-- Testing procedures
EXEC Sales.InsertOrderDetails @TestOrderID, @TestProductID, NULL, 1, 0.05;
EXEC Sales.GetOrderDetails @TestOrderID;