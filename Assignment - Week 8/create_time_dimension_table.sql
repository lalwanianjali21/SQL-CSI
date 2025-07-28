CREATE TABLE TimeDimension (
    SKDate VARCHAR(8) PRIMARY KEY,
    KeyDate DATE,
    `Date` DATE,
    CalendarDay INT,
    CalendarMonth INT,
    CalendarQuarter INT,
    CalendarYear INT,
    DayNameLong VARCHAR(20),
    DayNameShort VARCHAR(5),
    DayNumberOfWeek INT,
    DayNumberOfYear INT,
    DaySuffix VARCHAR(5),
    `Fiscal Week` INT,
    `Fiscal Period` INT,
    FiscalQuarter INT,
    `Fiscal Year` INT,
    `Fiscal Year/Period` VARCHAR(10)
);

