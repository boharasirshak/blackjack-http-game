import { Game } from './index';

export interface IGameResponse {
  game: Game;
}

export interface IResponseError {
  message?: string;
  error?: string;
}

