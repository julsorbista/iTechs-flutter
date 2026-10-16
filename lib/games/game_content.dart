import 'dart:convert';

import 'package:flutter/services.dart';

import '../glob/game_catalog.dart';

class GameContent {
  static Map<String, dynamic>? _data;
  static Future<void> load() async {
    if (_data != null) return;
    _data = jsonDecode(await rootBundle.loadString('assets/games/levels.json'));
    for (final game in [0, 2, 4]) {
      final levels = _data![{0: 'one', 2: 'three', 4: 'five'}[game]] as List;
      GameCatalog.games[game]['levels'] = levels
          .map(
            (l) => {
              'number': l['levelNumber'],
              'title': l['title'],
              'description':
                  l['objective'] ?? l['missionText'] ?? l['subtitle'],
            },
          )
          .toList();
    }
    GameCatalog.games[4].addAll({
      'title': 'Code Robot',
      'shortTitle': 'Code Robot',
      'description':
          'Guess programming words from clues before the robot shuts down.',
      'guidelines': [
        'Read the clue and tap letters, or use your keyboard, to reveal the word.',
        'Wrong guesses remove lives. Complete every word before time or lives run out.',
        'Each solved word earns coins. Spend 1 coin to reveal a letter.',
      ],
    });
    GameCatalog.games[2]['guidelines'] = [
      'Memorize the revealed cards before the preview ends.',
      'Flip two cards at a time to find identical programming concepts.',
      'Each comparison uses one attempt. You have as many attempts as cards.',
      'Each match earns 100 points. Match at least 75% to clear and unlock the next level.',
    ];
  }

  static Map<String, dynamic> level(int game, int number) =>
      _data![{0: 'one', 2: 'three', 4: 'five'}[game]][number - 1];
}

class GameOutcome {
  final bool cleared;
  final int stars, score;
  final String detail;
  const GameOutcome(this.cleared, this.stars, this.score, this.detail);
}

typedef FinishGame = void Function(GameOutcome result);
