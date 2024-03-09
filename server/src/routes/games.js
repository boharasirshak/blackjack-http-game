const express = require('express');
const { 
    getGames, 
    createGame, 
} = require("../controllers/games");
const verifyToken = require('../middlewares/token');

const router =  express.Router();

router.get('/', verifyToken, getGames);
router.post('/', verifyToken, createGame);

module.exports = router;
