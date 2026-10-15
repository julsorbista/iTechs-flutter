import 'package:flutter/material.dart';

import 'glob/user.dart';
import 'glob/class_data.dart';
import 'glob/lesson_data.dart';
import 'glob/audio.dart';
import 'student_ui.dart';

class MyClassPage extends StatefulWidget {
  const MyClassPage({super.key});
  @override
  State<MyClassPage> createState() => MyClassPageState();
}

class MyClassPageState extends State<MyClassPage> {
  final codeController = TextEditingController();
  String message = '';
  @override
  void initState() {
    super.initState();
    codeController.text = AllUsers.activeUser?['courseCode'] ?? 'FN2LH4CF';
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void updateCourse() {
    AppAudio.click();
    String code = codeController.text.trim().toUpperCase();
    bool found = false;
    for (int i = 0; i < ClassData.courses.length; i++) {
      if (ClassData.courses[i]['code'] == code) found = true;
    }
    if (!found) {
      setState(() {
        message = 'Enter a valid teacher course code.';
      });
      return;
    }
    if (code == AllUsers.activeUser!['courseCode']) {
      setState(() {
        message = 'You are already enrolled in this course.';
      });
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: Text(
          'Replacing your teacher code with $code starts your progress in the new course. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AllUsers.activeUser!['courseCode'] = code;
              Navigator.pop(context);
              setState(() {
                message = 'Course updated successfully.';
              });
            },
            child: const Text('Replace & Reset'),
          ),
        ],
      ),
    );
  }

  void openModule(int index) {
    AppAudio.click();
    ClassData.activeModule = index;
    Navigator.pushNamed(context, '/module').then((value) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    String teacher = '';
    for (int i = 0; i < ClassData.courses.length; i++) {
      if (ClassData.courses[i]['code'] == AllUsers.activeUser!['courseCode']) {
        teacher = ClassData.courses[i]['teacher']!;
      }
    }
    List<Widget> cards = [];
    for (int i = 0; i < LessonData.modules.length; i++) {
      final index = i;
      Map<String, dynamic> module = LessonData.modules[i];
      int percent = ClassData.percent(i);
      bool unlocked = ClassData.unlocked(i);
      cards.add(
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  unlocked ? Icons.menu_book_outlined : Icons.lock_outline,
                  size: 20,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                module['title'].toString().toUpperCase(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'MODULE · ICT-1A',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                !unlocked
                    ? 'Locked'
                    : percent == 100
                    ? 'Completed'
                    : percent > 0
                    ? 'In Progress'
                    : 'Not Started',
                style: const TextStyle(fontSize: 12, color: Color(0xFF0F997A)),
              ),
              const SizedBox(height: 12),
              Text(
                module['description'],
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF00BC8B),
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$percent%', style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 18),
              studentButton(
                unlocked ? 'START MODULE' : 'LOCKED',
                unlocked ? () => openModule(index) : null,
                const Color(0xFF159E80),
              ),
              if (!unlocked)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Pass the previous module quiz to unlock.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
            ],
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 20),
            child: Center(
              child: SizedBox(
                width: 560,
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
                        children: [
                          const Text(
                            'COURSE CODE',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            teacher,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Current code: ${AllUsers.activeUser!['courseCode']}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'TEACHER CODE',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: codeController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF4DFAB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3C9),
                              border: Border.all(
                                color: const Color(0xFF9E6F49),
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'Replacing your teacher code starts fresh progress in the new course.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                height: 1.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          studentButton(
                            'UPDATE COURSE',
                            updateCourse,
                            const Color(0xFFF5B225),
                          ),
                          if (message.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(message),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: studentPanel(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Class Resources',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Learning Materials',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${LessonData.modules.length} materials · $teacher',
                            textAlign: TextAlign.right,
                          ),
                          Column(children: cards),
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
    );
  }
}
