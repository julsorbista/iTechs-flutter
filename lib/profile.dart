import 'package:flutter/material.dart';

import 'glob/user.dart';
import 'glob/audio.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  String selectedAvatar = '';
  String category = 'Girl';
  final avatarScrollController = ScrollController();
  List<String> girlAvatars = [
    'girl-avatar-1',
    'girl-avatar-2',
    'girl-avatar-3',
    'girl-avatar-4',
  ];
  List<String> boyAvatars = [
    'boy-avatar-1',
    'boy-avatar-2',
    'boy-avatar-3',
    'boy-avatar-4',
  ];

  @override
  void initState() {
    super.initState();
    selectedAvatar = AllUsers.activeUser?['avatar'] ?? 'girl-avatar-3';
    if (selectedAvatar.startsWith('boy')) category = 'Boy';
  }

  void chooseCategory(String value) {
    AppAudio.click();
    setState(() {
      category = value;
    });
    if (avatarScrollController.hasClients) avatarScrollController.jumpTo(0);
  }

  void selectAvatar(String value) {
    AppAudio.click();
    setState(() {
      selectedAvatar = value;
    });
  }

  void saveAvatar() {
    if (AllUsers.activeUser == null) return;
    AppAudio.click();
    setState(() {
      AllUsers.activeUser!['avatar'] = selectedAvatar;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar updated successfully.')),
    );
  }

  @override
  void dispose() {
    avatarScrollController.dispose();
    super.dispose();
  }

  String avatarLabel(String value) {
    List<String> parts = value.split('-');
    String label = parts[0] == 'girl' ? 'Girl' : 'Boy';
    return '$label Avatar ${parts[2]}';
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

  Widget titleBlock(String smallTitle, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          smallTitle.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget avatarImage(String avatar) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCDEEFA),
        border: Border.all(color: const Color(0xFF6B4D72), width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4A3040), offset: Offset(4, 4)),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.asset(
          'assets/images/$avatar.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
          semanticLabel: avatarLabel(avatar),
        ),
      ),
    );
  }

  Widget categoryButton(String label) {
    bool selected = category == label;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFF7E8B5), Color(0xFFEDD796)],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: const Color(0xFF6B4D72), width: 3)
              : null,
        ),
        child: TextButton(
          onPressed: () => chooseCategory(label),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(vertical: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Color(0xFF2A1C23),
            ),
          ),
        ),
      ),
    );
  }

  Widget avatarOption(String avatar) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 8, 16),
      child: Semantics(
        button: true,
        selected: selectedAvatar == avatar,
        child: InkWell(
          onTap: () => selectAvatar(avatar),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2E6C2),
              border: Border.all(
                color: selectedAvatar == avatar
                    ? const Color(0xFF1FA87C)
                    : const Color(0xFF6B4D72),
                width: 4,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0xFF4A3040), offset: Offset(5, 5)),
              ],
            ),
            child: Column(
              children: [
                avatarImage(avatar),
                const SizedBox(height: 12),
                Text(
                  avatarLabel(avatar),
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> avatars = category == 'Girl' ? girlAvatars : boyAvatars;
    List<Widget> avatarCards = [];
    for (int i = 0; i < avatars.length; i++) {
      avatarCards.add(avatarOption(avatars[i]));
    }
    bool isSaved = selectedAvatar == AllUsers.activeUser?['avatar'];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/menu-background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xBA4F3347), BlendMode.srcOver),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 20),
            child: Center(
              child: SizedBox(
                width: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF4A3040),
                            offset: Offset(5, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          AppAudio.click();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            side: BorderSide(color: Colors.white, width: 4),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back, size: 16),
                            SizedBox(width: 10),
                            Text(
                              'BACK TO MENU',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: panelDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          titleBlock(
                            'Character Menu',
                            'Profile Editor',
                            'Choose a pixel avatar for your account. Your preview updates instantly, and the saved choice appears in the sidebar.',
                          ),
                          const SizedBox(height: 18),
                          avatarImage(selectedAvatar),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              color: const Color(0xFF724964),
                              child: Text(
                                isSaved ? 'SAVED AVATAR' : 'PREVIEW',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            avatarLabel(selectedAvatar),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2BC797), Color(0xFF138677)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF4A3040),
                                  offset: Offset(5, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: saveAvatar,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'CUSTOMIZE',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: panelDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          titleBlock(
                            'Category Tabs',
                            'Choose a Character',
                            'Switch between the girl and boy tabs, then pick the avatar you want to preview and save.',
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEFDBA4), Color(0xFFE0C27F)],
                              ),
                              border: Border.all(
                                color: const Color(0xFF6B4D72),
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                categoryButton('Girl'),
                                categoryButton('Boy'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: Scrollbar(
                              controller: avatarScrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: avatarScrollController,
                                child: Column(children: avatarCards),
                              ),
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
    );
  }
}
