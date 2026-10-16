import 'package:flutter/material.dart';

import 'glob/game_catalog.dart';
import 'glob/game_data.dart';
import 'glob/audio.dart';
import 'student_ui.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});
  @override
  State<PlayPage> createState() => PlayPageState();
}

class PlayPageState extends State<PlayPage> {
  int selectedGame = 0;
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void resetScroll() {
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  Widget badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFF724964),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget gameList() {
    List<Widget> cards = [];
    for (int i = 0; i < GameCatalog.games.length; i++) {
      final index = i;
      Map<String, dynamic> game = GameCatalog.games[i];
      Map<String, int> progress = GameData.summary(i);
      String status = progress['percent'] == 100
          ? 'Completed'
          : progress['percent']! > 0
          ? 'In Progress'
          : 'Not Started';
      cards.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: InkWell(
            key: ValueKey('game-$i'),
            onTap: () async {
              AppAudio.click();
              setState(() {
                selectedGame = index;
              });
              GameData.activeGame = index;
              await Navigator.pushNamed(context, '/levels');
              if (mounted) setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF4CB), Color(0xFFE7D4A3)],
                ),
                border: Border.all(
                  color: selectedGame == i
                      ? const Color(0xFFA46B12)
                      : const Color(0xFF6B4D72),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF4A3040), offset: Offset(5, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game['shortTitle'],
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    game['title'],
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  badge(status),
                  const SizedBox(height: 8),
                  Text(
                    '${progress['percent']}%',
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      decoration: studentPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GAME MENU',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Play',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 16),
                    ),
                  ],
                ),
              ),
              badge('${GameCatalog.games.length} games'),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: studentBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                studentButton('BACK TO MENU', () {
                  AppAudio.click();
                  Navigator.pop(context);
                }, const Color(0xFF172134)),
                const SizedBox(height: 16),
                gameList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
