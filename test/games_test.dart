import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itechs/games/game_content.dart';
import 'package:itechs/games/gameplay_page.dart';
import 'package:itechs/games/original_game_bridge.dart';
import 'package:itechs/glob/game_data.dart';
import 'package:itechs/glob/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    AllUsers.activeUser = Map<String, String>.from(AllUsers.userList[0]);
    AllUsers.activeUser!['courseCode'] = 'FN2LH4CF';
    GameData.levelRecords = [];
    GameData.history = [];
    GameData.wallets = {};
    await GameContent.load();
  });

  test('Original memory result saves, unlocks, and survives reload', () async {
    final bridge = OriginalGameBridge(2);
    final session = await bridge.handle({
      'type': 'start',
      'game': 'GAME_THREE',
      'number': 1,
    });
    final finish = {
      'type': 'finish',
      'game': 'GAME_THREE',
      'number': 1,
      'session': session['sessionId'],
      'payload': {
        'outcome': 'COMPLETED',
        'starsEarned': 3,
        'baseScore': 200,
        'mistakes': 0,
      },
    };
    final results = await Future.wait([
      bridge.handle(finish),
      bridge.handle(finish),
    ]);
    final result = results.first;
    expect(result['result'], 'COMPLETED');
    expect(result['finalScore'], 200);
    expect(GameData.level(2, 2)['status'], 'Ready');
    await bridge.handle(finish);
    expect(GameData.history.length, 1);
    GameData.levelRecords = [];
    GameData.history = [];
    await GameData.load();
    expect(GameData.level(2, 1)['bestStars'], 3);
    expect(GameData.level(2, 1)['attempts'], 1);
  });

  test(
    'Original game bridge rejects locked levels and other game types',
    () async {
      final bridge = OriginalGameBridge(0);
      await expectLater(
        bridge.handle({'type': 'start', 'game': 'GAME_ONE', 'number': 2}),
        throwsStateError,
      );
      await expectLater(
        bridge.handle({'type': 'start', 'game': 'GAME_TWO', 'number': 1}),
        throwsStateError,
      );
      await expectLater(
        bridge.handle({
          'type': 'finish',
          'game': 'GAME_ONE',
          'number': 1,
          'session': 'missing',
        }),
        throwsStateError,
      );
    },
  );

  test(
    'Wallet and reset are scoped to the current student and course',
    () async {
      final bridge = OriginalGameBridge(4);
      await bridge.handle({'type': 'coins', 'balance': 12});
      await bridge.handle({'type': 'start', 'game': 'GAME_FIVE', 'number': 1});
      AllUsers.activeUser!['courseCode'] = 'JAVA2026';
      expect(GameData.coins, 0);
      await expectLater(
        bridge.handle({'type': 'coins', 'balance': 20}),
        throwsStateError,
      );
      await GameData.reset(4);
      AllUsers.activeUser!['courseCode'] = 'FN2LH4CF';
      expect(GameData.coins, 12);
      expect(GameData.level(4, 1)['attempts'], 1);
      await GameData.reset(4);
      expect(GameData.level(4, 1)['attempts'], 0);
      expect(GameData.coins, 12);
    },
  );

  test(
    'Game One uses the original operator curriculum and mistake policy',
    () async {
      expect(
        GameContent.level(0, 3)['title'].toString().toLowerCase(),
        contains('operator'),
      );
      final bridge = OriginalGameBridge(0);
      final session = await bridge.handle({
        'type': 'start',
        'game': 'GAME_ONE',
        'number': 1,
      });
      final result = await bridge.handle({
        'type': 'finish',
        'game': 'GAME_ONE',
        'number': 1,
        'session': session['sessionId'],
        'payload': {'outcome': 'COMPLETED', 'baseScore': 500, 'mistakes': 4},
      });
      expect(result['starsEarned'], 2);
      expect(result['result'], 'COMPLETED');
      expect(GameData.level(0, 2)['status'], 'Ready');
    },
  );

  test(
    'Bundled game interfaces include Phaser, original panels and offline fonts',
    () {
      final files = Directory('assets/original_games')
          .listSync()
          .whereType<File>()
          .toList();
      expect(files.any((f) => f.path.endsWith('index.html')), true);
      final js = files
          .where((f) => f.path.endsWith('.js'))
          .map((f) => f.readAsStringSync())
          .join();
      final css = files
          .where((f) => f.path.endsWith('.css'))
          .map((f) => f.readAsStringSync())
          .join();
      expect(js, contains('GameOneTutorialScene'));
      expect(js, contains('game-five-layout'));
      expect(js, contains('game-three-side-panel'));
      expect(js, contains('game-one-mobile-controls'));
      expect(js, isNot(contains('flutter-touch-controls')));
      expect(css, contains('game-three-board-panel'));
      expect(css, isNot(contains('fonts.googleapis.com')));
      expect(files.any((f) => f.path.endsWith('.woff2')), true);
    },
  );

  testWidgets('Game One landscape viewport rotates a portrait browser', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Size? measured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LandscapeGameFrame(
            enabled: true,
            child: LayoutBuilder(
              builder: (context, c) {
                measured = Size(c.maxWidth, c.maxHeight);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    expect(measured, const Size(850, 400));
    tester.view.physicalSize = const Size(850, 400);
    await tester.pump();
    expect(measured, const Size(850, 400));
    await tester.pumpWidget(const SizedBox());
  });
}
