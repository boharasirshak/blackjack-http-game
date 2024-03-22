-- Active: 1709286938507@@127.0.0.1@3306@blackjack
DROP PROCEDURE IF EXISTS login;
CREATE PROCEDURE login(IN p_username VARCHAR(100), IN p_password VARCHAR(255))
COMMENT 'Login with username and password,
         p_username - The username of the user,
         p_password - The password of the user.'
BEGIN
    DECLARE v_user_id INT DEFAULT (SELECT id FROM users WHERE username = p_username AND password = p_password);
    IF v_user_id IS NOT NULL THEN
        SELECT * FROM users
        LEFT JOIN tokens ON users.id = tokens.user_id
        WHERE id = v_user_id;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Incorrect username or password';
    END IF;
END;


DROP PROCEDURE IF EXISTS signup;
CREATE PROCEDURE signup(IN p_username VARCHAR(100), IN p_password VARCHAR(255))
COMMENT 'Creates a new user with the username, password.
         p_username - The username of new user,
         p_password - The password of the new user.'
BEGIN
    DECLARE v_user_id INT DEFAULT (SELECT id FROM users WHERE username = p_username);
    IF v_user_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User already exists';
    ELSE
        INSERT INTO users (username, password) VALUES (p_username, p_password);
        SELECT * FROM users WHERE username = p_username;
    END IF;
END;

DROP PROCEDURE IF EXISTS updateToken;
CREATE PROCEDURE updateToken(IN p_user_id VARCHAR(100), IN p_token VARCHAR(255))
COMMENT 'updates the sesson token of a user,
        p_id - the id of the user,
        p_token - the new session token'
BEGIN
    DECLARE p_token_exists INT DEFAULT 0;
    SELECT COUNT(*) INTO p_token_exists FROM tokens WHERE user_id = p_user_id;
    IF p_token_exists > 0 THEN
        UPDATE tokens SET token = p_token WHERE user_id = p_user_id;
    ELSE
        INSERT INTO tokens (token, user_id) VALUES (p_token, p_user_id);
    END IF;
    SELECT * FROM tokens WHERE user_id = p_user_id;
END;


DROP PROCEDURE IF EXISTS getUserByToken;
CREATE PROCEDURE getUserByToken(IN p_token VARCHAR(255))
COMMENT 'Gets the user by the session token,
        p_token - the session token of the user'
BEGIN
    DECLARE v_user_id INT DEFAULT (SELECT user_id FROM tokens WHERE token = p_token LIMIT 1);
    DECLARE v_user_exists INT DEFAULT 0;
    SELECT COUNT(*) INTO v_user_exists FROM users WHERE id = v_user_id;
    IF v_user_exists > 0 THEN
        SELECT * FROM users WHERE id = v_user_id;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
    END IF;
END;
