import axios, { AxiosError } from "axios";
import { jwtDecode } from "jwt-decode";
import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import SquareTable from "../../components/Table/SquareTable";
import { BACKEND_URL } from "../../config";
import type { Game, Player, TokenData } from "../../types";
import type { IGameResponse, IResponseError } from "../../types/response";

import "./Game.css";

const values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
const suits = ["spades", "hearts", "clubs", "diamonds"];
function rand<T>(arr: T[]) {
  return arr[Math.floor(Math.random() * arr.length)];
}

const Game = () => {
  const token = localStorage.getItem("token");
  const decode = jwtDecode<TokenData>(token!);
  const [game, setGame] = useState<Game>();
  const [player, setPlayer] = useState<Player>();

  const { code } = useParams();
  if (!code) {
    window.location.href = "/games";
  }

  useEffect(() => {
    const init = async () => {
      try {
        const _game = await getAGame(code as string, token!);
        const _player = _game.players.find((p) => p.userId === decode.userId);
        setGame(_game);
        setPlayer(_player);

        // This is not a player in game, so join him.
        if (!_player) {
          // Check if game is full before creating a new player
          if (_game.players.length > 4 || _game.playersCount > 4) {
            alert("Game is full!");
            window.location.href = "/dashboard";
          }

          await joinGame(code as string, token!, decode.userId);
        }
      } catch (error) {
        const err = error as AxiosError<IResponseError>;
        console.log(err);
        alert(
          err.response?.data.message ||
            err.response?.data.error ||
            "Error joining game"
        );
        window.location.href = "/dashboard";
      }
    };

    init();
  }, [code, decode]);

  useEffect(() => {
    const event = new EventSource(`${BACKEND_URL}/games/${code}`);

    event.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setGame(data);
    };

    return () => {
      event.close();
    };
  });



  return (
    <div>
      <SquareTable gameCode={code as string} />
    </div>
  );
};

const getAGame = async (code: string, token: string) => {
  const res = await axios.get<IGameResponse>(
    `${BACKEND_URL}/games/${code}`,
    {
      headers: {
        Authorization: `Bearer ${token}`,
        'ngrok-skip-browser-warning': 'true'
      },
    }
  );
  if (
    res.data.game.players.length > 4 ||
    res.data.game.playersCount > 4
  ) {
    alert("Game is full!");
    window.location.href = "/dashboard";
  }

  if (res.data.game.state === "RUNNING") {
    alert(
      "This is a running game, please join once it is finished or idle"
    );
    window.location.href = "/dashboard";
  }

  return res.data.game;
}

const joinGame = async (code: string, token: string, userId: number) => {
  const res = await axios.post<Player>(
    `${BACKEND_URL}/games/${code}`,
    {
      userId: userId,
      gameCode: code,
    },
    {
      headers: {
        Authorization: `Bearer ${token}`,
        'ngrok-skip-browser-warning': 'true'
      },
    }
  );
  return res.status === 201 || res.status === 200;
}

export default Game;
