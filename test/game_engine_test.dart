import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/game_engine.dart';

void main() {
  group('GameEngine', () {
    late GameEngine engine;

    setUp(() {
      // Фиксированный Random для воспроизводимых тестов
      engine = GameEngine(
        rows: 4,
        cols: 4,
        random: Random(1),
      );
    });

    test('newGame создает две плитки', () {
      engine.newGame();

      expect(engine.tiles.length, 2);

      for (final tile in engine.tiles) {
        expect([2, 4], contains(tile.value));
      }

      expect(engine.score, 0);
      expect(engine.gameOver, false);
      expect(engine.canUndo, false);
    });

    test('moveLeft объединяет две плитки', () {
      engine.setBoard([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      engine.moveLeft();

      final board = engine.getBoard();

      expect(board[0][0], 4);
      expect(engine.score, 4);
    });

    test('moveLeft корректно обрабатывает [2,2,2,2]', () {
      engine.setBoard([
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      engine.moveLeft();

      final row = engine.getBoard()[0];

      expect(row[0], 4);
      expect(row[1], 4);
      expect(engine.score, 8);
    });

    test('moveRight объединяет плитки справа', () {
      engine.setBoard([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      engine.moveRight();

      final row = engine.getBoard()[0];

      expect(row[3], 4);
      expect(engine.score, 4);
    });

    test('moveUp объединяет плитки вверх', () {
      engine.setBoard([
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      engine.moveUp();

      final board = engine.getBoard();

      expect(board[0][0], 4);
      expect(engine.score, 4);
    });

    test('moveDown объединяет плитки вниз', () {
      engine.setBoard([
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      engine.moveDown();

      final board = engine.getBoard();

      expect(board[3][0], 4);
      expect(engine.score, 4);
    });

    test('canMove возвращает true при наличии пустых клеток', () {
      engine.setBoard([
        [2, 4, 8, 16],
        [32, 64, 128, 256],
        [512, 1024, 2048, 4096],
        [8192, 16384, 32768, 0],
      ]);

      expect(engine.canMove(), true);
    });

    test('canMove возвращает true при наличии возможного объединения', () {
      engine.setBoard([
        [2, 4, 8, 16],
        [32, 64, 128, 256],
        [512, 1024, 1024, 4096],
        [8192, 16384, 32768, 65536],
      ]);

      expect(engine.canMove(), true);
    });

    test('canMove возвращает false при отсутствии ходов', () {
      engine.setBoard([
        [2, 4, 8, 16],
        [32, 64, 128, 256],
        [512, 1024, 2048, 4096],
        [8192, 16384, 32768, 65536],
      ]);

      expect(engine.canMove(), false);
    });

    test('undo восстанавливает предыдущее состояние', () {
      engine.setBoard([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      final before = engine.getBoard();

      engine.moveLeft();

      expect(engine.canUndo, true);

      engine.undo();

      expect(engine.getBoard(), before);
      expect(engine.score, 0);
      expect(engine.canUndo, false);
    });

    test('setBoard корректно заполняет поле', () {
      engine.setBoard([
        [2, 4, 0, 0],
        [8, 16, 0, 0],
        [0, 0, 32, 64],
        [128, 256, 512, 1024],
      ]);

      final board = engine.getBoard();

      expect(board[0][0], 2);
      expect(board[0][1], 4);
      expect(board[1][0], 8);
      expect(board[1][1], 16);
      expect(board[2][2], 32);
      expect(board[2][3], 64);
      expect(board[3][0], 128);
      expect(board[3][1], 256);
      expect(board[3][2], 512);
      expect(board[3][3], 1024);
    });

    test('addRandomTile увеличивает количество плиток на 1', () {
      engine.setBoard([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      final countBefore = engine.tiles.length;

      engine.addRandomTile();

      expect(engine.tiles.length, countBefore + 1);
    });

    test('gameOver становится true после хода без доступных ходов', () {
      engine.setBoard([
        [2, 4, 8, 16],
        [32, 64, 128, 256],
        [512, 1024, 2048, 4096],
        [8192, 16384, 32768, 2],
      ]);

      engine.moveLeft();

      expect(engine.gameOver, true);
    });
  });
}