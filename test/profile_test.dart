import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itechs/glob/user.dart';
import 'package:itechs/home.dart';
import 'package:itechs/profile.dart';

import 'audio_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockAudio();
    AllUsers.userList[0]['avatar'] = 'girl-avatar-3';
    AllUsers.activeUser = AllUsers.userList[0];
  });
  tearDown(() {
    AllUsers.userList[0]['avatar'] = 'girl-avatar-3';
    AllUsers.activeUser = null;
  });

  testWidgets(
    'Preview is separate from saved avatar and Customize updates menu',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomePage(),
          routes: {'/profile': (context) => const ProfilePage()},
        ),
      );
      await tester.tap(find.text('PROFILE EDITOR'));
      await tester.pumpAndSettle();
      expect(find.text('SAVED AVATAR'), findsOneWidget);
      await tester.ensureVisible(find.text('Boy'));
      await tester.tap(find.text('Boy'));
      await tester.pumpAndSettle();
      expect(find.text('Boy Avatar 4'), findsOneWidget);
      expect(find.text('Girl Avatar 1'), findsNothing);
      await tester.ensureVisible(find.text('Boy Avatar 2'));
      await tester.tap(find.text('Boy Avatar 2'));
      await tester.pump();
      expect(find.text('PREVIEW'), findsOneWidget);
      expect(AllUsers.activeUser?['avatar'], 'girl-avatar-3');
      await tester.ensureVisible(find.text('BACK TO MENU'));
      await tester.tap(find.text('BACK TO MENU'));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName,
        'assets/images/girl-avatar-3.png',
      );
      await tester.tap(find.text('PROFILE EDITOR'));
      await tester.pumpAndSettle();
      expect(find.text('SAVED AVATAR'), findsOneWidget);
      await tester.ensureVisible(find.text('Boy'));
      await tester.tap(find.text('Boy'));
      await tester.pump();
      await tester.ensureVisible(find.text('Boy Avatar 4'));
      await tester.tap(find.text('Boy Avatar 4'));
      await tester.pump();
      await tester.ensureVisible(find.text('CUSTOMIZE'));
      await tester.tap(find.text('CUSTOMIZE'));
      await tester.pump();
      expect(AllUsers.userList[0]['avatar'], 'boy-avatar-4');
      expect(find.text('SAVED AVATAR'), findsOneWidget);
      await tester.ensureVisible(find.text('BACK TO MENU'));
      await tester.tap(find.text('BACK TO MENU'));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName,
        'assets/images/boy-avatar-4.png',
      );
      await tester.tap(find.text('PROFILE EDITOR'));
      await tester.pumpAndSettle();
      expect(find.text('SAVED AVATAR'), findsOneWidget);
      expect(find.text('Boy Avatar 4'), findsNWidgets(2));
    },
  );

  testWidgets('Profile Editor phone previews', (tester) async {
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
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(ProfilePage));
      await precacheImage(
        const AssetImage('assets/images/menu-background.png'),
        context,
      );
      for (final category in ['girl', 'boy']) {
        for (int i = 1; i <= 4; i++) {
          await precacheImage(
            AssetImage('assets/images/$category-avatar-$i.png'),
            context,
          );
        }
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/profile-editor.png'),
    );
    await tester.ensureVisible(find.text('Boy'));
    await tester.tap(find.text('Boy'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose a Character'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/profile-characters.png'),
    );
  });
}
