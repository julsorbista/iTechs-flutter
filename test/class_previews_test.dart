import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itechs/glob/class_data.dart';
import 'package:itechs/glob/lesson_data.dart';
import 'package:itechs/glob/user.dart';
import 'package:itechs/my_class.dart';
import 'package:itechs/module.dart';
import 'package:itechs/quiz.dart';
import 'package:itechs/result.dart';

import 'audio_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Java class, lesson, quiz and result mobile previews', (
    tester,
  ) async {
    mockAudio();
    AllUsers.activeUser = AllUsers.userList[0];
    ClassData.activeModule = 0;
    ClassData.progressList = [];
    ClassData.quizAttempts = [];
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in {
      'MenuPixel': 'PixelOperator8-Bold.ttf',
      'SettingsPixel': 'PixelOperator8.ttf',
    }.entries) {
      final font = FontLoader(entry.key);
      font.addFont(rootBundle.load('assets/images/${entry.value}'));
      await font.load();
    }
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
    await tester.pumpWidget(const MaterialApp(home: MyClassPage()));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/menu-background.png'),
        tester.element(find.byType(MyClassPage)),
      );
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/my-class.png'),
    );
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/learning-materials.png'),
    );
    final pages = LessonData.modules[0]['pages'] as List;
    for (int i = 0; i < pages.length; i++) {
      ClassData.viewPage(0, i);
    }
    ClassData.progress(0)['currentPage'] = 0;
    await tester.pumpWidget(const MaterialApp(home: ModulePage()));
    await tester.runAsync(() async {
      await precacheImage(
        AssetImage('assets/lessons/${pages[0]['image']}'),
        tester.element(find.byType(ModulePage)),
      );
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/java-module.png'),
    );
    await tester.pumpWidget(const MaterialApp(home: QuizPage()));
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/java-quiz.png'),
    );
    final questions = LessonData.modules[0]['questions'] as List;
    final draft = ClassData.draft(0);
    for (int i = 0; i < questions.length; i++) {
      draft['answers'][i] = i == 9
          ? (questions[i]['answer'] + 1) % 4
          : questions[i]['answer'];
    }
    draft['remainingSeconds'] = 936;
    ClassData.submitQuiz(0);
    await tester.pumpWidget(const MaterialApp(home: ResultPage()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/quiz-result.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    ClassData.progressList = [];
    ClassData.quizAttempts = [];
    ClassData.lastResult = null;
    AllUsers.activeUser = null;
  });
}
