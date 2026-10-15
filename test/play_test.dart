import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itechs/glob/game_catalog.dart';
import 'package:itechs/glob/game_data.dart';
import 'package:itechs/glob/user.dart';
import 'package:itechs/play.dart';
import 'package:itechs/levels.dart';

import 'audio_mock.dart';

void main() {
  setUp(() {
    mockAudio();
    AllUsers.activeUser = AllUsers.userList[0];
    AllUsers.sfxVolume = 0;
    GameData.levelRecords = [];
  });
  tearDown(() {
    AllUsers.sfxVolume = 55;
  });
  test('Original catalog and course-specific level records', () {
    expect(GameCatalog.games.map((g) => (g['levels'] as List).length), [
      5,
      5,
      10,
      5,
      5,
      5,
    ]);
    expect(GameCatalog.games[4]['title'], 'Code Snowman');
    GameData.level(0, 1)['bestStars'] = 3;
    AllUsers.activeUser!['courseCode'] = 'JAVA2026';
    expect(GameData.summary(0)['stars'], 0);
    AllUsers.activeUser!['courseCode'] = 'FN2LH4CF';
    expect(GameData.summary(0)['stars'], 3);
  });
  testWidgets('All six games open levels without awarding activity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    );
    final sdk = Uri.parse(config['flutterRoot'] as String).toFilePath();
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final font = FontLoader(entry.key);
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('$sdk/bin/cache/artifacts/material_fonts/${entry.value}')
                .readAsBytesSync(),
          ),
        ),
      );
      await font.load();
    }
    for (final entry in {
      'MenuPixel': 'PixelOperator8-Bold.ttf',
      'SettingsPixel': 'PixelOperator8.ttf',
    }.entries) {
      final font = FontLoader(entry.key);
      font.addFont(rootBundle.load('assets/images/${entry.value}'));
      await font.load();
    }
    await tester.pumpWidget(
      MaterialApp(
        home: const PlayPage(),
        routes: {'/levels': (_) => const LevelsPage()},
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final icon in [
        'icon-move.png',
        'icon-hazard.png',
        'icon-heart.png',
        'icon-lock.png',
        'icon-trophy.png',
        'icon-dot.png',
      ]) {
        await precacheImage(
          AssetImage('assets/guidelines/$icon'),
          tester.element(find.byType(PlayPage)),
        );
      }
      await precacheImage(
        const AssetImage('assets/images/menu-background.png'),
        tester.element(find.byType(PlayPage)),
      );
      await precacheImage(
        const AssetImage('assets/images/logo.png'),
        tester.element(find.byType(PlayPage)),
      );
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/play-menu.png'),
    );
    for (int i = 0; i < 6; i++) {
      final card = find.byKey(ValueKey('game-$i'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('LEVEL SELECT'), findsNothing);
      expect(find.byKey(const ValueKey('game-overview')), findsOneWidget);
      final open = find.widgetWithText(ElevatedButton, 'OPEN LEVELS  ›');
      if (i == 0) {
        await tester.ensureVisible(open);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold).last,
          matchesGoldenFile('previews/play-game-overview.png'),
        );
      }
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('game-overview')), findsNothing);
      expect(find.text('LEVEL SELECT'), findsOneWidget);
      if (i == 0) {
        await expectLater(
          find.byType(Scaffold).last,
          matchesGoldenFile('previews/play-levels.png'),
        );
      }
      final second = find.byKey(const ValueKey('level-2'));
      await tester.ensureVisible(second);
      await tester.tap(second);
      await tester.pumpAndSettle();
      expect(find.text('Level 02'), findsOneWidget);
      await tester.ensureVisible(find.text('LEVEL GUIDELINES'));
      await tester.tap(find.text('LEVEL GUIDELINES'));
      await tester.pumpAndSettle();
      expect(find.text('General Game Guidelines'), findsOneWidget);
      if (i == 0) {
        await tester.ensureVisible(find.text('LEVEL GUIDELINES'));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold).last,
          matchesGoldenFile('previews/play-guidelines.png'),
        );
      }
      final start = find.widgetWithText(ElevatedButton, 'START LEVEL');
      expect(tester.widget<ElevatedButton>(start).onPressed, isNull);
      expect(GameData.summary(i)['stars'], 0);
      expect(GameData.summary(i)['completed'], 0);
      expect(GameData.level(i, 2)['status'], 'Locked');
      expect(GameData.level(i, 2)['attempts'], 0);
      await tester.ensureVisible(find.text('BACK TO GAMES').last);
      await tester.tap(find.text('BACK TO GAMES').last);
      await tester.pumpAndSettle();
      expect(find.text('Play'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
