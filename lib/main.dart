import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, Process;
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

// --- СИСТЕМА ЛОКАЛИЗАЦИИ ---
enum AppLanguage { ru, en, zh }

class Localization {
  static const Map<AppLanguage, Map<String, String>> _localizedValues = {
    AppLanguage.ru: {
      'title': '2048',
      'select_mode': 'Выберите режим игры',
      'start_btn': 'Пуск',
      'score': 'Счет',
      'best': 'Рекорд',
      'game_over': 'Игра окончена',
      'home_tooltip': 'Главное меню',
      'refresh_tooltip': 'Перезапустить',
      'undo_tooltip': 'Шаг назад',
      'help_tooltip': 'Помощь',
      'lang_dialog_title': 'Выберите язык',
      'help_title': 'Руководство пользователя',
      'help_rules_title': 'Правила игры',
      'help_rules_text': '1. Используйте свайпы (вверх, вниз, влево, вправо), чтобы перемещать плитки на игровом поле.\n\n2. При столкновении двух плиток одинакового номинала они объединяются в одну, значение которой удваивается (2 + 2 = 4, 4 + 4 = 8 и так далее).\n\n3. После каждого вашего хода на случайном свободном месте поля появляется новая плитка номиналом 2 или 4.\n\n4. Ваша цель — объединять плитки и набрать как можно больше очков, стремясь получить плитку номиналом 2048 (и идти дальше!).\n\n5. Игра заканчивается, когда всё поле заполнено и ни одну плитку невозможно сдвинуть или объединить с соседней.',
      'help_controls_title': 'Управление',
      'help_controls_text': '• На смартфонах: Жесты свайпа по экрану в нужном направлении.\n• На ПК: Спайпы курсором по экрану в нужном направлении.',
      'help_close': 'Закрыть',
      'win': 'Победа',
    },
    AppLanguage.en: {
      'title': '2048',
      'select_mode': 'Select Game Mode',
      'start_btn': 'Start',
      'score': 'Score',
      'best': 'Best',
      'game_over': 'Game Over',
      'home_tooltip': 'Main Menu',
      'refresh_tooltip': 'Restart',
      'undo_tooltip': 'Undo Move',
      'help_tooltip': 'Help',
      'lang_dialog_title': 'Select Language',
      'help_title': 'User Guide',
      'help_rules_title': 'How to Play',
      'help_rules_text': '1. Swipe (Up, Down, Left, Right) to move all tiles on the board.\n\n2. When two tiles with the same number touch, they merge into one with double the value (2 + 2 = 4, 4 + 4 = 8, etc.).\n\n3. After every move, a new tile (valued 2 or 4) randomly appears in an empty space.\n\n4. Your goal is to combine tiles, earn maximum points, and reach the 2048 tile (and beyond!).\n\n5. The game ends when the board is full and no legal moves can be made (no empty spaces and no adjacent matching tiles).',
      'help_controls_title': 'Controls',
      'help_controls_text': '• On Mobile: Swipe gestures on the screen.\n• On PC: Press F1 key anytime during gameplay to open help.',
      'help_close': 'Close',
      'win': 'Victory',
    },
    AppLanguage.zh: {
      'title': '2048',
      'select_mode': '选择游戏模式',
      'start_btn': '开始游戏',
      'score': '得分',
      'best': '最高分',
      'game_over': '游戏结束',
      'home_tooltip': '主菜单',
      'refresh_tooltip': '重新开始',
      'undo_tooltip': '撤销一步',
      'help_tooltip': '帮助',
      'lang_dialog_title': '选择语言',
      'help_title': '用户指南',
      'help_rules_title': '游戏规则',
      'help_rules_text': '1. 通过向任意方向滑动屏幕（上、下、左、右）来移動所有方块。\n\n2. 当两个相同数字的方块撞在一起时，它们会合并成一个数字翻倍的新方块（如 2 + 2 = 4，4 + 4 = 8 等）。\n\n3. 每次滑动后，空白处会随机出现一个数字为 2 或 4 的新方块。\n\n4. 您的目标是不断合并方块以获得更高的分数，并努力拼出 “2048” 方块（甚至更高）！\n\n5. 当格子全部填满，且没有任何相邻方块数字相同时，游戏结束。',
      'help_controls_title': '操作说明',
      'help_controls_text': '• 手机端：在屏幕上顺着想要移动的方向滑动。\n• 电脑端：游戏中随时按下 F1 键即可调出帮助菜单。',
      'help_close': '关闭',
      'win': '胜利',
    },
  };

  static String getText(AppLanguage lang, String key) {
    return _localizedValues[lang]?[key] ?? key;
  }
}

void showLanguageDialog(BuildContext context, AppLanguage currentLang, ValueChanged<AppLanguage> onLangChanged) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(Localization.getText(currentLang, 'lang_dialog_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Русский'),
              trailing: currentLang == AppLanguage.ru ? const Icon(Icons.check, color: Colors.orange) : null,
              onTap: () {
                onLangChanged(AppLanguage.ru);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: currentLang == AppLanguage.en ? const Icon(Icons.check, color: Colors.orange) : null,
              onTap: () {
                onLangChanged(AppLanguage.en);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('中文'),
              trailing: currentLang == AppLanguage.zh ? const Icon(Icons.check, color: Colors.orange) : null,
              onTap: () {
                onLangChanged(AppLanguage.zh);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

// --- НОВАЯ СТРАНИЦА ОФФЛАЙН-СПРАВКИ ---
class OfflineHelpPage extends StatelessWidget {
  final AppLanguage currentLang;
  const OfflineHelpPage({super.key, required this.currentLang});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBBADA0),
        title: Text(
          Localization.getText(currentLang, 'help_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Localization.getText(currentLang, 'help_rules_title'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF776E65)),
              ),
              const SizedBox(height: 12),
              Text(
                Localization.getText(currentLang, 'help_rules_text'),
                style: const TextStyle(fontSize: 16, color: Color(0xFF3C3A32), height: 1.4),
              ),
              const Divider(height: 40, color: Color(0xFFCDC1B4), thickness: 1.5),
              Text(
                Localization.getText(currentLang, 'help_controls_title'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF776E65)),
              ),
              const SizedBox(height: 12),
              Text(
                Localization.getText(currentLang, 'help_controls_text'),
                style: const TextStyle(fontSize: 16, color: Color(0xFF3C3A32), height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8F7A66),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    Localization.getText(currentLang, 'help_close'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    GameModeOption(label: '3 × 4', rows: 3, cols: 4, available: true),
    GameModeOption(label: '4 × 5', rows: 4, cols: 5, available: true),
    GameModeOption(label: '5 × 5', rows: 5, cols: 5, available: true),
  ];

  late GameModeOption _selectedMode;
  AppLanguage _currentLang = AppLanguage.ru;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _selectedMode = availableModes.firstWhere((mode) => mode.available);
    _loadLanguage();
  }

  void _loadLanguage() async {
    _prefs = await SharedPreferences.getInstance();
    final langIndex = _prefs.getInt('app_lang') ?? AppLanguage.ru.index;
    setState(() {
      _currentLang = AppLanguage.values[langIndex];
    });
  }

  void _changeLanguage(AppLanguage lang) async {
    setState(() {
      _currentLang = lang;
    });
    await _prefs.setInt('app_lang', lang.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Image.asset(
                  'assets/icon/globe.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.language, size: 32),
                ),
                onPressed: () => showLanguageDialog(context, _currentLang, _changeLanguage),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    Localization.getText(_currentLang, 'title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF776E65),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    Localization.getText(_currentLang, 'select_mode'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Color(0xFF776E65)),
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
                            currentLang: _currentLang,
                          ),
                        ),
                      ).then((_) => _loadLanguage());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F7A66),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      Localization.getText(_currentLang, 'start_btn'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
  bool isToDestroy;

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
    required this.currentLang,
  });

  final int rows;
  final int cols;
  final AppLanguage currentLang;

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
  bool _hasWon = false;        // Сработал ли вообще факт победы в этой партии
  bool _showWinText = false;   // Нужно ли прямо сейчас показывать зеленую надпись "Победа"

  _PreviousGameState? _lastGameState;
  bool _canUndo = false;

  late SharedPreferences _prefs;
  bool _isInitialized = false;
  late AppLanguage _gameLang;

  @override
  void initState() {
    super.initState();
    rowCount = widget.rows;
    colCount = widget.cols;
    _gameLang = widget.currentLang;
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
      _hasWon = false;
      _showWinText = false;
      _generateNewGameGrid();
      _saveCurrentState();
    });
  }

  void _undoMove() {
    if (!_canUndo || _lastGameState == null) {
      return;
    }
    
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

  // --- КРОССПЛАТФОРМЕННЫЙ КОРРЕКТНЫЙ МЕТОД ОТКРЫТИЯ СПРАВКИ ---
  void _openHelp({String? contextPage}) async {
    // Если это Web (браузер) или мобилки (Android/iOS)
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OfflineHelpPage(currentLang: _gameLang),
          ),
        );
      }
    } else {
      // Этот блок выполнится ТОЛЬКО в нативном Windows/macOS/Linux приложении
      try {
        const String helpFile = 'New_help.chm';
        if (contextPage != null) {
          await Process.run('hh.exe', ['$helpFile::/$contextPage']);
        } else {
          await Process.run('hh.exe', [helpFile]);
        }
      } catch (e) {
        debugPrint('Ошибка запуска chm на десктопе: $e');
      }
    }
  }

  void _changeLanguage(AppLanguage lang) async {
    setState(() {
      _gameLang = lang;
    });
    await _prefs.setInt('app_lang', lang.index);
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

    if (emptyCells.isEmpty) {
      return;
    }
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
  if (_gameOver) {
    return;
  }

  // Сразу гасим надпись "Победа", если она отображалась. 
  // Это сработает в момент, когда игрок совершает следующий ход после победы.
  if (_showWinText) {
    setState(() {
      _showWinText = false;
    });
  }

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

    // ПРОВЕРКА НА ДОСТИЖЕНИЕ 2048
    // Если игрок еще не побеждал в текущей сессии, проверяем поле на наличие плитки 2048
    if (!_hasWon) {
      bool found2048 = _tiles.any((t) => t.value == 2048 && !t.isToDestroy);
      if (found2048) {
        _hasWon = true;       // Фиксируем победу в сессии (чтобы больше не спамить)
        _showWinText = true;  // Включаем отображение зеленой надписи на этот ход
      }
    }

    if (!_canMove()) {
      _gameOver = true;
    }
    setState(() {});
    _saveCurrentState();

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

      int targetCol = 0;
      TileModel? lastMergedCandidate;

      for (final tile in rowTiles) {
        if (lastMergedCandidate != null &&
            !lastMergedCandidate.isMerged &&
            lastMergedCandidate.value == tile.value) {
          tile.col = lastMergedCandidate.col;
          tile.isToDestroy = true;

          lastMergedCandidate.value *= 2;
          lastMergedCandidate.isMerged = true;

          _score += lastMergedCandidate.value;
          lastMergedCandidate = null;
        } else {
          tile.col = targetCol;
          targetCol++;
          lastMergedCandidate = tile;
        }
      }
    }
  }

  void _moveRight() {
    for (var r = 0; r < rowCount; r++) {
      var rowTiles = _tiles.where((t) => t.row == r && !t.isToDestroy).toList();
      rowTiles.sort((a, b) => b.col.compareTo(a.col));

      int targetCol = colCount - 1;
      TileModel? lastMergedCandidate;

      for (final tile in rowTiles) {
        if (lastMergedCandidate != null &&
            !lastMergedCandidate.isMerged &&
            lastMergedCandidate.value == tile.value) {
          tile.col = lastMergedCandidate.col;
          tile.isToDestroy = true;

          lastMergedCandidate.value *= 2;
          lastMergedCandidate.isMerged = true;

          _score += lastMergedCandidate.value;
          lastMergedCandidate = null;
        } else {
          tile.col = targetCol;
          targetCol--;
          lastMergedCandidate = tile;
        }
      }
    }
  }

  void _moveUp() {
    for (var c = 0; c < colCount; c++) {
      var colTiles = _tiles.where((t) => t.col == c && !t.isToDestroy).toList();
      colTiles.sort((a, b) => a.row.compareTo(b.row));

      int targetRow = 0;
      TileModel? lastMergedCandidate;

      for (final tile in colTiles) {
        if (lastMergedCandidate != null &&
            !lastMergedCandidate.isMerged &&
            lastMergedCandidate.value == tile.value) {
          tile.row = lastMergedCandidate.row;
          tile.isToDestroy = true;

          lastMergedCandidate.value *= 2;
          lastMergedCandidate.isMerged = true;

          _score += lastMergedCandidate.value;
          lastMergedCandidate = null;
        } else {
          tile.row = targetRow;
          targetRow++;
          lastMergedCandidate = tile;
        }
      }
    }
  }

  void _moveDown() {
    for (var c = 0; c < colCount; c++) {
      var colTiles = _tiles.where((t) => t.col == c && !t.isToDestroy).toList();
      colTiles.sort((a, b) => b.row.compareTo(a.row));

      int targetRow = rowCount - 1;
      TileModel? lastMergedCandidate;

      for (final tile in colTiles) {
        if (lastMergedCandidate != null &&
            !lastMergedCandidate.isMerged &&
            lastMergedCandidate.value == tile.value) {
          tile.row = lastMergedCandidate.row;
          tile.isToDestroy = true;

          lastMergedCandidate.value *= 2;
          lastMergedCandidate.isMerged = true;

          _score += lastMergedCandidate.value;
          lastMergedCandidate = null;
        } else {
          tile.row = targetRow;
          targetRow--;
          lastMergedCandidate = tile;
        }
      }
    }
  }

  bool _canMove() {
    if (_tiles.where((t) => !t.isToDestroy).length < rowCount * colCount) {
      return true;
    }

    var grid = List.generate(rowCount, (_) => List.filled(colCount, 0));
    for (var tile in _tiles.where((t) => !t.isToDestroy)) {
      grid[tile.row][tile.col] = tile.value;
    }

    for (var r = 0; r < rowCount; r++) {
      for (var c = 0; c < colCount; c++) {
        if (c < colCount - 1 && grid[r][c] == grid[r][c + 1]) {
          return true;
        }
        if (r < rowCount - 1 && grid[r][c] == grid[r + 1][c]) {
          return true;
        }
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
                  // Верхняя системная панель (Справка и Язык)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _openHelp(),
                        icon: const Icon(Icons.help_outline),
                        tooltip: Localization.getText(_gameLang, 'help_tooltip'),
                      ),
                      IconButton(
                        icon: Image.asset(
                          'assets/icon/globe.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.language, size: 24),
                        ),
                        onPressed: () => showLanguageDialog(context, _gameLang, _changeLanguage),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Панель со счетом и рекордом
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard(Localization.getText(_gameLang, 'score'), '$_score'),
                      _buildInfoCard(Localization.getText(_gameLang, 'best'), '$_highScore'),
                    ],
                  ),
                  
                  // Контейнер, выравнивающий поле и приклеенные крупные кнопки строго по центру экрана
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return AspectRatio(
                            aspectRatio: colCount / (rowCount + 0.65),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // КНОПКИ УПРАВЛЕНИЯ — УВЕЛИЧЕННЫЕ, СВЯЗАННЫЕ С КРАЯМИ ИГРОВОГО ПОЛЯ
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        icon: const Icon(Icons.home, size: 36),
                                        tooltip: Localization.getText(_gameLang, 'home_tooltip'),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        style: IconButton.styleFrom(
                                          foregroundColor: const Color(0xFF776E65),
                                          minimumSize: const Size(48, 48),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: _canUndo ? _undoMove : null,
                                        icon: const Icon(Icons.undo, size: 36),
                                        tooltip: Localization.getText(_gameLang, 'undo_tooltip'),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        style: IconButton.styleFrom(
                                          foregroundColor: const Color(0xFF776E65),
                                          minimumSize: const Size(48, 48),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      IconButton(
                                        onPressed: _resetGame,
                                        icon: const Icon(Icons.refresh, size: 36),
                                        tooltip: Localization.getText(_gameLang, 'refresh_tooltip'),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        style: IconButton.styleFrom(
                                          foregroundColor: const Color(0xFF776E65),
                                          minimumSize: const Size(48, 48),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Игровое поле
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBBADA0),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: GestureDetector(
                                      onHorizontalDragEnd: (details) {
                                        if (details.primaryVelocity == null) {
                                          return;
                                        }
                                        if (details.primaryVelocity! > 0) {
                                          _tryMove(_moveRight);
                                        } else if (details.primaryVelocity! < 0) {
                                          _tryMove(_moveLeft);
                                        }
                                      },
                                      onVerticalDragEnd: (details) {
                                        if (details.primaryVelocity == null) {
                                          return;
                                        }
                                        if (details.primaryVelocity! > 0) {
                                          _tryMove(_moveDown);
                                        } else if (details.primaryVelocity! < 0) {
                                          _tryMove(_moveUp);
                                        }
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

                                          var sortedTiles = List<TileModel>.from(_tiles);
                                          sortedTiles.sort((a, b) => (a.isToDestroy ? 0 : 1).compareTo(b.isToDestroy ? 0 : 1));

                                          List<Widget> tileWidgets = sortedTiles.map((tile) {
                                            return AnimatedPositioned(
                                              key: ValueKey(tile.id),
                                              duration: const Duration(milliseconds: 200),
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
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // НАДПИСЬ О ПОБЕДЕ (Выводится снизу под игровым полем)
                  if (_showWinText)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        Localization.getText(_gameLang, 'win'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.green, 
                          fontSize: 24, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),

                  if (_gameOver)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        Localization.getText(_gameLang, 'game_over'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
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
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      case 4096: return const Color(0xFFB77AED); // Благородный лавандовый
      case 8192: return const Color(0xFF8B5CF6); // Насыщенный фиолетовый
      case 16384: return const Color(0xFF6366F1); // Индиго
      case 32768: return const Color(0xFF3B82F6); // Яркий синий
      case 65536: return const Color(0xFF0EA5E9); // Неоновый голубой
      case 131072: return const Color(0xFF06B6D4); // Бирюзовая бездна
      case 262144: return const Color(0xFF14B8A6); // Морская волна
      case 524288: return const Color(0xFF10B981); // Мятно-изумрудный
      case 1048576: return const Color(0xFFA3E635); // Кислотно-лаймовый
      case 2097152: return const Color(0xFFFBBF24); // Янтарное золото
      case 4194304: return const Color(0xFFF97316); // Сочный оранжевый
      case 8388608: return const Color(0xFFEF4444); // Сигнальный красный
      case 16777216: return const Color(0xFFDC2626); // Глубокий рубиновый
      case 33554432: return const Color(0xFF450A0A); // Бордово-черный (Абсолютный максимум!)

      // Дефолтный цвет на случай, если кто-то взломает игру или наберёт больше максимума
      default: return const Color(0xFF1E1B18); 
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
      _isVisualMergeReady = false;
      _scaleAnimation = ConstantTween<double>(1.0).animate(_mergeController);

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _isVisualMergeReady = true;
          });
          
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
    int valToPrint = widget.tile.value;
    if (widget.tile.isMerged && !_isVisualMergeReady && !widget.tile.isToDestroy) {
      valToPrint = widget.tile.value ~/ 2;
    }

    double fontSize;
    if (valToPrint < 100) {
      fontSize = 32.0;
    } else {
      fontSize = 24.0;
    }

    Color textColor;
    if (valToPrint <= 4) {
      textColor = const Color(0xFF776E65);
    } else {
      textColor = Colors.white;
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
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
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