-- SCD Type 0 – Retain Original Data (No changes allowed) --

CREATE PROCEDURE SCD_Type0
AS
BEGIN
    INSERT INTO Customer (CustomerID, Name, Address)
    SELECT s.CustomerID, s.Name, s.Address
    FROM Stg_Customer s
    WHERE NOT EXISTS (
        SELECT 1 FROM Customer c WHERE c.CustomerID = s.CustomerID
    );
END;


--  SCD Type 1 – Overwrite the data --

CREATE PROCEDURE SCD_Type1
AS
BEGIN
    MERGE Customer AS Target
    USING Stg_Customer AS Source
    ON Target.CustomerID = Source.CustomerID
    WHEN MATCHED THEN
        UPDATE SET Target.Name = Source.Name, Target.Address = Source.Address
    WHEN NOT MATCHED THEN
        INSERT (CustomerID, Name, Address)
        VALUES (Source.CustomerID, Source.Name, Source.Address);
END;


-- SCD Type 2 – Keep full history --

CREATE PROCEDURE SCD_Type2
AS
BEGIN
    -- Expire old record
    UPDATE Customer
    SET EndDate = GETDATE(), IsCurrent = 0
    FROM Customer c
    JOIN Stg_Customer s ON c.CustomerID = s.CustomerID
    WHERE c.IsCurrent = 1
      AND (c.Name <> s.Name OR c.Address <> s.Address);

    -- Insert new record
    INSERT INTO Customer (CustomerID, Name, Address, StartDate, EndDate, IsCurrent, Version)
    SELECT s.CustomerID, s.Name, s.Address, GETDATE(), NULL, 1,
           COALESCE(MAX(c.Version), 0) + 1
    FROM Stg_Customer s
    LEFT JOIN Customer c ON s.CustomerID = c.CustomerID
    GROUP BY s.CustomerID, s.Name, s.Address;
END;


-- SCD Type 3 – Track limited history (e.g., previous value) --

CREATE PROCEDURE SCD_Type3
AS
BEGIN
    UPDATE Customer
    SET PreviousAddress = CurrentAddress,
        CurrentAddress = s.Address
    FROM Customer c
    JOIN Stg_Customer s ON c.CustomerID = s.CustomerID
    WHERE c.CurrentAddress <> s.Address;

    INSERT INTO Customer (CustomerID, CurrentAddress)
    SELECT s.CustomerID, s.Address
    FROM Stg_Customer s
    WHERE NOT EXISTS (
        SELECT 1 FROM Customer c WHERE c.CustomerID = s.CustomerID
    );
END;


-- SCD Type 4 – Use a historical table --

CREATE PROCEDURE SCD_Type4
AS
BEGIN
    -- Move existing to history
    INSERT INTO Customer_History
    SELECT * FROM Customer c
    JOIN Stg_Customer s ON c.CustomerID = s.CustomerID
    WHERE c.Name <> s.Name OR c.Address <> s.Address;

    -- Update current
    UPDATE Customer
    SET Name = s.Name, Address = s.Address
    FROM Customer c
    JOIN Stg_Customer s ON c.CustomerID = s.CustomerID;

    -- Insert new records
    INSERT INTO Customer (CustomerID, Name, Address)
    SELECT s.CustomerID, s.Name, s.Address
    FROM Stg_Customer s
    WHERE NOT EXISTS (
        SELECT 1 FROM Customer c WHERE c.CustomerID = s.CustomerID
    );
END;


-- SCD Type 6 – Hybrid of 1, 2, and 3 --

CREATE PROCEDURE SCD_Type6
AS
BEGIN
    -- Step 1: Expire current record
    UPDATE Customer
    SET EndDate = GETDATE(), IsCurrent = 0,
        PreviousAddress = Address
    FROM Customer c
    JOIN Stg_Customer s ON c.CustomerID = s.CustomerID
    WHERE c.IsCurrent = 1 AND c.Address <> s.Address;

    -- Step 2: Insert new record
    INSERT INTO Customer (CustomerID, Name, Address, StartDate, EndDate, IsCurrent, Version, PreviousAddress)
    SELECT s.CustomerID, s.Name, s.Address, GETDATE(), NULL, 1,
           COALESCE(MAX(c.Version), 0) + 1,
           c.Address
    FROM Stg_Customer s
    JOIN Customer c ON c.CustomerID = s.CustomerID
    WHERE c.IsCurrent = 1
    GROUP BY s.CustomerID, s.Name, s.Address, c.Address;
END;



