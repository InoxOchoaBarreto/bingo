import { BingoCard, GameMode } from '../types';

export const checkWin = (card: BingoCard, pattern: GameMode['pattern']): boolean => {
  const numbers = card.numbers;
  const marked = new Set(card.marked_numbers);

  const isMarked = (row: number, col: number): boolean => {
    if (row === 2 && col === 2) return true;
    return marked.has(numbers[row][col]);
  };

  switch (pattern.type) {
    case 'horizontal_line':
      return checkHorizontalLine(isMarked);

    case 'vertical_line':
      return checkVerticalLine(isMarked);

    case 'diagonal':
      return checkDiagonal(isMarked);

    case 'four_corners':
      return checkFourCorners(isMarked);

    case 'full_card':
      return checkFullCard(isMarked);

    case 'x_pattern':
      return checkXPattern(isMarked);

    default:
      return false;
  }
};

const checkHorizontalLine = (isMarked: (row: number, col: number) => boolean): boolean => {
  for (let row = 0; row < 5; row++) {
    let complete = true;
    for (let col = 0; col < 5; col++) {
      if (!isMarked(row, col)) {
        complete = false;
        break;
      }
    }
    if (complete) return true;
  }
  return false;
};

const checkVerticalLine = (isMarked: (row: number, col: number) => boolean): boolean => {
  for (let col = 0; col < 5; col++) {
    let complete = true;
    for (let row = 0; row < 5; row++) {
      if (!isMarked(row, col)) {
        complete = false;
        break;
      }
    }
    if (complete) return true;
  }
  return false;
};

const checkDiagonal = (isMarked: (row: number, col: number) => boolean): boolean => {
  let diagonal1 = true;
  let diagonal2 = true;

  for (let i = 0; i < 5; i++) {
    if (!isMarked(i, i)) diagonal1 = false;
    if (!isMarked(i, 4 - i)) diagonal2 = false;
  }

  return diagonal1 || diagonal2;
};

const checkFourCorners = (isMarked: (row: number, col: number) => boolean): boolean => {
  return isMarked(0, 0) && isMarked(0, 4) && isMarked(4, 0) && isMarked(4, 4);
};

const checkFullCard = (isMarked: (row: number, col: number) => boolean): boolean => {
  for (let row = 0; row < 5; row++) {
    for (let col = 0; col < 5; col++) {
      if (!isMarked(row, col)) return false;
    }
  }
  return true;
};

const checkXPattern = (isMarked: (row: number, col: number) => boolean): boolean => {
  for (let i = 0; i < 5; i++) {
    if (!isMarked(i, i)) return false;
    if (!isMarked(i, 4 - i)) return false;
  }
  return true;
};
