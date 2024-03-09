export interface ITokenData {
  name: string;
  email: string;
  userId: number;
}

export interface ICard {
  id: number;
  value: string;
  suit: string;
}

export interface IPlayerHands {
  playerId: number;
  cardId: number;
  card: ICard;
}

export interface IPlayer {
  id: number;
  gameId: number;
  userId: number;
  stay: boolean;
  sequenceNumber: number;
  hands: IPlayerHands[];
}

export interface IGame {
  id: number;
  code: string;
  bet: number;
  turnTime: number;
  playersLimit: number;
  players: IPlayer[];
}


export interface IError {
  message?: string;
  error?: string;
}
