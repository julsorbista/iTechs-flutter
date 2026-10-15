import 'user.dart';
import 'lesson_data.dart';

class ClassData {
  static int activeModule = 0;
  static Map<String, dynamic>? lastResult;
  static List<Map<String, dynamic>> progressList = [];
  static List<Map<String, dynamic>> quizAttempts = [];
  static List<Map<String, String>> courses = [
    {'code': 'FN2LH4CF', 'teacher': 'Julia Orbista'},
    {'code': 'JAVA2026', 'teacher': 'Java Demo Class'},
  ];

  static Map<String, dynamic> progress(int module) {
    String username = AllUsers.activeUser!['username']!;
    String course = AllUsers.activeUser!['courseCode'] ?? 'FN2LH4CF';
    for (int i = 0; i < progressList.length; i++) {
      if (progressList[i]['username'] == username &&
          progressList[i]['course'] == course &&
          progressList[i]['module'] == module) {
        return progressList[i];
      }
    }
    Map<String, dynamic> record = {
      'username': username,
      'course': course,
      'module': module,
      'viewedPages': <int>[],
      'currentPage': 0,
      'latestScore': null,
      'quizStars': 0,
      'passed': false,
      'readingMilliseconds': 0,
      'xpEarned': 0,
      'coinsEarned': 0,
    };
    progressList.add(record);
    return record;
  }

  static void viewPage(int module, int page) {
    Map<String, dynamic> record = progress(module);
    List<int> viewed = record['viewedPages'];
    if (!viewed.contains(page)) viewed.add(page);
    record['currentPage'] = page;
  }

  static int percent(int module) {
    List<int> viewed = progress(module)['viewedPages'];
    List<dynamic> pages = LessonData.modules[module]['pages'];
    return (viewed.length / pages.length * 100).round();
  }

  static bool unlocked(int module) {
    return module == 0 || progress(module - 1)['passed'] == true;
  }

  static Map<String, dynamic> progressSummary() {
    int totalProgress = 0;
    int completed = 0;
    int scoreTotal = 0;
    int quizCount = 0;
    int milliseconds = 0;
    int xp = 0;
    int coins = 0;
    for (int i = 0; i < LessonData.modules.length; i++) {
      Map<String, dynamic> record = progress(i);
      int percentage = percent(i);
      totalProgress += percentage;
      if (percentage == 100) completed++;
      if (record['latestScore'] != null) {
        scoreTotal += record['latestScore'] as int;
        quizCount++;
      }
      milliseconds += (record['readingMilliseconds'] ?? 0) as int;
      xp += (record['xpEarned'] ?? 0) as int;
      coins += (record['coinsEarned'] ?? 0) as int;
    }
    return {
      'overallProgress': LessonData.modules.isEmpty
          ? 0
          : (totalProgress / LessonData.modules.length).round(),
      'completedModules': completed,
      'totalModules': LessonData.modules.length,
      'quizPerformance': quizCount == 0 ? 0 : (scoreTotal / quizCount).round(),
      'learningSeconds': milliseconds ~/ 1000,
      'xpEarned': xp,
      'coinsEarned': coins,
    };
  }

  static Map<String, dynamic> draft(int module) {
    Map<String, dynamic> record = progress(module);
    if (record['draft'] == null) {
      List<int> answers = [];
      List<dynamic> questions = LessonData.modules[module]['questions'];
      for (int i = 0; i < questions.length; i++) {
        answers.add(-1);
      }
      record['draft'] = {
        'answers': answers,
        'questionIndex': 0,
        'remainingSeconds': LessonData.modules[module]['timeLimit'],
      };
    }
    return record['draft'];
  }

  static Map<String, dynamic> submitQuiz(int module) {
    Map<String, dynamic> currentDraft = draft(module);
    List<int> answers = currentDraft['answers'];
    List<dynamic> questions = LessonData.modules[module]['questions'];
    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i]['answer']) correct++;
    }
    int percentage = (correct / questions.length * 100).round();
    int stars = 0;
    if (percentage >= 85) {
      stars = 3;
    } else if (percentage >= 70) {
      stars = 2;
    } else if (percentage >= 50) {
      stars = 1;
    }
    bool passed = percentage >= LessonData.modules[module]['passingScore'];
    Map<String, dynamic> result = {
      'attempt': quizAttempts.length + 1,
      'username': AllUsers.activeUser!['username'],
      'course': AllUsers.activeUser!['courseCode'] ?? 'FN2LH4CF',
      'module': module,
      'correct': correct,
      'total': questions.length,
      'percentage': percentage,
      'stars': stars,
      'passed': passed,
      'seconds':
          LessonData.modules[module]['timeLimit'] -
          currentDraft['remainingSeconds'],
      'answers': List<int>.from(answers),
    };
    quizAttempts.add(result);
    Map<String, dynamic> record = progress(module);
    record['latestScore'] = percentage;
    record['quizStars'] = stars;
    record['passed'] = passed;
    record.remove('draft');
    lastResult = result;
    return result;
  }

  static List<Map<String, dynamic>> leaderboardRecords() {
    List<Map<String, dynamic>> records = [];
    String course = AllUsers.activeUser?['courseCode'] ?? 'FN2LH4CF';
    for (int i = 0; i < AllUsers.leaderboardList.length; i++) {
      Map<String, dynamic> row = Map<String, dynamic>.from(
        AllUsers.leaderboardList[i],
      );
      String username = row['username'] ?? '';
      for (int j = 0; j < AllUsers.userList.length; j++) {
        if (username == AllUsers.userList[j]['username']) {
          row['studentName'] =
              '${AllUsers.userList[j]['firstName']} ${AllUsers.userList[j]['lastName']}';
        }
      }
      for (int j = 0; j < progressList.length; j++) {
        Map<String, dynamic> record = progressList[j];
        if (record['username'] == username && record['course'] == course) {
          row['totalStars'] = row['totalStars'] + record['quizStars'];
          if (record['viewedPages'].length ==
              LessonData.modules[record['module']]['pages'].length) {
            row['completedActivities'] = row['completedActivities'] + 1;
          }
          if (record['passed']) {
            row['completedActivities'] = row['completedActivities'] + 1;
          }
        }
      }
      records.add(row);
    }
    return records;
  }
}
