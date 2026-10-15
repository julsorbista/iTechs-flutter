import 'dart:async';

import 'package:flutter/material.dart';

import 'glob/class_data.dart';
import 'glob/lesson_data.dart';
import 'glob/audio.dart';
import 'student_ui.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  int module = 0;
  String message = '';
  bool submitted = false;
  Timer? timer;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    module = ClassData.activeModule;
    ClassData.draft(module);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      Map<String, dynamic> draft = ClassData.draft(module);
      if (draft['remainingSeconds'] > 0) {
        setState(() {
          draft['remainingSeconds'] = draft['remainingSeconds'] - 1;
        });
      }
      if (draft['remainingSeconds'] == 0) submit(true);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    scrollController.dispose();
    super.dispose();
  }

  void submit(bool timedOut) {
    if (submitted) return;
    List<int> answers = ClassData.draft(module)['answers'];
    if (!timedOut) {
      for (int i = 0; i < answers.length; i++) {
        if (answers[i] == -1) {
          setState(() {
            ClassData.draft(module)['questionIndex'] = i;
            message = 'Answer all questions before submitting.';
          });
          return;
        }
      }
    }
    submitted = true;
    timer?.cancel();
    ClassData.submitQuiz(module);
    Navigator.pushReplacementNamed(context, '/result');
  }

  void changeQuestion(int index) {
    AppAudio.click();
    setState(() {
      ClassData.draft(module)['questionIndex'] = index;
      message = '';
    });
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = LessonData.modules[module];
    Map<String, dynamic> draft = ClassData.draft(module);
    int index = draft['questionIndex'];
    int remaining = draft['remainingSeconds'];
    List<int> answers = draft['answers'];
    List<dynamic> questions = data['questions'];
    Map<String, dynamic> question = questions[index];
    List<dynamic> options = question['options'];
    List<Widget> choices = [];
    for (int i = 0; i < options.length; i++) {
      final choice = i;
      bool selected = answers[index] == i;
      choices.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: InkWell(
            key: ValueKey('answer-$i'),
            onTap: () {
              AppAudio.click();
              setState(() {
                answers[index] = choice;
                message = '';
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE5FFF5) : Colors.white,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF00B982)
                      : const Color(0xFFE1E8F1),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: const Color(0xFF52627D),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(65 + i)}. ${options[i]}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    List<Widget> numbers = [];
    for (int i = 0; i < questions.length; i++) {
      final target = i;
      numbers.add(
        SizedBox(
          width: 38,
          height: 38,
          child: TextButton(
            onPressed: () => changeQuestion(target),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: index == i
                  ? const Color(0xFF00BA88)
                  : Colors.white,
              foregroundColor: index == i
                  ? Colors.white
                  : const Color(0xFF52627D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
          ),
        ),
      );
    }
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: studentBackground(),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 600,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          lessonButton('‹ Back', () => Navigator.pop(context)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'KNOWLEDGE CHECK',
                                  style: TextStyle(
                                    fontSize: 8,
                                    letterSpacing: 1,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  data['title'].toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF52627D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${data['title'].toString().toUpperCase()} QUIZ',
                              style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              question['question'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Column(children: choices),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: lessonButton(
                                    '‹ Previous',
                                    index > 0
                                        ? () => changeQuestion(index - 1)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: lessonButton(
                                    index == questions.length - 1
                                        ? 'Submit'
                                        : 'Next ›',
                                    () {
                                      if (index == questions.length - 1) {
                                        submit(false);
                                      } else {
                                        changeQuestion(index + 1);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (message.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    color: Color(0xFFB3261E),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 22),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: numbers,
                            ),
                          ],
                        ),
                      ),
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
