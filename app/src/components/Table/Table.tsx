import axios from "axios";
import { jwtDecode } from "jwt-decode";
import { useEffect, useState } from "react";
import { useBalance } from "../../context/Balance";
import { IGame, IPlayer, ITokenData } from "../../types";
import PlayArea from "../PlayArea";
import "./Table.css";

interface TableProps {
  game: IGame;
  mainPlayer: IPlayer;
}

const Table = ({ game, mainPlayer }: TableProps) => {
  const BACKEND_URL = import.meta.env.VITE_BACKEND_URL as string || "http://localhost:5000";

  const { balance, setBalance } = useBalance();

  const [currentTurn, setCurrentTurn] = useState<boolean>(false);
  // const [canSkipTurn, setCanSkipTurn] = useState<boolean>(false);

  // const [isTimerSet, setIsTimerSet] = useState<boolean>(false);
  // const [timer, setTimer] = useState<number>(0);

  const token = localStorage.getItem("token");
  const decode = jwtDecode<ITokenData>(token!);

  
  useEffect(() => {
    if (game.currentPlayer && game.currentPlayer.userId === decode.userId) {
      setCurrentTurn(true);
    }
  
    if (game.players.length === 1) {
      setCurrentTurn(true);
    }

    setBalance(20);
  }, []);

  function addCard() {
    if (!currentTurn) {
      return alert("Not your turn!");
    }

    const payload = {
      gameCode: game.code,
      playerId: mainPlayer.id,
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
        playerId: mainPlayer.id,
        currentSequenceNumber: mainPlayer.sequenceNumber
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
    if (mainPlayer.id === game.currentPlayer?.playerId) {
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
        // window.location.href = "/dashboard";
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
        disabled={!currentTurn} // only allow hit if it's the player's turn
      >
        Hit
      </button>
      <button
        className="button"
        onClick={stayPlayer}
        disabled={!currentTurn} // only allow hit if it's the player's turn
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

export default Table;
