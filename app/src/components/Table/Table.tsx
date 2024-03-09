import { IGame, IPlayer } from "../../types";

interface TableProps {
  game: IGame;
  player: IPlayer;
};

const Table = ({}: TableProps) => {
  return (
    <div>Table</div>
  )
}

export default Table
