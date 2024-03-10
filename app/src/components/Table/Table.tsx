import axios from "axios";
import { jwtDecode } from "jwt-decode";
import { useEffect, useState } from "react";
import { IGame, IPlayer, ITokenData } from "../../types";
import PlayArea from "../PlayArea";
import "./Table.css";

interface TableProps {
  game: IGame;
  mainPlayer: IPlayer;
}

const Table = ({ game, mainPlayer }: TableProps) => {
  const BACKEND_URL = import.meta.env.VITE_BACKEND_URL as string || "http://localhost:5000";
  // const [cards, setCards] = useState<ICard[]>([]);

  // const [players, setPlayers] = useState<IPlayer[]>([]);
  // const [balance, setBalance] = useState(0);

  const [currentTurn, setCurrentTurn] = useState<boolean>(false);
  // const [canSkipTurn, setCanSkipTurn] = useState<boolean>(false);

  // const [isTimerSet, setIsTimerSet] = useState<boolean>(false);
  // const [timer, setTimer] = useState<number>(0);

  const token = localStorage.getItem("token");
  const decode = jwtDecode<ITokenData>(token!);

  useEffect(() => {
    if (game.currentPlayer && game.currentPlayer.userId === decode.userId) {
      setCurrentTurn(true);
      // setCanSkipTurn(true);
    }
    if (game.players.length === 1) {
      setCurrentTurn(true);
      // setCanSkipTurn(true);
    }

    // setPlayers(game.players);
  }, [game]);

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
        // change the turn
        // changeTurn();
      })
      .catch((err) => {
        console.log(err);
        alert("Error adding card to player");
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
    </>
  );
};

export default Table;
