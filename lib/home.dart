import 'package:flutter/material.dart';

import 'glob/user.dart';
import 'glob/audio.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String activePage = 'Menu';
  List<String> menuNames = [
    'Play',
    'My Class',
    'My Progress',
    'Leaderboard',
    'Profile Editor',
    'Settings',
  ];
  List<IconData> menuIcons = [
    Icons.sports_esports_outlined,
    Icons.menu_book_outlined,
    Icons.bar_chart,
    Icons.emoji_events_outlined,
    Icons.person_outline,
    Icons.tune,
  ];

  void openPage(String page) {
    AppAudio.click();
    if (page == 'Play') {
      Navigator.pushNamed(context, '/play');
      return;
    }
    if (page == 'My Progress') {
      Navigator.pushNamed(context, '/progress');
      return;
    }
    if (page == 'My Class') {
      Navigator.pushNamed(context, '/class');
      return;
    }
    if (page == 'Leaderboard') {
      Navigator.pushNamed(context, '/leaderboard');
      return;
    }
    if (page == 'Profile Editor') {
      Navigator.pushNamed(context, '/profile').then((value) {
        if (mounted) setState(() {});
      });
      return;
    }
    if (page == 'Settings') {
      Navigator.pushNamed(context, '/settings');
      return;
    }
    setState(() {
      activePage = page;
    });
  }

  void logoutAccount() {
    AppAudio.stop();
    AllUsers.activeUser = null;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void initState() {
    super.initState();
    AppAudio.startMusic();
  }

  @override
  void dispose() {
    AppAudio.stop();
    super.dispose();
  }

  Widget menuButton(String name, IconData icon, VoidCallback action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8E9C6), Color(0xFFE6CB98)],
        ),
        boxShadow: [BoxShadow(color: Color(0xFF4A3040), offset: Offset(4, 4))],
      ),
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: const Color(0xFF2F2417),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFF8F6F4B), width: 3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17),
            if (name.isNotEmpty) const SizedBox(width: 8),
            Flexible(
              child: Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration panelDecoration() {
    return BoxDecoration(
      color: const Color(0xF0E7CF99),
      border: Border.all(color: const Color(0xFF6B4D72), width: 4),
      boxShadow: const [
        BoxShadow(color: Color(0xFF4A3040), offset: Offset(6, 6)),
      ],
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: const Color(0xF0F2E6C2),
      border: Border.all(color: const Color(0xFF6B4D72), width: 4),
      boxShadow: const [
        BoxShadow(color: Color(0xFF4A3040), offset: Offset(4, 4)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = AllUsers.activeUser;
    List<Widget> menuRows = [];
    for (int i = 0; i < menuNames.length; i++) {
      final index = i;
      menuRows.add(
        menuButton(
          menuNames[index],
          menuIcons[index],
          () => openPage(menuNames[index]),
        ),
      );
    }
    return PopScope(
      canPop: activePage == 'Menu',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) openPage('Menu');
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/menu-background.png'),
              colorFilter: ColorFilter.mode(
                Color(0xBA4F3347),
                BlendMode.srcOver,
              ),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
              child: Center(
                child: SizedBox(
                  width: 560,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: panelDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: activePage == 'Menu'
                          ? [
                              const Text(
                                'MENU',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  color: Color(0xFF2A1C23),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'iTECHS',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2A1C23),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Column(children: menuRows),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: cardDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'AVATAR',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Center(
                                      child: Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC9E8F6),
                                          border: Border.all(
                                            color: const Color(0xFF6B4D72),
                                            width: 4,
                                          ),
                                        ),
                                        child: Image.asset(
                                          'assets/images/${student?['avatar'] ?? 'girl-avatar-3'}.png',
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: cardDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'STUDENT',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${student?['firstName'] ?? ''} ${student?['lastName'] ?? ''}',
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Semantics(
                                label: 'Log out',
                                button: true,
                                child: Tooltip(
                                  message: 'Log out',
                                  child: menuButton(
                                    '',
                                    Icons.logout,
                                    logoutAccount,
                                  ),
                                ),
                              ),
                            ]
                          : [
                              menuButton(
                                'Back to Menu',
                                Icons.arrow_back,
                                () => openPage('Menu'),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                activePage,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 26,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                    ),
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
