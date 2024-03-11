const axios = require("axios");
const config = require("../config");

async function deletePlayer(req, res, next) {
  const { playerId, gameCode, balance } = req.query;
  if (!playerId || !gameCode, !balance) {
    return res.status(400).send({
      message: "playerId, gameCode and balance required in the query!",
    });
  }

  var response = await axios.get(`http://sql.lavro.ru/call.php`, {
    params: {
      db: config.dbName,
      pname: "deletePlayer",
      p1: playerId,
      p2: gameCode,
      p3: balance
    },
    timeout: 30000,
  });

  if (response.data.ERROR) {
    return res.status(404).send({
      message: response.data.ERROR,
    });
  }

  res.send({
    message: "Player deleted successfully",
  });
}

async function updatePlayerStay(req, res, next) {
  let { playerId, gameCode, stay } = req.body || req.query;
  if (!playerId || !gameCode || stay === undefined || stay === null) {
    return res.status(400).send({
      message: "playerId, gameCode and stay required in the body or query!",
    });
  }

  var response = await axios.get(`http://sql.lavro.ru/call.php`, {
    params: {
      db: config.dbName,
      pname: "updatePlayerStayState",
      p1: playerId,
      p2: gameCode,
      p3: stay,
    },
    timeout: 30000,
  });

  if (response.data.ERROR) {
    return res.status(404).send({
      message: response.data.ERROR,
    });
  }

  res.send({
    message: "Player stay updated successfully",
  });
}

module.exports.deletePlayer = deletePlayer;
module.exports.updatePlayerStay = updatePlayerStay;
