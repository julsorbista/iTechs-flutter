import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glob/class_data.dart';
import 'glob/lesson_data.dart';
import 'glob/audio.dart';
import 'student_ui.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => ProgressPageState();
}

class ProgressPageState extends State<ProgressPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Widget metric(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF687F9C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget overallCard(Map<String, dynamic> summary, [double minimumHeight = 0]) {
    return Container(
      constraints: BoxConstraints(minHeight: minimumHeight),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Progress',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF687F9C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                '${summary['overallProgress']}%',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF008663),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "You've completed ${summary['completedModules']} of ${summary['totalModules']} modules.",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF425675),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: summary['overallProgress'] / 100,
                      minHeight: 16,
                      color: const Color(0xFF00BC8B),
                      backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget metrics(Map<String, dynamic> summary) {
    int seconds = summary['learningSeconds'];
    String time = seconds >= 60 ? '${seconds ~/ 60}m' : '${seconds}s';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: metric(
                'Time Spent Learning',
                time,
                const Color(0xFF0076A8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: metric(
                'Quiz Performance',
                '${summary['quizPerformance']}%',
                const Color(0xFF7500ED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: metric(
                'XP Earned',
                '${summary['xpEarned']}',
                const Color(0xFFBB4E00),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: metric(
                'Coins Earned',
                '${summary['coinsEarned']}',
                const Color(0xFFBB4E00),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget tableRow(
    String title,
    String status,
    int percent,
    String score,
    bool header,
  ) {
    Color barColor = status == 'Completed'
        ? const Color(0xFF00BC8B)
        : status == 'In Progress'
        ? const Color(0xFFF6C741)
        : const Color(0xFFCBD5E1);
    return Container(
      margin: EdgeInsets.only(top: header ? 0 : 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: header ? const Color(0xFF383E43) : const Color(0xFF724964),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: header ? const Color(0xFFF5D64D) : const Color(0xFFF5E9CC),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (!header)
                    const Text(
                      'MODULE · ICT-1A',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: Color(0xFFD4C4CC),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(flex: 3, child: Text(status)),
            Expanded(
              flex: 3,
              child: header
                  ? const Text('Progress')
                  : Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(8),
                            color: barColor,
                            backgroundColor: const Color(0xFFF1F5F9),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(width: 54, child: Text('$percent%')),
                      ],
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: Text(score)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    if (screen.width < screen.height) {
      return RotatedBox(
        quarterTurns: 1,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: Size(screen.height, screen.width),
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
          ),
          child: Builder(builder: (context) => buildProgress(context)),
        ),
      );
    }
    return buildProgress(context);
  }

  Widget buildProgress(BuildContext context) {
    Map<String, dynamic> summary = ClassData.progressSummary();
    List<Widget> rows = [];
    rows.add(tableRow('Module', 'Status', 0, 'Score', true));
    for (int i = 0; i < LessonData.modules.length; i++) {
      int percent = ClassData.percent(i);
      String status = !ClassData.unlocked(i)
          ? 'Locked'
          : percent == 100
          ? 'Completed'
          : percent > 0
          ? 'In Progress'
          : 'Not Started';
      rows.add(
        KeyedSubtree(
          key: ValueKey('module-progress-$i'),
          child: tableRow(
            LessonData.modules[i]['title'].toString().toUpperCase(),
            status,
            percent,
            ClassData.progress(i)['latestScore'] == null
                ? '--'
                : '${ClassData.progress(i)['latestScore']}',
            false,
          ),
        ),
      );
    }
    bool wide = MediaQuery.of(context).size.width >= 760;
    double tableWidth = MediaQuery.of(context).size.width - 80;
    if (tableWidth < 850) tableWidth = 850;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: studentBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                studentButton('BACK TO MENU', () {
                  AppAudio.click();
                  Navigator.pop(context);
                }, const Color(0xFF172134)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: studentPanel(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Tracker',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2A1C23),
                        ),
                      ),
                      const Text(
                        'My Progress',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2A1C23),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE1E8F1)),
                        ),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: overallCard(summary, 238),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(flex: 6, child: metrics(summary)),
                                ],
                              )
                            : Column(
                                children: [
                                  overallCard(summary),
                                  const SizedBox(height: 12),
                                  metrics(summary),
                                ],
                              ),
                      ),
                      const SizedBox(height: 30),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: Column(children: rows),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
