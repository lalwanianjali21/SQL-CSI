-- 175. Combine Two Tables -- 

SELECT p.firstName, p.lastName, a.city, a.state
FROM Person p
LEFT JOIN Address a
ON p.personId = a.personId;


-- 176. Second Highest Salary --
WITH highest_salary AS (
    SELECT MAX(salary) AS salary
    FROM Employee
)
SELECT MAX(salary) AS SecondHighestSalary
FROM Employee
WHERE salary < (SELECT salary FROM highest_salary);


-- 177. Nth Highest salary --
CREATE FUNCTION getNthHighestSalary(@N INT) RETURNS INT AS
BEGIN
    RETURN (
        SELECT DISTINCT Salary FROM Employee ORDER BY Salary DESC OFFSET @N-1 ROWS FETCH NEXT 1 ROWS ONLY
    );
END



-- 1757. Recyclable and low fat products --
SELECT product_id FROM Products
WHERE low_fats = 'Y' and recyclable = 'Y';


-- 584. Find Customer Refree --
SELECT name FROM Customer WHERE referee_id is null or referee_id!=2;


-- 595. Big Countries --
SELECT name, population, area FROM World
WHERE population >= 25000000 OR area >= 3000000;


-- 1148. Article Views I --
SELECT DISTINCT author_id as id FROM Views
WHERE author_id = viewer_id ORDER BY id;


-- 1683. Invalid Tweets --
SELECT tweet_id FROM Tweets
WHERE LEN(content) > 15;


-- 1378. Replace Employee ID with the unique identifier --
SELECT EmployeeUNI.unique_id ,Employees.name FROM 
 Employees LEFT JOIN EmployeeUNI 
 ON Employees.id=EmployeeUNI.id;


 -- 1068. Product Sales Analysis I --
SELECT product_name, year, price FROM Sales
INNER JOIN Product ON Sales.product_id = Product.product_id;


-- 1581. Customer Who Visited but did not make any transactions --
SELECT
    customer_id,
    COUNT(visit_id) AS count_no_trans
FROM Visits
WHERE visit_id NOT IN (
    SELECT visit_id FROM Transactions
)
GROUP BY customer_id

-- 197. Rising Temperature --
SELECT current_day.id
FROM Weather AS current_day
WHERE EXISTS (
    SELECT 1
    FROM Weather AS yesterday
    WHERE current_day.temperature > yesterday.temperature
    AND current_day.recordDate = DATEADD(day, 1, yesterday.recordDate)
);

-- 1661. Average time of process per machine --
SELECT machine_id, ROUND(AVG(time_taken),3) AS processing_time
FROM(
    SELECT machine_id,process_id, MAX(timestamp)-MIN(timestamp) AS time_taken
    FROM Activity
    GROUP BY machine_id,process_id
)T1
GROUP BY machine_id


-- 577. Employee Bonus --
SELECT e.name, b.bonus FROM Employee e 
LEFT JOIN Bonus b ON e.empId = b.empId
WHERE bonus < 1000 or Bonus is NULL;


-- 1280. Students and examinations --
SELECT 
stu.student_id, stu.student_name, sub.subject_name, COUNT(exam.subject_name) AS attended_exams
FROM STUDENTS AS stu
CROSS JOIN SUBJECTS AS sub
LEFT JOIN EXAMINATIONS AS exam
ON exam.student_id = stu.student_id AND sub.subject_name = exam.subject_name
GROUP BY
stu.student_id, stu.student_name, sub.subject_name
ORDER BY
stu.student_id, sub.subject_name;


-- 570. Managers with at least 5 Direct reports --
SELECT name FROM Employee 
WHERE id IN(
    SELECT managerId 
    FROM Employee GROUP BY managerId
    Having COUNT(*) >= 5
)


-- 1934. Confirmation Rate -- 
SELECT S.user_id ,
ROUND(ISNULL(SUM(CASE WHEN action='confirmed' THEN 1 END)*1.00/COUNT(*),0),2) AS confirmation_rate 
FROM  Signups S  LEFT JOIN Confirmations C
ON S.user_id=C.user_id 
GROUP BY S.user_id


-- 1251. Average selling price --
select p.product_id ,Coalesce(round(sum(p.price * u.units) / sum(u.units),2),0) as average_price from prices p left join unitssold u
on p.product_id = u.product_id and u.purchase_date between p.start_date and p.end_date
group by p.product_id;


-- 550. Game Play Analysis IV --
SELECT
  ROUND(COUNT(DISTINCT player_id) / (SELECT COUNT(DISTINCT player_id) FROM Activity), 2) AS fraction
FROM
  Activity
WHERE
  (player_id, DATE_SUB(event_date, INTERVAL 1 DAY))
  IN (
    SELECT player_id, MIN(event_date) AS first_login FROM Activity GROUP BY player_id
  )


-- 1174. Immediate Food Delivery II --
Select 
    round(avg(order_date = customer_pref_delivery_date)*100, 2) as immediate_percentage
from Delivery
where (customer_id, order_date) in (
  Select customer_id, min(order_date) 
  from Delivery
  group by customer_id
);


-- 1193. Monthly Transactions I --
SELECT  SUBSTR(trans_date,1,7) as month, country, count(id) as trans_count, SUM(CASE WHEN state = 'approved' then 1 else 0 END) as approved_count, SUM(amount) as trans_total_amount, SUM(CASE WHEN state = 'approved' then amount else 0 END) as approved_total_amount
FROM Transactions
GROUP BY month, country


-- 620. Not Boring Movies --
SELECT * FROM Cinema WHERE MOD( id, 2) = 1 AND 
description <> 'boring' ORDER BY rating DESC


-- 1633. Percentage of Users Attended a Contest --
select 
contest_id, 
round(count(distinct user_id) * 100 /(select count(user_id) from Users) ,2) as percentage
from  Register
group by contest_id
order by percentage desc,contest_id


-- 1075. Project Employees I --
select
    project_id,
    round(sum(experience_years)/count(project_id), 2) average_years
from
    Project P
left join
    Employee E on P.employee_id = E.employee_id
group by project_id


-- 1211. Queries Quality and Percentage --
Select distinct query_name , round(avg(rating/position) over(partition by query_name) ,2) as quality,
round(avg(case when rating<3 then 1 else 0 end) over(partition by query_name)*100,2) as poor_query_percentage from queries
where query_name is not null
