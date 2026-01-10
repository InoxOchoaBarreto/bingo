import { BingoCard as BingoCardType } from '../../types';

interface BingoCardProps {
  card: BingoCardType;
  onMarkNumber: (number: number) => void;
  isDisabled?: boolean;
}

const LETTERS = ['B', 'I', 'N', 'G', 'O'];

export const BingoCard = ({ card, onMarkNumber, isDisabled = false }: BingoCardProps) => {
  const numbers = card.numbers;
  const markedNumbers = card.marked_numbers;

  const isMarked = (number: number) => markedNumbers.includes(number);

  return (
    <div className="bg-white rounded-2xl shadow-xl p-6 max-w-md">
      <div className="mb-4">
        <h3 className="text-2xl font-bold text-center text-gray-800">Tu Cartón</h3>
      </div>

      <div className="grid grid-cols-5 gap-2">
        {LETTERS.map((letter, index) => (
          <div
            key={letter}
            className="bg-gradient-to-br from-blue-600 to-blue-700 text-white font-bold text-xl py-3 rounded-lg text-center"
          >
            {letter}
          </div>
        ))}

        {numbers.map((row, rowIndex) =>
          row.map((number, colIndex) => {
            const isFreeSpace = rowIndex === 2 && colIndex === 2;
            const marked = isMarked(number) || isFreeSpace;

            return (
              <button
                key={`${rowIndex}-${colIndex}`}
                onClick={() => !isFreeSpace && !isDisabled && onMarkNumber(number)}
                disabled={isDisabled || isFreeSpace}
                className={`
                  aspect-square rounded-lg font-bold text-lg transition-all transform
                  ${
                    isFreeSpace
                      ? 'bg-gradient-to-br from-yellow-400 to-yellow-500 text-white cursor-default'
                      : marked
                      ? 'bg-gradient-to-br from-green-500 to-green-600 text-white scale-95 shadow-inner'
                      : 'bg-gray-100 text-gray-800 hover:bg-gray-200 hover:scale-105 active:scale-95'
                  }
                  ${isDisabled && !marked ? 'opacity-50 cursor-not-allowed' : ''}
                `}
              >
                {isFreeSpace ? 'FREE' : number}
              </button>
            );
          })
        )}
      </div>

      <div className="mt-4 text-center text-sm text-gray-600">
        Números marcados: {markedNumbers.length}
      </div>
    </div>
  );
};
