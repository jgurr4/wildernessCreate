DROP DATABASE IF EXISTS phptest;
CREATE DATABASE phptest;
USE phptest;

CREATE TABLE `task` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `title` varchar(255) UNIQUE NOT NULL,
	`order` int(10) unsigned,
    `cityOrder` int(10) unsigned,
	`rank` enum('A','B','C','D','E','F','G','H') NOT NULL DEFAULT 'A',
	`user_author` varchar(40) NOT NULL,
	`purpose` text NOT NULL,
	`instructions` text NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE InnoDB;

CREATE TABLE `user` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `name` varchar(50) not null,
  `password` mediumint unsigned NOT NULL,
  `email` varchar(50) NOT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `username` (`username`)
) ENGINE InnoDB;

CREATE TABLE `supply` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `task_id` int unsigned,
  `name` varchar(50) NOT NULL,
  `base_material` varchar(50) NOT NULL,
  `secondary_material` varchar(50) DEFAULT NULL,
  `description` text,
  `common` enum('Y','N') DEFAULT 'N',
  `howToGet` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE InnoDB;

CREATE TABLE taskCompletion(
  `user_id` int unsigned,
  `task_id` int unsigned,
  `dateCompleted` datetime not null default current_timestamp,
  PRIMARY KEY (`user_id`, `task_id`)
 ) ENGINE InnoDB;

CREATE TABLE `source` (
  `method_id` int(10) unsigned DEFAULT NULL,
  `source1` text NOT NULL,
  `source2` text,
  `source3` text,
  `source4` text,
  `source5` text,
  `extraInfo` text
) ENGINE InnoDB;

CREATE VIEW `userLastCompletedTask` AS
    SELECT username, t1.*
    FROM taskCompletion t1 INNER JOIN user ON (id = user_id)
    WHERE t1.dateCompleted = (SELECT MAX(t2.dateCompleted)
    FROM taskCompletion t2
    WHERE t2.user_id = t1.user_id);

DELIMITER //
CREATE PROCEDURE getNextTask(IN u1 VARCHAR(50))
BEGIN
    SELECT * FROM task WHERE id = (SELECT task_id from userLastCompletedTask WHERE username = u1) + 1;
END //

CREATE PROCEDURE addComplete(IN uname VARCHAR(50), IN tid int unsigned)
BEGIN
    set @uid = (SELECT id FROM user WHERE username = uname);
    INSERT INTO taskCompletion VALUES (@uid, tid, default);
END //

CREATE PROCEDURE removeComplete(IN uname VARCHAR(50), IN tid int unsigned)
BEGIN
    SET @uid = (SELECT id FROM user WHERE username = uname);
    DELETE FROM taskCompletion WHERE user_id = @uid AND task_id = tid;
END //

CREATE PROCEDURE createNewUser(
    IN username VARCHAR(50), IN name varchar(50), IN pass VARCHAR(255), IN email VARCHAR(50), IN phone VARCHAR(15))
BEGIN
    INSERT INTO user VALUES (0, username, name, pass, email, phone, default, default);
END //

CREATE PROCEDURE retrieveUser(IN uname VARCHAR(50), IN pass VARCHAR(255))
BEGIN
    SELECT * FROM user WHERE username = uname AND password = pass;
END //

CREATE PROCEDURE updateUser(
    IN uname VARCHAR(50), IN newUName VARCHAR(50), IN name varchar(50), IN pass VARCHAR(255), IN email VARCHAR(50), IN phone VARCHAR(15))
BEGIN
    SET @uid = (SELECT `id` FROM `user` WHERE username = uname);
    REPLACE INTO user VALUES (@uid, newUName, name, pass, email, phone, default, default);
END //

CREATE PROCEDURE deleteUser(IN uname VARCHAR(50), IN pass VARCHAR(255))
BEGIN
    SET @uid = (SELECT id FROM user WHERE username = uname AND password = pass);
    DELETE FROM user WHERE username = uname AND password = pass;
    DELETE FROM taskCompletion WHERE user_id = @uid;
    UPDATE user SET id = id - 1 WHERE id > @uid;
    SET @newInc = (SELECT max(id) FROM user) + 1;
    set @sql = concat('alter table user auto_increment = ', @newInc);
    prepare stmt from @sql;
    execute stmt;
    deallocate prepare stmt;
END //
DELIMITER ;

CREATE ROLE IF NOT EXISTS 'app', 'developer','administrator';
GRANT ALL ON *.* TO 'administrator';
GRANT INSERT, UPDATE, DELETE ON phptest.* TO 'developer';
GRANT EXECUTE ON phptest.* TO 'app';
CREATE USER IF NOT EXISTS 'jared'@'localhost' IDENTIFIED BY 'super03';
CREATE USER IF NOT EXISTS 'app'@'localhost' IDENTIFIED BY 'password';
GRANT 'app' TO 'app'@'localhost';
GRANT 'administrator' TO 'jared'@'localhost';