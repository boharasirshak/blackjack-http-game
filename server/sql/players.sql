-- Active: 1709286938507@@127.0.0.1@3306@blackjack

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
    DECLARE v_current_player_id INT;
    DECLARE v_current_player_pid INT;
    DECLARE v_players_sequence INT;
    DECLARE v_players_count INT DEFAULT 1;
    DECLARE v_game_player_limit INT DEFAULT 2;
    DECLARE v_winner_id INT DEFAULT NULL;

    -- Check if the player exists
    SELECT COUNT(*) INTO v_player_exists FROM players WHERE id = p_player_id;
    IF v_player_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player not found';
    END IF;

    -- Check if the game exists using game_code and get its ID 
    SELECT id, players_limit INTO v_game_id, v_game_player_limit FROM games WHERE code = p_game_code;
    IF v_game_id IS NULL THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game not found';
    END IF;

    -- Check if the player is in the game
    SELECT COUNT(*) INTO v_player_exists FROM players WHERE id = p_player_id AND game_id = v_game_id;
    IF v_player_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player not in game';
    END IF;

    -- Get the number of players in the game
    SELECT COUNT(*) INTO v_players_count FROM players WHERE game_id = v_game_id;

     -- Call findWinner to determine if there is a winner
    CALL findWinner(v_game_id, v_winner_id);

    -- Disallow deleting player if the game has started but no winner is declared
    IF v_game_player_limit = v_players_count AND v_winner_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game is running, cannot delete player unless there is a winner.';
    END IF;

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

DROP PROCEDURE IF EXISTS updatePlayerStayState;
CREATE PROCEDURE updatePlayerStayState(IN p_player_id INT, IN p_stay BOOLEAN)
COMMENT 'Update the stay state of a player, 
        p_player_id: The ID of the player, 
        p_stay: The new stay state.'
BEGIN
    DECLARE v_player_exists INT DEFAULT 0;
    DECLARE v_has_current_turn INT DEFAULT 0;

    -- Check if the player exists
    SELECT COUNT(*) INTO v_player_exists FROM players WHERE id = p_player_id;
    IF v_player_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player not found';
    END IF;

    -- Check if the player has the current turn
    SELECT COUNT(*) INTO v_has_current_turn FROM current_players WHERE player_id = p_player_id;
    IF v_has_current_turn = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player does not have the current turn';
    END IF;

    -- Do not allow player to unstay their turn
    IF p_stay = FALSE OR p_stay = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player cannot unstay their turn at this version of game.';
    END IF;

    -- Update the stay state
    UPDATE players SET stay = p_stay WHERE id = p_player_id;

    SELECT 'Player stay state updated successfully' AS message;
END;

DROP PROCEDURE IF EXISTS changePlayerTurn;
CREATE PROCEDURE changePlayerTurn(
    IN p_current_sequence_number INT,
    IN p_game_code VARCHAR(20), 
    IN p_player_id INT
)
COMMENT 'Changes the turn of the player in the game, 
        p_current_sequence_number: The current sequence number of the player, 
        p_game_code: Unique game code, 
        p_player_id: The ID of the player.'
BEGIN
    DECLARE v_game_id INT;
    DECLARE v_next_player_id INT DEFAULT NULL;
    DECLARE v_next_sequence_number INT;
    DECLARE v_players_count INT;
    DECLARE v_player_exists INT DEFAULT 0;
    DECLARE v_current_player_id INT;
    DECLARE v_score INT;
    DECLARE finished INT DEFAULT 0;
    DECLARE v_all_stayed_or_busted INT DEFAULT 0;
    DECLARE v_has_current_turn INT DEFAULT 0;

    -- Get the game ID
    SELECT id INTO v_game_id FROM games WHERE code = p_game_code;
    IF v_game_id IS NULL THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game not found';
    END IF;

    -- Check if the player exists
    SELECT COUNT(*) INTO v_player_exists FROM players WHERE id = p_player_id;

    IF v_player_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player not found';
    END IF;

    -- Check if the player has the current turn
    SELECT COUNT(*) INTO v_has_current_turn FROM current_players WHERE player_id = p_player_id;
    IF v_has_current_turn = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player does not have the current turn';
    END IF;
    
    -- Initialize loop variables
    SET v_next_sequence_number = p_current_sequence_number + 1;

    -- Loop to find the next player
    player_loop: LOOP
        -- Attempt to find the next player who has not stayed
        SELECT id INTO v_next_player_id FROM players
        WHERE game_id = v_game_id 
        AND sequence_number >= v_next_sequence_number
        AND stay = FALSE
        ORDER BY sequence_number ASC
        LIMIT 1;
        
         -- If no player is found, check if we've completed a loop
        IF v_next_player_id IS NULL THEN
            IF finished = 1 THEN
                -- After one full loop, if no eligible player is found
                SET v_all_stayed_or_busted = 1;
                LEAVE player_loop;
            ELSE
                SET v_next_sequence_number = 0; -- Reset to start from the first player
                SET finished = 1; -- Indicate we've completed a loop
                ITERATE player_loop;
            END IF;
        END IF;
        
        -- Exit loop if no valid next player
        IF v_next_player_id IS NULL THEN
            LEAVE player_loop;
        END IF;
        
        -- Calculate or retrieve the player's score.
        CALL getTotalScore(v_next_player_id, @player_score);
        SET v_score = @player_score; -- Retrieve the score from the session variable
        
        -- Check if the player is busted (>21). If so, skip them.
        IF v_score > 21 THEN
            SET v_next_sequence_number = v_next_sequence_number + 1;
            ITERATE player_loop;
        END IF;

        -- If a valid player is found, exit the loop
        LEAVE player_loop;
    END LOOP player_loop;

     -- Handle no eligible next player found after checking all
    IF v_all_stayed_or_busted = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'All players stayed or are busted. Turn cannot be changed.';
    END IF;

    -- Update or insert the current player
    IF v_next_player_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_players_count FROM current_players 
        WHERE player_id IN (SELECT id FROM players WHERE game_id = v_game_id);
        
        IF v_players_count = 0 THEN
            INSERT INTO current_players (player_id, start_time) VALUES (v_next_player_id, UNIX_TIMESTAMP());
        ELSE
            SELECT id INTO v_current_player_id FROM current_players 
            WHERE player_id IN (SELECT id FROM players WHERE game_id = v_game_id) LIMIT 1;

            UPDATE current_players 
                SET player_id = v_next_player_id, start_time = UNIX_TIMESTAMP() 
            WHERE id = v_current_player_id;
        END IF;
    END IF;
END;
