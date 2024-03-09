-- Active: 1709286938507@@127.0.0.1@3306@blackjack
DROP PROCEDURE IF EXISTS getGameByGameCode;
CREATE PROCEDURE getGameByGameCode(IN p_game_code VARCHAR(20))
COMMENT 'Retrieve details of a game using its unique game code, 
        p_gameCode: The game code identifying the game.'
BEGIN
    SELECT * FROM games WHERE code = p_game_code;
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
