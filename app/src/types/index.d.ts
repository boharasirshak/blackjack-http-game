export interface Card {
  id: number;
  name: string;
  value: string;
  suit: string;
}

export interface TokenData {
  userName: string;
  email: string;
  userId: number;
}

export interface Player {
  id: number;
  name: string;
  bet: number;
  gameId: number;
  userId: number;
  ready: number;
  state: string;
  outcome: string;
  score: number;
  stay: number;
  cards: Card[];
}

export interface Game {
  id: number;
  code: string;
  bet: number;
  playersCount: number;
  state: string;
  turnTime: number;
  winnerId: number;
  previousTurns: string;
  currentTurnId: number;
  players: Player[];
}

