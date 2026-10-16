import 'package:flutter/material.dart';

import 'login.dart';
import 'home.dart';
import 'glob/user.dart';
import 'glob/game_data.dart';
import 'games/game_content.dart';
import 'settings.dart';
import 'profile.dart';
import 'leaderboard.dart';
import 'my_class.dart';
import 'module.dart';
import 'quiz.dart';
import 'result.dart';
import 'progress.dart';
import 'play.dart';
import 'levels.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AllUsers.loadPasswords();
  await GameData.load();
  await GameContent.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iTECHS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF3F5FA),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/play': (context) =>
            AllUsers.activeUser == null ? const LoginPage() : const PlayPage(),
        '/levels': (context) => AllUsers.activeUser == null
            ? const LoginPage()
            : const LevelsPage(),
        '/progress': (context) => AllUsers.activeUser == null
            ? const LoginPage()
            : const ProgressPage(),
        '/class': (context) => AllUsers.activeUser == null
            ? const LoginPage()
            : const MyClassPage(),
        '/module': (context) => AllUsers.activeUser == null
            ? const LoginPage()
            : const ModulePage(),
        '/quiz': (context) =>
            AllUsers.activeUser == null ? const LoginPage() : const QuizPage(),
        '/result': (context) => AllUsers.activeUser == null
            ? const LoginPage()
            : const ResultPage(),
        '/leaderboard': (context) => AllUsers.activeUser == null
            ? const LoginPage()
            : const LeaderboardPage(),
        '/profile': (context) => AllUsers.activeUser == null
            ? const LoginPage()
            : const ProfilePage(),
        '/settings': (context) => AllUsers.activeUser == null
            ? const LoginPage()
            : const SettingsPage(),
        '/home': (context) =>
            AllUsers.activeUser == null ? const LoginPage() : const HomePage(),
      },
    );
  }
}
