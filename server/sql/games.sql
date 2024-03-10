-- Active: 1709286938507@@127.0.0.1@3306@blackjack
DROP PROCEDURE IF EXISTS getGameByGameCode;
CREATE PROCEDURE getGameByGameCode(IN p_game_code VARCHAR(20))
COMMENT 'Retrieve details of a game using its unique game code, 
        p_gameCode: The game code identifying the game.'
BEGIN
    SELECT * FROM games WHERE code = p_game_code;
END;

DROP PROCEDURE IF EXISTS getGameData;
CREATE PROCEDURE getGameData(IN p_game_code INT)
COMMENT 'Retrieve details of a game, its players and their cards using its unique game code, 
        p_game_code: The game code identifying the game.'
BEGIN  
    -- Select game details
  SELECT * FROM games WHERE code = p_game_code;

  -- Select players in the game
    SELECT 
        p.id, 
        p.sequence_number, 
        p.user_id, 
        p.game_id, 
        p.stay
    FROM players p
    INNER JOIN games g ON p.game_id = g.id
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
    
    -- Select current player in the game
    SELECT 
        cp.id AS current_player_id,
        cp.start_time,
        p.id AS player_id,
        p.sequence_number,
        p.user_id
    FROM current_players cp
    INNER JOIN players p ON cp.player_id = p.id
    INNER JOIN games g ON p.game_id = g.id
    WHERE g.code = p_game_code;
END;


DROP PROCEDURE IF EXISTS getAllGames;
CREATE PROCEDURE getAllGames()
COMMENT 'Retrieve details of all games available in the database without any input parameters.'
BEGIN
    SELECT * FROM games;
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
    DECLARE v_game_id INT;
    DECLARE v_player_id INT;
    
    -- Check if the user exists
    SELECT COUNT(*) INTO v_user_exists FROM users WHERE id = p_user_id;
    IF v_user_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
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
    
    -- Get the game ID
    SELECT id INTO v_game_id FROM games WHERE code = p_game_code;
    
    -- Create the player
    CALL createPlayer(v_game_id, p_user_id, v_player_id);
    
    SELECT v_player_id;
END;
