# Campus Issue Management System

## Overview

The **Campus Issue Management System** is a MySQL-based database project designed to manage and track maintenance-related issues reported by students on a college campus.

Students can report problems such as electrical faults, projector issues, damaged furniture, internet issues, broken equipments and plumbing issues. The system stores issue details, assigns maintenance staff, tracks issue status changes, and records resolution information.

The project demonstrates important DBMS concepts such as:

* Database and table creation
* Primary and foreign keys
* Constraints
* Joins
* Subqueries
* Aggregate functions
* Triggers
* Stored procedures
* User-defined functions
* Transactions
* Savepoints and rollback
* Indexing

---

## Database Name

```sql
campus_issues
```

The database is created using:

```sql
CREATE DATABASE IF NOT EXISTS campus_issues;
USE campus_issues;
```

---

## Database Structure

The system contains six main tables:

### 1. Student Table

The `student` table stores information about students who can report campus issues.

| Column       | Description              |
| ------------ | ------------------------ |
| `student_id` | Unique ID of the student |
| `name`       | Student name             |
| `email`      | Unique email address     |
| `dept`       | Department               |
| `phone`      | Contact number           |

The student ID is automatically generated using `AUTO_INCREMENT`.

---

### 2. Staff Table

The `staff` table stores information about maintenance staff members.

| Column     | Description          |
| ---------- | -------------------- |
| `staff_id` | Unique staff ID      |
| `name`     | Staff member name    |
| `role`     | Staff specialization |
| `dept`     | Department           |

Example roles include:

* Electrician
* IT Support
* Carpenter

---

### 3. Location Table

The `location` table stores campus locations where problems may occur.

| Column        | Description        |
| ------------- | ------------------ |
| `location_id` | Unique location ID |
| `building`    | Building name      |
| `room_no`     | Room number        |
| `floor_no`    | Floor number       |

Example locations include Academic Blocks and Hostel Blocks.

---

### 4. Category Table

The `category` table stores the different types of campus issues.

Available categories include:

* Electrical
* AV/Projector
* Furniture
* Internet
* Plumbing

Each category has a unique `category_id`.

---

### 5. Issue Table

The `issue` table is the main table of the system.

It connects students, locations, issue categories, and staff members.

| Column          | Description                    |
| --------------- | ------------------------------ |
| `issue_id`      | Unique issue ID                |
| `student_id`    | Student who reported the issue |
| `location_id`   | Location of the issue          |
| `category_id`   | Type of issue                  |
| `staff_id`      | Assigned maintenance staff     |
| `description`   | Description of the problem     |
| `status`        | Current issue status           |
| `date_reported` | Date and time when reported    |
| `date_resolved` | Date and time when resolved    |

The possible status values are:

```text
Open
Assigned
In Progress
Resolved
Rejected
```

The default status of a newly created issue is `Open`.

---

### 6. Status Log Table

The `status_log` table maintains the history of issue status changes.

| Column       | Description             |
| ------------ | ----------------------- |
| `log_id`     | Unique log ID           |
| `issue_id`   | Related issue           |
| `old_status` | Previous issue status   |
| `new_status` | Updated issue status    |
| `changed_on` | Date and time of change |

This table is automatically updated using a trigger.

---

## Entity Relationships

The main relationships in the database are:

```text
Student
   |
   | reports
   v
 Issue -------- Category
   |
   | occurs at
   v
Location

 Issue -------- Staff
   |
   | status changes
   v
Status_Log
```

Relationships:

```text
Student 1 ----- M Issue
Location 1 ---- M Issue
Category 1 ---- M Issue
Staff 1 ------- M Issue
Issue 1 ------- M Status_Log
```

A student can report multiple issues, while every issue belongs to one student.

A location can have multiple issues.

A category can contain multiple issues.

A staff member can be assigned multiple issues.

An issue can have multiple status log records.

---

## Sample Data

The database initially contains three students:

```text
Aman Verma
Riya Sharma
Kabir Singh
```

Three staff members are also inserted:

```text
Ramesh Yadav - Electrician
Suresh Patel - IT Support
Vikas Rao - Carpenter
```

Sample locations include:

```text
Academic Block 1 - Room 101
Academic Block 2 - Room 204
Hostel Block C - G-12
```

---

# Triggers

The project uses three database triggers.

## 1. Prevent Duplicate Issue Trigger

Trigger:

```sql
trg_prevent_duplicate
```

This trigger runs **before inserting a new issue**.

It checks whether the same student has already reported an unresolved issue for the same location and category.

If such an issue already exists, the insertion is stopped.

Example error message:

```text
Is location/category ke liye already ek open issue exist karta hai
```

This avoids unnecessary duplicate complaints.

---

## 2. Status Log Trigger

Trigger:

```sql
trg_status_log
```

This trigger executes after an issue is updated.

If the issue status changes, the old and new statuses are automatically inserted into the `status_log` table.

For example:

```text
Open → Assigned
Assigned → Resolved
```

This provides a history of the issue lifecycle.

---

## 3. Automatic Resolution Date Trigger

Trigger:

```sql
trg_auto_resolve_date
```

This trigger executes before an issue is updated.

When the status changes to:

```text
Resolved
```

the trigger automatically stores the current date and time in:

```sql
date_resolved
```

Therefore, the user does not have to manually enter the resolution date.

---

# Stored Procedures

The project contains two stored procedures.

## 1. `report_issue()`

The procedure is used for reporting a new campus problem.

Syntax:

```sql
CALL report_issue(
    student_id,
    location_id,
    category_id,
    description
);
```

Example:

```sql
CALL report_issue(
    1,
    1,
    1,
    'Room 101 ka switchboard kaam nahi kar raha'
);
```

The procedure uses a transaction.

If the issue is inserted successfully, the transaction is committed.

If an SQL error occurs, the transaction is rolled back.

Successful output:

```text
Issue reported successfully.
```

---

## 2. `assign_staff()`

The procedure assigns a maintenance staff member to an existing issue.

Syntax:

```sql
CALL assign_staff(issue_id, staff_id);
```

Example:

```sql
CALL assign_staff(1, 1);
```

The operation updates:

```text
staff_id
status = Assigned
```

If the issue does not exist, the procedure displays:

```text
Issue ID not found.
```

Otherwise:

```text
Staff assigned successfully.
```

---

# User-Defined Functions

Two SQL functions are implemented.

## 1. `get_pending_count()`

This function calculates the number of unresolved issues for a particular location.

Syntax:

```sql
SELECT get_pending_count(location_id);
```

Example:

```sql
SELECT get_pending_count(1);
```

It counts issues where:

```sql
status != 'Resolved'
```

---

## 2. `get_avg_resolution_days()`

This function calculates the average number of days required to resolve issues belonging to a particular category.

Syntax:

```sql
SELECT get_avg_resolution_days(category_id);
```

Example:

```sql
SELECT get_avg_resolution_days(1);
```

The function calculates:

```sql
DATEDIFF(date_resolved, date_reported)
```

for resolved issues and returns their average.

If no resolved issue exists, the function returns:

```text
0
```

---

# Sample Issue Workflow

A new issue can be reported using:

```sql
CALL report_issue(
    1,
    1,
    1,
    'Room 101 ka switchboard kaam nahi kar raha'
);
```

Another issue can be reported using:

```sql
CALL report_issue(
    2,
    2,
    2,
    'Projector on nahi ho raha, bulb fuse lag raha hai'
);
```

Staff can then be assigned:

```sql
CALL assign_staff(1, 1);
```

The issue can later be resolved:

```sql
UPDATE issue
SET status = 'Resolved'
WHERE issue_id = 1;
```

The `trg_auto_resolve_date` trigger automatically adds the resolution date.

At the same time, the `trg_status_log` trigger records the status change.

---

# SQL Queries Implemented

## Display All Unresolved Issues

The following query displays all issues that have not yet been resolved:

```sql
SELECT i.issue_id,
       s.name AS student_name,
       l.building,
       l.room_no,
       c.category_name,
       i.description,
       i.status,
       i.date_reported
FROM issue i
JOIN student s ON i.student_id = s.student_id
JOIN location l ON i.location_id = l.location_id
JOIN category c ON i.category_id = c.category_id
WHERE i.status != 'Resolved';
```

This query demonstrates the use of multiple `JOIN` operations.

---

## Count Issues by Category

```sql
SELECT c.category_name,
       COUNT(*) AS total_issues
FROM issue i
JOIN category c
ON i.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_issues DESC;
```

This query calculates how many issues have been reported under each category.

It uses:

* `COUNT()`
* `GROUP BY`
* `ORDER BY`

---

## Find Students Who Reported Multiple Issues

```sql
SELECT name
FROM student
WHERE student_id IN (
    SELECT student_id
    FROM issue
    GROUP BY student_id
    HAVING COUNT(*) > 1
);
```

This query demonstrates the use of a **subquery**.

It identifies students who have submitted more than one issue.

---

## Find Location With Maximum Issues

```sql
SELECT l.building,
       l.room_no,
       COUNT(*) AS issue_count
FROM issue i
JOIN location l
ON i.location_id = l.location_id
GROUP BY l.building, l.room_no
ORDER BY issue_count DESC
LIMIT 1;
```

This query determines the campus location where the highest number of issues have been reported.

---

# Transactions and Savepoints

The project demonstrates transaction management using:

```sql
START TRANSACTION
COMMIT
ROLLBACK
SAVEPOINT
```

Example:

```sql
START TRANSACTION;

UPDATE issue
SET status = 'Resolved'
WHERE category_id = 2;

SAVEPOINT after_projector_fix;

UPDATE issue
SET status = 'Resolved'
WHERE category_id = 99;

ROLLBACK TO after_projector_fix;

COMMIT;
```

A savepoint named:

```text
after_projector_fix
```

is created after resolving projector-related issues.

`ROLLBACK TO` can be used to return the transaction to this point without cancelling the complete transaction.

---

# Indexing

Two indexes are created to improve query performance.

```sql
CREATE INDEX idx_issue_status
ON issue(status);
```

This helps queries that frequently search or filter issues based on their status.

The second index is:

```sql
CREATE INDEX idx_issue_location
ON issue(location_id);
```

This improves queries that search or group issues according to location.

---

# DBMS Concepts Demonstrated

This project demonstrates several important database concepts:

| Concept             | Implementation                                 |
| ------------------- | ---------------------------------------------- |
| Database Creation   | `CREATE DATABASE`                              |
| DDL                 | `CREATE TABLE`, `DROP TABLE`                   |
| DML                 | `INSERT`, `UPDATE`                             |
| Primary Key         | IDs in all tables                              |
| Foreign Key         | Relationships with `issue`                     |
| Unique Constraint   | Student email and category name                |
| Check Constraint    | Issue status                                   |
| Default Values      | Status and timestamps                          |
| Joins               | Issue reporting query                          |
| Subqueries          | Students with multiple reports                 |
| Aggregate Functions | `COUNT()`, `AVG()`                             |
| Grouping            | `GROUP BY`                                     |
| Triggers            | Duplicate prevention, logging, resolution date |
| Stored Procedures   | Report issue and assign staff                  |
| Functions           | Pending count and average resolution time      |
| Transactions        | `START TRANSACTION`, `COMMIT`, `ROLLBACK`      |
| Savepoints          | `SAVEPOINT`                                    |
| Indexes             | Status and location indexes                    |

---

# Requirements

To execute the project, you need:

* MySQL Server
* MySQL Workbench, MySQL CLI, or another compatible SQL client
* MySQL 8.x recommended

---

# How to Run the Project

1. Open **MySQL Workbench** or another MySQL client.

2. Create a new SQL script.

3. Paste the complete SQL code into the editor.

4. Execute the script.

5. The following database will automatically be created:

```text
campus_issues
```

6. Check the created tables using:

```sql
SHOW TABLES;
```

7. Check issue records using:

```sql
SELECT * FROM issue;
```

8. Check the issue status history using:

```sql
SELECT * FROM status_log;
```

---

# Project Workflow

The overall working of the system is:

```text
Student identifies campus problem
            ↓
Student reports issue
            ↓
Issue stored with Open status
            ↓
Duplicate issue check
            ↓
Maintenance staff assigned
            ↓
Status becomes Assigned
            ↓
Staff works on issue
            ↓
Status can become In Progress
            ↓
Issue is resolved
            ↓
Resolution date automatically recorded
            ↓
Status change stored in Status Log
```

---

# Future Improvements

The system can be further extended by adding:

* Student and staff login authentication
* Issue priority such as Low, Medium, and High
* Image upload for damaged equipment
* Email notifications
* Admin dashboard
* Issue feedback and rating system
* Staff workload tracking
* Automatic staff assignment based on issue category
* Web or mobile frontend
* Graphical reports for issue statistics

---

# Conclusion

The **Campus Issue Management System** provides a structured database solution for reporting, assigning, tracking, and resolving campus maintenance problems.

The system maintains data consistency through foreign keys and constraints, prevents duplicate active complaints using triggers, automatically records issue status changes, and simplifies common operations through stored procedures and functions.

The project provides a practical implementation of important **Database Management System (DBMS)** concepts using MySQL.
thank you 
