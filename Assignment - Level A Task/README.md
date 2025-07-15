# SQL Stored Procedure — Count Total Working Hours

This repository contains a SQL Server stored procedure to calculate the total number of working hours between two datetime values.

### ✅ Logic:
- Excludes all **Sundays**
- Excludes **1st and 2nd Saturdays** (except if start or end date is on them)
- Adds **24 hours per working day**
- Works with SQL Server / SSMS (no external tables required)

---

### 🔧 Inputs
The procedure takes two parameters:
- `@Start_Date` (DATETIME)
- `@End_Date` (DATETIME)

### Output Table
The result is inserted into a table:
`counttotalworkinhours (
    START_DATE DATETIME,
    END_DATE DATETIME,
    NO_OF_HOURS INT
)`

# Sample Execution
`Copy
Edit
EXEC Get_Working_Hours '2023-07-01', '2023-07-17';
EXEC Get_Working_Hours '2023-07-12', '2023-07-13';`

# Sample Output 

`| START\_DATE | END\_DATE  | NO\_OF\_HOURS |
 | ----------- | ---------- | ------------- |
 | 2023-07-01  | 2023-07-17 | 288           |
 | 2023-07-12  | 2023-07-13 | 24            |`


# Tools Used
- SQL Server
- SSMS (SQL Server Management Studio)


# Contact 

Feel free to reach out to me at:
- *Name*: [Anjali Lalwani](https://github.com/lalwanianjali21/SQL-CSI.git)
- *ID*: CT_CSI_SQ_6425
- *Email*: anjalilalwani442@gmail.com
- *LinkedIn*: [Anjali Lalwani](https://www.linkedin.com/in/anjali-lalwani-702a7924a)


