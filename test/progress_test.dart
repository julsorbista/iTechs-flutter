import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itechs/glob/class_data.dart';
import 'package:itechs/glob/lesson_data.dart';
import 'package:itechs/glob/user.dart';
import 'package:itechs/module.dart';
import 'package:itechs/progress.dart';

import 'audio_mock.dart';

void seedProgress() {
  final pages = LessonData.modules[0]['pages'] as List;
  for (int i = 0; i < pages.length; i++) {
    ClassData.viewPage(0, i);
  }
  final first = ClassData.progress(0);
  first['latestScore'] = 90;
  first['passed'] = true;
  first['readingMilliseconds'] = 60000;
  ClassData.viewPage(1, 0);
  final second = ClassData.progress(1);
  second['latestScore'] = 0;
  second['readingMilliseconds'] = 120000;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockAudio();
    ClassData.progressList = [];
    AllUsers.activeUser = AllUsers.userList[0];
    AllUsers.activeUser!['courseCode'] = 'FN2LH4CF';
    ClassData.activeModule = 0;
  });
  tearDown(() {
    ClassData.progressList = [];
    AllUsers.userList[0]['courseCode'] = 'FN2LH4CF';
    AllUsers.activeUser = null;
  });

  test('Summary uses current course, reading percentages, and latest scores including zero', () {
    expect(ClassData.progressSummary()['overallProgress'], 0);
    seedProgress();
    final summary = ClassData.progressSummary();
    expect(summary['completedModules'], 1);
    expect(summary['totalModules'], 3);
    expect(
      summary['overallProgress'],
      ((100 + ClassData.percent(1)) / 3).round(),
    );
    expect(summary['quizPerformance'], 45);
    expect(summary['learningSeconds'], 180);
    expect(summary['xpEarned'], 0);
    expect(summary['coinsEarned'], 0);
    ClassData.progress(0)['latestScore'] = 100;
    expect(ClassData.progressSummary()['quizPerformance'], 50);
    AllUsers.activeUser!['courseCode'] = 'JAVA2026';
    expect(ClassData.progressSummary()['overallProgress'], 0);
    expect(ClassData.progressSummary()['learningSeconds'], 0);
    expect(ClassData.progressSummary()['quizPerformance'], 0);
  });

  testWidgets('Progress table reflects saved module status and score', (
    tester,
  ) async {
    seedProgress();
    await tester.pumpWidget(const MaterialApp(home: ProgressPage()));
    final completed = find.byKey(const ValueKey('module-progress-0'));
    final started = find.byKey(const ValueKey('module-progress-1'));
    final locked = find.byKey(const ValueKey('module-progress-2'));
    expect(
      find.descendant(of: completed, matching: find.text('Completed')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: completed, matching: find.text('90')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: started, matching: find.text('In Progress')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: started, matching: find.text('0')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: locked, matching: find.text('Locked')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: locked, matching: find.text('--')),
      findsOneWidget,
    );
    expect(find.text('3m'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);
  });

  testWidgets('Lesson time pauses behind other routes and saves on leaving', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ModulePage()));
    final state = tester.state<ModulePageState>(find.byType(ModulePage));
    expect(state.readingWatch.isRunning, isTrue);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    final context = tester.element(find.byType(ModulePage));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const Scaffold(body: Text('Other screen')),
      ),
    );
    await tester.pumpAndSettle();
    expect(state.readingWatch.isRunning, isFalse);
    final saved = ClassData.progress(0)['readingMilliseconds'] as int;
    expect(saved, greaterThan(0));
    await tester.pump(const Duration(seconds: 5));
    expect(ClassData.progress(0)['readingMilliseconds'], saved);
    Navigator.of(tester.element(find.text('Other screen'))).pop();
    await tester.pumpAndSettle();
    expect(state.readingWatch.isRunning, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      ClassData.progress(0)['readingMilliseconds'],
      greaterThanOrEqualTo(saved),
    );
  });

  testWidgets('Progress stays landscape in landscape and portrait windows', (
    tester,
  ) async {
    seedProgress();
    tester.view.physicalSize = const Size(1060, 470);
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
    await tester.pumpWidget(const MaterialApp(home: ProgressPage()));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/menu-background.png'),
        tester.element(find.byType(ProgressPage)),
      );
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tracker'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/my-progress-landscape.png'),
    );
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -380),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/my-progress-table.png'),
    );
    tester.view.physicalSize = const Size(400, 850);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Scaffold)).width, 850);
    expect(tester.getSize(find.byType(Scaffold)).height, 400);
    expect(tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns, 1);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/my-progress-portrait-window.png'),
    );
  });

  testWidgets('Progress requests landscape and restores portrait on exit', (
    tester,
  ) async {
    final orientations = <dynamic>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            orientations.add(call.arguments);
          }
          return null;
        });
    await tester.pumpWidget(const MaterialApp(home: ProgressPage()));
    await tester.pump();
    expect(orientations.first, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(orientations.last, ['DeviceOrientation.portraitUp']);
  });
}
