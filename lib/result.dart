import 'package:flutter/material.dart';

import 'glob/class_data.dart';
import 'glob/lesson_data.dart';
import 'student_ui.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  Widget resultRow(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> result = ClassData.lastResult!;
    int module = result['module'];
    int seconds = result['seconds'];
    bool passed = result['passed'];
    List<Widget> stars = [];
    for (int i = 0; i < 3; i++) {
      stars.add(
        Icon(
          i < result['stars'] ? Icons.star : Icons.star_border,
          size: 18,
          color: const Color(0xFF3A2921),
        ),
      );
    }
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: studentBackground(),
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FB),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFF4BB),
                            border: Border.all(
                              color: const Color(0xFFE3A10C),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            passed
                                ? Icons.emoji_events_outlined
                                : Icons.refresh,
                            color: const Color(0xFFD98F00),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        passed ? 'PASSED' : 'FAILED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: passed
                              ? const Color(0xFF18A16E)
                              : const Color(0xFFB45339),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        passed
                            ? 'Great job! You passed the quiz.'
                            : 'Keep learning and try the quiz again.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            resultRow(
                              'Final Score',
                              '${result['percentage']} / 100',
                            ),
                            resultRow('Percentage', '${result['percentage']}%'),
                            resultRow(
                              'Passing Score',
                              '${LessonData.modules[module]['passingScore']}%',
                            ),
                            resultRow(
                              'Time Taken',
                              '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            resultRow(
                              'Quiz Score',
                              '${result['correct']} / ${result['total']}',
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Stars',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Row(children: stars),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (passed && module + 1 < LessonData.modules.length)
                        lessonButton('Continue to Next Module  ›', () {
                          ClassData.activeModule = module + 1;
                          Navigator.pushReplacementNamed(context, '/module');
                        }),
                      const SizedBox(height: 12),
                      if (!passed)
                        lessonButton('Retake Quiz', () {
                          ClassData.activeModule = module;
                          ClassData.progress(module).remove('draft');
                          Navigator.pushReplacementNamed(context, '/quiz');
                        }),
                      const SizedBox(height: 12),
                      lessonButton(
                        passed ? 'Back to Materials' : 'Back to Module',
                        () {
                          if (passed) {
                            Navigator.popUntil(
                              context,
                              ModalRoute.withName('/class'),
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
