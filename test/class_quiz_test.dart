import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itechs/glob/class_data.dart';
import 'package:itechs/glob/lesson_data.dart';
import 'package:itechs/glob/user.dart';
import 'package:itechs/main.dart';
import 'package:itechs/quiz.dart';
import 'package:itechs/result.dart';

import 'audio_mock.dart';

void fillAnswers(int correct) {
  final questions = LessonData.modules[0]['questions'] as List;
  final draft = ClassData.draft(0);
  for (int i = 0; i < questions.length; i++) {
    draft['answers'][i] = i < correct
        ? questions[i]['answer']
        : (questions[i]['answer'] + 1) % 4;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockAudio();
    AllUsers.activeUser = AllUsers.userList[0];
    AllUsers.activeUser!['courseCode'] = 'FN2LH4CF';
    ClassData.progressList = [];
    ClassData.quizAttempts = [];
    ClassData.lastResult = null;
    ClassData.activeModule = 0;
  });
  tearDown(() {
    ClassData.progressList = [];
    ClassData.quizAttempts = [];
    ClassData.lastResult = null;
    AllUsers.userList[0]['courseCode'] = 'FN2LH4CF';
    AllUsers.activeUser = null;
  });

  test(
    'Latest quiz stars replace previous stars and preserve attempt history',
    () {
      fillAnswers(10);
      ClassData.submitQuiz(0);
      expect(ClassData.leaderboardRecords().first['totalStars'], 3);
      expect(ClassData.unlocked(1), isTrue);
      expect(ClassData.progress(0).containsKey('draft'), isFalse);
      fillAnswers(7);
      ClassData.submitQuiz(0);
      expect(ClassData.leaderboardRecords().first['totalStars'], 2);
      expect(ClassData.quizAttempts.length, 2);
      expect(ClassData.quizAttempts.first['percentage'], 100);
      fillAnswers(0);
      ClassData.submitQuiz(0);
      expect(ClassData.leaderboardRecords().first['totalStars'], 0);
    },
  );

  test('Original star thresholds, lesson progress, and course isolation', () {
    for (final pair in [
      [4, 0],
      [5, 1],
      [7, 2],
      [8, 2],
      [9, 3],
      [10, 3],
    ]) {
      fillAnswers(pair[0]);
      expect(ClassData.submitQuiz(0)['stars'], pair[1]);
    }
    expect(ClassData.percent(0), 0);
    ClassData.viewPage(0, 0);
    ClassData.viewPage(0, 0);
    expect(ClassData.progress(0)['viewedPages'].length, 1);
    AllUsers.activeUser!['courseCode'] = 'JAVA2026';
    expect(ClassData.percent(0), 0);
    expect(ClassData.leaderboardRecords().first['totalStars'], 0);
    AllUsers.activeUser!['courseCode'] = 'FN2LH4CF';
    expect(ClassData.leaderboardRecords().first['totalStars'], 3);
  });

  testWidgets(
    'My Class to lesson to quiz result changes the leaderboard rank',
    (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MyApp());
      await tester.enterText(find.byType(TextField).at(0), 'student01');
      await tester.enterText(find.byType(TextField).at(1), 'Student123!');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MY CLASS'));
      await tester.pumpAndSettle();
      expect(find.text('Learning Materials'), findsOneWidget);
      expect(ClassData.unlocked(1), isFalse);
      await tester.ensureVisible(find.textContaining('START MODULE').first);
      await tester.tap(find.textContaining('START MODULE').first);
      await tester.pumpAndSettle();
      final pages = LessonData.modules[0]['pages'] as List;
      for (int i = 0; i < pages.length; i++) {
        await tester.ensureVisible(find.textContaining('Course Outline').first);
        await tester.tap(find.textContaining('Course Outline').first);
        await tester.pumpAndSettle();
        final item = find.text('${i + 1}. ${pages[i]['title']}');
        await tester.ensureVisible(item);
        await tester.tap(item);
        await tester.pumpAndSettle();
      }
      expect(ClassData.percent(0), 100);
      await tester.ensureVisible(find.text('Take a Quiz'));
      await tester.tap(find.text('Take a Quiz'));
      await tester.pumpAndSettle();
      final questions = LessonData.modules[0]['questions'] as List;
      for (int i = 0; i < questions.length; i++) {
        final answer = find.byKey(ValueKey('answer-${questions[i]['answer']}'));
        await tester.ensureVisible(answer);
        await tester.tap(answer);
        final next = find.text(i == questions.length - 1 ? 'Submit' : 'Next ›');
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      expect(find.text('PASSED'), findsOneWidget);
      expect(find.text('10 / 10'), findsOneWidget);
      expect(ClassData.leaderboardRecords().first['totalStars'], 3);
      await tester.ensureVisible(find.text('Back to Materials'));
      await tester.tap(find.text('Back to Materials'));
      await tester.pumpAndSettle();
      expect(ClassData.unlocked(1), isTrue);
      await tester.ensureVisible(find.text('BACK TO MENU'));
      await tester.tap(find.text('BACK TO MENU'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LEADERBOARD'));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('rank-3'));
      expect(
        find.descendant(of: row, matching: find.text('Juan Dela Cruz')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('3')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Incomplete answers are blocked and timeout submits only once', (
    tester,
  ) async {
    ClassData.draft(0)['questionIndex'] = 9;
    await tester.pumpWidget(
      MaterialApp(
        home: const QuizPage(),
        routes: {'/result': (context) => const ResultPage()},
      ),
    );
    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(
      find.text('Answer all questions before submitting.'),
      findsOneWidget,
    );
    expect(ClassData.quizAttempts, isEmpty);
    ClassData.draft(0)['remainingSeconds'] = 1;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('FAILED'), findsOneWidget);
    expect(ClassData.quizAttempts.length, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(ClassData.quizAttempts.length, 1);
  });
}
