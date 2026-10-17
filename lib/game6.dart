import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'widgets/illustrated_results_overlay.dart';

import 'glob/coin_storage.dart';
import 'glob/game_data.dart';
import 'widgets/game_entry.dart';
import 'widgets/game6_announcement.dart';
import 'widgets/game_completion_flow.dart';
import 'glob/user.dart';
import 'student_story_frame.dart';

/// Flutter Game 6: Syntax Rain Typing.
///
/// Instructional overlays are deliberately local to this page so they pause
/// the live run without changing shared game or progression components.
class Game6Page extends StatelessWidget {
  const Game6Page({
    super.key,
    this.selectedLevel = 1,
    this.initialCoins = 0,
    this.isTutorialLevel = false,
    this.firstPlay = false,
  });

  final int selectedLevel;
  final int initialCoins;
  final bool isTutorialLevel;
  final bool firstPlay;

  static const _levels = <_Game6LevelConfig>[
    _Game6LevelConfig(
      level: 1,
      title: 'Speed-Up Wave',
      objective: 'Type each falling Java term before it reaches the bottom.',
      targetWords: 5,
      seconds: 120,
      lives: 5,
    ),
    _Game6LevelConfig(
      level: 2,
      title: 'Incomplete Letters',
      objective: 'Complete ten falling Java terms with missing letters.',
      targetWords: 10,
      seconds: 300,
      lives: 5,
    ),
    _Game6LevelConfig(
      level: 3,
      title: 'Target Words',
      objective: 'Clear fifteen target words while ignoring distractors.',
      targetWords: 15,
      seconds: 360,
      lives: 5,
    ),
    _Game6LevelConfig(
      level: 4,
      title: 'Fake Syntaxes',
      objective: 'Type twenty real Java terms while ignoring fake syntax.',
      targetWords: 20,
      seconds: 420,
      lives: 5,
    ),
    _Game6LevelConfig(
      level: 5,
      title: 'Odd Pair',
      objective: 'Complete twenty-five hidden Java pairs before time or health runs out.',
      targetWords: 25,
      seconds: 480,
      lives: 5,
    ),
  ];

  _Game6LevelConfig get _config => _levels[(selectedLevel - 1).clamp(0, 4)];

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final compact = media.width <= 1023;
    final playfieldHeight = compact
        ? (media.height * .58).clamp(410.0, 520.0)
        : (media.height * .48).clamp(440.0, 485.0);
    final theme = _Game6Theme.forLevel(_config.level);

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 10 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1560),
              child: _Game6Gameplay(
                config: _config,
                initialCoins: initialCoins,
                isTutorialLevel: isTutorialLevel,
                firstPlay: firstPlay,
                compact: compact,
                playfieldHeight: playfieldHeight,
                theme: theme,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Retained as the original static preview layout reference during the
  // gameplay port; the stateful shell below now renders the live controls.
  // ignore: unused_element
  Widget _gameShell(
    BuildContext context, {
    required bool compact,
    required double playfieldHeight,
    required _Game6Theme theme,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.shell,
        border: Border.all(color: theme.dark, width: 3),
        boxShadow: [BoxShadow(color: theme.dark, offset: const Offset(8, 8))],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 16),
        child: Column(
          children: [
            _header(theme),
            const SizedBox(height: 16),
            if (compact)
              Column(
                children: [
                  SizedBox(height: playfieldHeight, child: _playfield(theme)),
                  const SizedBox(height: 16),
                  _sidebar(context, theme),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 290, child: _sidebar(context, theme)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: playfieldHeight,
                      child: _playfield(theme),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(_Game6Theme theme) {
    return _panel(
      theme,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GAME 6',
                  style: _text(
                    theme.accent,
                    13,
                    weight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  _config.title,
                  style: _text(
                    const Color(0xFF172033),
                    24,
                    weight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _topStat(theme, 'Level: ${_config.level}  ★'),
              _topStat(theme, 'Coins: $initialCoins'),
              _topStat(theme, 'Guidelines', enabled: false),
              _topStat(theme, 'Game Tutorial', enabled: false),
              _topStat(theme, 'Round: 0/${_config.targetWords}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topStat(_Game6Theme theme, String label, {bool enabled = true}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 138),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: enabled ? theme.chip : theme.card.withValues(alpha: .75),
        border: Border.all(color: theme.dark, width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.dark.withValues(alpha: .75),
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: _text(const Color(0xFF172033), 15, weight: FontWeight.w700),
      ),
    );
  }

  Widget _sidebar(BuildContext context, _Game6Theme theme) {
    final minutes = (_config.seconds ~/ 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(10),
      color: theme.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panel(
            theme,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: theme.heading,
                  child: Text(
                    'MISSION',
                    style: _text(Colors.white, 18, weight: FontWeight.w900),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _config.objective,
                    style: _text(
                      const Color(0xFF172033),
                      14,
                      weight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _miniStat(
                        theme,
                        '$minutes:00',
                        'Timer',
                        Icons.access_time,
                      ),
                      _miniStat(theme, '1', 'Speed', Icons.bolt),
                      _miniStat(theme, '0', 'Score', Icons.star),
                      _miniStat(
                        theme,
                        '${_config.lives}',
                        'Health',
                        Icons.favorite,
                      ),
                      _miniStat(
                        theme,
                        '0',
                        'Combo',
                        Icons.local_fire_department,
                      ),
                      _miniStat(theme, '×1', 'Multiplier', Icons.close),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _panel(
                    theme,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '♥  Goal',
                              style: _text(
                                const Color(0xFF172033),
                                13,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '0/${_config.targetWords}',
                              style: _text(
                                const Color(0xFF172033),
                                13,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dark, width: 2),
                            color: const Color(0xFFDCE9E5),
                          ),
                          child: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _panel(
                    theme,
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Text(
                        '🔥 0/3 STREAK',
                        style: _text(
                          const Color(0xFF92400E),
                          13,
                          weight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            theme,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'GUIDE',
                  style: _text(theme.accent, 18, weight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type the falling Java terms before they reach the bottom. This preview has no active gameplay yet.',
                  style: _text(
                    const Color(0xFF172033),
                    14,
                    weight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.chip,
                border: Border.all(color: theme.dark, width: 2),
                boxShadow: [
                  BoxShadow(color: theme.dark, offset: const Offset(4, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 19, color: theme.mid),
                  const SizedBox(width: 6),
                  Text(
                    'BACK',
                    style: _text(theme.mid, 18, weight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    _Game6Theme theme,
    String value,
    String label,
    IconData icon,
  ) {
    return SizedBox(
      width: 112,
      child: _panel(
        theme,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.accent),
            Text(
              value,
              style: _text(
                const Color(0xFF172033),
                18,
                weight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: _text(
                const Color(0xFF172033),
                11,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playfield(_Game6Theme theme) {
    final background =
        'assets/game6/backgrounds/syntax bg ${_config.level}.png';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dark, width: 4),
        boxShadow: [BoxShadow(color: theme.dark, offset: const Offset(7, 7))],
        image: DecorationImage(
          image: AssetImage(background),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          colorFilter: const ColorFilter.mode(
            Color.fromRGBO(255, 255, 255, .97),
            BlendMode.modulate,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: _panel(
                theme,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: Text(
                  _config.level == 5
                      ? 'FIND THE HIDDEN JAVA PAIR'
                      : 'FALLING SYNTAX CHALLENGE',
                  textAlign: TextAlign.center,
                  style: _text(
                    const Color(0xFF172033),
                    16,
                    weight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 145,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(minWidth: 150, maxWidth: 280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.bubble,
                  border: Border.all(color: theme.bubbleBorder, width: 2),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: theme.bubbleGlow,
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  'FALLING TERM PREVIEW',
                  textAlign: TextAlign.center,
                  style: _text(theme.bubbleText, 17, weight: FontWeight.w900),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: _answerPreview(theme),
          ),
        ],
      ),
    );
  }

  Widget _answerPreview(_Game6Theme theme) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.typingSurface,
        border: Border.all(color: theme.dark, width: 3),
        boxShadow: [BoxShadow(color: theme.dark, offset: const Offset(6, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            color: theme.dark,
            child: const Text(
              '>_',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'type a Java term (case-sensitive)...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              color: theme.accent,
              border: Border.all(color: theme.dark, width: 2),
              boxShadow: [
                BoxShadow(color: theme.dark, offset: const Offset(4, 4)),
              ],
            ),
            child: const Text(
              'ENTER',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(
    _Game6Theme theme, {
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.card,
        border: Border.all(color: theme.dark, width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.dark.withValues(alpha: .75),
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  TextStyle _text(
    Color color,
    double size, {
    FontWeight weight = FontWeight.normal,
    double letterSpacing = 0,
    double height = 1.15,
  }) {
    return TextStyle(
      // GameCanvasGameSix.css applies a system monospace stack to the shell.
      fontFamily: 'monospace',
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

class _Game6Gameplay extends StatefulWidget {
  const _Game6Gameplay({
    required this.config,
    required this.initialCoins,
    required this.compact,
    required this.playfieldHeight,
    required this.theme,
    required this.isTutorialLevel,
    required this.firstPlay,
  });

  final _Game6LevelConfig config;
  final bool firstPlay;
  final int initialCoins;
  final bool compact;
  final double playfieldHeight;
  final _Game6Theme theme;
  final bool isTutorialLevel;

  @override
  State<_Game6Gameplay> createState() => _Game6GameplayState();
}

class _Game6GameplayState extends State<_Game6Gameplay> {
  static const _lanes = <double>[12, 31, 50, 69, 88];
  static const _levelOneTerms = <String>[
    'String',
    'int',
    'boolean',
    'double',
    'class',
  ];
  static const _levelTwoTerms = <String>[
    'print',
    'String',
    'boolean',
    'double',
    'class',
  ];
  static const _levelThreeTargetTerms = <String>[
    'int',
    'double',
    'boolean',
    'String',
  ];
  static const _levelThreeDistractors = <String>['class', 'for', 'if'];
  static const _levelFourRealTerms = <String>[
    'int',
    'String',
    'boolean',
    'for',
  ];
  static const _levelFourFakeTerms = <String>['textVar', 'numbr', 'strng'];
  static const _levelFivePairs = <List<String>>[
    ['if', 'else'],
    ['try', 'catch'],
    ['class', 'object'],
    ['int', 'double'],
  ];

  final _random = math.Random();
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  Timer? _clockTimer;
  Timer? _movementTimer;
  Timer? _spawnTimer;
  Timer? _announcementTimer;
  final AudioPlayer _announcementAudio = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _effectPlayers = {
    'shared': AudioPlayer(),
    'correct': AudioPlayer(),
    'incorrect': AudioPlayer(),
    'combo-3': AudioPlayer(),
    'combo-5': AudioPlayer(),
    'combo-10': AudioPlayer(),
    'game-over': AudioPlayer(),
  };
  final Map<AudioPlayer, Future<void>> _audioOperations = {};
  bool _audioDisposed = false;
  bool _musicDesired = false;
  int _musicGeneration = 0;
  final List<_Game6Drop> _drops = [];
  int _timeLeft = 0;
  int _score = 0;
  int _coins = 0;
  int _cleared = 0;
  int _health = 0;
  int _mistakes = 0;
  int _streak = 0;
  int _nextTermIndex = 0;
  final Set<String> _foundPairs = <String>{};
  Future<void>? _coinLoadFuture;
  bool _coinsLoading = true;
  String _coinMessage = '';
  bool _resultSubmitted = false;
  bool _resultSaving = false;
  bool _resultSaved = false;
  bool _nextLevelAvailable = false;
  int _stars = 0;
  String _feedback = '';
  String _feedbackType = '';
  final String _targetCategory = 'Data Types';
  bool _running = false;
  bool _finished = false;
  int _elapsedSeconds = 0;
  bool _submitting = false;
  String? _instructionMode;
  int _storyPage = 0;
  int _guidePage = 0;
  int _tutorialStep = 0;
  int _tutorialAnimationTick = 0;
  Timer? _tutorialTimer;
  int _announcementSecond = 0;
  int _coachStep = 0;
  bool _introSequence = false;
  OverlayEntry? _instructionOverlayEntry;
  OverlayEntry? _resultsOverlayEntry;
  final GlobalKey _tutorialOverlayKey = GlobalKey();
  final GlobalKey _tutorialAnswerKey = GlobalKey();
  final GlobalKey _tutorialEnterKey = GlobalKey();
  final GlobalKey _tutorialTermKey = GlobalKey();
  final GlobalKey _tutorialHealthKey = GlobalKey();
  final GlobalKey _tutorialTimerKey = GlobalKey();
  final GlobalKey _tutorialScoreKey = GlobalKey();
  Rect? _tutorialHighlightRect;

  _Game6LevelConfig get _config => widget.config;
  _Game6Theme get _theme => widget.theme;

  double _finiteDimension(double value, [double fallback = 0]) {
    return value.isFinite && value >= 0 ? value : fallback;
  }

  double _finiteFraction(double value, [double fallback = 0]) {
    return value.isFinite ? value.clamp(0.0, 1.0).toDouble() : fallback;
  }

  int get _speedLevel => math.min(7, _config.level + (_cleared ~/ 3));

  int get _comboMultiplier {
    if (_streak >= 10) return 5;
    if (_streak >= 5) return 3;
    if (_streak >= 3) return 2;
    return 1;
  }

  int get _maxDrops => _config.level == 5 ? 4 : 1;

  int get _spawnIntervalMs {
    final progressBoost = _cleared ~/ 3;
    const byLevel = [2000, 2250, 1900, 1600, 1350];
    if (_config.level == 1) return 2000;
    return math.max(1050, byLevel[_config.level - 1] - (progressBoost * 110));
  }

  double get _fallSpeed {
    final progressBoost = _cleared ~/ 3;
    const byLevel = [.27, .22, .255, .22, .205];
    return byLevel[_config.level - 1] + (progressBoost * .016);
  }

  @override
  void initState() {
    super.initState();
    _timeLeft = _config.seconds;
    _health = _config.lives;
    _coins = math.max(0, widget.initialCoins);
    _coinLoadFuture = _loadCoins();
    _startRound();
    if (widget.isTutorialLevel) {
      _instructionMode = 'coach';
    } else if (widget.firstPlay && _config.level == 1) {
      _instructionMode = 'guide';
      _introSequence = true;
    } else {
      Future<void>.microtask(() {
        if (mounted) _beginAnnouncement();
      });
    }
  }

  Future<void> _loadCoins() async {
    final result = await GameCoinStorage.load();
    if (!mounted) return;
    setState(() {
      _coinsLoading = false;
      if (result.success) {
        _coins = result.balance;
        _coinMessage = '';
      } else {
        _coinMessage = result.message ?? 'Coin balance could not be loaded.';
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _movementTimer?.cancel();
    _spawnTimer?.cancel();
    _announcementTimer?.cancel();
    _tutorialTimer?.cancel();
    _audioDisposed = true;
    _musicDesired = false;
    _musicGeneration++;
    _announcementAudio.dispose();
    _musicPlayer.dispose();
    for (final player in _effectPlayers.values) {
      player.dispose();
    }
    _inputController.dispose();
    _inputFocusNode.dispose();
    _removeInstructionOverlay();
    _removeResultsOverlay();
    super.dispose();
  }

  void _startGameplay() {
    _clockTimer?.cancel();
    _movementTimer?.cancel();
    _spawnTimer?.cancel();
    _running = true;
    _startBackgroundMusic();
    _requestGameplayFocus();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running || !mounted) return;
      if (_timeLeft <= 1) {
        setState(() => _timeLeft = 0);
        _finish(false, 'Time expired before all terms were cleared.');
      } else {
        setState(() => _timeLeft--);
      }
    });
    _movementTimer = Timer.periodic(const Duration(milliseconds: 28), (_) {
      _moveDrops();
    });
    _spawnTimer = Timer.periodic(Duration(milliseconds: _spawnIntervalMs), (_) {
      if (_running) _spawnIfNeeded();
    });
  }

  void _pauseGameplay() {
    _running = false;
    _clockTimer?.cancel();
    _movementTimer?.cancel();
    _spawnTimer?.cancel();
    _inputFocusNode.unfocus();
    _pauseBackgroundMusic();
  }

  void _requestGameplayFocus() {
    if (!mounted || !_running || _finished || _instructionMode != null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_running || _finished || _instructionMode != null) {
        return;
      }
      if (!_inputFocusNode.hasFocus) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  void _resumeGameplay() {
    if (_finished || _instructionMode != null) return;
    _startGameplay();
  }

  void _openGuide() {
    _pauseGameplay();
    setState(() {
      _instructionMode = 'guide';
      _guidePage = 0;
      _introSequence = false;
    });
    _refreshInstructionOverlay();
  }

  void _ensureInstructionOverlay() {
    if (_instructionMode == null || _instructionOverlayEntry != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _instructionMode == null ||
          _instructionOverlayEntry != null) {
        return;
      }
      _inputFocusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      final entry = OverlayEntry(
        builder: (_) => Stack(
          fit: StackFit.expand,
          children: [
            const ModalBarrier(dismissible: false, color: Colors.transparent),
            _instructionOverlay(),
          ],
        ),
      );
      _instructionOverlayEntry = entry;
      Overlay.of(context, rootOverlay: true).insert(entry);
    });
  }

  void _refreshInstructionOverlay() {
    _instructionOverlayEntry?.markNeedsBuild();
  }

  void _removeInstructionOverlay() {
    final entry = _instructionOverlayEntry;
    _instructionOverlayEntry = null;
    entry?.remove();
  }

  void _ensureResultsOverlay() {
    if (!_finished || _resultsOverlayEntry != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_finished || _resultsOverlayEntry != null) return;
      _inputFocusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      final entry = OverlayEntry(
        builder: (_) => Stack(
          fit: StackFit.expand,
          children: [
            const ModalBarrier(dismissible: false, color: Colors.transparent),
            _finishPanel(),
          ],
        ),
      );
      _resultsOverlayEntry = entry;
      Overlay.of(context, rootOverlay: true).insert(entry);
    });
  }

  void _refreshResultsOverlay() {
    _resultsOverlayEntry?.markNeedsBuild();
  }

  void _removeResultsOverlay() {
    final entry = _resultsOverlayEntry;
    _resultsOverlayEntry = null;
    entry?.remove();
  }

  void _setGuidePage(int page) {
    setState(() => _guidePage = page);
    _refreshInstructionOverlay();
  }

  void _openInteractiveTutorial() {
    _pauseGameplay();
    setState(() {
      _instructionMode = 'interactive';
      _tutorialStep = 0;
      _tutorialHighlightRect = null;
    });
    _startTutorialAnimation();
    _refreshInstructionOverlay();
    _refreshTutorialHighlight();
  }

  void _startTutorialAnimation() {
    _tutorialTimer?.cancel();
    _tutorialAnimationTick = 0;
    _tutorialTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted || _instructionMode != 'interactive') return;
      setState(() => _tutorialAnimationTick++);
      _refreshInstructionOverlay();
      _refreshTutorialHighlight();
    });
  }

  void _stopTutorialAnimation() {
    _tutorialTimer?.cancel();
    _tutorialTimer = null;
    _tutorialAnimationTick = 0;
  }

  void _setTutorialStep(int step) {
    setState(() {
      _tutorialStep = step;
      _tutorialAnimationTick = 0;
      _tutorialHighlightRect = null;
    });
    _startTutorialAnimation();
    _refreshInstructionOverlay();
    _refreshTutorialHighlight();
  }

  int get _tutorialElapsedMs => _tutorialAnimationTick * 80;

  int get _tutorialCycleElapsedMs {
    final duration = _tutorialStepDurationMs;
    if (duration <= 0) return 0;
    return _tutorialElapsedMs % duration;
  }

  int get _tutorialStepDurationMs {
    switch (_tutorialStep) {
      case 1:
        return 3200 * (_tutorialAnswers.isEmpty ? 1 : _tutorialAnswers.length);
      case 2:
        return 2800;
      case 3:
        return 3200;
      default:
        return 3200;
    }
  }

  _Game6Drop? get _tutorialSampleDrop => _drops.isEmpty ? null : _drops.first;

  String get _tutorialAnswer => _tutorialSampleDrop?.answer ?? 'int';

  List<String> get _tutorialAnswers {
    if (_config.level == 2) return const ['print'];
    if (_config.level == 3 || _config.level == 4) return const ['int'];
    if (_config.level == 5) {
      final pair = _drops
          .where((drop) => drop.required && drop.pairId != null)
          .take(2)
          .map((drop) => drop.answer)
          .toList();
      return pair.length == 2 ? pair : const ['int', 'double'];
    }
    return [_tutorialAnswer];
  }

  String get _tutorialWrongCase {
    final answer = _tutorialAnswer;
    return answer == answer.toUpperCase()
        ? answer.toLowerCase()
        : answer.toUpperCase();
  }

  String get _tutorialPracticeRule {
    if (_config.level == 2) {
      return 'Fill in the missing letter: type the FULL term, print. This is a practice example.';
    }
    if (_config.level == 3) {
      return 'Practice target: Data Types. Type int. Ignore class. The target category can change in real play.';
    }
    if (_config.level == 4) {
      return 'Type real Java syntax: int. Ignore the fake syntax textVar.';
    }
    if (_config.level == 5) {
      return 'Find two related Java terms. Submit one, then the other; either order works. A round completes only after both are cleared.';
    }
    return 'Read the complete Java term. Type its spelling before it reaches the bottom in real play.';
  }

  GlobalKey _tutorialTargetKey() {
    switch (_tutorialStep) {
      case 0:
        return _tutorialTermKey;
      case 1:
        return _tutorialElapsedMs < 2100
            ? _tutorialAnswerKey
            : _tutorialEnterKey;
      case 2:
        return _tutorialElapsedMs < 1600
            ? _tutorialAnswerKey
            : _tutorialHealthKey;
      case 3:
        return _tutorialElapsedMs < 1600
            ? _tutorialHealthKey
            : _tutorialTimerKey;
      case 4:
        return _tutorialScoreKey;
      default:
        return _tutorialAnswerKey;
    }
  }

  void _refreshTutorialHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _instructionMode != 'interactive') return;
      final renderObject = _tutorialTargetKey().currentContext
          ?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final topLeft = renderObject.localToGlobal(Offset.zero);
      final next = topLeft & renderObject.size;
      if (_tutorialHighlightRect == next) return;
      setState(() => _tutorialHighlightRect = next);
      _refreshInstructionOverlay();
    });
  }

  void _beginAnnouncement() {
    if (_instructionMode == 'interactive' &&
        _introSequence &&
        _tutorialStep == 5) {
      unawaited(GameIntro.complete(5));
      _introSequence = false;
    }
    _pauseGameplay();
    _stopTutorialAnimation();
    _announcementTimer?.cancel();
    setState(() {
      _instructionMode = 'announcement';
      _announcementSecond = 0;
    });
    _refreshInstructionOverlay();
    _announcementTimer = Timer(const Duration(milliseconds: 5500), () {
      if (!mounted) return;
      _playAnnouncementBeep(3);
      setState(() => _announcementSecond = 3);
      _refreshInstructionOverlay();
      _announcementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final next = _announcementSecond - 1;
        if (next <= 0) {
          timer.cancel();
          _announcementTimer = Timer(const Duration(milliseconds: 350), () {
            if (!mounted) return;
            _removeInstructionOverlay();
            setState(() => _instructionMode = null);
            _resumeGameplay();
          });
          return;
        }
        _playAnnouncementBeep(next);
        setState(() => _announcementSecond = next);
        _refreshInstructionOverlay();
      });
    });
  }

  Future<void> _playAnnouncementBeep(int number) async {
    try {
      await _announcementAudio.play(
        AssetSource('game6/audio/beep-$number.mp3'),
      );
    } catch (_) {
      // Browser autoplay restrictions must not interrupt the challenge.
    }
  }

  Future<void> _queueAudio(
    AudioPlayer player,
    Future<void> Function() operation,
  ) {
    final previous = _audioOperations[player] ?? Future<void>.value();
    final next = previous.then((_) async {
      if (_audioDisposed) return;
      try {
        await operation();
      } catch (_) {
        // Browser autoplay and interrupted media operations must not stop play.
      }
    });
    _audioOperations[player] = next;
    next.whenComplete(() {
      if (identical(_audioOperations[player], next)) {
        _audioOperations.remove(player);
      }
    });
    return next;
  }

  Future<void> _startBackgroundMusic() async {
    if (_audioDisposed) return;
    _musicDesired = true;
    final generation = ++_musicGeneration;
    await _queueAudio(_musicPlayer, () async {
      if (_audioDisposed || !_musicDesired || generation != _musicGeneration) {
        return;
      }
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(.28);
      await _musicPlayer.play(AssetSource('game6/audio/game6.mp3'));
    });
  }

  Future<void> _pauseBackgroundMusic() async {
    if (!_musicDesired) return;
    _musicDesired = false;
    final generation = ++_musicGeneration;
    await _queueAudio(_musicPlayer, () async {
      if (_audioDisposed || generation != _musicGeneration) return;
      await _musicPlayer.pause();
    });
  }

  Future<void> _stopBackgroundMusic() async {
    _musicDesired = false;
    final generation = ++_musicGeneration;
    await _queueAudio(_musicPlayer, () async {
      if (_audioDisposed || generation != _musicGeneration) return;
      await _musicPlayer.stop();
    });
  }

  Future<void> _playEffect(String key, String asset) {
    final player = _effectPlayers[key];
    if (player == null || _audioDisposed || (!_running && key != 'game-over')) {
      return Future<void>.value();
    }
    return _queueAudio(player, () async {
      if (_audioDisposed || !_running) return;
      await player.play(AssetSource(asset));
    });
  }

  void _closeInstruction({bool startGameplay = true}) {
    if (_instructionMode == 'interactive' &&
        _introSequence &&
        _tutorialStep == 5) {
      unawaited(GameIntro.complete(5));
      _introSequence = false;
    }
    _announcementTimer?.cancel();
    _stopTutorialAnimation();
    _removeInstructionOverlay();
    setState(() {
      _instructionMode = null;
      _tutorialHighlightRect = null;
    });
    if (startGameplay) _resumeGameplay();
  }

  void _startRound() {
    _drops.clear();
    _spawnIfNeeded(force: true);
    if (_config.level == 5) {
      _spawnIfNeeded(force: true);
      _spawnIfNeeded(force: true);
      _spawnIfNeeded(force: true);
    }
  }

  void _spawnIfNeeded({bool force = false}) {
    if (!mounted ||
        _finished ||
        (!_running && !force) ||
        _drops.length >= _maxDrops) {
      return;
    }
    final blocked = _drops
        .where((drop) => drop.y < 24)
        .map((drop) => drop.lane)
        .toSet();
    final available = <int>[];
    for (var i = 0; i < _lanes.length; i++) {
      if (!blocked.contains(i)) available.add(i);
    }
    if (available.isEmpty) return;
    final lane = available[_random.nextInt(available.length)];
    final term = _nextTerm();
    _drops.add(
      _Game6Drop(
        id: '${DateTime.now().microsecondsSinceEpoch}-$_nextTermIndex',
        answer: term.answer,
        display: term.display,
        lane: lane,
        y: -12,
        speed:
            _fallSpeed +
            (_config.level == 3 ? .012 : _random.nextDouble() * .025),
        required: term.required,
        pairId: term.pairId,
      ),
    );
    if (mounted) setState(() {});
  }

  _LocalTerm _nextTerm() {
    final index = _nextTermIndex++;
    switch (_config.level) {
      case 2:
        final answer = _levelTwoTerms[index % _levelTwoTerms.length];
        final display = answer.length > 2
            ? '${answer.substring(0, answer.length ~/ 2)}_${answer.substring((answer.length ~/ 2) + 1)}'
            : answer;
        return _LocalTerm(answer: answer, display: display);
      case 3:
        if (index % 3 == 2) {
          return _LocalTerm(
            answer:
                _levelThreeDistractors[index ~/
                    3 %
                    _levelThreeDistractors.length],
            display:
                _levelThreeDistractors[index ~/
                    3 %
                    _levelThreeDistractors.length],
            required: false,
          );
        }
        final answer =
            _levelThreeTargetTerms[index ~/ 3 % _levelThreeTargetTerms.length];
        return _LocalTerm(answer: answer, display: answer);
      case 4:
        if (index % 3 == 2) {
          final fake =
              _levelFourFakeTerms[index ~/ 3 % _levelFourFakeTerms.length];
          return _LocalTerm(answer: fake, display: fake, required: false);
        }
        final answer =
            _levelFourRealTerms[index ~/ 3 % _levelFourRealTerms.length];
        return _LocalTerm(answer: answer, display: answer);
      case 5:
        final pair =
            _levelFivePairs[(_cleared + index) % _levelFivePairs.length];
        final member = pair[index % 2];
        return _LocalTerm(
          answer: member,
          display: member,
          pairId: pair.join(':'),
        );
      default:
        final answer = _levelOneTerms[index % _levelOneTerms.length];
        return _LocalTerm(answer: answer, display: answer);
    }
  }

  void _moveDrops() {
    if (!mounted || !_running || _finished) return;
    var changed = false;
    final missed = <_Game6Drop>[];
    for (final drop in _drops) {
      drop.y += drop.speed * (_config.level == 5 ? 1.55 : 1.4);
      changed = true;
      if (drop.y >= 94) missed.add(drop);
    }
    if (missed.isNotEmpty) {
      for (final drop in missed) {
        _drops.remove(drop);
        if (drop.required) {
          _applyMistake('Missed required term: ${drop.display}.');
        }
      }
    }
    if (changed && mounted) setState(() {});
  }

  void _applyMistake(String message) {
    _mistakes++;
    _health = math.max(0, _config.lives - _mistakes);
    _streak = 0;
    _feedback = _health == 0 ? 'System failed. $message' : message;
    _feedbackType = 'incorrect';
    _playEffect('incorrect', 'game6/audio/incorrect-answer.mp3');
    if (_health == 0) _finish(false, _feedback);
  }

  Future<void> _awardMilestoneCoins() async {
    if (_coinLoadFuture != null) await _coinLoadFuture;
    final reward = 15 + (_config.level * 5);
    final result = await GameCoinStorage.add(reward);
    if (!mounted) return;
    if (result.success) {
      _coins = result.balance;
      _coinMessage = '';
    } else {
      _coinMessage = result.message ?? 'Coin reward could not be saved.';
    }
  }

  Future<void> _submitAnswer() async {
    if (_submitting || !_running || _finished) return;
    final answer = _inputController.text.trim();
    if (answer.isEmpty) return;
    final target = _leadingRequiredDrop();
    if (target == null) {
      _inputController.clear();
      _requestGameplayFocus();
      return;
    }
    setState(() {
      _submitting = true;
      _feedback = 'Checking answer...';
      _feedbackType = 'pending';
    });
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    // The active React client sends the typed value unchanged, and its
    // tutorial explicitly teaches that capitalization matters.
    final correct = answer == target.answer;
    if (!correct) {
      _applyMistake(
        target.required
            ? 'Incorrect term. You lost 1 health.'
            : 'That word should be ignored.',
      );
      _feedbackType = 'incorrect';
      _inputController.clear();
      _submitting = false;
      if (mounted) setState(() {});
      _requestGameplayFocus();
      return;
    }
    _playEffect('correct', 'game6/audio/correct-answer.mp3');
    _drops.remove(target);
    if (_config.level == 5 &&
        target.pairId != null &&
        !_foundPairs.contains(target.pairId)) {
      _foundPairs.add(target.pairId!);
      _feedback = '✓ ${target.answer} — 1/2 FOUND';
      _feedbackType = 'correct';
      _inputController.clear();
      _submitting = false;
      _spawnPairMate(target.pairId!, target.answer);
      if (mounted) setState(() {});
      _requestGameplayFocus();
      return;
    }
    if (_config.level == 5 && target.pairId != null) {
      _foundPairs.remove(target.pairId);
    }
    _cleared++;
    _streak++;
    final points = 100 * _comboMultiplier;
    _score += points;
    final isFinalClear = _cleared >= _config.targetWords;
    if (!isFinalClear) {
      _playEffect('shared', 'game6/audio/soundeffects.mp3');
    }
    var reward = false;
    if (_streak % 3 == 0) {
      reward = true;
      await _awardMilestoneCoins();
      if (!mounted) return;
      if (_health < _config.lives) _health++;
    }
    if (_streak == 3) {
      _playEffect('combo-3', 'game6/audio/combo_3_x2.mp3');
    } else if (_streak == 5) {
      _playEffect('combo-5', 'game6/audio/combo_5_x3.mp3');
    } else if (_streak == 10) {
      _playEffect('combo-10', 'game6/audio/combo_10_x5.mp3');
    }
    _feedback = _config.level == 5
        ? 'PAIR COMPLETE! +$points points. Pair $_cleared/${_config.targetWords}.'
        : 'Correct! +$points points. Round $_cleared/${_config.targetWords}.';
    if (reward) {
      _feedback =
          '$_feedback Reward streak: +${15 + (_config.level * 5)} coins.';
    }
    _feedbackType = 'correct';
    _inputController.clear();
    _submitting = false;
    if (_cleared >= _config.targetWords) {
      _finish(true, 'Level complete.');
    } else {
      _spawnIfNeeded(force: true);
      if (mounted) setState(() {});
      _requestGameplayFocus();
    }
  }

  void _spawnPairMate(String pairId, String answered) {
    if (_drops.length >= _maxDrops) return;
    final pair = _levelFivePairs.firstWhere(
      (candidate) => candidate.join(':') == pairId,
      orElse: () => const ['if', 'else'],
    );
    final answer = pair.firstWhere(
      (member) => member != answered,
      orElse: () => pair.first,
    );
    final blocked = _drops.map((drop) => drop.lane).toSet();
    final available = <int>[];
    for (var i = 0; i < _lanes.length; i++) {
      if (!blocked.contains(i)) available.add(i);
    }
    final lane = available.isEmpty
        ? _random.nextInt(_lanes.length)
        : available[_random.nextInt(available.length)];
    _drops.add(
      _Game6Drop(
        id: '${DateTime.now().microsecondsSinceEpoch}-pair',
        answer: answer,
        display: answer,
        lane: lane,
        y: -12,
        speed: _fallSpeed + _random.nextDouble() * .025,
        required: true,
        pairId: pairId,
      ),
    );
  }

  _Game6Drop? _leadingRequiredDrop() {
    final required = _drops.where((drop) => drop.required).toList();
    if (required.isEmpty) return null;
    required.sort((a, b) => b.y.compareTo(a.y));
    return required.first;
  }

  void _finish(bool success, String message) {
    if (_finished) return;
    _running = false;
    _finished = true;
    _elapsedSeconds = math.max(0, _config.seconds - _timeLeft);
    _stars = success ? 3 : 0;
    _feedback = message;
    _feedbackType = success ? 'correct' : 'incorrect';
    _clockTimer?.cancel();
    _movementTimer?.cancel();
    _spawnTimer?.cancel();
    _inputFocusNode.unfocus();
    _stopBackgroundMusic();
    if (!success) {
      _playEffect('game-over', 'game6/audio/game-over-sfx.mp3');
    }
    if (mounted) setState(() {});
    _ensureResultsOverlay();
    _submitResultOnce(success);
  }

  Future<void> _submitResultOnce(bool success) async {
    if (_resultSubmitted) return;
    _resultSubmitted = true;
    _resultSaving = true;
    if (mounted) setState(() {});
    _refreshResultsOverlay();

    final userAvailable = AllUsers.activeUser != null;
    final saved = userAvailable
        ? await GameData.recordLevelResult(
            game: 5,
            number: _config.level,
            score: _score,
            stars: _stars,
            completed: success,
            unlockStarRequirement: 1,
          )
        : false;

    var nextAvailable = false;
    if (saved && success && _config.level < 5) {
      final next = GameData.level(5, _config.level + 1);
      nextAvailable = next['status'] == 'Ready' || next['status'] == 'Cleared';
    }
    if (!mounted) return;
    setState(() {
      _resultSaving = false;
      _resultSaved = saved;
      _nextLevelAvailable = nextAvailable;
      if (!saved && userAvailable) {}
    });
    _refreshResultsOverlay();
  }

  void _retry() {
    _removeResultsOverlay();
    _clockTimer?.cancel();
    _movementTimer?.cancel();
    _spawnTimer?.cancel();
    setState(() {
      _timeLeft = _config.seconds;
      _score = 0;
      _cleared = 0;
      _health = _config.lives;
      _mistakes = 0;
      _streak = 0;
      _nextTermIndex = 0;
      _foundPairs.clear();
      _feedback = '';
      _feedbackType = '';
      _finished = false;
      _submitting = false;
      _resultSubmitted = false;
      _resultSaving = false;
      _resultSaved = false;
      _nextLevelAvailable = false;
      _stars = 0;
      _drops.clear();
      _running = true;
    });
    _startRound();
    _startGameplay();
  }

  @override
  Widget build(BuildContext context) {
    _ensureInstructionOverlay();
    _ensureResultsOverlay();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _theme.shell,
        border: Border.all(color: _theme.dark, width: 3),
        boxShadow: [BoxShadow(color: _theme.dark, offset: const Offset(8, 8))],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(widget.compact ? 10 : 16),
            child: Column(
              children: [
                _header(),
                const SizedBox(height: 16),
                if (widget.compact)
                  Column(
                    children: [
                      SizedBox(
                        height: widget.playfieldHeight,
                        child: _playfield(),
                      ),
                      const SizedBox(height: 16),
                      _sidebar(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 290, child: _sidebar()),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: widget.playfieldHeight,
                          child: _playfield(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return _panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GAME 6',
                style: _text(
                  _theme.accent,
                  14,
                  weight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              Text(
                _config.title,
                style: _text(
                  const Color(0xFF172033),
                  24,
                  weight: FontWeight.w900,
                ),
              ),
            ],
          );
          final stats = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: narrow ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _topStat('Level: ${_config.level}  ★'),
              _topStat(_coinsLoading ? 'Coins: ...' : 'Coins: $_coins'),
              _topStat('Guidelines', onTap: _openGuide),
              _topStat('Game Tutorial', onTap: _openInteractiveTutorial),
              _topStat('Round: $_cleared/${_config.targetWords}'),
            ],
          );

          return narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [title, const SizedBox(height: 10), stats],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 12),
                    Flexible(child: stats),
                  ],
                );
        },
      ),
    );
  }

  Widget _topStat(String label, {bool enabled = true, VoidCallback? onTap}) {
    final child = Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: enabled ? _theme.chip : _theme.card.withValues(alpha: .75),
        border: Border.all(color: _theme.dark, width: 2),
        boxShadow: [
          BoxShadow(
            color: _theme.dark.withValues(alpha: .75),
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: _text(const Color(0xFF172033), 14, weight: FontWeight.w700),
      ),
    );
    return onTap == null ? child : GestureDetector(onTap: onTap, child: child);
  }

  Widget _sidebar() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: _theme.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: _theme.heading,
                  child: Text(
                    'MISSION',
                    style: _text(Colors.white, 18, weight: FontWeight.w900),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _mission,
                    style: _text(
                      const Color(0xFF172033),
                      14,
                      weight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _miniStat(
                        '${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
                        'Timer',
                        Icons.access_time,
                        highlight:
                            _instructionMode == 'interactive' &&
                            _tutorialStep == 3 &&
                            _tutorialElapsedMs >= 1600,
                      ),
                      _miniStat('$_speedLevel', 'Speed', Icons.bolt),
                      _miniStat(
                        '$_score',
                        'Score',
                        Icons.star,
                        highlight:
                            _instructionMode == 'interactive' &&
                            _tutorialStep == 4,
                      ),
                      _miniStat(
                        '$_health',
                        'Health',
                        Icons.favorite,
                        highlight:
                            _instructionMode == 'interactive' &&
                            _tutorialStep == 2 &&
                            _tutorialElapsedMs >= 1600,
                      ),
                      _miniStat(
                        '$_streak',
                        'Combo',
                        Icons.local_fire_department,
                      ),
                      _miniStat(
                        '×$_comboMultiplier',
                        'Multiplier',
                        Icons.close,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _panel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '♥  Goal',
                              style: _text(
                                const Color(0xFF172033),
                                13,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$_cleared/${_config.targetWords}',
                              style: _text(
                                const Color(0xFF172033),
                                13,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(color: _theme.dark, width: 2),
                            color: const Color(0xFFDCE9E5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_cleared / _config.targetWords).clamp(
                              0,
                              1,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: _theme.accent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _panel(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Text(
                        '🔥 $_streak/3 STREAK',
                        style: _text(
                          const Color(0xFF92400E),
                          13,
                          weight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'GUIDE',
                  style: _text(_theme.accent, 18, weight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  _guide,
                  style: _text(
                    const Color(0xFF172033),
                    14,
                    weight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (_coinMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _coinMessage,
                    style: _text(
                      const Color(0xFF9A3412),
                      11,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _theme.chip,
                border: Border.all(color: _theme.dark, width: 2),
                boxShadow: [
                  BoxShadow(color: _theme.dark, offset: const Offset(4, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 19, color: _theme.mid),
                  const SizedBox(width: 6),
                  Text(
                    'BACK',
                    style: _text(_theme.mid, 18, weight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _mission {
    switch (_config.level) {
      case 2:
        return 'Identify each incomplete programming term and type its full correct spelling.';
      case 3:
        return 'Type only words that belong to the $_targetCategory category.';
      case 4:
        return 'Type the real Java syntax and ignore the believable fake syntax.';
      case 5:
        return 'Discover the hidden relationship and type both matching Java terms.';
      default:
        return 'Type each correctly spelled Java term before it reaches the bottom.';
    }
  }

  String get _guide {
    switch (_config.level) {
      case 2:
        return 'Use the visible letters to identify each incomplete syntax word, then type its full correct spelling.';
      case 3:
        return 'Type only words belonging to the visible target category. Ignore programming distractors.';
      case 4:
        return 'Type required real Java syntax and ignore believable fake syntax. Wrong entries cost 1 health.';
      case 5:
        return 'Find two terms with a hidden Java relationship. Either member may be typed first.';
      default:
        return 'Type each correctly spelled Java term before it reaches the bottom. Correct answers build combo multipliers; mistakes reset the combo.';
    }
  }

  Widget _miniStat(
    String value,
    String label,
    IconData icon, {
    bool highlight = false,
  }) {
    final stat = SizedBox(
      key: switch (label) {
        'Health' => _tutorialHealthKey,
        'Timer' => _tutorialTimerKey,
        'Score' => _tutorialScoreKey,
        _ => null,
      },
      width: 112,
      child: _panel(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: _theme.accent),
            Text(
              value,
              style: _text(
                const Color(0xFF172033),
                18,
                weight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: _text(
                const Color(0xFF172033),
                11,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
    return highlight
        ? DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFE08B), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55EFBE57),
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: stat,
          )
        : stat;
  }

  Widget _playfield() {
    final background =
        'assets/game6/backgrounds/syntax bg ${_config.level}.png';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _theme.dark, width: 4),
        boxShadow: [BoxShadow(color: _theme.dark, offset: const Offset(7, 7))],
        image: DecorationImage(
          image: AssetImage(background),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = _finiteDimension(constraints.maxWidth);
          final height = _finiteDimension(constraints.maxHeight);
          const topBoundary = 72.0;
          const bottomBoundary = 86.0;
          return Stack(
            children: [
              Positioned(
                top: topBoundary,
                left: 0,
                right: 0,
                bottom: bottomBoundary,
                child: ClipRect(
                  child: _instructionMode == 'interactive'
                      ? _tutorialPlayfieldDemo(
                          width,
                          height,
                          topOffset: topBoundary,
                        )
                      : Stack(
                          children: [
                            for (final drop in _drops)
                              _fallingDrop(
                                drop,
                                width,
                                height,
                                topOffset: topBoundary,
                              ),
                          ],
                        ),
                ),
              ),
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Center(
                  child: _panel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    child: Text(
                      _config.level == 5
                          ? 'FIND THE HIDDEN JAVA PAIR'
                          : _config.level == 3
                          ? '🎯 TARGET: $_targetCategory'
                          : 'FALLING SYNTAX CHALLENGE',
                      textAlign: TextAlign.center,
                      style: _text(
                        const Color(0xFF172033),
                        16,
                        weight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ),
              ),
              if (_feedback.isNotEmpty)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 90,
                  child: _feedbackPanel(),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 20,
                child: _instructionMode == 'interactive'
                    ? _tutorialAnswerForm()
                    : _answerForm(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _fallingDrop(
    _Game6Drop drop,
    double width,
    double height, {
    double topOffset = 0,
  }) {
    final safeWidth = _finiteDimension(width);
    final safeHeight = _finiteDimension(height);
    final safeY = drop.y.isFinite ? drop.y : 0.0;
    final left = (drop.lane >= 0 && drop.lane < _lanes.length)
        ? _lanes[drop.lane]
        : 50.0;
    final dropWidth = math.min(280.0, math.max(150.0, safeWidth * .72));
    final leftPosition = math.max(
      12.0,
      math.min(
        math.max(12.0, safeWidth - dropWidth - 12.0),
        safeWidth * left / 100 - dropWidth / 2,
      ),
    );
    return Positioned(
      left: leftPosition,
      top: safeHeight * safeY / 100 - topOffset,
      width: dropWidth,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _theme.bubble,
          border: Border.all(color: _theme.bubbleBorder, width: 2),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _theme.bubbleGlow,
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          drop.display,
          textAlign: TextAlign.center,
          style: _text(_theme.bubbleText, 17, weight: FontWeight.w900),
        ),
      ),
    );
  }

  List<_Game6TutorialDrop> _tutorialDrops() {
    final answers = _tutorialAnswers;
    final displays = switch (_config.level) {
      2 => const ['pr_nt'],
      3 || 4 => const ['int'],
      _ => answers,
    };
    final phase = (_tutorialStep == 0 || _tutorialStep == 1)
        ? _tutorialCycleElapsedMs / 3200
        : .12;
    final source = List.generate(
      displays.length,
      (index) => _Game6TutorialDrop(
        display: displays[index],
        x: 30 + index * 30,
        y: 8 + phase * 78,
      ),
    );
    if (_tutorialStep != 1) return source;

    final stepAnswers = _tutorialAnswers;
    final index = math.min(
      stepAnswers.length - 1,
      _tutorialCycleElapsedMs ~/ 3200,
    );
    final answerPhase = _tutorialCycleElapsedMs - index * 3200;
    return answerPhase >= 2700 ? const <_Game6TutorialDrop>[] : source;
  }

  String _tutorialTypedValue() {
    if (_tutorialStep != 1) {
      return _tutorialStep == 2 && _tutorialElapsedMs >= 700
          ? _tutorialWrongCase
          : '';
    }
    final answers = _tutorialAnswers;
    final cycleElapsed = _tutorialCycleElapsedMs;
    final index = math.min(answers.length - 1, cycleElapsed ~/ 3200);
    final answer = answers[index];
    final phase = cycleElapsed - index * 3200;
    if (phase >= 2700) return '';
    final length = ((phase - 300) / (1500 / answer.length)).floor().clamp(
      0,
      answer.length,
    );
    return answer.substring(0, length);
  }

  Widget _tutorialPlayfieldDemo(
    double width,
    double height, {
    double topOffset = 0,
  }) {
    final drops = _tutorialDrops();
    final safeWidth = _finiteDimension(width);
    final safeHeight = _finiteDimension(height);
    return Stack(
      children: [
        for (var index = 0; index < drops.length; index++)
          index == 0
              ? KeyedSubtree(
                  key: _tutorialTermKey,
                  child: _tutorialFallingDrop(
                    drops[index],
                    safeWidth,
                    safeHeight,
                    topOffset: topOffset,
                  ),
                )
              : _tutorialFallingDrop(
                  drops[index],
                  safeWidth,
                  safeHeight,
                  topOffset: topOffset,
                ),
      ],
    );
  }

  Widget _tutorialFallingDrop(
    _Game6TutorialDrop drop,
    double width,
    double height, {
    double topOffset = 0,
  }) {
    final safeWidth = _finiteDimension(width);
    final safeHeight = _finiteDimension(height);
    final dropWidth = math.min(280.0, math.max(150.0, safeWidth * .72));
    final leftPosition = math.max(
      12.0,
      math.min(
        math.max(12.0, safeWidth - dropWidth - 12.0),
        safeWidth * drop.x / 100 - dropWidth / 2,
      ),
    );
    return Positioned(
      left: leftPosition,
      top: safeHeight * drop.y / 100 - topOffset,
      width: dropWidth,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _theme.bubble,
          border: Border.all(color: _theme.bubbleBorder, width: 2),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _theme.bubbleGlow,
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          drop.display,
          textAlign: TextAlign.center,
          style: _text(_theme.bubbleText, 17, weight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _tutorialAnswerForm() {
    final typed = _tutorialTypedValue();
    final enterActive =
        _tutorialStep == 1 &&
        _tutorialCycleElapsedMs >= 2100 &&
        _tutorialCycleElapsedMs < 2650;
    return Container(
      key: _tutorialAnswerKey,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _theme.typingSurface,
        border: Border.all(color: _theme.dark, width: 3),
        boxShadow: [BoxShadow(color: _theme.dark, offset: const Offset(6, 6))],
      ),
      child: Row(
        children: [
          Text('>_', style: _text(_theme.accent, 17, weight: FontWeight.w900)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              typed,
              style: _text(Colors.white, 17, weight: FontWeight.w700),
            ),
          ),
          Container(
            key: _tutorialEnterKey,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: enterActive ? const Color(0xFFB0F0BB) : _theme.accent,
            child: Text(
              'Enter',
              style: _text(Colors.white, 15, weight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _feedbackType == 'correct'
            ? const Color(0xFFD7F5DF)
            : const Color(0xFFFFE0E0),
        border: Border.all(color: _theme.dark, width: 2),
      ),
      child: Text(
        _feedback,
        textAlign: TextAlign.center,
        style: _text(_theme.dark, 13, weight: FontWeight.w800),
      ),
    );
  }

  Widget _answerForm() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _theme.typingSurface,
        border: Border.all(color: _theme.dark, width: 3),
        boxShadow: [BoxShadow(color: _theme.dark, offset: const Offset(6, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            color: _theme.dark,
            child: const Text(
              '>_',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              enabled: _running && !_finished,
              onSubmitted: (_) => _submitAnswer(),
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'type a Java term...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _running && !_finished ? _submitAnswer : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: BoxDecoration(
                color: _theme.accent,
                border: Border.all(color: _theme.dark, width: 2),
                boxShadow: [
                  BoxShadow(color: _theme.dark, offset: const Offset(4, 4)),
                ],
              ),
              child: Text(
                _submitting ? '...' : 'ENTER',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _finishPanel() {
    final success = _cleared >= _config.targetWords;
    final resultMetrics = <ResultMetric>[
      ResultMetric(
        label: 'Stars',
        value: _resultSaving ? '...' : '$_stars',
        icon: Icons.star,
      ),
      ResultMetric(
        label: 'Outputs',
        value: '$_cleared/${_config.targetWords}',
        icon: Icons.circle_outlined,
      ),
      ResultMetric(
        label: 'Mistakes',
        value: '$_mistakes',
        icon: Icons.gps_fixed,
      ),
      ResultMetric(
        label: 'Time',
        value:
            '${_elapsedSeconds ~/ 60}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
        icon: Icons.alarm,
      ),
      ResultMetric(
        label: 'Score',
        value: _resultSaving ? '...' : '$_score',
        icon: Icons.emoji_events,
      ),
    ];
    return GameCompletionFlow(
      successful: success,
      child: IllustratedResultsOverlay(
        background: 'assets/results/results-frame.png',
        metrics: resultMetrics,
        canAdvance: _nextLevelAvailable && !_resultSaving,
        saving: _resultSaving,
        onNext: _openNextLevel,
        onRetry: _retry,
        onBack: () => Navigator.maybePop(context),
        retryLabel: success ? 'Play Again' : 'Retry Level',
        forceHorizontalFooter: true,
      ),
    );
  }

  Widget _illustratedGame6Result({
    required String background,
    required List<List<String>> metrics,
    required bool canAdvance,
    required bool saving,
    required VoidCallback onNext,
    required VoidCallback onRetry,
    required VoidCallback onBack,
    required String retryLabel,
  }) {
    return Container(
      color: const Color(0xCC020617),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final resultTextSize = math.max(
            9.0,
            math.min(13.0, constraints.maxWidth * .028),
          );
          final resultButtonHeight = math.max(
            38.0,
            math.min(44.0, constraints.maxWidth * .10),
          );
          final resultButtonTextSize = math.max(
            8.0,
            math.min(11.0, constraints.maxWidth * .025),
          );
          final width = math.min(
            410.0,
            math.min(
              constraints.maxWidth * .94,
              constraints.maxHeight * .92 * .85,
            ),
          );
          final height = width * 482 / 410;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: math.max(1, width),
              height: math.max(1, height),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(background, fit: BoxFit.fill),
                  ),
                  Positioned(
                    left: width * .15,
                    right: width * .15,
                    top: height * .26,
                    bottom: height * .17,
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: width * .19,
                              right: width * .03,
                            ),
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < metrics.length;
                                  index++
                                )
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: index < metrics.length - 1
                                            ? const Border(
                                                bottom: BorderSide(
                                                  color: Color(0x664B2816),
                                                  width: .7,
                                                ),
                                              )
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              metrics[index][0].toUpperCase(),
                                              style: TextStyle(
                                                color: const Color(0xFF4B2816),
                                                fontSize: resultTextSize,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            metrics[index][1],
                                            style: TextStyle(
                                              color: const Color(0xFF4B2816),
                                              fontSize: resultTextSize,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: resultButtonHeight,
                          child: saving
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  children: [
                                    if (canAdvance)
                                      Expanded(
                                        child: _illustratedGame6Button(
                                          'Next Level',
                                          onNext,
                                          const Color(0xFF166534),
                                          resultButtonTextSize,
                                        ),
                                      ),
                                    if (canAdvance) const SizedBox(width: 4),
                                    Expanded(
                                      child: _illustratedGame6Button(
                                        retryLabel,
                                        onRetry,
                                        canAdvance
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF166534),
                                        resultButtonTextSize,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: _illustratedGame6Button(
                                        'Back To Levels',
                                        onBack,
                                        const Color(0xFF475569),
                                        resultButtonTextSize,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _illustratedGame6Button(
    String label,
    VoidCallback onPressed,
    Color color,
    double textSize,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: const Color(0xFF14532D), width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontSize: textSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _instructionOverlay() {
    switch (_instructionMode) {
      case 'story':
        return _storyOverlay();
      case 'guide':
        return _guideOverlay();
      case 'interactive':
        return _interactiveTutorialOverlay();
      case 'coach':
        return _playableTutorialOverlay();
      case 'announcement':
        return _announcementOverlay();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _overlayFrame({required Widget child, bool dark = true}) {
    final viewport = MediaQuery.sizeOf(context);
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        height: viewport.height,
        child: Material(
          color: dark ? const Color(0xCC071B25) : Colors.transparent,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 920,
                    maxHeight: viewport.height - 28,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _storyOverlay() {
    final story = 'assets/game6/story/l${_storyPage + 1}.png';
    return _instructionViewport(
      child: StudentStoryFrame(
        imagePath: story,
        worldTitle: 'THE BLIZZARD TERMINAL',
        page: _storyPage,
        totalPages: 8,
        onBack: _storyPage == 0
            ? () {}
            : () {
                setState(() => _storyPage--);
                _refreshInstructionOverlay();
              },
        onNext: () {
          setState(() => _storyPage++);
          _refreshInstructionOverlay();
        },
        onSkip: () {
          setState(() {
            _instructionMode = 'guide';
            _guidePage = 0;
          });
          _refreshInstructionOverlay();
        },
        onPrimary: () {
          setState(() {
            _instructionMode = 'guide';
            _guidePage = 0;
          });
          _refreshInstructionOverlay();
        },
      ),
    );
  }

  Widget _guideOverlay() {
    final guideItems = <String>[
      _config.objective,
      'Clear ${_config.targetWords} Java types within ${_config.seconds} seconds.',
      'You have ${_config.lives} health and earn a reward every 3 consecutive clears.',
      _config.level == 1
          ? 'Read the correctly spelled falling Java term and type that exact word before it reaches the bottom.'
          : _config.level == 5
          ? 'Study the falling terms and identify the two that share a hidden Java relationship. The category is never displayed.'
          : 'Read the falling challenge and type the required complete Java answer before it reaches the bottom.',
      _config.level == 1
          ? 'Level 1 uses a steady, slightly faster falling speed with normally spelled Java terms.'
          : _config.level == 5
          ? 'Either pair member may be typed first. Early rounds have one distractor; later rounds add more distractors and two independent pairs.'
          : 'Only type the required Java answer shown by the current challenge rules.',
      'Every 3 consecutive clears awards coins and restores 1 missing health.',
      _config.level == 1
          ? 'Each correct Java term earns base points and increases the combo multiplier.'
          : 'Each correctly completed Java challenge earns game points.',
      'Every 3-term reward streak awards ${15 + (_config.level * 5)} coins separately; coins are not added to the game score.',
      'The backend verifies the score as correct terms × 100 (${_config.targetWords * 100} maximum before the retry multiplier).',
      'Completing every required term reports 3 Stars.',
      'An incomplete or failed run reports no completion Stars.',
      'This attempt randomly selects ${_config.targetWords} terms from the Level ${_config.level} pool.',
      _config.level == 1
          ? 'Type the normally spelled term exactly as displayed. Answers are case-sensitive: match uppercase and lowercase letters.'
          : 'Type the complete required term. Answers are case-sensitive: match uppercase and lowercase letters.',
    ];
    final splitIndex = (guideItems.length / 2).ceil();
    final pageOne = guideItems.take(splitIndex).toList();
    final pageTwo = guideItems.skip(splitIndex).toList();
    final items = _guidePage == 0 ? pageOne : pageTwo;
    return _guideViewport(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = _finiteDimension(constraints.maxWidth, 360);
          final viewportHeight = _finiteDimension(constraints.maxHeight, 640);
          final portrait = viewportHeight > viewportWidth;
          const portraitAspect = 1206 / 1304;
          final boardWidth = portrait
              ? math.min(viewportWidth, viewportHeight * portraitAspect)
              : math.min(viewportWidth * .96, viewportHeight * 1.72);
          final boardHeight = portrait
              ? math.min(viewportHeight, viewportWidth / portraitAspect)
              : math.min(viewportHeight * .96, viewportWidth / 1.72);
          final contentLeft = portrait ? .165 : .16;
          final contentTop = portrait ? .26 : .19;
          final contentWidth = portrait ? .67 : .68;
          final contentHeight = portrait ? .525 : .58;
          final footerLeft = portrait ? .14 : .13;
          final footerWidth = portrait ? .72 : .74;
          final footerBottom = portrait ? .116 : .05;
          final footerHeight = portrait
              ? boardHeight * .082
              : boardHeight * .18;
          final textSize = portrait
              ? (viewportWidth * .0272).clamp(.54 * 16, .86 * 16).toDouble()
              : math.min(18, math.max(12, boardHeight * .03)).toDouble();
          final iconSize = portrait
              ? (viewportWidth * .06).clamp(1.28 * 16, 1.86 * 16).toDouble()
              : 26.0;
          return SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/guidelines/Guidelinesformobile.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                  ),
                ),
                if (!portrait)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: boardHeight * .045,
                    height: boardHeight * .10,
                    child: Text(
                      'GUIDELINES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: const Color(0xFFF8F1CF),
                        fontSize: math.min(
                          24,
                          math.max(15, boardHeight * .055),
                        ),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        shadows: const [
                          Shadow(
                            color: Color(0xFF2B170C),
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: boardWidth * contentLeft,
                  width: boardWidth * contentWidth,
                  top: boardHeight * contentTop,
                  height: boardHeight * contentHeight,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF397E35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_config.title} Guide',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: const Color(0xFFFFF8DA),
                            fontSize: portrait
                                ? textSize
                                : math.min(
                                    20,
                                    math.max(12, boardHeight * .032),
                                  ),
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Scrollbar(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(right: 5),
                            itemCount: items.length,
                            itemBuilder: (context, index) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFAD854C)),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    _game6GuideIcon(items[index]),
                                    width: iconSize,
                                    height: iconSize,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(
                                    width: portrait ? viewportWidth * .02 : 8,
                                  ),
                                  Expanded(
                                    child: Text(
                                      items[index],
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        color: const Color(0xFF392812),
                                        fontSize: textSize,
                                        fontWeight: FontWeight.w600,
                                        height: portrait ? 1.18 : 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: boardWidth * footerLeft,
                  width: boardWidth * footerWidth,
                  bottom: boardHeight * footerBottom,
                  height: footerHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _game6GuideButton(
                          _guidePage == 0 ? 'Exit' : 'Back',
                          _guidePage == 0
                              ? _closeInstruction
                              : () => _setGuidePage(_guidePage - 1),
                        ),
                      ),
                      SizedBox(width: boardWidth * .02),
                      SizedBox(
                        width: portrait
                            ? boardWidth * .20
                            : math.min(70, boardWidth * .12).toDouble(),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  2,
                                  (index) => Container(
                                    width: portrait ? 6 : 8,
                                    height: portrait ? 6 : 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == _guidePage
                                          ? const Color(0xFF55B843)
                                          : const Color(0xFF3C2A1D),
                                      border: Border.all(
                                        color: const Color(0xFF2A160A),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '${_guidePage + 1} / 2',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: const Color(0xFF24160C),
                                  fontSize: textSize,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: boardWidth * .02),
                      Expanded(
                        child: _game6GuideButton(
                          _guidePage == 1
                              ? (_introSequence ? 'Start Tutorial' : 'Start')
                              : 'Next',
                          _guidePage == 0
                              ? () => _setGuidePage(1)
                              : _introSequence
                              ? () {
                                  setState(() {
                                    _instructionMode = 'interactive';
                                    _tutorialStep = 0;
                                  });
                                  _startTutorialAnimation();
                                  _refreshInstructionOverlay();
                                }
                              : _closeInstruction,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _interactiveTutorialOverlay() {
    const titles = [
      'Read the falling term',
      'Type, then press Enter',
      'Capitalization matters',
      'Protect health and time',
      'Build a reward streak',
      'Ready for Syntax Rain?',
    ];
    final bodies = [
      _tutorialPracticeRule,
      'Match the spelling AND capitalization, then press Enter. Watch the answer appear in the real input.',
      '"$_tutorialWrongCase" does not match "$_tutorialAnswer". A wrong answer costs health in real play. This demo does not.',
      'Start with ${_config.lives} health and ${_config.seconds ~/ 60}:${(_config.seconds % 60).toString().padLeft(2, '0')}. Wrong answers and missed required terms cost health. Ignore distractors when instructed.',
      'Correct clears earn points and combo multipliers. Every 3 consecutive ${_config.level == 5 ? 'completed pairs' : 'correct terms'} awards coins and restores one missing health.',
      'Complete ${_config.targetWords} ${_config.level == 5 ? 'pairs' : 'required terms'} before health or time runs out. You can replay Game Tutorial anytime.',
    ];
    final targetRect = _tutorialHighlightRect;
    final duration = _tutorialStepDurationMs;
    final progress = duration == 0
        ? 0.0
        : _finiteFraction(_tutorialElapsedMs / duration);
    return _instructionViewport(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(
            _finiteDimension(constraints.maxWidth),
            _finiteDimension(constraints.maxHeight),
          );
          final panelWidth = math.min(
            520.0,
            math.max(0.0, viewport.width - 16),
          );
          final panelHeight = math.min(
            360.0,
            math.max(0.0, viewport.height - 16),
          );
          final panelOffset = _tutorialPanelOffset(
            viewport,
            Size(panelWidth, panelHeight),
            targetRect,
          );
          final compact = viewport.width <= 540 || viewport.height <= 540;
          return Stack(
            key: _tutorialOverlayKey,
            children: [
              if (targetRect != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  left: targetRect.left,
                  top: targetRect.top,
                  width: targetRect.width,
                  height: targetRect.height,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _tutorialStep == 2
                              ? const Color(0xFFF0A27D)
                              : const Color(0xFFFFE08B),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _tutorialStep == 2
                                ? const Color(0x66E57E53)
                                : const Color(0x80EFBE57),
                            blurRadius: _tutorialStep == 2 ? 12 : 18,
                            spreadRadius: _tutorialStep == 2 ? 0 : 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (targetRect != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.linear,
                  left:
                      targetRect.left +
                      targetRect.width *
                          ((_tutorialStep == 1 || _tutorialStep == 3)
                              ? .15 + progress * .55
                              : .72),
                  top:
                      targetRect.top +
                      ((_tutorialStep == 1 || _tutorialStep == 3)
                          ? targetRect.height * .38
                          : targetRect.height - 5),
                  width: 45,
                  height: 52,
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        math.sin((_tutorialElapsedMs / 260) * math.pi) * -3,
                      ),
                      child: Image.asset(
                        'assets/game6/tutorial/tutorial-hand.png',
                        width: 45,
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: panelOffset.dx,
                top: panelOffset.dy,
                width: panelWidth,
                height: panelHeight,
                child: _game6TutorialPanel(
                  width: panelWidth,
                  height: panelHeight,
                  compact: compact,
                  titles: titles,
                  bodies: bodies,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Offset _tutorialPanelOffset(Size viewport, Size panel, Rect? target) {
    final maxLeft = math.max(8.0, viewport.width - panel.width - 8);
    final maxTop = math.max(8.0, viewport.height - panel.height - 8);
    final candidates = <Offset>[
      const Offset(8, 8),
      Offset(maxLeft, 8),
      Offset(8, maxTop),
      Offset(maxLeft, maxTop),
    ];
    if (target == null) return candidates.first;
    final panelRects = candidates
        .map(
          (offset) =>
              Rect.fromLTWH(offset.dx, offset.dy, panel.width, panel.height),
        )
        .toList();
    final nonOverlapping = <int>[];
    for (var index = 0; index < panelRects.length; index++) {
      if (!panelRects[index].overlaps(target)) nonOverlapping.add(index);
    }
    return candidates[(nonOverlapping.isEmpty ? 0 : nonOverlapping.first)];
  }

  Widget _instructionViewport({required Widget child}) {
    final viewport = MediaQuery.sizeOf(context);
    final viewportHeight = _finiteDimension(viewport.height);
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        height: viewportHeight,
        child: Material(
          color: const Color(0xCC142726),
          child: SafeArea(child: SizedBox.expand(child: child)),
        ),
      ),
    );
  }

  Widget _guideViewport({required Widget child}) {
    final viewport = MediaQuery.sizeOf(context);
    final viewportHeight = _finiteDimension(viewport.height);
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: double.infinity,
        height: viewportHeight,
        child: Material(
          color: const Color(0xCC142726),
          child: SafeArea(
            child: Align(alignment: const Alignment(0, -0.16), child: child),
          ),
        ),
      ),
    );
  }

  String _game6GuideIcon(String text) {
    final value = text.toLowerCase();
    if (value.contains('time') || value.contains('second')) {
      return 'assets/guidelines/icon-move.png';
    }
    if (value.contains('health') || value.contains('life')) {
      return 'assets/guidelines/icon-heart.png';
    }
    if (value.contains('coin') || value.contains('reward')) {
      return 'assets/guidelines/icon-trophy.png';
    }
    if (value.contains('star')) {
      return 'assets/guidelines/icon-star.png';
    }
    return 'assets/guidelines/icon-dot.png';
  }

  Widget _game6GuideButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/game4/guidelines/buttons.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFFFFF8DE),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Color(0xFF24551D), offset: Offset(1, 2))],
            ),
          ),
        ),
      ),
    );
  }

  Widget _woodButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 30,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF56331E),
          backgroundColor: const Color(0xFFE6C28A),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: const BorderSide(color: Color(0xFF825731)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          shadowColor: const Color(0xFFA87742),
          elevation: 2,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _game6TutorialPanel({
    required double width,
    required double height,
    required bool compact,
    required List<String> titles,
    required List<String> bodies,
  }) {
    final isLast = _tutorialStep == 5;
    final contentPadding = compact
        ? const EdgeInsets.fromLTRB(34, 96, 34, 32)
        : const EdgeInsets.fromLTRB(46, 110, 46, 42);
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/game6/tutorial/tutorial4.png',
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          top: height * .14,
          right: width * .025,
          width: width * .10,
          height: height * .17,
          child: TextButton(
            onPressed: _closeInstruction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: Colors.transparent,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          top: height * .21,
          right: width * .12,
          child: Text(
            '${_tutorialStep + 1} / 6',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFFFFF4D9),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: contentPadding,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          titles[_tutorialStep],
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: compact ? 18 : 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF5C3D26),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bodies[_tutorialStep],
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: compact ? 14 : 15,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF563A24),
                          ),
                        ),
                        if (_tutorialStep == 0) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Demo examples use the same playfield. No real terms are submitted.',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              height: 1.5,
                              color: Color(0xFF795E43),
                            ),
                          ),
                        ],
                        if (_tutorialStep == 1 &&
                            _tutorialElapsedMs % 3200 >= 2100) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF5DB),
                                border: Border.all(color: Color(0xFF967047)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFA7804C),
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                child: Text(
                                  'Enter',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        const Text(
                          'Auto demo · real progress unchanged',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: Color(0xFF765B3E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _woodButton(
                      'Back',
                      _tutorialStep == 0
                          ? _closeInstruction
                          : () => _setTutorialStep(_tutorialStep - 1),
                    ),
                    _woodButton(
                      isLast ? 'Return to game' : 'Next',
                      isLast
                          ? (_introSequence
                                ? _beginAnnouncement
                                : _closeInstruction)
                          : () => _setTutorialStep(_tutorialStep + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _playableTutorialOverlay() {
    const titles = [
      'Practice Tutorial',
      'Read The Falling Term',
      'Press Enter',
      'Try Again',
      'Build A Combo',
    ];
    const bodies = [
      'This practice teaches falling syntax terms, typing accuracy, health, and combos before Level 1 starts.',
      'Read the complete Java syntax word, then type that exact word before it reaches the bottom.',
      'Type the correct term into the input box, then press Enter to clear it and earn score.',
      'A wrong answer leaves the puzzle falling, so correct it quickly. A missed card removes health.',
      'Every reward streak gives coins and restores 1 health only if health is not full.',
    ];
    return _overlayFrame(
      child: Align(
        alignment: Alignment.centerRight,
        child: LayoutBuilder(
          builder: (context, constraints) => Container(
            width: math.min(360, constraints.maxWidth),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xF0183A35),
              border: Border.all(color: const Color(0xFF96CDBB)),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black54, offset: Offset(5, 5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  titles[_coachStep],
                  style: _text(
                    const Color(0xFFE0FFF0),
                    20,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  bodies[_coachStep],
                  style: _text(
                    const Color(0xFFE0FFF0),
                    14,
                    weight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Terms: $_cleared/${_config.targetWords}   Health: $_health/${_config.lives}',
                  style: _text(
                    const Color(0xFFB2E2D0),
                    12,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _instructionButton(
                      'Back',
                      _coachStep == 0
                          ? () {}
                          : () => setState(() => _coachStep--),
                      disabled: _coachStep == 0,
                    ),
                    _instructionButton(
                      _coachStep == 4 ? 'Finish Tutorial' : 'Continue',
                      _coachStep == 4
                          ? () => _closeInstruction()
                          : () => setState(() => _coachStep++),
                      primary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Compatibility helper for older preview builds. The active tutorial now
  // highlights the actual playfield target.
  // ignore: unused_element
  Widget _tutorialHighlight(String target) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFE5A0), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55FFD478),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Text(
          target,
          style: _text(const Color(0xFFFFE5A0), 15, weight: FontWeight.w900),
        ),
      ),
    );
  }

  // Compatibility helper for older preview builds. The active tutorial now
  // renders its demonstration in the actual playfield.
  // ignore: unused_element
  Widget _tutorialDemo(int step) {
    final elapsed = _tutorialAnimationTick * 80;
    final phase = _finiteFraction((elapsed % 3200) / 3200);
    final typedLength = (phase * 3).floor().clamp(0, 3);
    final typed = 'int'.substring(0, typedLength);
    final pressingEnter = phase >= .64 && phase < .78;
    final lives = math.max(1, _config.lives);
    final health = phase < .52 ? lives : math.max(1, lives - 1);
    final seconds = math.max(0, _config.seconds - (phase * 9).floor());
    final combo = phase < .34
        ? 1
        : phase < .68
        ? 2
        : 3;
    final hand = Image.asset(
      'assets/game6/tutorial/tutorial-hand.png',
      width: 42,
      height: 42,
      fit: BoxFit.contain,
    );

    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xD9FFF5DB),
        border: Border.all(color: const Color(0xFF967047), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66A7804C), offset: Offset(0, 3)),
        ],
      ),
      child: Stack(
        children: [
          if (step == 0) ...[
            AnimatedPositioned(
              duration: const Duration(milliseconds: 80),
              left: 34 + phase * 80,
              top: 4 + phase * 44,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                color: const Color(0xFF183A35),
                child: const Text(
                  'int',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 66 + phase * 80,
              top: 50 + phase * 34,
              child: hand,
            ),
          ] else if (step == 1) ...[
            Positioned(
              left: 8,
              right: 88,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                color: const Color(0xFF123A32),
                child: Text(
                  '>_  $typed',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFFE0FFF0),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              right: pressingEnter ? 8 : 68,
              bottom: pressingEnter ? 8 : 34,
              child: hand,
            ),
            Positioned(
              right: 8,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: pressingEnter
                    ? const Color(0xFFB0F0BB)
                    : const Color(0xFFE6C28A),
                child: const Text(
                  'ENTER',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF56331E),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ] else if (step == 2) ...[
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  phase < .55 ? 'INT  ≠  int' : 'Wrong case example',
                  key: ValueKey(phase < .55),
                  style: TextStyle(
                    color: phase < .55
                        ? const Color(0xFF9A3412)
                        : const Color(0xFF563A24),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(left: 46 + phase * 120, bottom: 8, child: hand),
          ] else if (step == 3) ...[
            Positioned(
              left: 8,
              right: 8,
              top: 10,
              child: Text(
                'HEALTH  $health/${_config.lives}     TIME  0:${seconds.toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF563A24),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 16,
              child: LinearProgressIndicator(
                value: _finiteFraction(health / lives),
                minHeight: 10,
                backgroundColor: const Color(0xFFE6C28A),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF4A9C31),
                ),
              ),
            ),
          ] else if (step == 4) ...[
            Center(
              child: Text(
                '${3 + (phase * 3).floor()} COMBO  ×$combo   +${combo * 20} coins',
                style: const TextStyle(
                  color: Color(0xFF563A24),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ] else ...[
            Center(
              child: Text(
                '${_config.targetWords} terms before time runs out',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF563A24),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _announcementOverlay() {
    final countdown = _announcementSecond == 0 ? null : _announcementSecond;
    final challenge = switch (_config.level) {
      2 => 'INCOMPLETE LETTERS',
      3 => 'TARGET WORDS',
      4 => 'FAKE SYNTAXES',
      5 => 'ODD PAIR',
      _ => 'SPEED-UP WAVE',
    };
    return Game6Announcement(
      level: _config.level,
      challenge: challenge,
      objective: _config.level == 1
          ? 'Type each Java term before it reaches the bottom. The falling speed increases as you progress.'
          : _config.objective,
      countdown: countdown,
    );
  }

  Widget _instructionButton(
    String label,
    VoidCallback onPressed, {
    bool primary = false,
    bool disabled = false,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? const Color(0xFFB0F0BB)
              : const Color(0xFFF0FFF6),
          foregroundColor: const Color(0xFF123A32),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
            side: const BorderSide(color: Color(0xFF96CDBB)),
          ),
        ),
        child: Text(
          label,
          style: _text(const Color(0xFF123A32), 11, weight: FontWeight.w900),
        ),
      ),
    );
  }

  void _openNextLevel() {
    if (!_resultSaved || !_nextLevelAvailable || _config.level >= 5) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameEntry(
          game: 5,
          level: _config.level + 1,
          builder: (_) =>
              Game6Page(selectedLevel: _config.level + 1, initialCoins: _coins),
        ),
      ),
    );
  }

  Widget _panel({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _theme.card,
        border: Border.all(color: _theme.dark, width: 2),
        boxShadow: [
          BoxShadow(
            color: _theme.dark.withValues(alpha: .75),
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  TextStyle _text(
    Color color,
    double size, {
    FontWeight weight = FontWeight.normal,
    double letterSpacing = 0,
    double height = 1.15,
  }) {
    return TextStyle(
      fontFamily: 'SettingsPixel',
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

class _Game6Drop {
  _Game6Drop({
    required this.id,
    required this.answer,
    required this.display,
    required this.lane,
    required this.y,
    required this.speed,
    required this.required,
    this.pairId,
  });

  final String id;
  final String answer;
  final String display;
  final int lane;
  double y;
  final double speed;
  final bool required;
  final String? pairId;
}

class _Game6TutorialDrop {
  const _Game6TutorialDrop({
    required this.display,
    required this.x,
    required this.y,
  });

  final String display;
  final double x;
  final double y;
}

class _LocalTerm {
  const _LocalTerm({
    required this.answer,
    required this.display,
    this.required = true,
    this.pairId,
  });

  final String answer;
  final String display;
  final bool required;
  final String? pairId;
}

class _Game6LevelConfig {
  const _Game6LevelConfig({
    required this.level,
    required this.title,
    required this.objective,
    required this.targetWords,
    required this.seconds,
    required this.lives,
  });

  final int level;
  final String title;
  final String objective;
  final int targetWords;
  final int seconds;
  final int lives;
}

class _Game6Theme {
  const _Game6Theme({
    required this.shell,
    required this.sidebar,
    required this.card,
    required this.chip,
    required this.heading,
    required this.dark,
    required this.mid,
    required this.accent,
    required this.typingSurface,
    required this.bubble,
    required this.bubbleBorder,
    required this.bubbleText,
    required this.bubbleGlow,
  });

  final Color shell;
  final Color sidebar;
  final Color card;
  final Color chip;
  final Color heading;
  final Color dark;
  final Color mid;
  final Color accent;
  final Color typingSurface;
  final Color bubble;
  final Color bubbleBorder;
  final Color bubbleText;
  final Color bubbleGlow;

  static _Game6Theme forLevel(int level) {
    switch (level) {
      case 2:
        return const _Game6Theme(
          shell: Color(0xFFF5E5ED),
          sidebar: Color(0xFF765067),
          card: Color(0xFFA77A91),
          chip: Color(0xFFEAD3DF),
          heading: Color(0xFF573247),
          dark: Color(0xFF39273D),
          mid: Color(0xFF81506F),
          accent: Color(0xFF81506F),
          typingSurface: Color(0xFFF5E5ED),
          bubble: Color(0xFFE2B0CA),
          bubbleBorder: Color(0xFFE2B0CA),
          bubbleText: Color(0xFF39273D),
          bubbleGlow: Color(0xFFD89AB9),
        );
      case 3:
        return const _Game6Theme(
          shell: Color(0xFFF8E4CC),
          sidebar: Color(0xFFB47B4E),
          card: Color(0xFFD6A873),
          chip: Color(0xFFF3D7B1),
          heading: Color(0xFF744327),
          dark: Color(0xFF4E2F22),
          mid: Color(0xFF9A6238),
          accent: Color(0xFF9A6238),
          typingSurface: Color(0xFFF8E4CC),
          bubble: Color(0xFFEFCA94),
          bubbleBorder: Color(0xFF8A5431),
          bubbleText: Color(0xFF4E2F22),
          bubbleGlow: Color(0xFFDFA66C),
        );
      case 4:
        return const _Game6Theme(
          shell: Color(0xFFF5DFEB),
          sidebar: Color(0xFF73517F),
          card: Color(0xFF9C75A7),
          chip: Color(0xFFE3CCE8),
          heading: Color(0xFF4F3458),
          dark: Color(0xFF472947),
          mid: Color(0xFF95547D),
          accent: Color(0xFF95547D),
          typingSurface: Color(0xFFF5DFEB),
          bubble: Color(0xFFF4B1A6),
          bubbleBorder: Color(0xFF713653),
          bubbleText: Color(0xFF3A2038),
          bubbleGlow: Color(0xFFFFC7B0),
        );
      case 5:
        return const _Game6Theme(
          shell: Color(0xFFF7E4DC),
          sidebar: Color(0xFFB77D78),
          card: Color(0xFFD9AAA0),
          chip: Color(0xFFF4D8CF),
          heading: Color(0xFF774844),
          dark: Color(0xFF503532),
          mid: Color(0xFFA66762),
          accent: Color(0xFFA66762),
          typingSurface: Color(0xFFF7E4DC),
          bubble: Color(0xFFF7D6CC),
          bubbleBorder: Color(0xFF9C5F59),
          bubbleText: Color(0xFF503532),
          bubbleGlow: Color(0xFFE5A49A),
        );
      default:
        return const _Game6Theme(
          shell: Color(0xFFEFFDF9),
          sidebar: Color(0xFFD5AD72),
          card: Color(0xFFEFD29D),
          chip: Color(0xFFFFE8BD),
          heading: Color(0xFF9B5927),
          dark: Color(0xFF63391F),
          mid: Color(0xFFB8752F),
          accent: Color(0xFFB8752F),
          typingSurface: Color(0xFFFFF1D5),
          bubble: Color(0xFFFFE8AA),
          bubbleBorder: Color(0xFFA86428),
          bubbleText: Color(0xFF57351F),
          bubbleGlow: Color(0xFFF0BD68),
        );
    }
  }
}
