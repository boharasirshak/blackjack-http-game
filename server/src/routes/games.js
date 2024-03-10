const express = require('express');
const { 
    getGames, 
    createGame, 
    getAGame,
    joinGame
} = require("../controllers/games");
const verifyToken = require('../middlewares/token');

const router =  express.Router();

router.get('/', verifyToken, getGames);
router.post('/', verifyToken, createGame);
router.get('/:code', verifyToken, getAGame);
router.post('/:code', verifyToken, joinGame);

module.exports = router;
