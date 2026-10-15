import 'user.dart';
import 'game_catalog.dart';

class GameData {
  static int activeGame = 0;
  static List<Map<String, dynamic>> levelRecords = [];

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
