-- Active: 1709286938507@@127.0.0.1@3306@blackjack
CREATE TABLE IF NOT EXISTS users(
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(128) NOT NULL,
  password VARCHAR(255) NOT NULL,
  balance INT NOT NULL
);

CREATE TABLE IF NOT EXISTS tokens (
  token VARCHAR(255) PRIMARY KEY,
  user_id INT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS games (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(16) NOT NULL,
  bet INT NOT NULL,
  turn_time INT NOT NULL,
  players_limit INT NOT NULL
);

CREATE TABLE IF NOT EXISTS players (
  id INT AUTO_INCREMENT PRIMARY KEY,
  stay BOOLEAN NOT NULL DEFAULT 0,
  sequence_number INT NOT NULL,
  user_id INT NOT NULL,
  game_id INT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (game_id) REFERENCES games(id)
);

CREATE TABLE IF NOT EXISTS current_players (
  id INT AUTO_INCREMENT PRIMARY KEY,
  start_time TIMESTAMP NOT NULL,
  player_id INT NOT NULL,
  FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cards (
  id INT AUTO_INCREMENT PRIMARY KEY,
  value INT NOT NULL,
  suit VARCHAR(8) NOT NULL
);

CREATE TABLE IF NOT EXISTS player_hands (
  id INT AUTO_INCREMENT PRIMARY KEY,
  player_id INT NOT NULL,
  card_id INT NOT NULL,
  FOREIGN KEY (player_id) REFERENCES players(id),
  FOREIGN KEY (card_id) REFERENCES cards(id)
);
