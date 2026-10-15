import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itechs/glob/user.dart';
import 'package:itechs/main.dart';
import 'package:itechs/settings.dart';

import 'audio_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AllUsers.savedPasswords = {};
    mockAudio();
    audioCalls.clear();
    AllUsers.userList[0]['password'] = 'Student123!';
    AllUsers.activeUser = AllUsers.userList[0];
    AllUsers.musicVolume = 55;
    AllUsers.sfxVolume = 55;
  });
  tearDown(() {
    AllUsers.savedPasswords = {};
    AllUsers.userList[0]['password'] = 'Student123!';
    AllUsers.activeUser = null;
  });

  testWidgets('Password validates and changes credentials for the next login', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.ensureVisible(find.text('CHANGE PASSWORD'));
    await tester.tap(find.text('CHANGE PASSWORD'));
    await tester.pump();
    expect(find.text('Complete both password fields first.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Wrong123!');
    await tester.enterText(find.byType(TextField).at(1), 'NewPass456!');
    await tester.ensureVisible(find.text('CHANGE PASSWORD'));
    await tester.tap(find.text('CHANGE PASSWORD'));
    await tester.pump();
    expect(find.text('Current password is incorrect.'), findsOneWidget);
    expect(AllUsers.userList[0]['password'], 'Student123!');
    await tester.enterText(find.byType(TextField).at(0), 'Student123!');
    await tester.enterText(find.byType(TextField).at(1), 'short');
    await tester.ensureVisible(find.text('CHANGE PASSWORD'));
    await tester.tap(find.text('CHANGE PASSWORD'));
    await tester.pump();
    expect(
      find.text('New password must be at least 8 characters.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).at(1), 'NewPass456!');
    await tester.ensureVisible(find.text('CHANGE PASSWORD'));
    await tester.tap(find.text('CHANGE PASSWORD'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Password changed successfully.'), findsOneWidget);
    expect(AllUsers.userList[0]['password'], 'NewPass456!');
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      isEmpty,
    );
    AllUsers.activeUser = null;
    AllUsers.userList[0]['password'] = 'Student123!';
    AllUsers.savedPasswords = {};
    await AllUsers.loadPasswords();
    final storage = await SharedPreferences.getInstance();
    expect(storage.getString('password_student01'), isNot('NewPass456!'));
    expect(
      AllUsers.matchesPassword(AllUsers.userList[0], 'NewPass456!'),
      isTrue,
    );
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'student01');
    await tester.enterText(find.byType(TextField).at(1), 'Student123!');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Incorrect username or password.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'NewPass456!');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('MENU'), findsOneWidget);
    for (int i = 0; i < 20; i++) {
      await tester.pump();
    }
  });

  testWidgets('Audio sliders update playback volume and retain settings', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.tap(find.text('AUDIO'));
    await tester.pumpAndSettle();
    final musicSlider = tester.widget<Slider>(find.byType(Slider).at(0));
    musicSlider.onChanged!(0);
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    expect(AllUsers.musicVolume, 0);
    expect(
      audioCalls.any(
        (call) => call.method == 'setVolume' && call.arguments['volume'] == 0,
      ),
      isTrue,
    );
    final soundSlider = tester.widget<Slider>(find.byType(Slider).at(1));
    soundSlider.onChanged!(24);
    soundSlider.onChangeEnd!(24);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    expect(AllUsers.sfxVolume, 24);
    expect(find.text('24%'), findsOneWidget);
    expect(
      audioCalls.any(
        (call) =>
            call.method == 'setVolume' &&
            ((call.arguments['volume'] as num) - 0.108).abs() < 0.00001,
      ),
      isTrue,
    );
    await tester.tap(find.text('ACCOUNT'));
    await tester.pump();
    await tester.tap(find.text('AUDIO'));
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider).at(0)).value, 0);
    expect(tester.widget<Slider>(find.byType(Slider).at(1)).value, 24);
  });

  testWidgets('Settings phone previews', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pixel = FontLoader('MenuPixel');
    pixel.addFont(rootBundle.load('assets/images/PixelOperator8-Bold.ttf'));
    await pixel.load();
    final settingsFont = FontLoader('SettingsPixel');
    settingsFont.addFont(rootBundle.load('assets/images/PixelOperator8.ttf'));
    await settingsFont.load();
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    );
    final sdk = Uri.parse(config['flutterRoot'] as String).toFilePath();
    for (final family in ['Roboto', 'MaterialIcons']) {
      final font = FontLoader(family);
      final file = family == 'Roboto'
          ? 'roboto-regular.ttf'
          : 'materialicons-regular.otf';
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('$sdk/bin/cache/artifacts/material_fonts/$file')
                .readAsBytesSync(),
          ),
        ),
      );
      await font.load();
    }
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/menu-background.png'),
        tester.element(find.byType(SettingsPage)),
      );
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/settings-account.png'),
    );
    await tester.tap(find.text('AUDIO'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/settings-audio.png'),
    );
  });
}
