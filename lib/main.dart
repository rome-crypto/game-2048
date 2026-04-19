import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const Game2048App());
}

class Game2048App extends StatelessWidget {
  const Game2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MainMenuPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  static const availableModes = <GameModeOption>[ 
    GameModeOption(label: '4 × 4', rows: 4, cols: 4, available: true),
    GameModeOption(label: '3 × 4', rows: 3, cols: 4, available: false),
    GameModeOption(label: '4 × 5', rows: 4, cols: 5, available: false),
  ];

  late GameModeOption _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = availableModes.firstWhere((mode) => mode.available);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                '2048',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF776E65),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Выберите режим игры',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xFF776E65)),
              ),
              const SizedBox(height: 24),
              ...availableModes.map((mode) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: mode.available
                          ? () => setState(() {
                                _selectedMode = mode;
                              })
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        decoration: BoxDecoration(
                          color: mode == _selectedMode ? const Color(0xFFBBADA0) : const Color(0xFFEDE0C8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: mode.available ? const Color(0xFF776E65) : const Color(0xFFB0A69B),
                            width: mode == _selectedMode ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: mode.available ? const Color(0xFF3C3A32) : const Color(0xFF8F7A66),
                                ),
                              ),
                            ),
                            if (!mode.available)
                              const Text(
                                'Скоро',
                                style: TextStyle(color: Color(0xFF8F7A66), fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Game2048Page(
                        rows: _selectedMode.rows,
                        cols: _selectedMode.cols,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8F7A66),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Пуск',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameModeOption {
  final String label;
  final int rows;
  final int cols;
  final bool available;

  const GameModeOption({
    required this.label,
    required this.rows,
    required this.cols,
    required this.available,
  });
}

class Game2048Page extends StatefulWidget {
  const Game2048Page({
    super.key,
    required this.rows,
    required this.cols,
  });

  final int rows;
  final int cols;

  @override
  State<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends State<Game2048Page> {
  late final int rowCount;
  late final int colCount;
  final Random _random = Random();

  late List<List<int>> _board;
  int _score = 0;
  bool _gameOver = false;
  final List<_PreviousGameState> _undoStack = [];

  @override
  void initState() {
    super.initState();
    rowCount = widget.rows;
    colCount = widget.cols;
    _resetGame();
  }

  void _resetGame() {
    _board = List.generate(rowCount, (_) => List.filled(colCount, 0));
    _score = 0;
    _gameOver = false;
    _undoStack.clear();
    _addRandomTile();
    _addRandomTile();
    setState(() {});
  }

  void _saveState() {
    _undoStack.add(_PreviousGameState(
      board: _cloneBoard(_board),
      score: _score,
      gameOver: _gameOver,
    ));
  }

  void _undoMove() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    _board = _cloneBoard(previous.board);
    _score = previous.score;
    _gameOver = previous.gameOver;
    setState(() {});
  }

  List<List<int>> _cloneBoard(List<List<int>> board) {
    return board.map((row) => List<int>.from(row)).toList();
  }

  void _addRandomTile() {
    final emptyCells = <Point<int>>[];
    for (var row = 0; row < rowCount; row++) {
      for (var col = 0; col < colCount; col++) {
        if (_board[row][col] == 0) {
          emptyCells.add(Point(row, col));
        }
      }
    }

    if (emptyCells.isEmpty) return;

    final position = emptyCells[_random.nextInt(emptyCells.length)];
    _board[position.x][position.y] = _random.nextInt(10) == 0 ? 4 : 2;
  }

  bool _moveLeft() {
    var moved = false;
    for (var row = 0; row < rowCount; row++) {
      final line = _board[row];
      final newLine = _compressLine(line);
      if (!_listEquals(line, newLine)) {
        _board[row] = newLine;
        moved = true;
      }
    }
    return moved;
  }

  bool _moveRight() {
    var moved = false;
    for (var row = 0; row < rowCount; row++) {
      final line = List.of(_board[row].reversed);
      final newLine = _compressLine(line).reversed.toList();
      if (!_listEquals(_board[row], newLine)) {
        _board[row] = newLine;
        moved = true;
      }
    }
    return moved;
  }

  bool _moveUp() {
    var moved = false;
    for (var col = 0; col < colCount; col++) {
      final line = List<int>.generate(rowCount, (row) => _board[row][col]);
      final newLine = _compressLine(line);
      for (var row = 0; row < rowCount; row++) {
        if (_board[row][col] != newLine[row]) {
          _board[row][col] = newLine[row];
          moved = true;
        }
      }
    }
    return moved;
  }

  bool _moveDown() {
    var moved = false;
    for (var col = 0; col < colCount; col++) {
      final line = List<int>.generate(rowCount, (row) => _board[row][col]).reversed.toList();
      final newLine = _compressLine(line).reversed.toList();
      for (var row = 0; row < rowCount; row++) {
        if (_board[row][col] != newLine[row]) {
          _board[row][col] = newLine[row];
          moved = true;
        }
      }
    }
    return moved;
  }

  List<int> _compressLine(List<int> line) {
    final filtered = line.where((value) => value != 0).toList();
    for (var i = 0; i < filtered.length - 1; i++) {
      if (filtered[i] == filtered[i + 1]) {
        filtered[i] *= 2;
        _score += filtered[i];
        filtered[i + 1] = 0;
        i++;
      }
    }
    final result = filtered.where((value) => value != 0).toList();
    while (result.length < colCount) {
      result.add(0);
    }
    return result;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _canMove() {
    for (var row = 0; row < rowCount; row++) {
      for (var col = 0; col < colCount; col++) {
        if (_board[row][col] == 0) return true;
        if (col < colCount - 1 && _board[row][col] == _board[row][col + 1]) {
          return true;
        }
        if (row < rowCount - 1 && _board[row][col] == _board[row + 1][col]) {
          return true;
        }
      }
    }
    return false;
  }

  void _tryMove(bool Function() move) {
    if (_gameOver) return;
    final boardBefore = _cloneBoard(_board);
    final scoreBefore = _score;
    final gameOverBefore = _gameOver;

    final moved = move();
    if (moved) {
      _undoStack.add(_PreviousGameState(
        board: boardBefore,
        score: scoreBefore,
        gameOver: gameOverBefore,
      ));
      _addRandomTile();
      if (!_canMove()) {
        _gameOver = true;
      }
      setState(() {});
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    if (details.primaryVelocity! > 0) {
      _tryMove(_moveRight);
    } else if (details.primaryVelocity! < 0) {
      _tryMove(_moveLeft);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    if (details.primaryVelocity! > 0) {
      _tryMove(_moveDown);
    } else if (details.primaryVelocity! < 0) {
      _tryMove(_moveUp);
    }
  }

  Color _tileColor(int value) {
    switch (value) {
      case 0:
        return const Color(0xFFCCC0B3);
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      case 2048:
        return const Color(0xFFEDC22E);
      default:
        return const Color(0xFF3C3A32);
    }
  }

  Color _tileTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home),
                    tooltip: 'Главное меню',
                  ),
                  IconButton(
                    onPressed: _resetGame,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Перезапустить',
                  ),
                  IconButton(
                    onPressed: _undoStack.isNotEmpty ? _undoMove : null,
                    icon: const Icon(Icons.undo),
                    tooltip: 'Шаг назад',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoCard('Score', '$_score'),
                  _buildInfoCard('Undo', '${_undoStack.length}'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBADA0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AspectRatio(
                      aspectRatio: colCount / rowCount,
                      child: GestureDetector(
                        onHorizontalDragEnd: _onHorizontalDragEnd,
                        onVerticalDragEnd: _onVerticalDragEnd,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: colCount,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: rowCount * colCount,
                          itemBuilder: (context, index) {
                            final row = index ~/ colCount;
                            final col = index % colCount;
                            final value = _board[row][col];
                            return Container(
                              decoration: BoxDecoration(
                                color: _tileColor(value),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: value == 0
                                    ? const SizedBox.shrink()
                                    : Text(
                                        '$value',
                                        style: TextStyle(
                                          fontSize: value < 100 ? 32 : value < 1000 ? 28 : 24,
                                          fontWeight: FontWeight.w700,
                                          color: _tileTextColor(value),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Swipe to move tiles', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF776E65))),
              if (_gameOver)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Game Over',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFCDC1B4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousGameState {
  final List<List<int>> board;
  final int score;
  final bool gameOver;

  _PreviousGameState({
    required this.board,
    required this.score,
    required this.gameOver,
  });
}
