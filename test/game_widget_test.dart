import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game_2048/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Очищаем SharedPreferences перед каждым тестом
    SharedPreferences.setMockInitialValues({});
  });

  group('MainMenuPage Widget Tests', () {
    testWidgets(
      'отображается главное меню и кнопка запуска',
      (tester) async {
        await tester.pumpWidget(const Game2048App());

        expect(find.text('2048'), findsOneWidget);
        expect(find.text('Пуск'), findsOneWidget);
      },
    );

    testWidgets(
      'отображаются все игровые режимы',
      (tester) async {
        await tester.pumpWidget(const Game2048App());

        expect(find.text('4 × 4'), findsOneWidget);
        expect(find.text('3 × 4'), findsOneWidget);
        expect(find.text('4 × 5'), findsOneWidget);
        expect(find.text('5 × 5'), findsOneWidget);
      },
    );

    testWidgets(
      'можно выбрать другой игровой режим',
      (tester) async {
        await tester.pumpWidget(const Game2048App());

        await tester.tap(find.text('5 × 5'));
        await tester.pump();

        expect(find.text('5 × 5'), findsOneWidget);
      },
    );

    testWidgets(
      'кнопка Пуск открывает игровую страницу',
      (tester) async {
        await tester.pumpWidget(const Game2048App());

        await tester.tap(find.text('Пуск'));

        await tester.pumpAndSettle();

        expect(find.byType(Game2048Page), findsOneWidget);
      },
    );
  });

  group('Game2048Page Widget Tests', () {
    testWidgets(
      'отображаются счет и рекорд',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Game2048Page(
              rows: 4,
              cols: 4,
              currentLang: AppLanguage.ru,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Счет'), findsOneWidget);
        expect(find.text('Рекорд'), findsOneWidget);
      },
    );

    testWidgets(
      'отображаются кнопки управления',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Game2048Page(
              rows: 4,
              cols: 4,
              currentLang: AppLanguage.ru,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byIcon(Icons.undo), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
      },
    );

    testWidgets(
      'кнопка справки существует',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Game2048Page(
              rows: 4,
              cols: 4,
              currentLang: AppLanguage.ru,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byTooltip('Помощь (F1)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'отображается игровое поле',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Game2048Page(
              rows: 4,
              cols: 4,
              currentLang: AppLanguage.ru,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(GestureDetector), findsWidgets);
      },
    );

    testWidgets(
      'кнопка возврата возвращается в меню',
      (tester) async {
        await tester.pumpWidget(
          const Game2048App(),
        );

        await tester.tap(find.text('Пуск'));

        await tester.pumpAndSettle();

        expect(find.byType(Game2048Page), findsOneWidget);

        await tester.tap(find.byIcon(Icons.home));

        await tester.pumpAndSettle();

        expect(find.byType(MainMenuPage), findsOneWidget);
      },
    );

    testWidgets(
      'кнопка перезапуска существует и активна',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Game2048Page(
              rows: 4,
              cols: 4,
              currentLang: AppLanguage.ru,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final refreshButton =
            find.byTooltip('Перезапустить');

        expect(refreshButton, findsOneWidget);

        await tester.tap(refreshButton);

        await tester.pump();
      },
    );
  });
}