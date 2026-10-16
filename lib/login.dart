import 'package:flutter/material.dart';

import 'glob/game_data.dart';
import 'glob/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMessage = '';
  bool hidePassword = true;
  bool isLoggingIn = false;

  List<Map<String, String>> terms = [
    {
      'title': '1. Use of the Application',
      'body': 'This app is intended for educational purposes. Users must use the app responsibly and only for lawful activities.',
    },
    {
      'title': '2. User Account',
      'body': 'Users must provide accurate information and are responsible for maintaining the confidentiality of their account.',
    },
    {
      'title': '3. Game and Progress Data',
      'body': 'User progress, scores, and activity may be stored and used to improve the system.',
    },
    {
      'title': '4. Content and Questions',
      'body': 'Questions and content may be dynamically or AI-generated. Accuracy is not guaranteed, and content may change over time.',
    },
    {
      'title': '5. User Conduct',
      'body': 'Users must not cheat, exploit bugs, or misuse the system. Violations may result in account suspension.',
    },
    {
      'title': '6. Privacy',
      'body': 'Basic user data (such as name, progress, and scores) may be collected for system functionality. Data will not be sold to third parties.',
    },
    {
      'title': '7. Availability',
      'body': 'The app may be updated or modified at any time and is not guaranteed to be error-free.',
    },
    {
      'title': '8. Limitation of Liability',
      'body': 'The system is not responsible for data loss, incorrect content, or damages from usage.',
    },
    {
      'title': '9. Changes to Terms',
      'body': 'Terms may be updated anytime. Continued use means acceptance of the updated terms.',
    },
    {
      'title': '10. Contact',
      'body': 'For questions or concerns, please contact the iTECHS support team through your school administrator or official support channel.',
    },
  ];

  void showTerms() {
    List<Widget> termsWidgets = [];
    for (int i = 0; i < terms.length; i++) {
      termsWidgets.add(
        Text(
          terms[i]['title']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      termsWidgets.add(const SizedBox(height: 6));
      termsWidgets.add(Text(terms[i]['body']!));
      termsWidgets.add(const SizedBox(height: 18));
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please review these terms before continuing to sign in.',
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: termsWidgets,
              ),
            ],
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

  Future<void> loginAccount() async {
    if (isLoggingIn) return;

    String username = usernameController.text.trim();
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your username and password.';
      });
      return;
    }

    for (int i = 0; i < AllUsers.userList.length; i++) {
      if (AllUsers.userList[i]['username'] == username &&
          AllUsers.matchesPassword(AllUsers.userList[i], password)) {
        setState(() {
          isLoggingIn = true;
          errorMessage = '';
        });
        AllUsers.activeUser = AllUsers.userList[i];

        // A storage failure must not prevent a valid user from entering the app.
        await GameData.loadProgress();
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
    }
    setState(() {
      isLoggingIn = false;
      errorMessage = 'Incorrect username or password.';
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login-background.png'),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xF5FFFFFF), Color(0xEBF8FBFD)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD6DEE5)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0F172A),
                        blurRadius: 60,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 64,
                        width: 64,
                        semanticLabel: 'iTECHS',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Account Login',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter your credentials to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Email or Username',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: usernameController,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'username@school.edu',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) => loginAccount(),
                        decoration: InputDecoration(
                          hintText: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 3,
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          suffixIcon: IconButton(
                            tooltip: hidePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: const Color(0xFF6B4A85),
                            ),
                          ),
                        ),
                      ),
                      if (errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: loginAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xE6F8FAFC),
                          border: Border.all(color: const Color(0xCCE2E8F0)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: OutlinedButton(
                          onPressed: showTerms,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Secure academic access powered by iTECHS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
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
