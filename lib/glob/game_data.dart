import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user.dart';
import 'game_catalog.dart';

class GameData {
  static int activeGame = 0;
  static List<Map<String, dynamic>> levelRecords = [];
  static List<Map<String, dynamic>> history = [];
  static Map<String, int> wallets = {};
  static const playable = {0, 2, 4};
  static String get owner =>
      '${AllUsers.activeUser!['username']}:${AllUsers.activeUser!['courseCode'] ?? 'FN2LH4CF'}';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('itechs.games.v1');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      levelRecords = (data['levels'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      history = (data['history'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      wallets = Map<String, int>.from(data['wallets']);
    } on FormatException {
      // Keep the demo usable if browser storage contains invalid JSON.
    } on TypeError {
      // Older or incomplete local records can be reset from level selection.
    }
  }

  static Future<void> save() async {
    final snapshot = jsonEncode({
      'levels': levelRecords,
      'history': history,
      'wallets': wallets,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('itechs.games.v1', snapshot);
  }

  static int get coins => wallets[owner] ?? 0;
  static Future<void> addCoins(int amount) {
    wallets[owner] = coins + amount;
    return save();
  }

  static Future<void> start(int game, int number) async {
    final record = level(game, number);
    if (!playable.contains(game) || record['status'] == 'Locked') {
      throw StateError('This level is locked.');
    }
    record['attempts'] = (record['attempts'] as int) + 1;
    await save();
  }

  static Future<void> finish(
    int game,
    int number, {
    required bool cleared,
    required int stars,
    required int score,
    required String detail,
    int mistakes = 0,
  }) async {
    final record = level(game, number);
    record['bestStars'] = stars > record['bestStars']
        ? stars
        : record['bestStars'];
    record['bestScore'] = score > (record['bestScore'] ?? 0)
        ? score
        : record['bestScore'] ?? 0;
    if (cleared && stars >= 2) {
      record['status'] = 'Cleared';
      if (number < (GameCatalog.games[game]['levels'] as List).length) {
        final next = level(game, number + 1);
        if (next['status'] == 'Locked') next['status'] = 'Ready';
      }
    }
    history.add({
      ...record,
      'stars': stars,
      'score': score,
      'cleared': cleared,
      'detail': detail,
      'mistakes': mistakes,
      'date': DateTime.now().toIso8601String(),
    });
    await save();
  }

  static Future<void> reset(int game) async {
    final username = AllUsers.activeUser!['username'];
    final course = AllUsers.activeUser!['courseCode'] ?? 'FN2LH4CF';
    bool belongs(Map<String, dynamic> r) =>
        r['username'] == username && r['course'] == course && r['game'] == game;
    levelRecords.removeWhere(belongs);
    history.removeWhere(belongs);
    await save();
  }

  static Map<String, dynamic> level(int game, int number) {
    String username = AllUsers.activeUser!['username']!;
    String course = AllUsers.activeUser!['courseCode'] ?? 'FN2LH4CF';
    for (int i = 0; i < levelRecords.length; i++) {
      Map<String, dynamic> record = levelRecords[i];
      if (record['username'] == username &&
          record['course'] == course &&
          record['game'] == game &&
          record['number'] == number) {
        return record;
      }
    }
    Map<String, dynamic> record = {
      'username': username,
      'course': course,
      'game': game,
      'number': number,
      'status': number == 1 ? 'Ready' : 'Locked',
      'attempts': 0,
      'bestStars': 0,
    };
    levelRecords.add(record);
    return record;
  }

  static Map<String, int> summary(int game) {
    List<dynamic> levels = GameCatalog.games[game]['levels'];
    int completed = 0;
    int stars = 0;
    int next = 0;
    for (int i = 0; i < levels.length; i++) {
      Map<String, dynamic> record = level(game, i + 1);
      if (record['status'] == 'Cleared') completed++;
      if (record['status'] == 'Ready' && next == 0) next = i + 1;
      stars += record['bestStars'] as int;
    }
    return {
      'percent': levels.isEmpty ? 0 : (completed / levels.length * 100).round(),
      'completed': completed,
      'stars': stars,
      'levels': levels.length,
      'next': next,
    };
  }
}
