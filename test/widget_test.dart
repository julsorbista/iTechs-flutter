import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itechs/main.dart';
import 'package:itechs/glob/user.dart';

import 'audio_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(mockAudio);
  setUp(() {
    AllUsers.activeUser = null;
  });

  testWidgets('Login validation and logout session', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(
      find.text('Please enter your username and password.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).at(0), 'student01');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Incorrect username or password.'), findsOneWidget);
    expect(AllUsers.activeUser, isNull);
    await tester.enterText(find.byType(TextField).at(1), 'Student123!');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(AllUsers.activeUser?['username'], 'student01');
    for (final page in [
      'Play',
      'My Class',
      'My Progress',
      'Leaderboard',
      'Profile Editor',
      'Settings',
    ]) {
      await tester.ensureVisible(find.text(page.toUpperCase()));
      await tester.tap(find.text(page.toUpperCase()));
      await tester.pumpAndSettle();
      expect(
        find.text(
          page == 'Settings'
              ? 'Preferences'
              : page == 'My Class'
              ? 'Learning Materials'
              : page == 'Leaderboard'
              ? 'Leaderboards'
              : page,
        ),
        findsOneWidget,
      );
      expect(find.text('BACK TO MENU'), findsOneWidget);
      await tester.ensureVisible(find.text('BACK TO MENU'));
      await tester.tap(find.text('BACK TO MENU'));
      await tester.pumpAndSettle();
      expect(find.text('MENU'), findsOneWidget);
    }
    await tester.ensureVisible(find.byTooltip('Log out'));
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(AllUsers.activeUser, isNull);
    expect(find.text('Sign In'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.text('Sign In'))).canPop(),
      isFalse,
    );
  });

  testWidgets('Password visibility toggle', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isFalse,
    );
  });
}
