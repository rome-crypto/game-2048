import 'dart:math';

/// Модель плитки 2048
class TileModel {
  final int id;
  int value;
  int row;
  int col;

  TileModel({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
  });

  TileModel copy() {
    return TileModel(
      id: id,
      value: value,
      row: row,
      col: col,
    );
  }
}

class PreviousGameState {
  final List<TileModel> tiles;
  final int score;
  final bool gameOver;

  PreviousGameState({
    required this.tiles,
    required this.score,
    required this.gameOver,
  });
}

/// Игровой движок 2048
class GameEngine {
  final int rows;
  final int cols;
  final Random random;

  List<TileModel> tiles = [];

  int score = 0;
  bool gameOver = false;

  int _tileIdCounter = 0;

  PreviousGameState? _lastState;

  bool canUndo = false;

  GameEngine({
    required this.rows,
    required this.cols,
    Random? random,
  }) : random = random ?? Random();

  /// Создание новой игры
  void newGame() {
    tiles.clear();

    score = 0;
    gameOver = false;
    canUndo = false;
    _lastState = null;

    _tileIdCounter = 0;

    addRandomTile();
    addRandomTile();
  }

  /// Добавление случайной плитки
  void addRandomTile() {
    final occupied = <String>{};

    for (final tile in tiles) {
      occupied.add('${tile.row},${tile.col}');
    }

    final emptyCells = <Point<int>>[];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!occupied.contains('$r,$c')) {
          emptyCells.add(Point(r, c));
        }
      }
    }

    if (emptyCells.isEmpty) {
      return;
    }

    final position = emptyCells[random.nextInt(emptyCells.length)];

    final value = random.nextInt(10) == 0 ? 4 : 2;

    tiles.add(
      TileModel(
        id: _tileIdCounter++,
        value: value,
        row: position.x,
        col: position.y,
      ),
    );
  }

  void moveLeft() {
    _saveUndoState();

    for (int r = 0; r < rows; r++) {
      final rowTiles =
          tiles.where((t) => t.row == r).toList()
            ..sort((a, b) => a.col.compareTo(b.col));

      int targetCol = 0;
      TileModel? last;

      for (final tile in rowTiles) {
        if (last != null && last.value == tile.value) {
          last.value *= 2;
          score += last.value;

          tiles.remove(tile);

          last = null;
        } else {
          tile.col = targetCol;
          targetCol++;
          last = tile;
        }
      }
    }

    _finishMove();
  }

  void moveRight() {
    _saveUndoState();

    for (int r = 0; r < rows; r++) {
      final rowTiles =
          tiles.where((t) => t.row == r).toList()
            ..sort((a, b) => b.col.compareTo(a.col));

      int targetCol = cols - 1;
      TileModel? last;

      for (final tile in rowTiles) {
        if (last != null && last.value == tile.value) {
          last.value *= 2;
          score += last.value;

          tiles.remove(tile);

          last = null;
        } else {
          tile.col = targetCol;
          targetCol--;
          last = tile;
        }
      }
    }

    _finishMove();
  }

  void moveUp() {
    _saveUndoState();

    for (int c = 0; c < cols; c++) {
      final columnTiles =
          tiles.where((t) => t.col == c).toList()
            ..sort((a, b) => a.row.compareTo(b.row));

      int targetRow = 0;
      TileModel? last;

      for (final tile in columnTiles) {
        if (last != null && last.value == tile.value) {
          last.value *= 2;
          score += last.value;

          tiles.remove(tile);

          last = null;
        } else {
          tile.row = targetRow;
          targetRow++;
          last = tile;
        }
      }
    }

    _finishMove();
  }

  void moveDown() {
    _saveUndoState();

    for (int c = 0; c < cols; c++) {
      final columnTiles =
          tiles.where((t) => t.col == c).toList()
            ..sort((a, b) => b.row.compareTo(a.row));

      int targetRow = rows - 1;
      TileModel? last;

      for (final tile in columnTiles) {
        if (last != null && last.value == tile.value) {
          last.value *= 2;
          score += last.value;

          tiles.remove(tile);

          last = null;
        } else {
          tile.row = targetRow;
          targetRow--;
          last = tile;
        }
      }
    }

    _finishMove();
  }

  /// Проверка наличия возможных ходов
  bool canMove() {
    if (tiles.length < rows * cols) {
      return true;
    }

    final grid = List.generate(
      rows,
      (_) => List.filled(cols, 0),
    );

    for (final tile in tiles) {
      grid[tile.row][tile.col] = tile.value;
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (c < cols - 1 &&
            grid[r][c] == grid[r][c + 1]) {
          return true;
        }

        if (r < rows - 1 &&
            grid[r][c] == grid[r + 1][c]) {
          return true;
        }
      }
    }

    return false;
  }

  /// Откат хода
  void undo() {
    if (!canUndo || _lastState == null) {
      return;
    }

    tiles = _lastState!.tiles
        .map((e) => e.copy())
        .toList();

    score = _lastState!.score;
    gameOver = _lastState!.gameOver;

    canUndo = false;
  }

  void _saveUndoState() {
    _lastState = PreviousGameState(
      tiles: tiles.map((e) => e.copy()).toList(),
      score: score,
      gameOver: gameOver,
    );
  }

  void _finishMove() {
    canUndo = true;

    addRandomTile();

    gameOver = !canMove();
  }

  /// Позволяет задавать состояние поля в тестах
  void setBoard(List<List<int>> board) {
    tiles.clear();

    _tileIdCounter = 0;

    for (int r = 0; r < board.length; r++) {
      for (int c = 0; c < board[r].length; c++) {
        final value = board[r][c];

        if (value != 0) {
          tiles.add(
            TileModel(
              id: _tileIdCounter++,
              value: value,
              row: r,
              col: c,
            ),
          );
        }
      }
    }
  }

  /// Получение матрицы поля для проверок
  List<List<int>> getBoard() {
    final board = List.generate(
      rows,
      (_) => List.filled(cols, 0),
    );

    for (final tile in tiles) {
      board[tile.row][tile.col] = tile.value;
    }

    return board;
  }
}