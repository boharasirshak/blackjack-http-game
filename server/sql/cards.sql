-- Active: 1709286938507@@127.0.0.1@3306@blackjack
DROP PROCEDURE IF EXISTS insertUniqueCards;
CREATE PROCEDURE insertUniqueCards()
COMMENT 'Procedure to insert 52 unique playing cards into the cards table,
         This procedure does not let the table to have more than 52 cards,
         Every card is unique so ensure interigity to the gameplay.'
BEGIN
    DECLARE cardCount INT;
    SET cardCount = (SELECT COUNT(*) FROM cards);
    
    IF cardCount < 52 THEN
        INSERT IGNORE INTO cards (value, suit)
        VALUES
            ('2', '♠'),
            ('3', '♠'),
            ('4', '♠'),
            ('5', '♠'),
            ('6', '♠'),
            ('7', '♠'),
            ('8', '♠'),
            ('9', '♠'),
            ('10', '♠'),
            ('A', '♠'),
            ('J', '♠'),
            ('Q', '♠'),
            ('K', '♠'),
            ('2', '♥'),
            ('3', '♥'),
            ('4', '♥'),
            ('5', '♥'),
            ('6', '♥'),
            ('7', '♥'),
            ('8', '♥'),
            ('9', '♥'),
            ('10', '♥'),
            ('A', '♥'),
            ('J', '♥'),
            ('Q', '♥'),
            ('K', '♥'),
            ('2', '♦'),
            ('3', '♦'),
            ('4', '♦'),
            ('5', '♦'),
            ('6', '♦'),
            ('7', '♦'),
            ('8', '♦'),
            ('9', '♦'),
            ('10', '♦'),
            ('A', '♦'),
            ('J', '♦'),
            ('Q', '♦'),
            ('K', '♦'),
            ('2', '♣'),
            ('3', '♣'),
            ('4', '♣'),
            ('5', '♣'),
            ('6', '♣'),
            ('7', '♣'),
            ('8', '♣'),
            ('9', '♣'),
            ('10', '♣'),
            ('A', '♣'),
            ('J', '♣'),
            ('Q', '♣'),
            ('K', '♣');
    END IF;
END;

DROP PROCEDURE IF EXISTS getCards;
CREATE PROCEDURE getCards()
COMMENT 'Procedure to get all the 52 card from the cards table.'
BEGIN
    SELECT * FROM cards;
END;

DROP PROCEDURE IF EXISTS getACard;
CREATE PROCEDURE getACard(IN i_cardId INT)
COMMENT 'Procreudre to get a single card from the cards table using cardId
         i_cardId INT - the card id'
BEGIN
    SELECT * FROM cards WHERE id = i_cardId;
END;
