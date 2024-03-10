import { IGame, IPlayer } from "../../types";
import Card from "../Card";

interface PlayAreaProps {
  game: IGame;
  mainPlayer: IPlayer;
}

const PlayArea = ({game, mainPlayer}: PlayAreaProps) => {
  const renderingStrategy = [
    // 'bottom', Bottom is always the main player
    "right",
    "top",
    "left",
  ];

  // // Function to render cards
  const renderCards = () => {
    let area = [];
    var i = 0;
    var j = 0;

    while (i < game.players.length && i < 4) {
      const player = game.players[i];
      console.log(player);

      if (player.id === mainPlayer?.id) {
        area.push(
          <>
            <div className="bottom player-info">
              <span className="info">
                {game.currentPlayer &&
                game.currentPlayer.userId === player.userId
                  ? "Current | "
                  : ""}
                {player.stay ? "Stayed | " : ""}
              </span>

              <div className="cards-container">
                {player?.cards.map((card) => (
                  <Card
                    key={card.playerId}
                    value={card.value}
                    suit={card.suite}
                    hidden={false}
                  />
                ))}
              </div>
            </div>
          </>
        );
        i++;
        continue;
      }

      const strategy = renderingStrategy[j];
      area.push(
        <>
          <div className={`${strategy} player-info`}>
            <span className="info">
              {game.currentPlayer && game.currentPlayer.userId === player.userId
                ? "Current | "
                : ""}
              {player.stay ? "Stayed | " : ""}
            </span>

            <div className="cards-container">
              {player?.cards.map((card) => (
                <Card
                  key={card.playerId}
                  value={card.value}
                  suit={card.suite}
                  hidden={false}
                />
              ))}
            </div>
          </div>
        </>
      );
      i++;
      j++;
    }

    return area;
  };

  return <div className="square-table">{renderCards()}</div>
}

export default PlayArea
