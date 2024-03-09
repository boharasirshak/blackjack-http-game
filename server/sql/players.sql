-- Active: 1709286938507@@127.0.0.1@3306@blackjack
DROP PROCEDURE IF EXISTS getAPlayer;
CREATE PROCEDURE getAPlayer(IN p_player_id INT)
COMMENT 'Retrieve player details by their ID, 
        p_player_id: The ID of the player.'
BEGIN
    SELECT * FROM players WHERE id = p_player_id;
END;


DROP PROCEDURE IF EXISTS getPlayerByUserId;
CREATE PROCEDURE getPlayerByUserId(IN p_user_id INT)
COMMENT 'Retrieve player details by their user ID, 
         p_user_id: The user ID associated with the player.'
BEGIN
    SELECT * FROM players WHERE user_id = p_user_id;
END;

DROP PROCEDURE IF EXISTS getPlayerByGameId;
CREATE PROCEDURE getPlayerByGameId(IN p_game_id INT)
COMMENT 'Retrieve players by their game ID, 
        p_game_id: The ID of the game.'
BEGIN
    SELECT * FROM players WHERE game_id = p_game_id;
END;

DROP PROCEDURE IF EXISTS getPlayerByUserIdAndGameId;
CREATE PROCEDURE getPlayerByUserIdAndGameId(IN p_user_id INT, IN p_game_id INT)
COMMENT 'Retrieve a player by both their user ID and game ID, 
        p_user_id: The user ID, 
        p_game_id: The game ID.'
BEGIN
    SELECT * FROM players WHERE user_id = p_user_id AND game_id = p_game_id;
END;


DROP PROCEDURE IF EXISTS createPlayer;
CREATE PROCEDURE createPlayer(
    IN p_game_id INT, 
    IN p_user_id INT,
    OUT o_player_id INT
)
COMMENT 'Create a player with game ID, user ID, name, and bet. 
        Returns new player ID, 
        p_game_id: Game ID, 
        p_user_id: User ID.'
BEGIN
    -- Check for the user 
    DECLARE v_user_exists INT DEFAULT 0;
    DECLARE v_game_exists INT DEFAULT 0;
    DECLARE v_player_id INT;
    DECLARE v_sequence_number INT;

    -- Generate a random number between 1 and INT_MAX (2147483647 - 2) to be stored as sequence
    SET v_sequence_number = FLOOR(RAND() * 2147483645) + 1;

    -- Check if the user exists
    SELECT COUNT(*) INTO v_user_exists FROM users WHERE id = p_user_id;
    IF v_user_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
    END IF;

    -- Check if the game exists
    SELECT COUNT(*) INTO v_game_exists FROM games WHERE id = p_game_id;
    IF v_game_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game not found';
    END IF;

    -- Create the player
    INSERT INTO players (game_id, user_id, sequence_number) 
    VALUES (p_game_id, p_user_id, v_sequence_number);

    SET o_player_id = LAST_INSERT_ID();

    SELECT 'Player created successfully' AS message;
END;
