const express = require('express');
const { 
    getGames, 
    createGame, 
    getAGame,
    joinGame,
    addGamePlayerCard
} = require("../controllers/games");
const verifyToken = require('../middlewares/token');

const router =  express.Router();

router.get('/', verifyToken, getGames);
router.post('/', verifyToken, createGame);
router.post('/cards', verifyToken, addGamePlayerCard);
router.get('/:code', verifyToken, getAGame);
router.post('/:code', verifyToken, joinGame);

module.exports = router;
