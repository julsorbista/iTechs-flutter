import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'glob/game_catalog.dart';
import 'glob/game_data.dart';
import 'glob/user.dart';
import 'glob/class_data.dart';
import 'glob/audio.dart';
import 'student_ui.dart';
import 'student_story_frame.dart';
import 'game2.dart';
import 'game4.dart';
import 'game6.dart';

class LevelsPage extends StatefulWidget {
  const LevelsPage({super.key});
  @override
  State<LevelsPage> createState() => LevelsPageState();
}

class LevelsPageState extends State<LevelsPage> {
  int selectedLevel = 1;
  int game = 0;
  bool showGuidelines = false;
  bool showLevels = false;
  int? pendingStoryLevel;
  int pendingStoryPage = 0;
  final pageController = ScrollController();
  final guidelinesController = ScrollController();

  @override
  void dispose() {
    guidelinesController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    game = GameData.activeGame;
    int next = GameData.summary(game)['next']!;
    if (next > 0) selectedLevel = next;
  }

  Widget pill(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: const Color(0xFF724964),
      child: Text(
        value.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget statistic(String value, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E6C2),
        border: Border.all(color: const Color(0xFF6B4D72), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontFamily: 'Roboto', fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget gameOverview() {
    Map<String, dynamic> metadata = GameCatalog.games[game];
    Map<String, int> progress = GameData.summary(game);
    String teacher = '';
    for (int i = 0; i < ClassData.courses.length; i++) {
      if (ClassData.courses[i]['code'] == AllUsers.activeUser!['courseCode']) {
        teacher = ClassData.courses[i]['teacher']!;
      }
    }
    return Container(
      key: const ValueKey('game-overview'),
      padding: const EdgeInsets.all(16),
      decoration: studentPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            metadata['label'].toString().toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metadata['title'],
            style: const TextStyle(fontFamily: 'Roboto', fontSize: 16),
          ),
          const SizedBox(height: 14),
          Text(
            metadata['description'],
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: pill(
              progress['percent'] == 100 ? 'Completed' : 'Not Started',
            ),
          ),
          const SizedBox(height: 14),
          statistic('${progress['percent']}%', 'progress'),
          statistic('${progress['completed']}', 'completed'),
          statistic('${progress['stars']}', 'stars'),
          statistic('${progress['levels']}', 'levels'),
          statistic(
            progress['next'] == 0 ? '--' : '${progress['next']}',
            'next level',
          ),
          statistic(teacher, 'teacher'),
          const SizedBox(height: 8),
          studentButton('OPEN LEVELS  ›', () {
            AppAudio.click();
            setState(() {
              showLevels = true;
            });
            pageController.jumpTo(0);
          }, const Color(0xFF159E80)),
        ],
      ),
    );
  }

  Widget levelGrid() {
    List<dynamic> levels = GameCatalog.games[game]['levels'];
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth >= 950
        ? 3
        : screenWidth <= 640
        ? 1
        : 2;
    List<Widget> cards = [];
    for (int i = 0; i < levels.length; i++) {
      final number = i + 1;
      Map<String, dynamic> record = GameData.level(game, number);
      bool locked = record['status'] == 'Locked';
      List<Widget> stars = [];
      for (int star = 0; star < 3; star++) {
        stars.add(
          Icon(
            star < record['bestStars'] ? Icons.star : Icons.star_border,
            size: 18,
            color: const Color(0xFFFFE7A0),
          ),
        );
      }
      cards.add(
        InkWell(
          key: ValueKey('level-$number'),
          onTap: () {
            AppAudio.click();
            setState(() {
              selectedLevel = number;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF724D69),
              border: Border.all(
                color: selectedLevel == number
                    ? const Color(0xFFE2A517)
                    : const Color(0xFF50364F),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Color(0xFF4A3040), offset: Offset(4, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'LEVEL',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Color(0xFFFFEDBF),
                        ),
                      ),
                    ),
                    pill(locked ? 'Locked' : record['status']),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  number.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    color: Color(0xFFFFEDBF),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    levels[i]['title'],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Color(0xFFFFEDBF),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: stars),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      key: const ValueKey('level-grid'),
      padding: const EdgeInsets.all(16),
      decoration: studentPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LEVEL SELECT',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            primary: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 0, 6, 8),
            crossAxisCount: crossAxisCount,
            childAspectRatio: screenWidth <= 640 ? 1.7 : 1.02,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: cards,
          ),
        ],
      ),
    );
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget levelDetails() {
    Map<String, dynamic> metadata = GameCatalog.games[game];
    List<dynamic> levels = metadata['levels'];
    Map<String, dynamic> record = GameData.level(game, selectedLevel);
    bool locked = record['status'] == 'Locked';
    List<Widget> guidelines = [];
    List<dynamic> items = metadata['guidelines'];
    List<String> icons = [
      'icon-move.png',
      'icon-hazard.png',
      'icon-heart.png',
      'icon-lock.png',
      'icon-trophy.png',
      'icon-lock.png',
    ];
    if (game == 0) {
      items = [
        'Move, jump, dash, and attack to travel safely through platform areas.',
        'Enemy contact, projectiles, traps, and falls can remove health.',
        'Losing all health ends the level attempt.',
        'Coins and collectible clues help meet objectives, unlock progress, or support hints when available.',
        'Complete the objective and enter the portal to finish the level.',
        'Earn at least 2 Stars to unlock the next level.',
      ];
    }
    for (int i = 0; i < items.length; i++) {
      guidelines.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x88FFE7A6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x447E5B2C)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/guidelines/${game == 0 ? icons[i] : 'icon-dot.png'}',
                width: 42,
                height: 42,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[i],
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    height: 1.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      key: const ValueKey('selected-level-details'),
      padding: const EdgeInsets.all(16),
      decoration: studentPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'SELECTED LEVEL',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Level ${selectedLevel.toString().padLeft(2, '0')}',
            style: const TextStyle(fontFamily: 'Roboto', fontSize: 17),
          ),
          const SizedBox(height: 10),
          Text(
            levels[selectedLevel - 1]['title'],
            style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            levels[selectedLevel - 1]['description'],
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              AppAudio.click();
              setState(() {
                showGuidelines = !showGuidelines;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF63416B),
              foregroundColor: const Color(0xFFFFEDBF),
              minimumSize: const Size(double.infinity, 72),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
                side: const BorderSide(color: Color(0xFF91718C), width: 3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 17),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'LEVEL GUIDELINES',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(showGuidelines ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (showGuidelines)
            Container(
              margin: const EdgeInsets.only(top: 16),
              height: 330,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBE9AA), Color(0xFFE3BE69)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF826331), width: 5),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF63482D), offset: Offset(4, 5)),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF9C793B), width: 2),
                ),
                child: Scrollbar(
                  controller: guidelinesController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: guidelinesController,
                    primary: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'General Game Guidelines',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Column(children: guidelines),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          detailRow('Status', record['status']),
          detailRow('Attempts', '${record['attempts']}'),
          detailRow('Best Stars', '${record['bestStars']}'),
          const SizedBox(height: 18),
          studentButton(
            'START LEVEL',
            !locked && metadata['gameType'] == 'GAME_TWO'
                ? () async {
                    AppAudio.click();
                    if (selectedLevel == 1) {
                      _openStory();
                    } else {
                      await _launchSelectedLevel();
                    }
                    if (!mounted) return;
                    setState(() {});
                  }
                : !locked && metadata['gameType'] == 'GAME_FOUR'
                ? () async {
                    AppAudio.click();
                    final firstPlay =
                        selectedLevel == 1 &&
                        (record['attempts'] as int? ?? 0) == 0;
                    if (selectedLevel == 1) {
                      _openStory();
                    } else {
                      await _launchSelectedLevel(game4FirstPlay: firstPlay);
                    }
                    if (!mounted) return;
                    setState(() {});
                  }
                : !locked && metadata['gameType'] == 'GAME_SIX'
                ? () async {
                    AppAudio.click();
                    await _launchSelectedLevel();
                    if (!mounted) return;
                    setState(() {});
                  }
                : null,
            const Color(0xFF172134),
          ),
          const SizedBox(height: 12),
          Text(
            metadata['gameType'] == 'GAME_TWO'
                ? 'Game 2 — Code Slice is ready to play.'
                : metadata['gameType'] == 'GAME_FOUR'
                ? 'Game 4 — Catch The Code is ready to play.'
                : metadata['gameType'] == 'GAME_SIX'
                ? 'Game 6 — Syntax Rain Typing is ready to play.'
                : 'Gameplay is not available yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF654E50)),
          ),
        ],
      ),
    );
  }

  void _openStory() {
    setState(() {
      pendingStoryLevel = selectedLevel;
      pendingStoryPage = 0;
    });
  }

  Future<void> _launchSelectedLevel({bool? game4FirstPlay}) async {
    final level = pendingStoryLevel ?? selectedLevel;
    final gameType = GameCatalog.games[game]['gameType'];
    setState(() {
      pendingStoryLevel = null;
      pendingStoryPage = 0;
    });
    if (gameType == 'GAME_TWO') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Game2Page(selectedLevel: level)),
      );
      return;
    }
    if (gameType == 'GAME_SIX') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Game6Page(selectedLevel: level)),
      );
      return;
    }
    final firstPlay = game4FirstPlay ?? false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Game4Page(
          selectedLevel: level,
          suppressIntroTutorial: level == 1,
          continueToTutorialAfterGuide: firstPlay,
          startWithGuide: level == 1 && firstPlay,
        ),
      ),
    );
  }

  Widget _storyOverlay() {
    final gameType = GameCatalog.games[game]['gameType'];
    final world = gameType == 'GAME_TWO' ? 'game2' : 'game4';
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xD691D7FF),
                        Color(0xD6FFE7A9),
                        Color(0xD6FFC3D8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: StudentStoryFrame(
                  imagePath: 'assets/$world/story/${pendingStoryPage + 1}.png',
                  worldTitle: gameType == 'GAME_TWO'
                      ? 'THE ASSEMBLY FORTRESS'
                      : 'CODE CATCHER',
                  page: pendingStoryPage,
                  totalPages: 8,
                  onBack: () {
                    if (pendingStoryPage == 0) {
                      setState(() => pendingStoryLevel = null);
                    } else {
                      setState(() => pendingStoryPage--);
                    }
                  },
                  onNext: () => setState(() => pendingStoryPage++),
                  onSkip: () => _launchSelectedLevel(
                    game4FirstPlay:
                        gameType == 'GAME_FOUR' &&
                        (GameData.level(game, selectedLevel)['attempts']
                                    as int? ??
                                0) ==
                            0,
                  ),
                  onPrimary: () => _launchSelectedLevel(
                    game4FirstPlay:
                        gameType == 'GAME_FOUR' &&
                        (GameData.level(game, selectedLevel)['attempts']
                                    as int? ??
                                0) ==
                            0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> metadata = GameCatalog.games[game];
    Map<String, int> progress = GameData.summary(game);
    bool wide = MediaQuery.of(context).size.width >= 950;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: studentBackground(),
            child: SafeArea(
              child: SingleChildScrollView(
                controller: pageController,
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    studentButton('BACK TO MENU', () {
                      AppAudio.click();
                      Navigator.popUntil(context, ModalRoute.withName('/home'));
                    }, const Color(0xFF172134)),
                    const SizedBox(height: 16),
                    studentButton('BACK TO GAMES', () {
                      AppAudio.click();
                      Navigator.pop(context);
                    }, const Color(0xFF172134)),
                    const SizedBox(height: 16),
                    if (showLevels) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: studentPanel(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metadata['label'].toString().toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              metadata['title'],
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: statistic(
                                    '${progress['percent']}%',
                                    'progress',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: statistic(
                                    '${progress['completed']}',
                                    'cleared',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: statistic(
                                    '${progress['stars']}',
                                    'stars',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: levelGrid()),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: levelDetails()),
                          ],
                        )
                      else ...[
                        levelGrid(),
                        const SizedBox(height: 16),
                        levelDetails(),
                      ],
                    ] else
                      gameOverview(),
                  ],
                ),
              ),
            ),
          ),
          if (pendingStoryLevel != null) _storyOverlay(),
        ],
      ),
    );
  }
}
