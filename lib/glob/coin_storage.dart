import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user.dart';

class CoinOperationResult {
  const CoinOperationResult({
    required this.success,
    required this.balance,
    this.message,
  });

  final bool success;
  final int balance;
  final String? message;
}

class GameCoinStorage {
  static const String _storageKey = 'itechs_shared_user_coins_v1';
  static Future<void> _operationQueue = Future<void>.value();

  static String? activeUserKey() {
    final user = AllUsers.activeUser;
    final username = user?['username']?.trim();
    if (username == null || username.isEmpty) return null;
    final course = user?['courseCode']?.trim();
    return '$username:${course == null || course.isEmpty ? 'FN2LH4CF' : course}';
  }

  static Future<CoinOperationResult> load() {
    return _enqueue(() async {
      final key = activeUserKey();
      if (key == null) {
        return const CoinOperationResult(
          success: false,
          balance: 0,
          message: 'No active user is available for coin storage.',
        );
      }
      try {
        final preferences = await SharedPreferences.getInstance();
        final balances = _decode(preferences.getString(_storageKey));
        return CoinOperationResult(success: true, balance: balances[key] ?? 0);
      } catch (error) {
        return CoinOperationResult(
          success: false,
          balance: 0,
          message: 'Coin balance could not be loaded: $error',
        );
      }
    });
  }

  static Future<CoinOperationResult> add(int amount) {
    final safeAmount = amount < 0 ? 0 : amount;
    return _enqueue(() => _changeBalance(safeAmount));
  }

  static Future<CoinOperationResult> spend(int amount) {
    final safeAmount = amount < 0 ? 0 : amount;
    return _enqueue(() => _changeBalance(-safeAmount));
  }

  static Future<CoinOperationResult> _changeBalance(int delta) async {
    final key = activeUserKey();
    if (key == null) {
      return const CoinOperationResult(
        success: false,
        balance: 0,
        message: 'No active user is available for coin storage.',
      );
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      final balances = _decode(preferences.getString(_storageKey));
      final current = _safeBalance(balances[key]);
      if (delta < 0 && current < -delta) {
        return CoinOperationResult(
          success: false,
          balance: current,
          message: 'Insufficient coins.',
        );
      }
      final next = _safeBalance(current + delta);
      balances[key] = next;
      final saved = await preferences.setString(
        _storageKey,
        jsonEncode(balances),
      );
      if (!saved) {
        return CoinOperationResult(
          success: false,
          balance: current,
          message: 'Coin balance could not be saved.',
        );
      }
      return CoinOperationResult(success: true, balance: next);
    } catch (error) {
      return CoinOperationResult(
        success: false,
        balance: 0,
        message: 'Coin balance could not be saved: $error',
      );
    }
  }

  static Future<CoinOperationResult> _enqueue(
    Future<CoinOperationResult> Function() operation,
  ) {
    final result = _operationQueue.then((_) => operation());
    _operationQueue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  static Map<String, int> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final balances = <String, int>{};
      for (final entry in decoded.entries) {
        if (entry.key is String) {
          balances[entry.key as String] = _safeBalance(entry.value);
        }
      }
      return balances;
    } catch (_) {
      return {};
    }
  }

  static int _safeBalance(dynamic value) {
    final number = value is num ? value.round() : int.tryParse('$value') ?? 0;
    return number < 0 ? 0 : number;
  }
}
