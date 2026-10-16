import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_catalog.dart';
import 'user.dart';

class GameData {
  static const String _storageKey = 'itechs_game_progress_v1';
  static const String _readyStatus = 'Ready';
  static const String _lockedStatus = 'Locked';
  static const String _clearedStatus = 'Cleared';
  static const int _maximumPersistedLevel = 5;

  static int activeGame = 0;
  static List<Map<String, dynamic>> levelRecords = [];
  static Future<bool> _saveQueue = Future<bool>.value(true);
  static Future<bool> _resultQueue = Future<bool>.value(true);

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
    Map<String, dynamic> record = _defaultRecord(
      username: username,
      course: course,
      game: game,
      number: number,
    );
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
      if (record['status'] == _clearedStatus) completed++;
      if (record['status'] == _readyStatus && next == 0) next = i + 1;
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

  static Future<bool> loadProgress() async {
    try {
      final storage = await SharedPreferences.getInstance();
      final savedRecords = _decodeRecords(storage.getString(_storageKey));
      levelRecords = _mergeRecords(savedRecords, levelRecords);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> saveProgress() {
    final operation = _saveQueue.then((_) => _saveProgressNow());
    _saveQueue = operation.then((_) => true, onError: (_) => false);
    return operation;
  }

  static Future<bool> recordLevelResult({
    required int game,
    required int number,
    required int score,
    required int stars,
    required bool completed,
    int unlockStarRequirement = 2,
  }) {
    final operation = _resultQueue.then(
      (_) => _recordLevelResult(
        game: game,
        number: number,
        score: score,
        stars: stars,
        completed: completed,
        unlockStarRequirement: unlockStarRequirement,
      ),
    );
    _resultQueue = operation.then((_) => true, onError: (_) => false);
    return operation;
  }

  static Future<bool> _recordLevelResult({
    required int game,
    required int number,
    required int score,
    required int stars,
    required bool completed,
    required int unlockStarRequirement,
  }) async {
    final identity = _activeIdentity();
    if (identity == null ||
        game < 0 ||
        number < 1 ||
        number > _maximumPersistedLevel) {
      return false;
    }

    final username = identity['username']!;
    final course = identity['course']!;
    final key = _recordKey(username, course, game, number);
    // Build the complete candidate result separately. The shared in-memory
    // list is committed only after SharedPreferences confirms the write.
    final candidateRecords = levelRecords
        .map((record) => Map<String, dynamic>.from(record))
        .toList();
    final existingIndex = candidateRecords.indexWhere(
      (record) => _recordKeyFor(record) == key,
    );
    final now = DateTime.now().toUtc().toIso8601String();
    final current = existingIndex >= 0
        ? _normalizeRecord(candidateRecords[existingIndex])
        : _defaultRecord(
            username: username,
            course: course,
            game: game,
            number: number,
          );

    final safeScore = score < 0 ? 0 : score;
    final safeStars = stars.clamp(0, 3).toInt();
    current['attempts'] = (current['attempts'] as int) + 1;
    current['bestScore'] = maxInt(current['bestScore'] as int, safeScore);
    current['bestStars'] = maxInt(current['bestStars'] as int, safeStars);
    current['lastScore'] = safeScore;
    current['lastStars'] = safeStars;
    current['lastResult'] = completed ? 'COMPLETED' : 'FAILED';
    current['lastAttemptAt'] = now;

    final qualifies = completed && safeStars >= unlockStarRequirement;
    if (qualifies) {
      current['status'] = _clearedStatus;
    } else if (current['status'] != _clearedStatus) {
      current['status'] = current['status'] == _lockedStatus
          ? _lockedStatus
          : _readyStatus;
    }

    if (existingIndex >= 0) {
      candidateRecords[existingIndex] = current;
    } else {
      candidateRecords.add(current);
    }

    if (qualifies) {
      _unlockNextLevel(candidateRecords, username, course, game, number);
    }

    return _saveCandidateProgress(candidateRecords);
  }

  static Future<bool> _saveCandidateProgress(
    List<Map<String, dynamic>> candidateRecords,
  ) {
    final operation = _saveQueue.then(
      (_) => _saveProgressNow(candidateRecords),
    );
    _saveQueue = operation.then((_) => true, onError: (_) => false);
    return operation;
  }

  static Future<bool> _saveProgressNow([
    List<Map<String, dynamic>>? records,
  ]) async {
    if (_activeIdentity() == null) return false;

    final storage = await SharedPreferences.getInstance();
    final storedRecords = _decodeRecords(storage.getString(_storageKey));
    final mergedRecords = _mergeRecords(storedRecords, records ?? levelRecords);
    final payload = jsonEncode({'version': 1, 'records': mergedRecords});
    final saved = await storage.setString(_storageKey, payload);
    if (saved) levelRecords = mergedRecords;
    return saved;
  }

  static List<Map<String, dynamic>> _decodeRecords(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return [];
      final rawRecords = decoded['records'];
      if (rawRecords is! List) return [];

      final validRecords = <Map<String, dynamic>>[];
      for (final value in rawRecords) {
        if (value is Map) {
          final normalized = _normalizeRecord(Map<String, dynamic>.from(value));
          if (_isValidRecord(normalized)) validRecords.add(normalized);
        }
      }
      return _deduplicate(validRecords);
    } catch (_) {
      return [];
    }
  }

  static List<Map<String, dynamic>> _mergeRecords(
    List<Map<String, dynamic>> saved,
    List<Map<String, dynamic>> current,
  ) {
    final merged = <String, Map<String, dynamic>>{};
    for (final record in saved) {
      final normalized = _normalizeRecord(record);
      if (_isValidRecord(normalized)) {
        merged[_recordKeyFor(normalized)] = normalized;
      }
    }
    for (final record in current) {
      final normalized = _normalizeRecord(record);
      if (!_isValidRecord(normalized)) continue;
      final key = _recordKeyFor(normalized);
      final previous = merged[key];
      merged[key] = previous == null
          ? normalized
          : _mergeRecord(previous, normalized);
    }
    return merged.values.toList();
  }

  static List<Map<String, dynamic>> _deduplicate(
    List<Map<String, dynamic>> records,
  ) {
    return _mergeRecords([], records);
  }

  static Map<String, dynamic> _mergeRecord(
    Map<String, dynamic> saved,
    Map<String, dynamic> current,
  ) {
    final merged = Map<String, dynamic>.from(saved);
    merged['status'] = _higherStatus(
      saved['status'] as String,
      current['status'] as String,
    );
    merged['attempts'] = maxInt(
      saved['attempts'] as int,
      current['attempts'] as int,
    );
    merged['bestStars'] = maxInt(
      saved['bestStars'] as int,
      current['bestStars'] as int,
    );
    merged['bestScore'] = maxInt(
      saved['bestScore'] as int,
      current['bestScore'] as int,
    );

    final savedDate = DateTime.tryParse(saved['lastAttemptAt'] as String);
    final currentDate = DateTime.tryParse(current['lastAttemptAt'] as String);
    if (savedDate == null ||
        (currentDate != null && currentDate.isAfter(savedDate))) {
      merged['lastScore'] = current['lastScore'];
      merged['lastStars'] = current['lastStars'];
      merged['lastResult'] = current['lastResult'];
      merged['lastAttemptAt'] = current['lastAttemptAt'];
    }
    return merged;
  }

  static Map<String, dynamic>? _activeIdentity() {
    final user = AllUsers.activeUser;
    final username = user?['username']?.trim();
    if (username == null || username.isEmpty) return null;
    final course = user?['courseCode']?.trim();
    return {
      'username': username,
      'course': course == null || course.isEmpty ? 'FN2LH4CF' : course,
    };
  }

  static Map<String, dynamic> _defaultRecord({
    required String username,
    required String course,
    required int game,
    required int number,
  }) {
    return {
      'username': username,
      'course': course,
      'game': game,
      'number': number,
      'status': number == 1 ? _readyStatus : _lockedStatus,
      'attempts': 0,
      'bestStars': 0,
      'bestScore': 0,
      'lastScore': 0,
      'lastStars': 0,
      'lastResult': null,
      'lastAttemptAt': '',
    };
  }

  static Map<String, dynamic> _normalizeRecord(Map<String, dynamic> value) {
    final result = Map<String, dynamic>.from(value);
    result['username'] = result['username']?.toString() ?? '';
    result['course'] = result['course']?.toString() ?? '';
    result['game'] = _asInt(result['game']);
    result['number'] = _asInt(result['number']);
    result['status'] = _normalizeStatus(result['status']);
    result['attempts'] = maxInt(0, _asInt(result['attempts']));
    result['bestStars'] = _asInt(result['bestStars']).clamp(0, 3).toInt();
    result['bestScore'] = maxInt(0, _asInt(result['bestScore']));
    result['lastScore'] = maxInt(0, _asInt(result['lastScore']));
    result['lastStars'] = _asInt(result['lastStars']).clamp(0, 3).toInt();
    result['lastResult'] = result['lastResult']?.toString();
    result['lastAttemptAt'] = result['lastAttemptAt']?.toString() ?? '';
    return result;
  }

  static bool _isValidRecord(Map<String, dynamic> record) {
    final username = record['username'] as String;
    final course = record['course'] as String;
    final game = record['game'] as int;
    final number = record['number'] as int;
    return username.isNotEmpty &&
        course.isNotEmpty &&
        game >= 0 &&
        number >= 1 &&
        number <= _maximumPersistedLevel &&
        _validStatuses.contains(record['status']);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _normalizeStatus(dynamic value) {
    switch (value?.toString()) {
      case _clearedStatus:
        return _clearedStatus;
      case _readyStatus:
        return _readyStatus;
      default:
        return _lockedStatus;
    }
  }

  static const Set<String> _validStatuses = {
    _readyStatus,
    _lockedStatus,
    _clearedStatus,
  };

  static String _higherStatus(String first, String second) {
    final firstRank = _statusRank(first);
    final secondRank = _statusRank(second);
    return secondRank > firstRank ? second : first;
  }

  static int _statusRank(String status) {
    switch (status) {
      case _clearedStatus:
        return 2;
      case _readyStatus:
        return 1;
      default:
        return 0;
    }
  }

  static String _recordKey(
    String username,
    String course,
    int game,
    int number,
  ) => '$username\u0000$course\u0000$game\u0000$number';

  static String _recordKeyFor(Map<String, dynamic> record) => _recordKey(
    record['username'] as String,
    record['course'] as String,
    record['game'] as int,
    record['number'] as int,
  );

  static void _unlockNextLevel(
    List<Map<String, dynamic>> records,
    String username,
    String course,
    int game,
    int number,
  ) {
    if (number >= _maximumPersistedLevel) return;
    final nextNumber = number + 1;
    final key = _recordKey(username, course, game, nextNumber);
    final index = records.indexWhere(
      (record) => _recordKeyFor(_normalizeRecord(record)) == key,
    );
    if (index < 0) {
      final next = _defaultRecord(
        username: username,
        course: course,
        game: game,
        number: nextNumber,
      );
      next['status'] = _readyStatus;
      records.add(next);
      return;
    }

    final next = _normalizeRecord(records[index]);
    if (next['status'] != _clearedStatus) next['status'] = _readyStatus;
    records[index] = next;
  }

  static int maxInt(int first, int second) => first > second ? first : second;
}
