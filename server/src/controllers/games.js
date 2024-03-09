const jwt = require("jsonwebtoken");
const axios = require("axios");
const config = require("../config");
const { genRandomString } = require("../utils/generators");

async function getGames(req, res, next) {
  const token = req.token; // from the middleware
  const data = jwt.decode(token, { json: true });
  // const userId = data?.userId;

  var response = await axios.get(`http://sql.lavro.ru/call.php`, {
    params: {
      db: config.dbName,
      pname: "getAllGames",
    },
    timeout: 30000,
  });

  var games = [];

  for (var i = 0; i < response.data.RESULTS[0].id.length; i++) {
    games.push({
      id: response.data.RESULTS[0].id[i],
      code: response.data.RESULTS[0].code[i],
      bet: response.data.RESULTS[0].bet[i],
      turnTime: response.data.RESULTS[0].turnTime[i],
      creatorId: response.data.RESULTS[0].creatorId[i],
      playersCount: response.data.RESULTS[0].playersCount[i],
      state: response.data.RESULTS[0].state[i],
      previousTurns: response.data.RESULTS[0].previousTurns[i],
      currentTurnId: response.data.RESULTS[0].currentTurnId[i],
      winnerId: response.data.RESULTS[0].winnerId[i],
    });
  }

  return res.send(games);

  // Since we are not using the user's id to get their games, we can comment out the following code, FOR NOW
  // if (!data || !userId) {
  //     return res.status(401).send({
  //         message: 'Invalid token!'
  //     });
  // }

  // // these steps make sure the user is valid and only gets their own games

  // const getUserStmt = db.prepare('SELECT * FROM users WHERE id = ?');
  // const user = getUserStmt.get(userId);

  // if (!user) {
  //     return res.status(401).send({
  //         message: 'Invalid token!'
  //     });
  // }

  // const getPlayersStmt = db.prepare('SELECT * FROM players WHERE userId = ?');
  // const players = getPlayersStmt.all(userId);

  // if (!players || players.length === 0) {
  //     return res.status(401).send({
  //         message: 'User has not joined any games!'
  //     });
  // }

  // let games = [];

  // for (const player of players) {
  //     const getGameStmt = db.prepare('SELECT * FROM games WHERE id = ?');
  //     const game = getGameStmt.get(player.gameId);
  //     games.push(game);
  // }

  // return res.send(games);
}

async function createGame(req, res, next) {
  const { turnTime, bet, playersLimit } = req.body;
  if (!turnTime || !bet || !playersLimit) {
    return res.status(400).send({
      message: "turnTime, bet and playersLimit are required!",
    });
  }

  const token = req.token; // from the middleware
  const data = jwt.decode(token, { json: true });
  const userId = data?.userId;

  const gameCode = genRandomString(config.gameCodeLength);

  var response = await axios.get(`http://sql.lavro.ru/call.php`, {
    params: {
      db: config.dbName,
      pname: "createGame",
      p1: gameCode,
      p2: userId,
      p3: turnTime,
      p4: bet,
      p5: playersLimit,
    },
    timeout: 30000,
  });

  if (response.data.ERROR) {
    return res.status(404).send({
      message: response.data.ERROR,
    });
  }

  // only player is creater but not linked with game
  if (response.data.RESULTS.length === 1) {
    return res.status(500).send({
      message: "Error creating game!",
    });
  }

  // In any edge cases
  if (
    !response.data.RESULTS[1]["v_game_id"] ||
    response.data.RESULTS[1]["v_game_id"].length === 0 ||
    !response.data.RESULTS[1]["v_player_id"] ||
    response.data.RESULTS[1]["v_player_id"].length === 0
  ) {
    return res.status(500).send({
      message: "Error creating game!",
    });
  }

  return res.send({
    message: "Game created!",
    code: gameCode,
    playerId: response.data.RESULTS[1]["v_game_id"][0] || 1,
    gameId: response.data.RESULTS[1]["v_player_id"][0] || 1,
  });
}

module.exports.getGames = getGames;
module.exports.createGame = createGame;
