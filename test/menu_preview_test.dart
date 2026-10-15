import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itechs/glob/user.dart';
import 'package:itechs/home.dart';

import 'audio_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(mockAudio);
  testWidgets('Menu matches the single column mobile reference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('MenuPixel');
    font.addFont(rootBundle.load('assets/images/PixelOperator8-Bold.ttf'));
    await font.load();
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    );
    final sdk = Uri.parse(config['flutterRoot'] as String).toFilePath();
    for (final family in ['Roboto', 'MaterialIcons']) {
      final loader = FontLoader(family);
      final filename = family == 'Roboto'
          ? 'roboto-regular.ttf'
          : 'materialicons-regular.otf';
      loader.addFont(
        Future.value(
          ByteData.sublistView(
            File('$sdk/bin/cache/artifacts/material_fonts/$filename')
                .readAsBytesSync(),
          ),
        ),
      );
      await loader.load();
    }
    AllUsers.activeUser = AllUsers.userList[0];
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(HomePage));
      await precacheImage(
        const AssetImage('assets/images/girl-avatar-3.png'),
        context,
      );
      await precacheImage(
        const AssetImage('assets/images/menu-background.png'),
        context,
      );
    });
    await tester.pumpAndSettle();
    final play = tester.getRect(find.text('PLAY'));
    final myClass = tester.getRect(find.text('MY CLASS'));
    expect(myClass.top, greaterThan(play.bottom));
    expect(myClass.center.dx, play.center.dx);
    final avatar = tester.widgetList<Image>(find.byType(Image)).single;
    expect(
      (avatar.image as AssetImage).assetName,
      'assets/images/girl-avatar-3.png',
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('previews/student-menu.png'),
    );
    AllUsers.activeUser = null;
  });
}
