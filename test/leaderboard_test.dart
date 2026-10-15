import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itechs/glob/user.dart';
import 'package:itechs/leaderboard.dart';

void main() {
  final originalRecords = List<Map<String, dynamic>>.from(
    AllUsers.leaderboardList,
  );
  tearDown(() {
    AllUsers.leaderboardList = List.from(originalRecords);
  });

  testWidgets(
    'Ranking uses stars, completed activities, then name without changing shared order',
    (tester) async {
      AllUsers.leaderboardList = [
        {'studentName': 'Zoe', 'totalStars': 10, 'completedActivities': 2},
        {'studentName': 'Bea', 'totalStars': 10, 'completedActivities': 3},
        {'studentName': 'Ace', 'totalStars': 12, 'completedActivities': 0},
        {'studentName': 'Ana', 'totalStars': 10, 'completedActivities': 3},
      ];
      await tester.pumpWidget(const MaterialApp(home: LeaderboardPage()));
      for (int i = 0; i < 4; i++) {
        final row = find.byKey(ValueKey('rank-${i + 1}'));
        expect(
          find.descendant(
            of: row,
            matching: find.text(['Ace', 'Ana', 'Bea', 'Zoe'][i]),
          ),
          findsOneWidget,
        );
      }
      expect(AllUsers.leaderboardList.first['studentName'], 'Zoe');
      expect(find.text('4 students ranked'), findsOneWidget);
    },
  );

  testWidgets('Empty standings show the original empty state', (tester) async {
    AllUsers.leaderboardList = [];
    await tester.pumpWidget(const MaterialApp(home: LeaderboardPage()));
    expect(find.text('0 students ranked'), findsOneWidget);
    expect(find.text('No leaderboard data available yet.'), findsOneWidget);
  });

  testWidgets('Leaderboard mobile preview', (tester) async {
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
    await tester.pumpWidget(const MaterialApp(home: LeaderboardPage()));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/menu-background.png'),
        tester.element(find.byType(LeaderboardPage)),
      );
    });
    await tester.pumpAndSettle();
    expect(find.text('5 students ranked'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(5));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/leaderboard.png'),
    );
  });
}
