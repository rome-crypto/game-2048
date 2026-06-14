import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class HelpIntent extends Intent {
  const HelpIntent();
}

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  static const availableModes = <GameModeOption>[
    GameModeOption(label: '4 × 4', rows: 4, cols: 4, available: true),
    GameModeOption(label: '3 × 4', rows: 3, cols: 4, available: true),
    GameModeOption(label: '4 × 5', rows: 4, cols: 5, available: true),
    GameModeOption(label: '5 × 5', rows: 5, cols: 5, available: true),
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
                  ).then((_) => setState(() {}));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8F7A66),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Пуск',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

class TileModel {
  final int id;
  int value;
  int row;
  int col;
  bool isNew;
  bool isMerged;
  bool isToDestroy; // Флаг для плитки, которая заезжает под другую и уничтожается

  TileModel({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    this.isNew = true,
    this.isMerged = false,
    this.isToDestroy = false,
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

  List<TileModel> _tiles = [];
  int _score = 0;
  int _highScore = 0;
  bool _gameOver = false;
  int _tileIdCounter = 0;

  _PreviousGameState? _lastGameState;
  bool _canUndo = false;

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    rowCount = widget.rows;
    colCount = widget.cols;
    _initStorageAndLoad();
  }

  void _initStorageAndLoad() async {
    _prefs = await SharedPreferences.getInstance();
    final modeKey = '${rowCount}x$colCount';
    
    _highScore = _prefs.getInt('high_score_$modeKey') ?? 0;

    final savedBoardJson = _prefs.getString('saved_board_$modeKey');
    final savedScore = _prefs.getInt('saved_score_$modeKey');
    final savedGameOver = _prefs.getBool('saved_gameover_$modeKey');

    if (savedBoardJson != null && savedScore != null && savedGameOver != null) {
      final List<dynamic> decoded = jsonDecode(savedBoardJson);
      _tiles.clear();
      for (var item in decoded) {
        _tiles.add(TileModel(
          id: item['id'],
          value: item['value'],
          row: item['row'],
          col: item['col'],
          isNew: false,
          isMerged: false,
        ));
        if (item['id'] >= _tileIdCounter) {
          _tileIdCounter = item['id'] + 1;
        }
      }
      _score = savedScore;
      _gameOver = savedGameOver;
    } else {
      _generateNewGameGrid();
    }

    setState(() {
      _isInitialized = true;
    });
  }

  void _generateNewGameGrid() {
    _tiles.clear();
    _score = 0;
    _gameOver = false;
    _lastGameState = null;
    _canUndo = false;
    _addRandomTile();
    _addRandomTile();
  }

  void _saveCurrentState() async {
    final modeKey = '${rowCount}x$colCount';
    
    if (_score > _highScore) {
      _highScore = _score;
      await _prefs.setInt('high_score_$modeKey', _highScore);
    }

    if (_gameOver) {
      await _prefs.remove('saved_board_$modeKey');
      await _prefs.remove('saved_score_$modeKey');
      await _prefs.remove('saved_gameover_$modeKey');
    } else {
      // Сохраняем только живые плитки (исключая те, что в процессе удаления)
      final boardData = _tiles.where((t) => !t.isToDestroy).map((tile) => {
        'id': tile.id,
        'value': tile.value,
        'row': tile.row,
        'col': tile.col,
      }).toList();

      await _prefs.setString('saved_board_$modeKey', jsonEncode(boardData));
      await _prefs.setInt('saved_score_$modeKey', _score);
      await _prefs.setBool('saved_gameover_$modeKey', _gameOver);
    }
  }

  void _resetGame() {
    setState(() {
      _generateNewGameGrid();
      _saveCurrentState();
    });
  }

  void _undoMove() {
    if (!_canUndo || _lastGameState == null) return;
    
    setState(() {
      _tiles = _lastGameState!.tiles.map((t) => TileModel(
        id: t.id,
        value: t.value,
        row: t.row,
        col: t.col,
        isNew: false,
        isMerged: false,
      )).toList();
      _score = _lastGameState!.score;
      _gameOver = _lastGameState!.gameOver;
      _canUndo = false;
      _saveCurrentState();
    });
  }

  void _openHelp({String? contextPage}) async {
    const String helpFile = 'New_help.chm';
    if (contextPage != null) {
      await Process.run('hh.exe', ['$helpFile::/$contextPage']);
    } else {
      await Process.run('hh.exe', [helpFile]);
    }
  }

  void _addRandomTile() {
    final occupied = <String, bool>{};
    for (var tile in _tiles.where((t) => !t.isToDestroy)) {
      occupied['${tile.row},${tile.col}'] = true;
    }

    final emptyCells = <Point<int>>[];
    for (var r = 0; r < rowCount; r++) {
      for (var c = 0; c < colCount; c++) {
        if (occupied['$r,$c'] == null) {
          emptyCells.add(Point(r, c));
        }
      }
    }

    if (emptyCells.isEmpty) return;
    final position = emptyCells[_random.nextInt(emptyCells.length)];
    final val = _random.nextInt(10) == 0 ? 4 : 2;

    _tiles.add(TileModel(
      id: _tileIdCounter++,
      value: val,
      row: position.x,
      col: position.y,
      isNew: true,
    ));
  }

  void _tryMove(void Function() moveDirection) {
    if (_gameOver) return;

    // Удаляем старые уничтоженные плитки перед новым ходом, если они остались
    _tiles.removeWhere((t) => t.isToDestroy);

    final tilesBefore = _tiles.map((t) => TileModel(id: t.id, value: t.value, row: t.row, col: t.col)).toList();
    final scoreBefore = _score;
    final gameOverBefore = _gameOver;

    for (var tile in _tiles) {
      tile.isNew = false;
      tile.isMerged = false;
    }

    moveDirection();

    bool moved = false;
    for (var current in _tiles.where((t) => !t.isToDestroy)) {
      var before = tilesBefore.firstWhere((t) => t.id == current.id, orElse: () => TileModel(id: -1, value: 0, row: -1, col: -1));
      if (before.id == -1 || before.row != current.row || before.col != current.col) {
        moved = true;
        break;
      }
    }
    // Также свайп засчитывается, если появились плитки на уничтожение (было слияние)
    if (_tiles.any((t) => t.isToDestroy)) {
      moved = true;
    }

    if (moved) {
      _lastGameState = _PreviousGameState(
        tiles: tilesBefore,
        score: scoreBefore,
        gameOver: gameOverBefore,
      );
      _canUndo = true;

      _addRandomTile();
      if (!_canMove()) {
        _gameOver = true;
      }
      setState(() {});
      _saveCurrentState();

      // Через 200мс (время окончания анимации переезда) очищаем заехавшие плитки
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _tiles.removeWhere((t) => t.isToDestroy);
          });
        }
      });
    }
  }

  void _moveLeft() {
    for (var r = 0; r < rowCount; r++) {
      var rowTiles = _tiles.where((t) => t.row == r && !t.isToDestroy).toList();
      rowTiles.sort((a, b) => a.col.compareTo(b.col));

      var targetCol = 0;
      for (var i = 0; i < rowTiles.length; i++) {
        var current = rowTiles[i];
        if (targetCol > 0 && rowTiles[i - 1].value == current.value && !rowTiles[i - 1].isMerged) {
          var targetTile = rowTiles[i - 1];
          
          // Текущая плитка въезжает в целевую
          current.col = targetTile.col;
          current.isToDestroy = true; 

          // Целевая плитка помечается как объединившаяся
          targetTile.value *= 2;
          targetTile.isMerged = true;
          _score += targetTile.value;
        } else {
          current.col = targetCol;
          targetCol++;
        }
      }
    }
  }

  void _moveRight() {
    for (var r = 0; r < rowCount; r++) {
      var rowTiles = _tiles.where((t) => t.row == r && !t.isToDestroy).toList();
      rowTiles.sort((a, b) => b.col.compareTo(a.col));

      var targetCol = colCount - 1;
      for (var i = 0; i < rowTiles.length; i++) {
        var current = rowTiles[i];
        if (targetCol < colCount - 1 && rowTiles[i - 1].value == current.value && !rowTiles[i - 1].isMerged) {
          var targetTile = rowTiles[i - 1];
          current.col = targetTile.col;
          current.isToDestroy = true;

          targetTile.value *= 2;
          targetTile.isMerged = true;
          _score += targetTile.value;
        } else {
          current.col = targetCol;
          targetCol--;
        }
      }
    }
  }

  void _moveUp() {
    for (var c = 0; c < colCount; c++) {
      var colTiles = _tiles.where((t) => t.col == c && !t.isToDestroy).toList();
      colTiles.sort((a, b) => a.row.compareTo(b.row));

      var targetRow = 0;
      for (var i = 0; i < colTiles.length; i++) {
        var current = colTiles[i];
        if (targetRow > 0 && colTiles[i - 1].value == current.value && !colTiles[i - 1].isMerged) {
          var targetTile = colTiles[i - 1];
          current.row = targetTile.row;
          current.isToDestroy = true;

          targetTile.value *= 2;
          targetTile.isMerged = true;
          _score += targetTile.value;
        } else {
          current.row = targetRow;
          targetRow++;
        }
      }
    }
  }

  void _moveDown() {
    for (var c = 0; c < colCount; c++) {
      var colTiles = _tiles.where((t) => t.col == c && !t.isToDestroy).toList();
      colTiles.sort((a, b) => b.row.compareTo(a.row));

      var targetRow = rowCount - 1;
      for (var i = 0; i < colTiles.length; i++) {
        var current = colTiles[i];
        if (targetRow < rowCount - 1 && colTiles[i - 1].value == current.value && !colTiles[i - 1].isMerged) {
          var targetTile = colTiles[i - 1];
          current.row = targetTile.row;
          current.isToDestroy = true;

          targetTile.value *= 2;
          targetTile.isMerged = true;
          _score += targetTile.value;
        } else {
          current.row = targetRow;
          targetRow--;
        }
      }
    }
  }

  bool _canMove() {
    if (_tiles.where((t) => !t.isToDestroy).length < rowCount * colCount) return true;

    var grid = List.generate(rowCount, (_) => List.filled(colCount, 0));
    for (var tile in _tiles.where((t) => !t.isToDestroy)) {
      grid[tile.row][tile.col] = tile.value;
    }

    for (var r = 0; r < rowCount; r++) {
      for (var c = 0; c < colCount; c++) {
        if (c < colCount - 1 && grid[r][c] == grid[r][c + 1]) return true;
        if (r < rowCount - 1 && grid[r][c] == grid[r + 1][c]) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF8EF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.f1): const HelpIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          HelpIntent: CallbackAction<HelpIntent>(
            onInvoke: (intent) => _openHelp(contextPage: 'pravila_igry.htm'),
          ),
        },
        child: Scaffold(
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
                        onPressed: _canUndo ? _undoMove : null,
                        icon: const Icon(Icons.undo),
                        tooltip: 'Шаг назад',
                      ),
                      IconButton(
                        onPressed: () => _openHelp(),
                        icon: const Icon(Icons.help_outline),
                        tooltip: 'Помощь (F1)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard('Score', '$_score'),
                      _buildInfoCard('Best', '$_highScore'),
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
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity == null) return;
                              if (details.primaryVelocity! > 0) _tryMove(_moveRight);
                              else if (details.primaryVelocity! < 0) _tryMove(_moveLeft);
                            },
                            onVerticalDragEnd: (details) {
                              if (details.primaryVelocity == null) return;
                              if (details.primaryVelocity! > 0) _tryMove(_moveDown);
                              else if (details.primaryVelocity! < 0) _tryMove(_moveUp);
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final boardWidth = constraints.maxWidth;
                                final boardHeight = constraints.maxHeight;

                                final double spacing = 8.0;
                                final double tileWidth = (boardWidth - (spacing * (colCount + 1))) / colCount;
                                final double tileHeight = (boardHeight - (spacing * (rowCount + 1))) / rowCount;

                                List<Widget> backgroundCells = [];
                                for (int r = 0; r < rowCount; r++) {
                                  for (int c = 0; c < colCount; c++) {
                                    backgroundCells.add(
                                      Positioned(
                                        left: spacing + c * (tileWidth + spacing),
                                        top: spacing + r * (tileHeight + spacing),
                                        width: tileWidth,
                                        height: tileHeight,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFCCC0B3),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }

                                // Сортируем плитки так, чтобы въезжающие (isToDestroy) отрисовывались ПОД основными
                                var sortedTiles = List<TileModel>.from(_tiles);
                                sortedTiles.sort((a, b) => (a.isToDestroy ? 0 : 1).compareTo(b.isToDestroy ? 0 : 1));

                                List<Widget> tileWidgets = sortedTiles.map((tile) {
                                  return AnimatedPositioned(
                                    key: ValueKey(tile.id),
                                    duration: const Duration(milliseconds: 200), // Плавный переезд плитки
                                    curve: Curves.easeOutQuad,
                                    left: spacing + tile.col * (tileWidth + spacing),
                                    top: spacing + tile.row * (tileHeight + spacing),
                                    width: tileWidth,
                                    height: tileHeight,
                                    child: _AnimatedTileWidget(
                                      tile: tile,
                                      color: _tileColor(tile.value),
                                    ),
                                  );
                                }).toList();

                                return Stack(
                                  children: [
                                    ...backgroundCells,
                                    ...tileWidgets,
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_gameOver)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Game Over', textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFCDC1B4), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _tileColor(int value) {
    switch (value) {
      case 0: return const Color(0xFFCCC0B3);
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      default: return const Color(0xFFEDCF72);
    }
  }
}

class _AnimatedTileWidget extends StatefulWidget {
  final TileModel tile;
  final Color color;

  const _AnimatedTileWidget({
    required this.tile,
    required this.color,
  });

  @override
  State<_AnimatedTileWidget> createState() => _AnimatedTileWidgetState();
}

class _AnimatedTileWidgetState extends State<_AnimatedTileWidget> with TickerProviderStateMixin {
  late AnimationController _appearController;
  late AnimationController _mergeController;
  late Animation<double> _scaleAnimation;
  
  // Флаг, который переключится в true, когда анимация наплыва завершится
  bool _isVisualMergeReady = false;

  @override
  void initState() {
    super.initState();

    _appearController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _mergeController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);

    _setupAnimations();
  }

  void _setupAnimations() {
    if (widget.tile.isNew) {
      _isVisualMergeReady = true;
      _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _appearController, curve: Curves.easeOut),
      );
      _appearController.forward();
    } else if (widget.tile.isMerged) {
      // Пока плитка летит (200мс), мы НЕ показываем новое число и не пульсируем
      _isVisualMergeReady = false;
      _scaleAnimation = ConstantTween<double>(1.0).animate(_mergeController);

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _isVisualMergeReady = true; // Время пришло, показываем новое число!
          });
          
          // Создаем красивый «взрывной» эффект расширения
          _scaleAnimation = TweenSequence<double>([
            TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
            TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
          ]).animate(_mergeController);
          
          _mergeController.forward(from: 0.0);
        }
      });
    } else {
      _isVisualMergeReady = true;
      _scaleAnimation = ConstantTween<double>(1.0).animate(_mergeController);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedTileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если плитка внезапно получила статус слияния (произошел новый ход)
    if (widget.tile.isMerged && !oldWidget.tile.isMerged) {
      _setupAnimations();
    }
  }

  @override
  void dispose() {
    _appearController.dispose();
    _mergeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Если это плитка на уничтожение (которая въезжает), она сохраняет свой номинал.
    // Если это принимающая плитка, то до окончания въезда (200мс) мы делим её текущее значение на 2,
    // а как только анимация готова (_isVisualMergeReady) — показываем честный новый номинал.
    int valToPrint = widget.tile.value;
    if (widget.tile.isMerged && !_isVisualMergeReady && !widget.tile.isToDestroy) {
      valToPrint = widget.tile.value ~/ 2;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '$valToPrint',
            style: TextStyle(
              fontSize: valToPrint < 100 ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: valToPrint <= 4 ? const Color(0xFF776E65) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviousGameState {
  final List<TileModel> tiles;
  final int score;
  final bool gameOver;
  _PreviousGameState({required this.tiles, required this.score, required this.gameOver});
}