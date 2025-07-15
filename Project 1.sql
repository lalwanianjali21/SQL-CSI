CREATE TABLE counttotalworkinhours (
    START_DATE DATETIME,
    END_DATE DATETIME,
    NO_OF_HOURS INT
);

CREATE PROCEDURE Get_Working_Hours
    @Start_Date DATETIME,
    @End_Date DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @date DATETIME = @Start_Date;
    DECLARE @hours INT = 0;
    DECLARE @firstDayOfMonth DATETIME;

    WHILE @date <= @End_Date
    BEGIN
        DECLARE @isSunday BIT = CASE WHEN DATENAME(WEEKDAY, @date) = 'Sunday' THEN 1 ELSE 0 END;
        DECLARE @isSaturday BIT = CASE WHEN DATENAME(WEEKDAY, @date) = 'Saturday' THEN 1 ELSE 0 END;

        DECLARE @sat_count INT = 0;

        IF @isSaturday = 1
        BEGIN
            SET @firstDayOfMonth = DATEFROMPARTS(YEAR(@date), MONTH(@date), 1);
            DECLARE @d DATETIME = @firstDayOfMonth;

            WHILE @d <= @date
            BEGIN
                IF DATENAME(WEEKDAY, @d) = 'Saturday'
                    SET @sat_count += 1;

                SET @d = DATEADD(DAY, 1, @d);
            END
        END

        IF (
            @isSunday = 0 AND (@isSaturday = 0 OR @sat_count IN (1, 2))
        )
        BEGIN
            SET @hours += 24;
        END
        ELSE IF @date = @Start_Date OR @date = @End_Date
        BEGIN
            SET @hours += 24;
        END

        SET @date = DATEADD(DAY, 1, @date);
    END

    INSERT INTO counttotalworkinhours (START_DATE, END_DATE, NO_OF_HOURS)
    VALUES (@Start_Date, @End_Date, @hours);
END;

EXEC Get_Working_Hours '2023-07-01', '2023-07-17';
EXEC Get_Working_Hours '2023-07-12', '2023-07-13';

SELECT * FROM counttotalworkinhours;