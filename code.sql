CREATE DATABASE IF NOT EXISTS campus_issues;
USE campus_issues;


SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS status_log;
DROP TABLE IF EXISTS issue;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS location;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS student;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE student (
    student_id   INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(50) NOT NULL,
    email        VARCHAR(60) UNIQUE NOT NULL,
    dept         VARCHAR(30),
    phone        VARCHAR(15)
);

CREATE TABLE staff (
    staff_id     INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(50) NOT NULL,
    role         VARCHAR(30),   -- Electrician, IT support, Carpenter, etc.
    dept         VARCHAR(30)
);

CREATE TABLE location (
    location_id  INT PRIMARY KEY AUTO_INCREMENT,
    building     VARCHAR(40) NOT NULL,
    room_no      VARCHAR(10),
    floor_no     INT
);

CREATE TABLE category (
    category_id   INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(40) UNIQUE NOT NULL   -- Electrical, AV/Projector, Furniture, Internet, Plumbing
);

CREATE TABLE issue (
    issue_id      INT PRIMARY KEY AUTO_INCREMENT,
    student_id    INT NOT NULL,
    location_id   INT NOT NULL,
    category_id   INT NOT NULL,
    staff_id      INT,
    description   VARCHAR(200) NOT NULL,
    status        VARCHAR(15) DEFAULT 'Open'
                  CHECK (status IN ('Open','Assigned','In Progress','Resolved','Rejected')),
    date_reported DATETIME DEFAULT CURRENT_TIMESTAMP,
    date_resolved DATETIME,
    FOREIGN KEY (student_id) REFERENCES student(student_id),
    FOREIGN KEY (location_id) REFERENCES location(location_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

CREATE TABLE status_log (
    log_id       INT PRIMARY KEY AUTO_INCREMENT,
    issue_id     INT NOT NULL,
    old_status   VARCHAR(15),
    new_status   VARCHAR(15),
    changed_on   DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (issue_id) REFERENCES issue(issue_id)
);

INSERT INTO student (student_id, name, email, dept, phone) VALUES 
(1,'Aman Verma','aman@vitb.ac.in','CSE','9876500001'),
(2,'Riya Sharma','riya@vitb.ac.in','ECE','9876500002'),
(3,'Kabir Singh','kabir@vitb.ac.in','ME','9876500003');

INSERT INTO staff (staff_id, name, role, dept) VALUES 
(1,'Ramesh Yadav','Electrician','Maintenance'),
(2,'Suresh Patel','IT Support','Maintenance'),
(3,'Vikas Rao','Carpenter','Maintenance');

INSERT INTO location (location_id, building, room_no, floor_no) VALUES 
(1,'Academic Block 1','101',1),
(2,'Academic Block 2','204',2),
(3,'Hostel Block C','G-12',0);

INSERT INTO category (category_id, category_name) VALUES 
(1,'Electrical'),
(2,'AV/Projector'),
(3,'Furniture'),
(4,'Internet'),
(5,'Plumbing');

COMMIT;

DELIMITER //

CREATE TRIGGER trg_prevent_duplicate
BEFORE INSERT ON issue
FOR EACH ROW
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM issue
    WHERE student_id  = NEW.student_id
      AND location_id = NEW.location_id
      AND category_id = NEW.category_id
      AND status NOT IN ('Resolved','Rejected');

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Is location/category ke liye already ek open issue exist karta hai';
    END IF;
END //

CREATE TRIGGER trg_status_log
AFTER UPDATE ON issue
FOR EACH ROW
BEGIN
    IF NEW.status != OLD.status THEN
        INSERT INTO status_log(issue_id, old_status, new_status)
        VALUES (NEW.issue_id, OLD.status, NEW.status);
    END IF;
END //

-- (c) BEFORE UPDATE: status 'Resolved' hote hi date_resolved apne aap set ho
CREATE TRIGGER trg_auto_resolve_date
BEFORE UPDATE ON issue
FOR EACH ROW
BEGIN
    IF NEW.status = 'Resolved' AND OLD.status != 'Resolved' THEN
        SET NEW.date_resolved = CURRENT_TIMESTAMP;
    END IF;
END //

DELIMITER ;

DELIMITER //

DROP PROCEDURE IF EXISTS report_issue;

CREATE PROCEDURE report_issue (
    IN p_student_id  INT,
    IN p_location_id INT,
    IN p_category_id INT,
    IN p_description VARCHAR(200)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error occurred during report_issue' AS message;
    END;

    START TRANSACTION;
    INSERT INTO issue (student_id, location_id, category_id, description)
    VALUES (p_student_id, p_location_id, p_category_id, p_description);
    COMMIT;
    
    SELECT 'Issue reported successfully.' AS message;
END //

DROP PROCEDURE IF EXISTS assign_staff;
CREATE PROCEDURE assign_staff (
    IN p_issue_id INT,
    IN p_staff_id INT
)
BEGIN
    UPDATE issue
    SET staff_id = p_staff_id, status = 'Assigned'
    WHERE issue_id = p_issue_id;

    IF ROW_COUNT() = 0 THEN
        SELECT 'Issue ID not found.' AS message;
    ELSE
        COMMIT;
        SELECT 'Staff assigned successfully.' AS message;
    END IF;
END //

DELIMITER ;

DELIMITER //

DROP FUNCTION IF EXISTS get_pending_count;

CREATE FUNCTION get_pending_count (p_location_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM issue
    WHERE location_id = p_location_id AND status != 'Resolved';
    RETURN v_count;
END //

DROP FUNCTION IF EXISTS get_avg_resolution_days;
 
CREATE FUNCTION get_avg_resolution_days (p_category_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_avg DECIMAL(10,2);
    SELECT AVG(DATEDIFF(date_resolved, date_reported)) INTO v_avg
    FROM issue
    WHERE category_id = p_category_id AND status = 'Resolved';
    RETURN IFNULL(v_avg, 0);
END //

DELIMITER ;


CALL report_issue(1, 1, 1, 'Room 101 ka switchboard kaam nahi kar raha');
CALL report_issue(2, 2, 2, 'Projector on nahi ho raha, bulb fuse lag raha hai');
CALL assign_staff(1, 1);
UPDATE issue SET status = 'Resolved' WHERE issue_id = 1;
COMMIT;


SELECT * FROM status_log;
SELECT issue_id, status, date_reported, date_resolved FROM issue;

CREATE INDEX idx_issue_status   ON issue(status);
CREATE INDEX idx_issue_location ON issue(location_id);


SELECT i.issue_id, s.name AS student_name, l.building, l.room_no,
       c.category_name, i.description, i.status, i.date_reported
FROM issue i
JOIN student s  ON i.student_id = s.student_id
JOIN location l ON i.location_id = l.location_id
JOIN category c ON i.category_id = c.category_id
WHERE i.status != 'Resolved';


SELECT c.category_name, COUNT(*) AS total_issues
FROM issue i JOIN category c ON i.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_issues DESC;


SELECT name FROM student
WHERE student_id IN (
    SELECT student_id FROM issue
    GROUP BY student_id
    HAVING COUNT(*) > 1
);


SELECT l.building, l.room_no, COUNT(*) AS issue_count
FROM issue i JOIN location l ON i.location_id = l.location_id
GROUP BY l.building, l.room_no
ORDER BY issue_count DESC
LIMIT 1;

START TRANSACTION;
UPDATE issue SET status = 'Resolved' WHERE category_id = 2;
SAVEPOINT after_projector_fix;

UPDATE issue SET status = 'Resolved' WHERE category_id = 99; -- invalid, 0 rows

ROLLBACK TO after_projector_fix;
COMMIT;
