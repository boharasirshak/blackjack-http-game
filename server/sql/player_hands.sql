-- Active: 1709286938507@@127.0.0.1@3306@blackjack
DROP PROCEDURE IF EXISTS addRandomGamePlayerCard;
CREATE PROCEDURE addRandomGamePlayerCard(
    IN p_game_code VARCHAR(20),
    IN p_player_id INT
)
COMMENT 'Add a random card to a player in a game, 
        p_game_code: The game code identifying the game, 
        p_player_id: The ID of the player.'
BEGIN
    DECLARE v_game_id INT;
    DECLARE v_player_exists INT DEFAULT 0;
    DECLARE v_player_in_game INT DEFAULT 0;
    DECLARE v_card_id INT;

    -- Check if game exists 
    SELECT id INTO v_game_id FROM games WHERE code = p_game_code LIMIT 1;

    -- Check if the game ID was found
    IF v_game_id IS NULL THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Game not found';
    END IF;

    -- Check player EXISTS
    SELECT COUNT(*) INTO v_player_exists FROM players WHERE id = p_player_id;
    IF v_player_exists = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player not found';
    END IF;

    -- Check if the player is in the game
    SELECT COUNT(*) INTO v_player_in_game FROM players WHERE id = p_player_id AND game_id = v_game_id;
    IF v_player_in_game = 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player not in game';
    END IF;
    
    -- Get a random card which is not in players hands
    SELECT id INTO v_card_id FROM cards WHERE id NOT IN (SELECT card_id FROM player_hands) ORDER BY RAND() LIMIT 1;
    
    -- Add the card to the player's hand
    INSERT INTO player_hands (player_id, card_id) VALUES (p_player_id, v_card_id);

    -- Return the card ID
    SELECT v_card_id;
END;
