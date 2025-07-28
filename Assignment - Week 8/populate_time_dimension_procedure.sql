DELIMITER //

CREATE PROCEDURE PopulateTimeDimension(IN input_date DATE)
BEGIN
    DECLARE start_date DATE;
    DECLARE end_date DATE;

    SET start_date = DATE_FORMAT(input_date, '%Y-01-01');
    SET end_date = DATE_FORMAT(input_date, '%Y-12-31');

    WITH RECURSIVE DateSequence AS (
        SELECT start_date AS TheDate
        UNION ALL
        SELECT DATE_ADD(TheDate, INTERVAL 1 DAY)
        FROM DateSequence
        WHERE TheDate < end_date
    )
    INSERT INTO TimeDimension (
        SKDate,
        KeyDate,
        `Date`,
        CalendarDay,
        CalendarMonth,
        CalendarQuarter,
        CalendarYear,
        DayNameLong,
        DayNameShort,
        DayNumberOfWeek,
        DayNumberOfYear,
        DaySuffix,
        `Fiscal Week`,
        `Fiscal Period`,
        FiscalQuarter,
        `Fiscal Year`,
        `Fiscal Year/Period`
    )
    SELECT 
        DATE_FORMAT(TheDate, '%Y%m%d'),
        TheDate,
        TheDate,
        DAY(TheDate),
        MONTH(TheDate),
        QUARTER(TheDate),
        YEAR(TheDate),
        DAYNAME(TheDate),
        LEFT(DAYNAME(TheDate), 3),
        DAYOFWEEK(TheDate),
        DAYOFYEAR(TheDate),
        CONCAT(
            DAY(TheDate),
            CASE 
                WHEN DAY(TheDate) IN (11,12,13) THEN 'th'
                WHEN RIGHT(DAY(TheDate),1) = '1' THEN 'st'
                WHEN RIGHT(DAY(TheDate),1) = '2' THEN 'nd'
                WHEN RIGHT(DAY(TheDate),1) = '3' THEN 'rd'
                ELSE 'th'
            END
        ),
        WEEK(TheDate, 3),
        MONTH(TheDate),
        QUARTER(TheDate),
        YEAR(TheDate),
        CONCAT(YEAR(TheDate), LPAD(MONTH(TheDate), 2, '0'))
    FROM DateSequence;
END //

DELIMITER ;

