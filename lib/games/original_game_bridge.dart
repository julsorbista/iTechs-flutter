import 'dart:math';

import '../glob/game_data.dart';
import 'game_content.dart';

class OriginalGameBridge {
  final int game;
  final String owner = GameData.owner;
  final sessions = <String, Map<String, dynamic>>{};
  OriginalGameBridge(this.game);
  static const types = {0: 'GAME_ONE', 2: 'GAME_THREE', 4: 'GAME_FIVE'};

  Future<Map<String, dynamic>> handle(Map<String, dynamic> message) async {
    if (owner != GameData.owner) {
      throw StateError('The active student or course changed.');
    }
    if (message['type'] == 'coins') {
      final balance = (message['balance'] as num).round().clamp(0, 999999);
      await GameData.addCoins(balance - GameData.coins);
      return {};
    }
    final number = (message['number'] as num?)?.toInt() ?? 0;
    final maximum = game == 2 ? 10 : 5;
    if (message['game'] != types[game] || number < 1 || number > maximum) {
      throw StateError('Invalid game or level.');
    }
    if (message['type'] == 'start') {
      await GameData.start(game, number);
      final attempt = GameData.level(game, number)['attempts'] as int;
      final id =
          '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 30)}';
      int retryAttempt = attempt;
      if (game == 0) {
        retryAttempt = 1;
        final record = GameData.level(game, number);
        for (final previous in GameData.history.reversed) {
          if (previous['username'] != record['username'] ||
              previous['course'] != record['course'] ||
              previous['game'] != game ||
              previous['number'] != number) {
            continue;
          }
          if (previous['cleared'] == true) break;
          if ((previous['mistakes'] ?? 0) >= 6) retryAttempt++;
        }
      }
      final multiplier = max(.5, 1 - (retryAttempt - 1) * .1);
      sessions[id] = {'number': number, 'multiplier': multiplier};
      return {
        'sessionId': id,
        'attemptNumber': attempt,
        'retryMultiplier': multiplier,
        'isFirstGamePlay': attempt == 1,
      };
    }
    if (message['type'] != 'finish') {
      throw StateError('Unknown game operation.');
    }
    final session = sessions[message['session']];
    if (session == null || session['number'] != number) {
      throw StateError('Unknown local game session.');
    }
    if (session['result'] != null) {
      return Map<String, dynamic>.from(session['result']);
    }
    if (session['completion'] != null) return await session['completion'];
    final payload = Map<String, dynamic>.from(message['payload']);
    final completion = finishSession(session, payload, number);
    session['completion'] = completion;
    return completion;
  }

  Future<Map<String, dynamic>> finishSession(
    Map<String, dynamic> session,
    Map<String, dynamic> payload,
    int number,
  ) async {
    final maximum = game == 2 ? 10 : 5;
    final mistakes = (payload['mistakes'] as num? ?? 0).toInt();
    final stars =
        (game == 0
                ? 3 - max(0, mistakes - 3)
                : (payload['starsEarned'] as num? ?? 0).toInt())
            .clamp(0, 3)
            .toInt();
    final cleared = payload['outcome'] == 'COMPLETED' && stars >= 2;
    final score = cleared
        ? ((payload['baseScore'] as num? ?? 0) *
                  (session['multiplier'] as double))
              .round()
        : 0;
    await GameData.finish(
      game,
      number,
      cleared: cleared,
      stars: stars,
      score: score,
      detail:
          '${GameContent.level(game, number)['title']} · $mistakes mistakes',
      mistakes: mistakes,
    );
    final result = <String, dynamic>{
      'result': cleared ? 'COMPLETED' : 'FAILED',
      'starsEarned': stars,
      'starsRemaining': stars,
      'finalScore': score,
      'baseScore': payload['baseScore'] ?? 0,
      'unlockedNextLevel': cleared && number < maximum,
      'gameType': types[game],
      'levelNumber': number,
      'retryMultiplier': session['multiplier'],
    };
    session['result'] = result;
    return result;
  }
}
