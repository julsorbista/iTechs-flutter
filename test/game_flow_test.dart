import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itechs/glob/user.dart';
import 'package:itechs/widgets/game_entry.dart';
import 'package:itechs/widgets/game_completion_flow.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AllUsers.activeUser = Map<String, String>.from(AllUsers.userList.first);
  });

  for (final game in [1, 3, 5]) {
    testWidgets(
      'Game ${game + 1} loads, introduces level 1 once, skips later levels',
      (tester) async {
        Future<void> enter(int level) async {
          await tester.pumpWidget(
            MaterialApp(
              home: GameEntry(
                key: UniqueKey(),
                game: game,
                level: level,
                builder: (firstPlay) => Text(firstPlay ? 'intro' : 'game'),
              ),
            ),
          );
          expect(find.text('Loading game...'), findsOneWidget);
          await tester.pumpAndSettle();
        }

        await enter(1);
        expect(find.text('intro'), findsOneWidget);
        // Leaving before completing the tutorial must not consume first play.
        await enter(1);
        expect(find.text('intro'), findsOneWidget);
        await GameIntro.complete(game);
        await enter(1);
        expect(find.text('game'), findsOneWidget);
        for (var level = 2; level <= 5; level++) {
          await enter(level);
          expect(find.text('game'), findsOneWidget);
        }
      },
    );
  }

  for (final size in [const Size(1280, 720), const Size(390, 844)]) {
    testWidgets('Successful run celebrates then shows results at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameCompletionFlow(successful: true, child: Text('Results')),
          ),
        ),
      );
      expect(find.text('CONGRATULATIONS!'), findsOneWidget);
      expect(find.text('Results'), findsNothing);
      await tester.tap(find.text('View Results'));
      await tester.pumpAndSettle();
      expect(find.text('Results'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Failed run goes directly to results', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameCompletionFlow(
            successful: false,
            child: Text('Retry Level'),
          ),
        ),
      ),
    );
    expect(find.text('CONGRATULATIONS!'), findsNothing);
    expect(find.text('Retry Level'), findsOneWidget);
  });
}
