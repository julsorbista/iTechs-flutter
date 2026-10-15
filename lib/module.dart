import 'package:flutter/material.dart';

import 'glob/class_data.dart';
import 'glob/lesson_data.dart';
import 'glob/user.dart';
import 'glob/audio.dart';
import 'student_ui.dart';

class ModulePage extends StatefulWidget {
  const ModulePage({super.key});
  @override
  State<ModulePage> createState() => ModulePageState();
}

class ModulePageState extends State<ModulePage> {
  int module = 0;
  int page = 0;
  final scrollController = ScrollController();
  final readingWatch = Stopwatch();
  Map<String, dynamic> readingRecord = {};
  @override
  void initState() {
    super.initState();
    module = ClassData.activeModule;
    page = ClassData.progress(module)['currentPage'];
    ClassData.viewPage(module, page);
    readingRecord = ClassData.progress(module);
    readingWatch.start();
  }

  void saveReadingTime() {
    readingRecord['readingMilliseconds'] =
        (readingRecord['readingMilliseconds'] ?? 0) +
        readingWatch.elapsedMilliseconds;
    readingWatch.reset();
  }

  @override
  void dispose() {
    readingWatch.stop();
    saveReadingTime();
    scrollController.dispose();
    super.dispose();
  }

  void changePage(int value) {
    saveReadingTime();
    AppAudio.click();
    setState(() {
      page = value;
      ClassData.viewPage(module, page);
    });
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  void showOutline() {
    List<dynamic> pages = LessonData.modules[module]['pages'];
    List<Widget> items = [];
    for (int i = 0; i < pages.length; i++) {
      final index = i;
      items.add(
        ListTile(
          title: Text('${i + 1}. ${pages[i]['title']}'),
          onTap: () {
            Navigator.pop(context);
            changePage(index);
          },
        ),
      );
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Course Outline'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: items),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void showAudio() {
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Sound settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Music ${AllUsers.musicVolume.round()}%'),
              Slider(
                value: AllUsers.musicVolume,
                min: 0,
                max: 100,
                onChanged: (value) {
                  update(() {
                    AllUsers.musicVolume = value;
                  });
                  AppAudio.updateMusicVolume();
                },
              ),
              Text('Sound FX ${AllUsers.sfxVolume.round()}%'),
              Slider(
                value: AllUsers.sfxVolume,
                min: 0,
                max: 100,
                onChanged: (value) {
                  update(() {
                    AllUsers.sfxVolume = value;
                  });
                },
                onChangeEnd: (value) => AppAudio.click(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible) {
      readingWatch.start();
    } else if (readingWatch.isRunning) {
      readingWatch.stop();
      saveReadingTime();
    }
    Map<String, dynamic> data = LessonData.modules[module];
    List<dynamic> pages = data['pages'];
    Map<String, dynamic> lesson = pages[page];
    int percent = ClassData.percent(module);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: studentBackground(),
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: 720,
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
                          IconButton(
                            tooltip: 'Back to Materials',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'COURSE MODULE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 2,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  data['title'].toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          lessonButton(
                            'Course Outline',
                            showOutline,
                            Icons.menu_book_outlined,
                          ),
                          lessonButton(
                            'Audio',
                            showAudio,
                            Icons.volume_up_outlined,
                          ),
                          Chip(
                            label: Text(
                              '$percent% complete',
                              style: const TextStyle(
                                color: Color(0xFF008B66),
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: const Color(0xFFEBFFF7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: lessonButton(
                          'Take a Quiz',
                          percent == 100
                              ? () {
                                  ClassData.activeModule = module;
                                  Navigator.pushNamed(context, '/quiz').then((
                                    value,
                                  ) {
                                    if (mounted) setState(() {});
                                  });
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'MODULE SECTION   ${page + 1} / ${pages.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 1,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lesson['title'].toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              lesson['content'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.9,
                                color: Color(0xFF53627C),
                              ),
                            ),
                            if ((lesson['image'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Image.asset(
                                'assets/lessons/${lesson['image']}',
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                lesson['caption'] ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: lessonButton(
                                    '‹ Previous',
                                    page > 0
                                        ? () => changePage(page - 1)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: lessonButton(
                                    'Next ›',
                                    page < pages.length - 1
                                        ? () => changePage(page + 1)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (percent < 100)
                              const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  'Read all lesson sections to unlock the quiz.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
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
          ),
        ),
      ),
    );
  }
}
