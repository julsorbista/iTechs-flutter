import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllUsers {
  static Map<String, String> savedPasswords = {};

  static String passwordHash(String username, String password) {
    return sha256.convert(utf8.encode('$username:$password')).toString();
  }

  static Future<void> loadPasswords() async {
    final storage = await SharedPreferences.getInstance();
    savedPasswords = {};
    for (final user in userList) {
      final saved = storage.getString('password_${user['username']}');
      if (saved != null) savedPasswords[user['username']!] = saved;
    }
  }

  static bool matchesPassword(Map<String, String> user, String password) {
    final saved = savedPasswords[user['username']];
    if (saved != null) {
      return saved == passwordHash(user['username']!, password);
    }
    return user['password'] == password;
  }

  static Future<void> updatePassword(
    Map<String, String> user,
    String password,
  ) async {
    final username = user['username']!;
    final hash = passwordHash(username, password);
    final storage = await SharedPreferences.getInstance();
    final saved = await storage.setString('password_$username', hash);
    if (!saved) throw Exception('Password could not be saved.');
    savedPasswords[username] = hash;
    user['password'] = password;
  }

  static List<Map<String, String>> userList = [
    {
      'username': 'student01',
      'password': 'Student123!',
      'firstName': 'Juan',
      'lastName': 'Dela Cruz',
      'section': 'INF231',
      'avatar': 'girl-avatar-3',
      'courseCode': 'FN2LH4CF',
    },
  ];

  static Map<String, String>? activeUser;
  static double musicVolume = 55;
  static double sfxVolume = 55;
  static List<Map<String, dynamic>> leaderboardList = [
    {
      'username': 'student01',
      'studentName': 'Juls Orbista',
      'totalStars': 0,
      'completedActivities': 0,
    },
    {'studentName': 'Aly Parrilla', 'totalStars': 61, 'completedActivities': 3},
    {
      'studentName': 'Khatleya Tacda',
      'totalStars': 28,
      'completedActivities': 2,
    },
    {'studentName': 'Peejay Yatco', 'totalStars': 3, 'completedActivities': 1},
    {
      'studentName': 'James Magnifico',
      'totalStars': 0,
      'completedActivities': 0,
    },
  ];
}
