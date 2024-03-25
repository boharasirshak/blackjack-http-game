-- Active: 1709286938507@@127.0.0.1@3306@blackjack

DROP PROCEDURE IF EXISTS getAllGames;
CREATE PROCEDURE getAllGames()
COMMENT 'Retrieve details of all games available in the database without any input parameters.'
BEGIN
    SELECT * FROM games;
END;

DROP PROCEDURE IF EXISTS getGameData;
CREATE PROCEDURE getGameData(IN p_game_code VARCHAR(16))
COMMENT 'Retrieve details of a game, its players and their cards using its unique game code, 
        p_game_code: The game code identifying the game.'
BEGIN
    DECLARE v_game_exists INT DEFAULT 0;

    -- Check if the game exists
    SELECT COUNT(*) INTO v_game_exists FROM games WHERE code = p_game_code;
    IF v_game_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game not found';
    END IF;
    
    -- Select game details
    SELECT * FROM games WHERE code = p_game_code;

    -- Select players in the game along with players, user.
    SELECT 
        p.id, 
        p.sequence_number, 
        p.user_id, 
        u.username, 
        p.game_id, 
        p.stay
    FROM players p
    INNER JOIN games g ON p.game_id = g.id
    INNER JOIN users u ON p.user_id = u.id
    WHERE g.code = p_game_code;

    -- Select cards for each player in the game
    SELECT 
        ph.player_id, 
        c.value, 
        c.suit
    FROM player_hands ph
    INNER JOIN players p ON ph.player_id = p.id
    INNER JOIN games g ON p.game_id = g.id
    INNER JOIN cards c ON ph.card_id = c.id
    WHERE g.code = p_game_code;
    
    -- Select current player in the game along with the associated username
    SELECT 
        cp.id AS current_player_id,
        cp.start_time,
        p.id AS player_id,
        p.sequence_number,
        p.user_id,
        u.username
    FROM current_players cp
    INNER JOIN players p ON cp.player_id = p.id
    INNER JOIN games g ON p.game_id = g.id
    INNER JOIN users u ON p.user_id = u.id 
    WHERE g.code = p_game_code;
END;

DROP PROCEDURE IF EXISTS createGame;
CREATE PROCEDURE createGame(
    IN p_game_code VARCHAR(20), 
    IN p_user_id INT,
    IN p_turn_time INT,
    IN p_bet INT,
    IN p_players_limit INT
)
COMMENT 'Creates a new game with specified parameters and automatically adds the creator as a player, 
        p_game_code: Unique game code, 
        p_user_id: User ID of the game creator, 
        p_turn_time: Time allocated for each turn, 
        p_bet: Initial bet amount,
        p_players_limit: Maximum number of players allowed in the game.'
BEGIN
    DECLARE v_user_exists INT DEFAULT 0;
    DECLARE v_game_exists INT DEFAULT 0;
    DECLARE v_game_id INT;
    DECLARE v_player_id INT;

    -- Input validation
    IF p_turn_time < 10 OR p_turn_time > 120 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Turn time must be between 10 and 120 seconds';
    END IF;

    IF p_bet < 1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bet amount must be greater than 0';
    END IF;

    IF p_players_limit < 2 OR p_players_limit > 4 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Players limit must be greater between 4 and 2';
    END IF;
    
    -- Check if the user exists
    SELECT COUNT(*) INTO v_user_exists FROM users WHERE id = p_user_id;
    IF v_user_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
    END IF;

    -- Check if the game code is unique
    SELECT COUNT(*) INTO v_game_exists FROM games WHERE code = p_game_code;
    IF v_game_exists > 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game code already exists';
    END IF;
    
    -- Create the game
    INSERT INTO games (code, turn_time, bet, players_limit) 
    VALUES (p_game_code, p_turn_time, p_bet, p_players_limit);

    -- Get the last insert id 
    SELECT LAST_INSERT_ID() INTO v_game_id;

    -- Create the player immediately
    CALL createPlayer(v_game_id, p_user_id, v_player_id);

    SELECT v_game_id, v_player_id;
END;

DROP PROCEDURE IF EXISTS joinGame;
CREATE PROCEDURE joinGame(
    IN p_game_code VARCHAR(20), 
    IN p_user_id INT
)
COMMENT 'Adds a player to a game using the game code and user ID, 
        p_game_code: Unique game code, 
        p_user_id: User ID of the player.'
BEGIN
    DECLARE v_user_exists INT DEFAULT 0;
    DECLARE v_game_exists INT DEFAULT 0;
    DECLARE v_player_id INT;
    DECLARE v_game_id INT;
    DECLARE v_players_count INT;
    DECLARE v_user_already_joined INT DEFAULT 0;
    
    -- Check if the user exists
    SELECT COUNT(*) INTO v_user_exists FROM users WHERE id = p_user_id;
    IF v_user_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
    END IF;
    
    -- Check if the game exists
    SELECT COUNT(*) INTO v_game_exists FROM games WHERE code = p_game_code;
    IF v_game_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game not found';
    END IF;
    
    -- Check if the game is full
    SELECT COUNT(*) INTO v_players_count FROM players p
    INNER JOIN games g ON p.game_id = g.id
    WHERE g.code = p_game_code;

    IF v_players_count >= (SELECT players_limit FROM games WHERE code = p_game_code) THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game is full';
    END IF;

    -- Check if the user has already joined the game
    SELECT COUNT(*) INTO v_user_already_joined FROM players p
        INNER JOIN games g ON p.game_id = g.id
    WHERE g.code = p_game_code AND p.user_id = p_user_id;

    IF v_user_already_joined > 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User has already joined the game';
    END IF;
    
    -- Get the game ID
    SELECT id INTO v_game_id FROM games WHERE code = p_game_code;
    
    -- Create the player
    CALL createPlayer(v_game_id, p_user_id, v_player_id);
    
    SELECT v_player_id;
END;

DROP PROCEDURE IF EXISTS startGame;
CREATE PROCEDURE startGame(
    IN p_game_code VARCHAR(20)
)
COMMENT 'Starts the game by changing the turn to the first player, 
        p_game_code: Unique game code.'
BEGIN
    DECLARE v_game_id INT;
    DECLARE v_first_player_id INT;
    DECLARE v_first_sequence_number INT;
    DECLARE v_players_count INT;
    
    -- Get the game ID
    SELECT id INTO v_game_id FROM games WHERE code = p_game_code;
    IF v_game_id IS NULL THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game not found';
    END IF;

     -- Ensure there are players in the game
    SELECT COUNT(*) INTO v_players_count FROM players WHERE game_id = v_game_id;
    IF v_players_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No players in the game';
    END IF;
    
    -- Get the first player
    SELECT id, sequence_number INTO v_first_player_id, v_first_sequence_number FROM players 
    WHERE game_id = v_game_id
    ORDER BY sequence_number ASC
    LIMIT 1;
    
    -- Check if the current_player exists for the players in the game
    SELECT COUNT(*) INTO v_players_count FROM current_players 
    WHERE player_id in (SELECT id FROM players WHERE game_id = v_game_id);

    IF v_players_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game has already started';
    END IF;

    -- Create the current player
    INSERT INTO current_players (player_id, start_time) VALUES ( v_first_player_id, UNIX_TIMESTAMP());
    
    -- Return the first player
    SELECT v_first_player_id, v_first_sequence_number;
END;


DROP PROCEDURE IF EXISTS findWinner;
CREATE PROCEDURE findWinner(IN game_id INT, OUT winner_id INT)
COMMENT 'Finds the winner of a game based on the total score of players, 
        game_id: The ID of the game, 
        OUT winner_id: The ID of the winner.'
BEGIN
    DECLARE player_id INT;
    DECLARE player_stay BOOLEAN;
    DECLARE player_score INT;
    DECLARE highest_score INT DEFAULT 0;
    DECLARE busted_players INT DEFAULT 0;
    DECLARE non_busted_players INT DEFAULT 0;
    DECLARE non_stayed_players INT DEFAULT 0;
    DECLARE total_players INT DEFAULT 0;

    DECLARE cur CURSOR FOR
        SELECT players.id, players.stay
        FROM players
        WHERE players.game_id = game_id;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET player_id = NULL;

    OPEN cur;

    find_non_busted: LOOP
        FETCH cur INTO player_id, player_stay;
        IF player_id IS NULL THEN
            LEAVE find_non_busted;
        END IF;

        CALL getTotalScore(player_id, @player_score);
        IF @player_score > 21 THEN
            SET busted_players = busted_players + 1;
        ELSE
            SET non_busted_players = non_busted_players + 1;
            IF NOT player_stay THEN
                SET non_stayed_players = non_stayed_players + 1;
            END IF;
            -- Keep track of the highest score and winner ID among non-busted players
            IF @player_score > highest_score THEN
                SET highest_score = @player_score;
                SET winner_id = player_id;
            END IF;
        END IF;
        SET total_players = total_players + 1;
    END LOOP;

    CLOSE cur;

    -- Apply game logic to determine the winner
    IF non_busted_players = 0 THEN
        -- All players are busted
        SET winner_id = NULL;
    ELSEIF non_busted_players = 1 AND total_players > 1 THEN
        -- Only one non-busted player
        -- winner_id is already set
        SELECT winner_id;
    ELSEIF non_stayed_players = 0 THEN
        -- All non-busted players have stayed, winner_id is already the highest scorer
        -- No action needed as winner_id is already set
        SELECT winner_id;
    ELSE
        -- If there's no clear winner based on the above conditions
        SET winner_id = NULL;
    END IF;

END;
