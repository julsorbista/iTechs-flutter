import 'package:flutter/material.dart';

import 'glob/user.dart';
import 'glob/audio.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  String activeTab = 'Account';
  String message = '';
  bool passwordChanged = false;
  bool savingPassword = false;
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  Future<void> changePassword() async {
    if (savingPassword) return;
    AppAudio.click();
    String oldPassword = oldPasswordController.text;
    String newPassword = newPasswordController.text;
    final user = AllUsers.activeUser;
    bool valid = false;
    setState(() {
      passwordChanged = false;
      if (oldPassword.isEmpty || newPassword.isEmpty) {
        message = 'Complete both password fields first.';
      } else if (AllUsers.activeUser == null) {
        message = 'Please log in again.';
      } else if (!AllUsers.matchesPassword(user!, oldPassword)) {
        message = 'Current password is incorrect.';
      } else if (newPassword.length < 8) {
        message = 'New password must be at least 8 characters.';
      } else if (!RegExp(r'[A-Z]').hasMatch(newPassword) ||
          !RegExp(r'[a-z]').hasMatch(newPassword) ||
          !RegExp(r'[0-9]').hasMatch(newPassword) ||
          !RegExp(r'[@$!%*?&_#-]').hasMatch(newPassword)) {
        message = 'Use uppercase, lowercase, a number, and a special character (@\$!%*?&_#-).';
      } else {
        valid = true;
        savingPassword = true;
        message = 'Saving password...';
      }
    });
    if (!valid) return;
    try {
      await AllUsers.updatePassword(user!, newPassword);
      if (!mounted) return;
      setState(() {
        savingPassword = false;
        oldPasswordController.clear();
        newPasswordController.clear();
        passwordChanged = true;
        message = 'Password changed successfully.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        savingPassword = false;
        message = 'Could not save password. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
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

  Widget heading(String smallTitle, String title) {
    return Column(
      children: [
        Text(
          smallTitle.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            letterSpacing: 1,
            color: Color(0xFF2A1C23),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A1C23),
          ),
        ),
      ],
    );
  }

  Widget actionButton(String label, bool selected, VoidCallback action) {
    return Container(
      margin: EdgeInsets.only(top: label == 'BACK TO MENU' ? 0 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selected
              ? [const Color(0xFFFFDF78), const Color(0xFFF5A70B)]
              : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4A3040), offset: Offset(5, 5)),
        ],
      ),
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.white, width: 4),
          ),
        ),
        child: Row(
          mainAxisAlignment:
              label == 'BACK TO MENU' || label == 'CHANGE PASSWORD'
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            if (label == 'BACK TO MENU') ...[
              const Icon(Icons.arrow_back, size: 16),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget passwordField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0xFF4A3040), offset: Offset(5, 5)),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9D8A65),
              ),
              filled: true,
              fillColor: const Color(0xFFF4DFAB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFF7D5B60)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Color(0xFF7D5B60),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget audioCard(
    String title,
    String description,
    IconData icon,
    bool isMusic,
  ) {
    double volume = isMusic ? AllUsers.musicVolume : AllUsers.sfxVolume;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E6C2),
        border: Border.all(color: const Color(0xFF6B4D72), width: 3),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF724964),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4A3040), width: 3),
                ),
                child: Icon(
                  volume == 0 ? Icons.volume_off_outlined : icon,
                  color: const Color(0xFFF2E6C2),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF2A1C23),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: const Color(0xFF1B9E75),
              inactiveTrackColor: const Color(0xFF404047),
              thumbColor: const Color(0xFF1B9E75),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: SliderComponentShape.noOverlay,
              trackShape: const RectangularSliderTrackShape(),
            ),
            child: Slider(
              value: volume,
              min: 0,
              max: 100,
              divisions: 100,
              semanticFormatterCallback: (value) => '${value.round()} percent',
              onChanged: (value) {
                setState(() {
                  if (isMusic) {
                    AllUsers.musicVolume = value;
                  } else {
                    AllUsers.sfxVolume = value;
                  }
                });
                if (isMusic) AppAudio.updateMusicVolume();
              },
              onChangeEnd: (value) => AppAudio.click(),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
              Text(
                '100%',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF724964),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF4A3040), width: 3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  '${volume.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
                    actionButton('BACK TO MENU', false, () {
                      AppAudio.click();
                      Navigator.pop(context);
                    }),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: panelDecoration(),
                      child: Column(
                        children: [
                          heading('Settings', 'Preferences'),
                          actionButton('ACCOUNT', activeTab == 'Account', () {
                            AppAudio.click();
                            setState(() {
                              activeTab = 'Account';
                            });
                          }),
                          actionButton('AUDIO', activeTab == 'Audio', () {
                            AppAudio.click();
                            setState(() {
                              activeTab = 'Audio';
                            });
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: panelDecoration(),
                      child: activeTab == 'Account'
                          ? Column(
                              children: [
                                heading('Account', 'Account Settings'),
                                passwordField(
                                  'OLD PASSWORD',
                                  'Enter current password',
                                  oldPasswordController,
                                ),
                                passwordField(
                                  'NEW PASSWORD',
                                  'Enter new password',
                                  newPasswordController,
                                ),
                                const SizedBox(height: 8),
                                actionButton(
                                  'CHANGE PASSWORD',
                                  true,
                                  changePassword,
                                ),
                                if (message.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        color: passwordChanged
                                            ? const Color(0xFF0F766E)
                                            : const Color(0xFFB3261E),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Column(
                              children: [
                                heading('Audio', 'Menu Sound'),
                                audioCard(
                                  'Music',
                                  'Control the volume for menu background music.',
                                  Icons.volume_up_outlined,
                                  true,
                                ),
                                audioCard(
                                  'Sound FX',
                                  'Control the volume for button and interface sounds.',
                                  Icons.auto_awesome_outlined,
                                  false,
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
