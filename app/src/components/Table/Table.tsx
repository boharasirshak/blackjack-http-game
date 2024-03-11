import axios from "axios";
import { jwtDecode } from "jwt-decode";
import { useEffect, useState } from "react";
import { useBalance } from "../../context/Balance";
import { IGame, IPlayer, IPlayerCards, ITokenData } from "../../types";
import PlayArea from "../PlayArea";
import "./Table.css";

interface TableProps {
  initialGame: IGame;
  initialPlayer?: IPlayer;
}

const Table = ({ initialGame, initialPlayer }: TableProps) => {
  const BACKEND_URL = import.meta.env.VITE_BACKEND_URL as string || "http://localhost:5000";

  const [mainPlayer, setMainPlayer] = useState<IPlayer | undefined>(initialPlayer);
  const [game, setGame] = useState<IGame>(initialGame);
  const [_, setRunning] = useState<boolean>(false);
  const { balance, setBalance } = useBalance();

  const [currentTurn, setCurrentTurn] = useState<boolean>(false);
  const [canAddCard, setCanAddCard] = useState<boolean>(false);
  const [canClickStay, setCanClickStay] = useState<boolean>(false);

  // const [isTimerSet, setIsTimerSet] = useState<boolean>(false);
  // const [timer, setTimer] = useState<number>(0);

  const token = localStorage.getItem("token");
  const decode = jwtDecode<ITokenData>(token!);

  function startGame() {
    axios.put(`${BACKEND_URL}/games/start`, {
      gameCode: game.code,
    }, {
      headers: {
        Authorization: `Bearer ${token}`,
        "ngrok-skip-browser-warning": "true",
      },
    }).then(() => {
      setRunning(true);
    }).catch((_) => {});
  }

  
  useEffect(() => {

    // Had to use a flag to prevent multiple calls to the backend
    // and React state updates
    let _isRunning: boolean = false;

    async function getGame() {
      try {
        const res = await axios.get<IGame>(
          `${BACKEND_URL}/games/${game.code}`,
          {
            headers: {
              Authorization: `Bearer ${token}`,
              'ngrok-skip-browser-warning': 'true'
            },
          }
        );

        function findWinner() {
          let nonBustedPlayers = res.data.players.filter((player) => !isBusted(player.cards));
          let nonStayedPlayers = nonBustedPlayers.filter((player) => !player.stay);

          if (nonBustedPlayers.length === 0) return null;
      
          // if there is only one player who is not busted in a game of multiple players, then they are the winner
          if (nonBustedPlayers.length === 1 && game.players.length > 1) {
           return nonBustedPlayers[0];
          }
          // if all players have STAYED, then the Non-Busted player with the highest score wins
          if (nonStayedPlayers.length === 0) {
            return nonBustedPlayers.reduce((prev, current) =>
              getTotalScore(prev.cards) > getTotalScore(current.cards) ? prev : current
            );
          }
          return null;
        }

        setGame(res.data);
        
        const winner = findWinner();
        if (!_isRunning && res.data.players.length === res.data.playersLimit) {
          startGame();
          _isRunning = true;
        }

        for(const player of res.data.players) {
          if (player.userId === decode.userId) {
            setMainPlayer(player);
            
            // you can add cards if you have the current turn
            if (res.data.currentPlayer && res.data.currentPlayer.userId === decode.userId) {
              setCurrentTurn(true);
              setCanAddCard(true);
            } else {
              setCurrentTurn(false);
              setCanAddCard(false);
              setCanClickStay(false);
            }
            
            // if there is only one player, you cannot do anything
            if (res.data.players.length === 1) {
              setCurrentTurn(false);
              setCanClickStay(false);
            }

            // if you stayed, you cannot add card
            if (player.stay) {
              setCanAddCard(false);
              setCanClickStay(false);
            }
          
            // you can stay, 
            // if you have current turn & there are more than 1 players & 2+ cards & not stayed & are not winner or busted
            if (
              res.data.players.length > 1 &&
              player.cards.length >= 2 && 
              !player.stay && 
              !isBusted(player.cards) && 
              winner === null &&
              res.data.currentPlayer &&
              res.data.currentPlayer.userId === decode.userId
            ) {
              setCanClickStay(true);
            }
          }
          
          // if someone is winner, we cannot add card
          if (winner) {
            setCanAddCard(false);
            setCanClickStay(false);
          }

          // add the balance to the user
          if (winner && winner.userId === decode.userId) {
            setBalance(balance + game.bet);
          }
        }
      } catch (err) {
        console.log(err);
        alert("Invalid game code");
        window.location.href = "/dashboard";
      }
    }

    const intervalId = setInterval(getGame, 2000);

    return () => { 
      clearInterval(intervalId); 
    };
  }, []);
  
  useEffect(() => {
    if (balance === 0) return;

    // if (balance < 0) {
    //   document.getElementById("player-bet")!.style.color = "red";
    // } else {
    //   document.getElementById("player-bet")!.style.color = "green";
    // }
  }, [balance]);

  function addCard() {
    if (!currentTurn) {
      return alert("Not your turn!");
    }

    const payload = {
      gameCode: game.code,
      playerId: mainPlayer?.id,
    };

    axios
      .post(`${BACKEND_URL}/games/cards`, payload, {
        headers: {
          Authorization: `Bearer ${token}`,
          "ngrok-skip-browser-warning": "true",
        },
      })
      .then(() => {
        changeTurn();
      })
      .catch((err) => {
        console.log(err);
        alert("Error adding card to player");
      });
  }

  function stayPlayer() {
    axios
      .put(`${BACKEND_URL}/players/stay`, {
        playerId: mainPlayer?.id,
        stay: true,
      }, {
        headers: {
          Authorization: `Bearer ${token}`,
          "ngrok-skip-browser-warning": "true",
        },
      })
      .then(() => {
        changeTurn(true);
      })
      .catch((err) => {
        console.log(err);
        alert("Error staying player");
      });
  }

  function changeTurn(check = false) {
    if (check) {
      if (game?.players.length === 1) {
        return alert("You are the only player in the game");
      }
    }
    axios
      .put(`${BACKEND_URL}/games/turn`, {
        gameCode: game.code,
        playerId: mainPlayer?.id,
        currentSequenceNumber: mainPlayer?.sequenceNumber
      }, {
        headers: {
          Authorization: `Bearer ${token}`,
          "ngrok-skip-browser-warning": "true",
        },
      })
      .then(() => {})
      .catch((err) => {
        console.log(err);
        alert("Error changing turn");
      });
  }

  function leavePlayer() {
    var conf = confirm("Are you sure you want to leave the game?");
    if (!conf) {
      return;
    }
    if (mainPlayer?.id === game.currentPlayer?.playerId) {
      changeTurn(false);
    }

    axios
      .delete(`${BACKEND_URL}/players/`, {
        params: {
          playerId: mainPlayer?.id,
          gameCode: game.code,
          balance: balance
        },
        headers: {
          Authorization: `Bearer ${token}`,
          "ngrok-skip-browser-warning": "true",
        },
      })
      .then(() => {
        window.location.href = "/dashboard";
      })
      .catch((err) => {
        alert("Error leaving game");
        console.log(err);
      });
  }

  return (
    <>
      <PlayArea game={game} mainPlayer={mainPlayer} />
      <button
        className="button"
        onClick={addCard}
        disabled={!canAddCard}
      >
        Hit
      </button>
      <button
        className="button"
        onClick={stayPlayer}
        disabled={!canClickStay}
      >
        Stay
      </button>
      <button
        className="button"
        onClick={leavePlayer}
        style={{
          backgroundColor: "red",
        }}
      >
        Leave
      </button>
    </>
  );
};

function getCardValue(value: string) {
  switch (value) {
    case "J":
    case "Q":
    case "K":
      return 10;
    case "A":
      return 11;
    default:
      return parseInt(value);
  }
}

function getTotalScore(cards: IPlayerCards[]) {
  let total = 0;
  let aces = cards.filter((card) => card.value === "A");
  let withoutAces = cards.filter((card) => card.value !== "A");

  for (const card of withoutAces) {
    total += getCardValue(card.value);
  }

  for (const _ of aces) {
    if ((total + 11) > 21) {
      total += 1;
    } else {
      total += 11;
    }
  }
  
  return total;
}

function isBusted(cards: IPlayerCards[]) {
  return getTotalScore(cards) > 21;
}

export default Table;
