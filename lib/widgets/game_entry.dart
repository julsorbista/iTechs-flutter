import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../glob/game_data.dart';

class GameIntro {
  static String _key(int game) => 'game_intro_v1:${GameData.owner}:$game';
  static Future<bool> needed(int game) async =>
      !((await SharedPreferences.getInstance()).getBool(_key(game)) ?? false);
  static Future<void> complete(int game) async {
    await (await SharedPreferences.getInstance()).setBool(_key(game), true);
  }
}

/// Keep the game unmounted until its first-play state is available.
class GameEntry extends StatefulWidget {
  const GameEntry({
    super.key,
    required this.game,
    required this.level,
    required this.builder,
  });
  final int game, level;
  final Widget Function(bool firstPlay) builder;
  @override
  State<GameEntry> createState() => _GameEntryState();
}

class _GameEntryState extends State<GameEntry> {
  late final Future<bool> ready = _load();
  Future<bool> _load() async {
    final needed = await GameIntro.needed(widget.game);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return widget.level == 1 && needed;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: ready,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Scaffold(
          body: Center(
            child: Text(
              'Could not load game preferences. Please reopen the level.',
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(
          backgroundColor: Color(0xFF111827),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading game...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      }
      return widget.builder(snapshot.data!);
    },
  );
}
