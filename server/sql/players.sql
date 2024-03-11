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

DROP PROCEDURE IF EXISTS deletePlayer;
CREATE PROCEDURE deletePlayer(IN p_player_id INT, IN p_game_code VARCHAR(20), IN p_balance INT)
COMMENT 'Deletes a player from game, its cards, and adds/subtracts its balance to the user, 
        p_player_id: The ID of the player, 
        p_game_code: The game code, 
        p_balance: The balance of the player.'
BEGIN
    DECLARE v_player_exists INT DEFAULT 0;
    DECLARE v_user_id INT;
    DECLARE v_game_id INT;
    DECLARE v_players_count INT;
    DECLARE v_current_player_id INT;
    DECLARE v_current_player_pid INT;
    DECLARE v_players_sequence INT;

    -- Check if the player exists
    SELECT COUNT(*) INTO v_player_exists FROM players WHERE id = p_player_id;
    IF v_player_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player not found';
    END IF;

    -- Check if the game exists using game_code and get its ID 
    SELECT id INTO v_game_id FROM games WHERE code = p_game_code;
    IF v_game_id IS NULL THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game not found';
    END IF;

    -- Get the number of players in the game
    SELECT COUNT(*) INTO v_players_count FROM players WHERE game_id = v_game_id;

    -- Get the user ID of the player
    SELECT user_id, sequence_number INTO v_user_id, v_players_sequence FROM players WHERE id = p_player_id;

    -- Delete the player's hands
    DELETE FROM player_hands WHERE player_id = p_player_id;

    -- Update the user balance
    UPDATE users SET balance = balance + p_balance WHERE id = v_user_id;

    -- If the player was the last one in the game
    IF v_players_count = 1 THEN
        DELETE FROM current_players WHERE player_id = p_player_id;
        DELETE FROM players WHERE id = p_player_id;
        DELETE FROM games WHERE id = v_game_id;
    ELSE
        -- More than one player in the game, might need to handle turn change
        SELECT id, player_id INTO v_current_player_id, v_current_player_pid FROM current_players 
        WHERE player_id = p_player_id;

        IF v_current_player_pid = p_player_id THEN
            CALL changePlayerTurn(v_players_sequence, p_game_code, p_player_id);
        END IF;
        
        DELETE FROM players WHERE id = p_player_id;
    END IF;

    SELECT 'Player deleted successfully' AS message;
END;
