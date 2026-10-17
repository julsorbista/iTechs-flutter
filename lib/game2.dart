import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'glob/game_data.dart';
import 'widgets/game_entry.dart';
import 'widgets/game_completion_flow.dart';
import 'widgets/illustrated_results_overlay.dart';

class Game2Page extends StatefulWidget {
  const Game2Page({super.key, this.selectedLevel, this.firstPlay = false});
  final bool firstPlay;

  final int? selectedLevel;

  @override
  State<Game2Page> createState() => _Game2PageState();
}

class _Game2PageState extends State<Game2Page> {
  int score = 0;
  bool _introCompleted = false;
  int lives = 3;
  int combo = 0;
  int completedOutputs = 0;
  int _mistakes = 0;
  bool _gameOver = false;

  Timer? _movementTimer;
  Offset? _lastSwipePosition;
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _slicePlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _comboPlayer = AudioPlayer();
  final Map<AudioPlayer, Future<void>> _audioOperations = {};
  bool _audioDisposed = false;
  bool _audioShutdownStarted = false;
  bool _musicStarting = false;
  bool _musicStarted = false;
  bool _musicBlocked = false;
  int _nextPieceIndex = 0;
  int _challengeIndex = 0;
  double _spawnClockMs = 0;
  double _inactivityMs = 0;
  Size _gameplaySize = Size.zero;
  DateTime? _lastPhysicsTime;
  int _correctGapRemaining = 0;
  int _hazardsSinceCorrect = 0;
  String? _lastSpawnKind;
  String _feedback = 'SWIPE ACROSS A CARD';
  String? _flashMessage;
  Color _flashColor = const Color(0xFFFF8FA0);
  double _flashMs = 0;
  double _shakeMs = 0;
  List<String> _slicedPieces = [];
  bool _announcementVisible = false;
  int _announcementCountdown = 0;
  int _announcementElapsedMs = 0;
  bool _levelCleared = false;
  bool _resultSubmitted = false;
  bool _resultSavePending = false;
  bool? _resultSaveSucceeded;
  int _runId = 0;
  DateTime? _runStartedAt;
  int _elapsedSeconds = 0;
  int _activeLevel = 1;
  Timer? _announcementTimer;
  bool _guidelinesVisible = false;
  bool _tutorialVisible = false;
  int _tutorialPage = 0;
  double _tutorialElapsedMs = 0;
  Timer? _tutorialTimer;
  int _lastCountdownSound = 0;
  int _guidelinesPage = 0;
  Rect? _tutorialHighlightRect;

  final GlobalKey _javaCodeKey = GlobalKey();
  final GlobalKey _livesKey = GlobalKey();
  final GlobalKey _outputKey = GlobalKey();
  final GlobalKey _tutorialOverlayKey = GlobalKey();

  static const List<Map<String, String>> _tutorialSteps = [
    {
      'title': 'Build the Java code',
      'text': 'Read Correct Code. Slice the green pieces in that order to build the matching Sliced Code.',
    },
    {
      'title': 'Swipe through the piece',
      'text': 'Hold the mouse button and drag across the green code piece. On a touch screen, swipe with your finger.',
    },
    {
      'title': 'Avoid red code and bombs',
      'text': 'Do not slice red decoys or bombs. They cost lives and break your combo in real play.',
    },
    {
      'title': 'Follow the correct order',
      'text': 'Watch each correct piece join the code. Only the next required piece should be sliced.',
    },
    {
      'title': 'Watch lives and combo',
      'text': 'Correct slices build your combo. Avoid mistakes and keep slicing: a long idle period ends the real run.',
    },
    {
      'title': 'Complete the outputs',
      'text': 'Finish the code to produce its output. Complete this level\'s output goal to win.',
    },
  ];

  final Random _random = Random();
  final List<Map<String, dynamic>> _particles = [];
  final List<Map<String, dynamic>> _trails = [];
  final List<Map<String, dynamic>> _sliceBursts = [];
  final List<Map<String, dynamic>> _floatingFeedback = [];

  static const Map<int, Map<String, dynamic>> levelConfigurations = {
    1: {
      'outputs': 2,
      'spawnRate': 1750.0,
      'speed': 90.0,
      'bombChance': 0.12,
      'decoyChance': 0.22,
      'correctChance': 0.42,
      'correctGap': 1,
      'maxObjects': 4,
    },
    2: {
      'outputs': 3,
      'spawnRate': 1220.0,
      'speed': 128.0,
      'bombChance': 0.16,
      'decoyChance': 0.28,
      'correctChance': 0.36,
      'correctGap': 1,
      'maxObjects': 6,
    },
    3: {
      'outputs': 4,
      'spawnRate': 980.0,
      'speed': 155.0,
      'bombChance': 0.21,
      'decoyChance': 0.35,
      'correctChance': 0.33,
      'correctGap': 1,
      'maxObjects': 7,
    },
    4: {
      'outputs': 5,
      'spawnRate': 780.0,
      'speed': 180.0,
      'bombChance': 0.25,
      'decoyChance': 0.43,
      'correctChance': 0.30,
      'correctGap': 2,
      'maxObjects': 8,
    },
    5: {
      'outputs': 6,
      'spawnRate': 640.0,
      'speed': 205.0,
      'bombChance': 0.29,
      'decoyChance': 0.50,
      'correctChance': 0.28,
      'correctGap': 2,
      'maxObjects': 9,
    },
  };

  final Map<int, List<Map<String, dynamic>>> _generatedChallenges = {};

  static const List<String> _fallbackDecoys = [
    'System.out.printline',
    'int score == 10;',
    'if score >= 10',
    'retrun;',
    'clas CodeLab',
    'boolean ready = yes;',
    'for int i = 0;',
    'whlie (isRunning)',
    'new Scaner(System.in)',
  ];
  static const List<int> comboMilestones = [3, 5, 10];
  static const double inactivityTimeoutMs = 20000;

  T _randomItem<T>(List<T> values) {
    return values[_random.nextInt(values.length)];
  }

  int _randomNumber(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  Map<String, dynamic> _generatedTask({
    required String type,
    required String title,
    required String prompt,
    required String answer,
    String snippet = '',
  }) {
    return {
      'type': type,
      'title': title,
      'prompt': prompt,
      'answer': answer,
      'acceptedAnswers': [answer],
      'snippet': snippet,
    };
  }

  List<Map<String, dynamic>> _originalTaskPool(int level) {
    const variables = [
      'score',
      'level',
      'coins',
      'health',
      'attempts',
      'bonus',
      'total',
      'age',
      'speed',
      'damage',
    ];
    const strings = ['status', 'name', 'rank', 'message', 'title', 'badge'];
    const classes = [
      'Player',
      'Student',
      'Hero',
      'Account',
      'QuizSession',
      'GameProfile',
      'Badge',
    ];
    const children = [
      'PremiumPlayer',
      'AdminStudent',
      'MageHero',
      'SavingsAccount',
      'TimedQuizSession',
      'RankedProfile',
    ];
    const methods = [
      'calculateBonus',
      'printStatus',
      'getLevel',
      'applyDamage',
      'loadProfile',
      'validateScore',
      'showResult',
    ];
    const exceptions = [
      'IllegalArgumentException',
      'ArithmeticException',
      'NullPointerException',
      'IOException',
    ];
    const foundationContexts = [
      'a score tracker for a coding challenge',
      'a health system for a platform game',
      'a coin counter for an arcade level',
      'a speed meter for a racing simulator',
      'an attempts counter for a quiz app',
    ];
    const oopContexts = [
      'a school portal',
      'a role-playing game',
      'a banking dashboard',
      'a quiz engine',
      'a badge rewards system',
    ];
    const modelingContexts = [
      'student login',
      'quiz submission',
      'level unlocking',
      'course enrollment',
      'password reset',
    ];
    const architectureContexts = [
      'a leaderboard service',
      'a profile manager',
      'an inventory system',
      'a progress tracker',
      'a rewards module',
    ];

    final foundations = <Map<String, dynamic>>[
      () {
        final variable = _randomItem(variables);
        final value = _randomNumber(4, 90);
        final context = _randomItem(foundationContexts);
        return _generatedTask(
          type: 'typing',
          title: 'Declare An Integer',
          prompt:
              'Scenario: You are building $context. Type the Java statement that declares int $variable with value $value.',
          answer: 'int $variable = $value;',
        );
      }(),
      () {
        final variable = _randomItem(strings);
        final value = _randomItem([
          'Ready',
          'Bronze',
          'Active',
          'Complete',
          'Passed',
        ]);
        final context = _randomItem(foundationContexts);
        return _generatedTask(
          type: 'complete',
          title: 'Complete A String',
          prompt:
              'Scenario: In $context, fill the blank so $variable stores the text "$value".',
          answer: '"$value"',
          snippet: 'String $variable = ____;',
        );
      }(),
      () {
        final variable = _randomItem(variables);
        final value = _randomNumber(5, 30);
        final context = _randomItem(foundationContexts);
        return _generatedTask(
          type: 'debug',
          title: 'Repair Assignment',
          prompt:
              'Scenario: $context is failing to compile. Rewrite the broken Java line correctly.',
          answer: 'int $variable = $value;',
          snippet: 'int $variable == $value',
        );
      }(),
      () {
        final variable = _randomItem(variables);
        final threshold = _randomNumber(10, 100);
        final context = _randomItem(foundationContexts);
        return _generatedTask(
          type: 'debug',
          title: 'Repair An If Condition',
          prompt:
              'Scenario: $context should check whether $variable reached $threshold. Fix the broken Java condition.',
          answer: 'if ($variable >= $threshold) {',
          snippet: 'if $variable >= $threshold) {',
        );
      }(),
    ];

    final inheritance = <Map<String, dynamic>>[
      () {
        final parent = _randomItem(classes);
        final child = _randomItem(children);
        final context = _randomItem(oopContexts);
        return _generatedTask(
          type: 'typing',
          title: 'Write Inheritance Header',
          prompt:
              'Scenario: In $context, $child should inherit behavior from $parent. Type the Java class header.',
          answer: 'class $child extends $parent {',
        );
      }(),
      _generatedTask(
        type: 'debug',
        title: 'Fix Override Syntax',
        prompt: 'Scenario: A subclass method should override a parent method. Repair the broken override annotation.',
        answer: '@Override\npublic void move() {',
        snippet: 'Override\npublic void move() {',
      ),
      () {
        final parent = _randomItem(classes);
        final child = _randomItem(children);
        final context = _randomItem(oopContexts);
        return _generatedTask(
          type: 'debug',
          title: 'Fix Extends Syntax',
          prompt:
              'Scenario: In $context, $child should extend $parent. Repair the broken class declaration.',
          answer: 'class $child extends $parent {',
          snippet: 'class $child extend $parent {',
        );
      }(),
    ];

    final exceptionsPool = <Map<String, dynamic>>[
      () {
        final exception = _randomItem(exceptions);
        final context = _randomItem(oopContexts);
        return _generatedTask(
          type: 'complete',
          title: 'Complete Catch Block',
          prompt:
              'Scenario: $context may throw $exception. Fill the missing exception type to catch it.',
          answer: exception,
          snippet: 'try {\n  runLevel();\n} catch (____ error) {\n  System.out.println(error.getMessage());\n}',
        );
      }(),
      _generatedTask(
        type: 'debug',
        title: 'Repair Try Catch Syntax',
        prompt: 'Scenario: The error handler is malformed. Rewrite the broken catch line correctly.',
        answer: 'catch (Exception e) {',
        snippet: 'catch Exception e) {',
      ),
      () {
        final exception = _randomItem(exceptions);
        final context = _randomItem(oopContexts);
        return _generatedTask(
          type: 'debug',
          title: 'Fix Throw Statement',
          prompt:
              'Scenario: In $context, invalid input should throw $exception. Repair the broken Java statement.',
          answer: 'throw new $exception("Invalid data");',
          snippet: 'throw new $exception("Invalid data")',
        );
      }(),
    ];

    final oop = <Map<String, dynamic>>[
      () {
        final method = _randomItem(methods);
        final context = _randomItem(oopContexts);
        return _generatedTask(
          type: 'typing',
          title: 'Write A Getter',
          prompt:
              'Scenario: In $context, type a Java method header named $method that returns int.',
          answer: 'public int $method() {',
        );
      }(),
      () {
        final className = _randomItem(classes);
        final context = _randomItem(oopContexts);
        return _generatedTask(
          type: 'complete',
          title: 'Complete An Object Creation',
          prompt:
              'Scenario: $context needs a new $className object. Fill the missing constructor call.',
          answer: 'new $className()',
          snippet: '$className player = ____;',
        );
      }(),
    ];

    final modeling = <Map<String, dynamic>>[
      () {
        final useCase = _randomItem(modelingContexts);
        return _generatedTask(
          type: 'debug',
          title: 'Fix UML Class Syntax',
          prompt:
              'Scenario: While modeling $useCase, repair the Java class declaration.',
          answer: 'public class StudentAccount extends Account {',
          snippet: 'public class StudentAccount extends {',
        );
      }(),
      () {
        final useCase = _randomItem([
          'Login',
          'SubmitQuiz',
          'ReviewScore',
          'ResetPassword',
          'EnrollCourse',
          'UnlockLevel',
        ]);
        return _generatedTask(
          type: 'typing',
          title: 'Name A Use Case',
          prompt:
              'Scenario: You are documenting a use-case diagram. Type the use-case name exactly as "$useCase".',
          answer: useCase,
        );
      }(),
    ];

    final interaction = <Map<String, dynamic>>[
      _generatedTask(
        type: 'debug',
        title: 'Fix Method Call',
        prompt: 'Scenario: An interaction step should validate a login request. Repair the broken Java method call.',
        answer: 'authService.validate(username, password);',
        snippet: 'authService validate(username, password);',
      ),
      () {
        final useCase = _randomItem([
          'Login',
          'SubmitQuiz',
          'ReviewScore',
          'ResetPassword',
          'EnrollCourse',
          'UnlockLevel',
        ]);
        return _generatedTask(
          type: 'typing',
          title: 'Write Interaction Log',
          prompt:
              'Scenario: A sequence step should log "$useCase". Type the Java output statement.',
          answer: 'System.out.println("$useCase");',
        );
      }(),
    ];

    final architecture = <Map<String, dynamic>>[
      () {
        final field = _randomItem(['balance', 'score', 'health', 'level']);
        final context = _randomItem(architectureContexts);
        return _generatedTask(
          type: 'typing',
          title: 'Encapsulate A Field',
          prompt:
              'Scenario: In $context, protect internal state. Type a private int field declaration named $field.',
          answer: 'private int $field;',
        );
      }(),
      () {
        final method = _randomItem(methods);
        final context = _randomItem(architectureContexts);
        return _generatedTask(
          type: 'debug',
          title: 'Repair Method Header',
          prompt:
              'Scenario: In $context, rewrite this Java method header correctly.',
          answer: 'public int $method() {',
          snippet: 'public int $method {',
        );
      }(),
      () {
        final field = _randomItem(['score', 'health', 'level', 'coins']);
        final context = _randomItem(architectureContexts);
        final setter =
            'set${field.substring(0, 1).toUpperCase()}${field.substring(1)}';
        return _generatedTask(
          type: 'typing',
          title: 'Write A Setter Header',
          prompt:
              'Scenario: $context needs controlled updates. Type a setter header for int $field.',
          answer: 'public void $setter(int $field) {',
        );
      }(),
    ];

    switch (level) {
      case 1:
        return foundations;
      case 2:
        return [...inheritance, ...exceptionsPool, ...oop];
      case 3:
        return [...modeling, ...oop];
      case 4:
        return [...modeling, ...interaction];
      case 5:
        return [...architecture, ...oop];
      default:
        return foundations;
    }
  }

  Map<String, dynamic> _configuredReorderTask(int level) {
    if (level == 4) {
      return {
        'type': 'reorder',
        'title': 'Print A Start Message',
        'prompt': 'Arrange the Java statement pieces into the correct order.',
        'blocks': [
          {'id': 'a', 'code': 'System.out'},
          {'id': 'b', 'code': '.println'},
          {'id': 'c', 'code': '("Start!")'},
          {'id': 'd', 'code': ';'},
        ],
        'correctOrder': ['a', 'b', 'c', 'd'],
      };
    }
    return {
      'type': 'reorder',
      'title': level == 5 ? 'Store A Score' : 'Build A Tiny Program',
      'prompt': 'Arrange the Java statement pieces into the correct order.',
      'blocks': level == 5
          ? [
              {'id': 'a', 'code': 'double'},
              {'id': 'b', 'code': 'score'},
              {'id': 'c', 'code': '='},
              {'id': 'd', 'code': '100'},
              {'id': 'e', 'code': ';'},
            ]
          : [
              {'id': 'a', 'code': 'let name = "Ada";'},
              {'id': 'b', 'code': 'console.log(name);'},
              {'id': 'c', 'code': 'let ready = true;'},
            ],
      'correctOrder': level == 5 ? ['a', 'b', 'c', 'd', 'e'] : ['a', 'c', 'b'],
    };
  }

  String _normalizeCode(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _getTaskTargetCode(Map<String, dynamic> task) {
    if (task['type'] == 'reorder') {
      final blocks = (task['blocks'] as List).cast<Map<String, dynamic>>();
      final byId = {for (final block in blocks) block['id']: block['code']};
      final order = (task['correctOrder'] as List).cast<String>();
      return order.map((id) => byId[id]).whereType<String>().join('\n');
    }
    if (task['type'] == 'choice') {
      final options = (task['options'] as List?) ?? const [];
      final correctOptionId = '${task['correctOptionId']}';
      for (final option in options) {
        if (option is Map && '${option['id']}' == correctOptionId) {
          return '${option['label'] ?? ''}'.trim();
        }
      }
    }
    return ((task['acceptedAnswers'] as List?)?.first ?? task['answer'] ?? '')
        .toString()
        .trim();
  }

  List<String> _splitCodePieces(String code) {
    final value = code.trim();
    if (value.isEmpty) return [];
    if (value.contains('\n')) {
      return value
          .split(RegExp(r'\n+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    }
    final printlnMatch = RegExp(r'^System\.out\.println\s*(\(.*\))\s*;?$')
        .firstMatch(value);
    if (printlnMatch != null) {
      return ['System', '.out', '.println', printlnMatch.group(1)!, ';'];
    }
    final tokens = RegExp(
      r'"[^"]*"|==|>=|<=|!=|\+\+|--|&&|\|\||[A-Za-z_$][\w$]*|\d+|[(){}\[\].,;=<>+\-*/]',
    ).allMatches(value).map((match) => match.group(0)!).toList();
    if (tokens.isEmpty) return [value];
    final pieces = <String>[];
    for (var index = 0; index < tokens.length; index++) {
      final token = tokens[index];
      final isSystemChain =
          (token == 'System' &&
              index + 2 < tokens.length &&
              tokens[index + 1] == '.' &&
              tokens[index + 2] == 'out') ||
          (token == 'out' &&
              index + 2 < tokens.length &&
              tokens[index + 1] == '.' &&
              tokens[index + 2] == 'println');
      if (isSystemChain) {
        pieces.add(token);
        continue;
      }
      if (token == '.' && pieces.isNotEmpty) {
        pieces[pieces.length - 1] = '${pieces.last}.';
        continue;
      }
      if (RegExp(r'^["\d]').hasMatch(token) &&
          pieces.isNotEmpty &&
          pieces.last == '(' &&
          index + 1 < tokens.length &&
          tokens[index + 1] == ')') {
        pieces[pieces.length - 1] = '($token)';
        index += 1;
        continue;
      }
      pieces.add(token);
    }
    return pieces.where((piece) => piece.isNotEmpty).toList();
  }

  String _smartJoin(List<String> pieces) {
    var line = '';
    for (final piece in pieces) {
      if (line.isEmpty) {
        line = piece;
      } else if (RegExp(r'^[;,){}\]]').hasMatch(piece) ||
          piece.startsWith('.')) {
        line += piece;
      } else if (line.endsWith('(') ||
          line.endsWith('.') ||
          line.endsWith('[')) {
        line += piece;
      } else {
        line += ' $piece';
      }
    }
    return line;
  }

  String _formatCodePieces(List<String> pieces, String type) {
    return type == 'reorder' ? pieces.join('\n') : _smartJoin(pieces);
  }

  String _makeDecoy(String piece) {
    var value = piece.trim();
    if (value.isEmpty) return _randomItem(_fallbackDecoys);
    value = value
        .replaceAll(RegExp(r'\bSystem\b'), 'Systme')
        .replaceAll(RegExp(r'\bprintln\b'), 'printline')
        .replaceAll(RegExp(r'\bpublic\b'), 'publik')
        .replaceAll(RegExp(r'\bstatic\b'), 'statik')
        .replaceAll(RegExp(r'\bvoid\b'), 'viod')
        .replaceAll(RegExp(r'\bclass\b'), 'clas')
        .replaceAll('==', '=')
        .replaceAll('>=', '=>')
        .replaceAll(';', '');
    return value;
  }

  String _inferOutput(Map<String, dynamic> task, String targetCode) {
    final source = '${task['snippet'] ?? ''}\n$targetCode';
    final printed = RegExp(r'System\.out\.println\s*\(\s*"([^"]*)"\s*\)\s*;?')
        .allMatches(source)
        .map((match) => match.group(1)!)
        .toList();
    if (printed.isNotEmpty) return printed.join('\n');
    final assignment = RegExp(
      r'(?:int|double|String|boolean)\s+([A-Za-z_$][\w$]*)\s*=\s*([^;]+);?',
    ).firstMatch(targetCode);
    if (assignment != null) {
      final value = assignment.group(2)!.replaceAll(RegExp(r'^"|"$'), '');
      return '${assignment.group(1)} = $value';
    }
    if (task['type'] == 'choice') return _getTaskTargetCode(task);
    if ('${task['prompt'] ?? ''}'.toLowerCase().contains('how many times')) {
      return targetCode;
    }
    return targetCode.isEmpty ? 'Compiled' : targetCode;
  }

  Map<String, dynamic> _taskToChallenge(Map<String, dynamic> task, int index) {
    final targetCode = _getTaskTargetCode(task);
    var pieces = _splitCodePieces(targetCode);
    final snippet = (task['snippet'] ?? '').toString();
    if (pieces.length < 3 && snippet.contains('____')) {
      final expanded = snippet.replaceFirst('____', targetCode);
      final expandedPieces = _splitCodePieces(expanded);
      if (expandedPieces.length >= 3) pieces = expandedPieces;
    }
    if (pieces.length > 5) {
      final groupSize = (pieces.length / 5).ceil();
      pieces = [
        for (var start = 0; start < pieces.length; start += groupSize)
          pieces
              .sublist(start, min(start + groupSize, pieces.length))
              .join(' '),
      ];
    }
    final optionDecoys = <String>[];
    final options = (task['options'] as List?) ?? const [];
    for (final option in options) {
      final label = option is Map
          ? option['label'].toString()
          : option.toString();
      if (_normalizeCode(label) != _normalizeCode(targetCode)) {
        optionDecoys.add(label);
      }
    }
    final decoys =
        <String>{...optionDecoys, ...pieces.map(_makeDecoy), ..._fallbackDecoys}
          ..removeWhere(
            (decoy) => pieces.any(
              (piece) => _normalizeCode(piece) == _normalizeCode(decoy),
            ),
          );
    final code = _formatCodePieces(pieces, task['type'].toString());
    return {
      'id': task['id'] ?? 'game-two-slice-$index',
      'title': task['title'] ?? 'Code Challenge ${index + 1}',
      'prompt': task['prompt'] ?? 'Slice the code pieces in order.',
      'type': task['type'] ?? 'complete',
      'template': snippet.isEmpty ? targetCode : snippet,
      'targetCode': targetCode,
      'code': code,
      'pieces': pieces.isEmpty ? [targetCode] : pieces,
      'output': _inferOutput(task, targetCode),
      'decoys': decoys.toList(),
    };
  }

  List<Map<String, dynamic>> _buildChallengesForLevel(int level) {
    final desiredCount = level == 5 ? 6 : 5;
    final pool = _originalTaskPool(level)..shuffle(_random);
    final tasks = [
      for (var index = 0; index < desiredCount; index++)
        Map<String, dynamic>.from(pool[index % pool.length]),
    ];
    if (level == 4 || level == 5) {
      tasks[4] = _configuredReorderTask(level);
    }
    final target = levelConfigurations[level]!['outputs'] as int;
    return [
      for (var index = 0; index < target; index++)
        _taskToChallenge(tasks[index % tasks.length], index),
    ];
  }

  final List<Map<String, dynamic>> _syntaxCards = [
    {
      'id': 'system',
      'kind': 'correct',
      'pieceIndex': 0,
      'text': 'System',
      'x': 0.08,
      'y': 0.64,
      'vx': 0.22,
      'vy': -0.12,
      'speed': 90.0,
      'spawned': true,
      'sliced': false,
    },
    {
      'id': 'out',
      'kind': 'correct',
      'pieceIndex': 1,
      'text': '.out',
      'x': 0.50,
      'y': 0.44,
      'vx': -0.18,
      'vy': 0.14,
      'speed': 90.0,
      'spawned': false,
      'sliced': false,
    },
    {
      'id': 'println',
      'kind': 'correct',
      'pieceIndex': 2,
      'text': '.println',
      'x': 0.24,
      'y': 0.15,
      'vx': 0.16,
      'vy': 0.16,
      'speed': 90.0,
      'spawned': false,
      'sliced': false,
    },
    {
      'id': 'message',
      'kind': 'correct',
      'pieceIndex': 3,
      'text': '("Hello, iTECHS!")',
      'x': 0.62,
      'y': 0.70,
      'vx': -0.20,
      'vy': -0.10,
      'speed': 90.0,
      'spawned': false,
      'sliced': false,
    },
    {
      'id': 'semicolon',
      'kind': 'correct',
      'pieceIndex': 4,
      'text': ';',
      'x': 0.72,
      'y': 0.18,
      'vx': -0.15,
      'vy': 0.13,
      'speed': 90.0,
      'spawned': false,
      'sliced': false,
    },
  ];

  static const Color panelBackground = Color(0xFF1F2937);
  static const Color panelBorder = Color(0xFF4B5563);
  static const Color codeBackground = Color(0xFF0B1220);
  static const Color gold = Color(0xFFE7CF99);
  static const Color green = Color(0xFF75C98B);
  static const Color red = Color(0xFFE07A7A);

  @override
  void initState() {
    super.initState();
    _activeLevel = _validatedLevel(widget.selectedLevel);
    _resetGameState();
    _startBackgroundMusic();
    _movementTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _moveSyntaxCards(),
    );
  }

  @override
  void didUpdateWidget(covariant Game2Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLevel != widget.selectedLevel) {
      _activeLevel = _validatedLevel(widget.selectedLevel);
      _resetGameState();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _audioDisposed = true;
    _movementTimer?.cancel();
    _announcementTimer?.cancel();
    _tutorialTimer?.cancel();
    _stopAndDisposeAudio();
    super.dispose();
  }

  Future<void> _startBackgroundMusic() async {
    if (_audioDisposed || _musicStarting || _musicStarted) return;
    _musicStarting = true;
    try {
      await _queueAudioOperation(_musicPlayer, () async {
        if (_audioDisposed) return;
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        if (_audioDisposed) return;
        await _musicPlayer.play(
          AssetSource('game2/game2background.mp3'),
          volume: 0.22,
        );
      });
      if (!_audioDisposed) {
        _musicStarted = true;
        _musicBlocked = false;
      }
    } catch (error) {
      if (!_audioDisposed) {
        // Browser autoplay restrictions must not stop gameplay.
        _musicBlocked = true;
        _reportUnexpectedAudioError('background music', error);
      }
    } finally {
      _musicStarting = false;
    }
  }

  void _resumeBackgroundMusic() {
    if (_musicBlocked && !_audioDisposed) {
      _musicBlocked = false;
      unawaited(_startBackgroundMusic());
    }
  }

  Future<void> _playGameSound(AudioPlayer player, String assetName) async {
    if (_audioDisposed) return;
    try {
      await _queueAudioOperation(player, () async {
        if (_audioDisposed) return;
        await player.play(AssetSource('game2/$assetName'), volume: 0.8);
      });
    } catch (error) {
      _reportUnexpectedAudioError(assetName, error);
    }
  }

  void _stopAndDisposeAudio() {
    if (_audioShutdownStarted) return;
    _audioShutdownStarted = true;
    unawaited(_stopAndDisposePlayer(_musicPlayer));
    unawaited(_stopAndDisposePlayer(_slicePlayer));
    unawaited(_stopAndDisposePlayer(_effectPlayer));
    unawaited(_stopAndDisposePlayer(_comboPlayer));
  }

  Future<void> _stopAndDisposePlayer(AudioPlayer player) async {
    try {
      await _queueAudioOperation(player, () async {
        try {
          await player.stop();
        } catch (error) {
          _reportUnexpectedAudioError('stop', error);
        }
        try {
          await player.dispose();
        } catch (error) {
          _reportUnexpectedAudioError('dispose', error);
        }
      }, allowAfterDispose: true);
    } catch (error) {
      _reportUnexpectedAudioError('shutdown', error);
    }
  }

  Future<void> _queueAudioOperation(
    AudioPlayer player,
    Future<void> Function() operation, {
    bool allowAfterDispose = false,
  }) {
    final previous = _audioOperations[player] ?? Future<void>.value();
    final ready = previous.then<void>((_) {}, onError: (_, _) {});
    final queued = ready.then<void>((_) async {
      if (_audioDisposed && !allowAfterDispose) return;
      await operation();
    });
    _audioOperations[player] = queued;
    queued.then<void>((_) {}, onError: (_, _) {});
    return queued;
  }

  void _reportUnexpectedAudioError(String operation, Object error) {
    final message = error.toString();
    if (message.contains('AbortError') ||
        message.contains('play() request was interrupted') ||
        message.contains('NotAllowedError')) {
      return;
    }
    debugPrint('Game 2 audio $operation failed: $message');
  }

  void _playSliceSound() {
    unawaited(_playGameSound(_slicePlayer, 'swordslice.mp3'));
  }

  void _playCorrectSound() {
    unawaited(_playGameSound(_effectPlayer, 'sfxgame2.mp3'));
  }

  void _playErrorSound() {
    unawaited(_playGameSound(_effectPlayer, 'error.mp3'));
  }

  void _playComboSound() {
    unawaited(_playGameSound(_comboPlayer, 'game2combo.mp3'));
  }

  int get _currentLevel {
    return _activeLevel;
  }

  int _validatedLevel(int? requestedLevel) {
    return (requestedLevel ?? 1).clamp(1, 5).toInt();
  }

  Map<String, dynamic> get _currentLevelConfig {
    return levelConfigurations[_currentLevel]!;
  }

  List<Map<String, dynamic>> get _currentLevelChallenges {
    return _generatedChallenges[_currentLevel] ?? const [];
  }

  List<String> get _currentDecoys {
    final decoys = _currentChallenge['decoys'];
    if (decoys is List) {
      final values = decoys
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList();
      if (values.isNotEmpty) return values;
    }
    return _fallbackDecoys;
  }

  Map<String, dynamic> get _currentChallenge {
    final challenges = _currentLevelChallenges;
    return challenges[_challengeIndex.clamp(0, challenges.length - 1).toInt()];
  }

  int get _requiredOutputs => _currentLevelConfig['outputs'] as int;

  int get _requiredSyntaxSlices => _currentLevelChallenges.fold<int>(
    0,
    (total, challenge) => total + (challenge['pieces'] as List).length,
  );

  int get _noMistakeScore {
    var currentCombo = 0;
    var total = 0;
    for (final challenge in _currentLevelChallenges) {
      final pieces = challenge['pieces'] as List;
      for (var index = 0; index < pieces.length; index++) {
        currentCombo += 1;
        total += 40 * _comboMultiplier(currentCombo);
        if (index == pieces.length - 1) {
          total += 120 * _comboMultiplier(currentCombo);
        }
      }
    }
    return total;
  }

  void _resetGameState() {
    _runId += 1;
    _runStartedAt = DateTime.now();
    _elapsedSeconds = 0;
    _announcementTimer?.cancel();
    _announcementTimer = null;
    score = 0;
    lives = 3;
    combo = 0;
    completedOutputs = 0;
    _mistakes = 0;
    _gameOver = false;
    _levelCleared = false;
    _resultSubmitted = false;
    _resultSavePending = false;
    _resultSaveSucceeded = null;
    _announcementVisible = false;
    _announcementCountdown = 0;
    _announcementElapsedMs = 0;
    _lastCountdownSound = 0;
    _guidelinesVisible = false;
    _tutorialVisible = false;
    _tutorialPage = 0;
    _tutorialElapsedMs = 0;
    _guidelinesPage = 0;
    _tutorialHighlightRect = null;
    _tutorialTimer?.cancel();
    _tutorialTimer = null;
    _challengeIndex = 0;
    _nextPieceIndex = 0;
    _spawnClockMs = (_currentLevelConfig['spawnRate'] as double) * 0.65;
    _inactivityMs = 0;
    _lastPhysicsTime = null;
    _gameplaySize = Size.zero;
    _correctGapRemaining = 0;
    _hazardsSinceCorrect = 0;
    _lastSpawnKind = null;
    _lastSwipePosition = null;
    _slicedPieces = [];
    _particles.clear();
    _trails.clear();
    _sliceBursts.clear();
    _floatingFeedback.clear();
    _generatedChallenges[_currentLevel] = _buildChallengesForLevel(
      _currentLevel,
    );
    _feedback = 'SWIPE ACROSS A CARD';
    _flashMessage = null;
    _flashMs = 0;
    _shakeMs = 0;
    _initializeChallengeCards();
    if (widget.firstPlay && _currentLevel == 1 && !_introCompleted) {
      _guidelinesVisible = true;
    } else {
      _startAnnouncementSequence(advanceChallenge: false);
    }
  }

  void _startAnnouncementSequence({required bool advanceChallenge}) {
    _announcementTimer?.cancel();
    _announcementVisible = true;
    _announcementCountdown = 0;
    _announcementElapsedMs = 0;
    _lastCountdownSound = 0;
    var elapsedMs = 0;
    _announcementTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        elapsedMs += 100;
        _announcementElapsedMs = elapsedMs;
        if (elapsedMs >= 5500 && elapsedMs < 6500) {
          _announcementCountdown = 3;
        } else if (elapsedMs >= 6500 && elapsedMs < 7500) {
          _announcementCountdown = 2;
        } else if (elapsedMs >= 7500 && elapsedMs < 8500) {
          _announcementCountdown = 1;
        }
        if (_announcementCountdown > 0 &&
            _announcementCountdown != _lastCountdownSound) {
          _lastCountdownSound = _announcementCountdown;
          unawaited(
            _playGameSound(_effectPlayer, 'beep-$_announcementCountdown.mp3'),
          );
        }
        if (elapsedMs >= 8500) {
          timer.cancel();
          _announcementTimer = null;
          if (advanceChallenge) _challengeIndex += 1;
          _nextPieceIndex = 0;
          _slicedPieces = [];
          _spawnClockMs = 0;
          _correctGapRemaining = 0;
          _hazardsSinceCorrect = 0;
          _lastSpawnKind = null;
          _inactivityMs = 0;
          _lastPhysicsTime = DateTime.now();
          _feedback = 'SWIPE ACROSS A CARD';
          _initializeChallengeCards();
          _announcementVisible = false;
        }
      });
    });
  }

  void _initializeChallengeCards() {
    _syntaxCards.clear();
    // The original runtime starts with an empty canvas and creates objects
    // from below the play area through spawnWave().
  }

  void _triggerVisualFeedback(String message, Color color) {
    _flashMessage = message;
    _flashColor = color;
    _flashMs = 780;
    _shakeMs = 360;
  }

  int _activeObjectCount() {
    return _syntaxCards
        .where((card) => card['spawned'] == true && card['sliced'] != true)
        .length;
  }

  void _spawnNextCorrectPiece() {
    if (_gameplaySize == Size.zero) return;
    final pieces = _currentChallenge['pieces'] as List<String>;
    if (_nextPieceIndex >= pieces.length) return;
    _createMovingItem('correct', text: pieces[_nextPieceIndex]);
    _lastSpawnKind = 'correct';
    _correctGapRemaining = _currentLevelConfig['correctGap'] as int;
    _hazardsSinceCorrect = 0;
  }

  void _createMovingItem(String kind, {String? text}) {
    final width = _gameplaySize.width;
    final height = _gameplaySize.height;
    if (width <= 0 || height <= 0) return;

    final isBomb = kind == 'bomb';
    final String itemText =
        text ?? (isBomb ? 'BUG' : _randomItem(_currentDecoys));
    final baseWidth = isBomb ? 118.0 : _syntaxCardWidth(itemText);
    final baseHeight = isBomb ? 138.0 : 108.0;
    // Keep the visual bounds and swipe hit bounds in sync while leaving the
    // spawn, movement, and scoring rules unchanged.
    final renderScale = width < 820 ? 0.56 : 0.84;
    final itemWidth = baseWidth * renderScale;
    final itemHeight = baseHeight * renderScale;
    final isWide = width >= 820;
    final playLeft = isWide ? max(360.0, width * 0.28) : width * 0.22;
    final playRight = isWide ? min(width - 360.0, width * 0.72) : width * 0.78;
    final x = playLeft + _random.nextDouble() * max(1.0, playRight - playLeft);
    final launchDirection = x < width / 2 ? 1.0 : -1.0;
    final speed = _currentLevelConfig['speed'] as double;

    _syntaxCards.add({
      'id': '$kind-${DateTime.now().microsecondsSinceEpoch}',
      'kind': kind,
      'pieceIndex': kind == 'correct' ? _nextPieceIndex : -1,
      'text': itemText,
      'x': x.clamp(itemWidth / 2 + 20, width - itemWidth / 2 - 20),
      'y': height + itemHeight + _random.nextDouble() * 64 + 22,
      'width': itemWidth,
      'height': itemHeight,
      'baseWidth': baseWidth,
      'baseHeight': baseHeight,
      'renderScale': renderScale,
      'vx': launchDirection * (22 + _random.nextDouble() * 60),
      'vy': -(560 + speed * 1.45 + (-30 + _random.nextDouble() * 100)),
      'gravity': 330 + speed,
      'drift': -10 + _random.nextDouble() * 20,
      'phase': _random.nextDouble() * pi * 2,
      'spin': -0.08 + _random.nextDouble() * 0.16,
      'rotation': 0.0,
      'spawned': true,
      'sliced': false,
    });
  }

  double _syntaxCardWidth(String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return max(190.0, min(410.0, 108.0 + painter.width));
  }

  void _removeDeadObjects(double width, double height) {
    _syntaxCards.removeWhere((card) {
      if (card['spawned'] != true || card['sliced'] == true) return false;
      final x = card['x'] as double;
      final y = card['y'] as double;
      final itemWidth = card['width'] as double;
      final itemHeight = card['height'] as double;
      final vy = card['vy'] as double;
      return (vy > 0 && y - itemHeight / 2 > height + 18) ||
          x + itemWidth < -90 ||
          x - itemWidth > width + 90;
    });
  }

  void _updateMovingItem(Map<String, dynamic> card, double dt, double now) {
    card['vy'] = (card['vy'] as double) + (card['gravity'] as double) * dt;
    card['y'] = (card['y'] as double) + (card['vy'] as double) * dt;
    card['x'] =
        (card['x'] as double) +
        (card['vx'] as double) * dt +
        sin(now / 700 + (card['phase'] as double)) *
            (card['drift'] as double) *
            dt;
    card['rotation'] =
        sin(now / 720 + (card['phase'] as double)) * 0.06 +
        (card['spin'] as double);
  }

  void _updateEffects(double dt) {
    for (final particle in _particles) {
      particle['x'] =
          (particle['x'] as double) + (particle['vx'] as double) * dt;
      particle['y'] =
          (particle['y'] as double) + (particle['vy'] as double) * dt;
      particle['vy'] = (particle['vy'] as double) + 350 * dt;
      particle['life'] = (particle['life'] as double) - dt;
    }
    _particles.removeWhere((particle) => (particle['life'] as double) <= 0);

    for (final trail in _trails) {
      trail['life'] = (trail['life'] as double) - dt;
    }
    _trails.removeWhere((trail) => (trail['life'] as double) <= 0);

    for (final burst in _sliceBursts) {
      burst['life'] = (burst['life'] as double) - dt;
    }
    _sliceBursts.removeWhere((burst) => (burst['life'] as double) <= 0);

    for (final feedback in _floatingFeedback) {
      feedback['life'] = (feedback['life'] as double) - dt;
      feedback['y'] = (feedback['y'] as double) - 28 * dt;
    }
    _floatingFeedback.removeWhere(
      (feedback) => (feedback['life'] as double) <= 0,
    );
  }

  void _addParticleBurst(Offset center, Color color, int count) {
    for (var index = 0; index < count; index++) {
      _particles.add({
        'x': center.dx,
        'y': center.dy,
        'vx': -190 + _random.nextDouble() * 380,
        'vy': -230 + _random.nextDouble() * 310,
        'life': 0.35 + _random.nextDouble() * 0.45,
        'color': color,
      });
    }
  }

  void _addSliceBurst(Offset center, Offset start, Offset end) {
    final direction = end - start;
    final length = direction.distance;
    final safeLength = length == 0 ? 1.0 : length;
    final unit = direction / safeLength;
    final slashLength = length.clamp(70.0, 150.0).toDouble();
    _sliceBursts.add({
      'x': center.dx,
      'y': center.dy,
      'a': center - unit * slashLength * 0.5,
      'b': center + unit * slashLength * 0.5,
      'life': 0.48,
      'maxLife': 0.48,
    });
    _floatingFeedback.add({
      'title': '+1',
      'detail': '',
      'x': center.dx + 26,
      'y': center.dy - 38,
      'life': 0.48,
      'maxLife': 0.48,
      'color': const Color(0xFFFFD15D),
    });
  }

  void _addHitFeedback({
    required Offset center,
    required String title,
    required String detail,
    required Color color,
  }) {
    _floatingFeedback.add({
      'title': title,
      'detail': detail,
      'x': center.dx,
      'y': center.dy,
      'life': 0.86,
      'maxLife': 0.86,
      'color': color,
    });
  }

  void _spawnHazard() {
    final bombChance = _currentLevelConfig['bombChance'] as double;
    final decoyChance = _currentLevelConfig['decoyChance'] as double;
    final hazardTotal = bombChance + decoyChance;
    final bombProbability = hazardTotal > 0 ? bombChance / hazardTotal : 0.35;
    final isBomb = _random.nextDouble() < bombProbability;

    _createMovingItem(
      isBomb ? 'bomb' : 'wrong',
      text: isBomb ? 'BUG' : _randomItem(_currentDecoys),
    );
    _lastSpawnKind = isBomb ? 'bomb' : 'wrong';
    _correctGapRemaining = max(0, _correctGapRemaining - 1);
    _hazardsSinceCorrect += 1;
  }

  void _spawnWave() {
    final config = _currentLevelConfig;
    final maximumObjects = config['maxObjects'] as int;
    if (_gameOver ||
        _announcementVisible ||
        _activeObjectCount() >= maximumObjects) {
      return;
    }

    final hasNeededPiece = _syntaxCards.any(
      (card) =>
          card['kind'] == 'correct' &&
          card['pieceIndex'] == _nextPieceIndex &&
          card['spawned'] == true &&
          card['sliced'] != true,
    );
    final canSpawnCorrect =
        !hasNeededPiece &&
        _lastSpawnKind != 'correct' &&
        _correctGapRemaining <= 0;

    if (canSpawnCorrect &&
        (_random.nextDouble() < (config['correctChance'] as double) ||
            _hazardsSinceCorrect >= 3)) {
      _spawnNextCorrectPiece();
    } else {
      _spawnHazard();
    }

    final canSpawnAdditionalHazard =
        _currentLevel >= 4 &&
        _random.nextDouble() < 0.24 &&
        _activeObjectCount() < maximumObjects;
    if (canSpawnAdditionalHazard) _spawnHazard();
  }

  void _moveSyntaxCards() {
    if (!mounted ||
        _gameOver ||
        _levelCleared ||
        _announcementVisible ||
        _guidelinesVisible ||
        _tutorialVisible) {
      return;
    }

    final now = DateTime.now();
    final previous = _lastPhysicsTime;
    _lastPhysicsTime = now;
    final secondsPerTick = previous == null
        ? 0.016
        : min(0.04, now.difference(previous).inMicroseconds / 1000000);
    _inactivityMs += secondsPerTick * 1000;
    _flashMs = max(0, _flashMs - secondsPerTick * 1000);
    _shakeMs = max(0, _shakeMs - secondsPerTick * 1000);
    if (_flashMs == 0) _flashMessage = null;
    if (_inactivityMs >= inactivityTimeoutMs) {
      setState(() {
        _finishGame('Inactive for 20 seconds');
      });
      return;
    }

    _spawnClockMs += secondsPerTick * 1000;
    if (_spawnClockMs >= (_currentLevelConfig['spawnRate'] as double)) {
      _spawnClockMs = 0;
      _spawnWave();
    }

    if (_gameplaySize == Size.zero) return;
    for (final card in _syntaxCards) {
      if (card['spawned'] != true || card['sliced'] == true) continue;
      _updateMovingItem(
        card,
        secondsPerTick,
        now.millisecondsSinceEpoch.toDouble(),
      );
    }
    _removeDeadObjects(_gameplaySize.width, _gameplaySize.height);
    _updateEffects(secondsPerTick);

    if (mounted) setState(() {});
  }

  int _comboMultiplier(int currentCombo) {
    if (currentCombo >= 10) return 5;
    if (currentCombo >= 5) return 3;
    if (currentCombo >= 3) return 2;
    return 1;
  }

  void _applySliceResult(Map<String, dynamic> card, Offset start, Offset end) {
    if (_gameOver ||
        _levelCleared ||
        _announcementVisible ||
        card['sliced'] == true) {
      return;
    }

    card['sliced'] = true;
    _inactivityMs = 0;
    final kind = card['kind'] as String;
    _playSliceSound();

    if (kind == 'correct') {
      combo += 1;
      final multiplier = _comboMultiplier(combo);
      if (comboMilestones.contains(combo) && lives < 3) {
        lives = min(3, lives + 1);
      }
      _playCorrectSound();
      if (comboMilestones.contains(combo)) _playComboSound();
      score += 40 * multiplier;
      _addParticleBurst(
        Offset(card['x'] as double, card['y'] as double),
        const Color(0xFFFFD15D),
        18,
      );
      _addSliceBurst(
        Offset(card['x'] as double, card['y'] as double),
        start,
        end,
      );
      if (comboMilestones.contains(combo)) {
        _addHitFeedback(
          center: Offset(card['x'] as double, (card['y'] as double) - 80),
          title: '$combo COMBO',
          detail: 'Score multiplier ×$multiplier',
          color: const Color(0xFFFFD15D),
        );
      }
      _nextPieceIndex += 1;
      _slicedPieces = _syntaxCards
          .where((item) => item['kind'] == 'correct')
          .take(_nextPieceIndex)
          .map((item) => item['text'] as String)
          .toList();

      final requiredPieces = (_currentChallenge['pieces'] as List).length;
      if (_nextPieceIndex >= requiredPieces) {
        completedOutputs += 1;
        score += 120 * multiplier;
        _addParticleBurst(
          Offset(_gameplaySize.width / 2, _gameplaySize.height * 0.42),
          const Color(0xFFFFD15D),
          34,
        );
        _feedback = 'OUTPUT DONE';
        _triggerVisualFeedback('OUTPUT DONE', const Color(0xFFEAFaff));
        _prepareNextChallenge();
      } else {
        _spawnNextCorrectPiece();
        _feedback = '$combo COMBO  •  x$multiplier';
      }
      return;
    }

    _mistakes += 1;
    combo = 0;
    lives = max(0, lives - 1);
    score = max(0, score - (kind == 'bomb' ? 100 : 70));
    _playErrorSound();
    _feedback = kind == 'bomb' ? 'BOMB HIT' : 'DECOY HIT';
    _triggerVisualFeedback(
      kind == 'bomb' ? 'BOMB HIT' : 'DECOY HIT',
      const Color(0xFFFF8FA0),
    );
    _addParticleBurst(
      Offset(card['x'] as double, card['y'] as double),
      const Color(0xFFFF334F),
      kind == 'bomb' ? 36 : 22,
    );
    _addHitFeedback(
      center: Offset(card['x'] as double, card['y'] as double),
      title: kind == 'bomb' ? 'LIFE LOST' : 'WRONG SYNTAX',
      detail: '${max(0, lives)} / 3 LIVES',
      color: const Color(0xFFFF6F82),
    );
    if (lives == 0) {
      _finishGame('No lives remaining');
    }
  }

  void _finishGame(String reason) {
    if (_gameOver || _levelCleared) return;
    _gameOver = true;
    _elapsedSeconds = _runStartedAt == null
        ? 0
        : DateTime.now().difference(_runStartedAt!).inSeconds;
    _particles.clear();
    _trails.clear();
    _sliceBursts.clear();
    _floatingFeedback.clear();
    _announcementVisible = false;
    _announcementTimer?.cancel();
    _announcementTimer = null;
    _guidelinesVisible = false;
    _tutorialVisible = false;
    _tutorialTimer?.cancel();
    _tutorialTimer = null;
    _feedback = 'GAME OVER';
    unawaited(_submitResultIfNeeded());
  }

  int _calculateStars() {
    return _levelCleared ? 3 : 0;
  }

  void _prepareNextChallenge() {
    if (completedOutputs >= _requiredOutputs) {
      _levelCleared = true;
      _announcementVisible = false;
      _announcementTimer?.cancel();
      _announcementTimer = null;
      _feedback = 'LEVEL CLEARED';
      unawaited(_submitResultIfNeeded());
      return;
    }

    _startAnnouncementSequence(advanceChallenge: true);
  }

  void _openGuidelines() {
    _tutorialTimer?.cancel();
    setState(() {
      _guidelinesVisible = true;
      _tutorialVisible = false;
      _guidelinesPage = 0;
    });
  }

  void _closeGuidelines() {
    if (widget.firstPlay && !_introCompleted) {
      _openTutorial();
      return;
    }
    if (!mounted) return;
    setState(() {
      _guidelinesVisible = false;
      _inactivityMs = 0;
      _lastPhysicsTime = DateTime.now();
      _tutorialHighlightRect = null;
    });
  }

  void _openTutorial() {
    _tutorialTimer?.cancel();
    setState(() {
      _guidelinesVisible = false;
      _tutorialVisible = true;
      _tutorialPage = 0;
      _tutorialElapsedMs = 0;
    });
    _refreshTutorialHighlight();
    _tutorialTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted || !_tutorialVisible) return;
      setState(() {
        _tutorialElapsedMs += 80;
        final duration = _tutorialDurationMs(_tutorialPage);
        if (_tutorialElapsedMs > duration) _tutorialElapsedMs = duration;
      });
    });
  }

  void _closeTutorial() {
    if (widget.firstPlay && !_introCompleted) {
      _introCompleted = true;
      if (_tutorialPage == _tutorialSteps.length - 1) {
        unawaited(GameIntro.complete(1));
      }
      _startAnnouncementSequence(advanceChallenge: false);
    }
    _tutorialTimer?.cancel();
    _tutorialTimer = null;
    if (!mounted) return;
    setState(() {
      _tutorialVisible = false;
      _tutorialElapsedMs = 0;
      _inactivityMs = 0;
      _lastPhysicsTime = DateTime.now();
      _tutorialHighlightRect = null;
    });
  }

  double _tutorialDurationMs(int page) {
    if (page == 1) return 3000;
    if (page == 2) return 3600;
    if (page == 3) {
      return ((_currentChallenge['pieces'] as List).length * 1800 + 300)
          .toDouble();
    }
    return 0;
  }

  void _nextTutorialPage() {
    if (_tutorialPage >= _tutorialSteps.length - 1) {
      _closeTutorial();
      return;
    }
    setState(() {
      _tutorialPage += 1;
      _tutorialElapsedMs = 0;
    });
    _refreshTutorialHighlight();
  }

  void _previousTutorialPage() {
    if (_tutorialPage == 0) {
      _closeTutorial();
      return;
    }
    setState(() {
      _tutorialPage -= 1;
      _tutorialElapsedMs = 0;
    });
    _refreshTutorialHighlight();
  }

  void _sliceCardAtSwipe(Offset start, Offset end, Size areaSize) {
    for (final card in _syntaxCards) {
      if (card['spawned'] != true || card['sliced'] == true) continue;

      final isBomb = card['kind'] == 'bomb';
      final center = Offset(card['x'] as double, card['y'] as double);
      final collisionRadius = isBomb
          ? 58 * (card['renderScale'] as double)
          : max(
              (card['width'] as double) * 0.45,
              (card['height'] as double) * 0.55,
            );
      if (!_segmentNearPoint(start, end, center, collisionRadius)) continue;

      if (card['kind'] == 'correct' && card['pieceIndex'] != _nextPieceIndex) {
        setState(() {
          _feedback = 'FOLLOW THE CORRECT CODE ORDER';
        });
        return;
      }

      setState(() {
        _applySliceResult(card, start, end);
      });
      return;
    }
  }

  bool _segmentNearPoint(
    Offset start,
    Offset end,
    Offset point,
    double radius,
  ) {
    final vector = end - start;
    final offset = point - start;
    final lengthSquared = vector.distanceSquared;
    final ratio = lengthSquared == 0
        ? 0.0
        : (offset.dx * vector.dx + offset.dy * vector.dy) / lengthSquared;
    final clampedRatio = ratio.clamp(0.0, 1.0).toDouble();
    final closest = start + vector * clampedRatio;
    return (point - closest).distanceSquared <= radius * radius;
  }

  void _handleSwipeStart(DragStartDetails details) {
    if (_gameOver ||
        _levelCleared ||
        _announcementVisible ||
        _guidelinesVisible ||
        _tutorialVisible) {
      return;
    }
    _resumeBackgroundMusic();
    _lastSwipePosition = details.localPosition;
  }

  void _handleSwipeUpdate(DragUpdateDetails details, Size areaSize) {
    if (_gameOver ||
        _levelCleared ||
        _announcementVisible ||
        _guidelinesVisible ||
        _tutorialVisible) {
      return;
    }
    final previous = _lastSwipePosition;
    final current = details.localPosition;
    if (previous != null) {
      _trails.add({'a': previous, 'b': current, 'life': 0.18});
      _sliceCardAtSwipe(previous, current, areaSize);
    }
    _lastSwipePosition = current;
  }

  void _handleSwipeEnd(DragEndDetails details) {
    _lastSwipePosition = null;
  }

  Widget hudValue(
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: panelBackground,
          border: Border.all(color: panelBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFFB8C2D1),
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: valueColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget codePanel(String title, String code, {Color accent = gold}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: codeBackground,
        border: Border.all(color: accent.withValues(alpha: 0.8), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Roboto',
              color: accent,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            code,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFFD7DEE9),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget outputProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelBackground,
        border: Border.all(color: panelBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OUTPUT PROGRESS',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFFB8C2D1),
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$completedOutputs / $_requiredOutputs',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completedOutputs / _requiredOutputs,
              minHeight: 8,
              backgroundColor: Color(0xFF374151),
              valueColor: AlwaysStoppedAnimation<Color>(gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget syntaxCard(Map<String, dynamic> card, double width, double height) {
    final isBomb = card['kind'] == 'bomb';
    final cardWidth = card['width'] as double;
    final cardHeight = card['height'] as double;
    final left = (card['x'] as double) - cardWidth / 2;
    final top = (card['y'] as double) - cardHeight / 2;
    final rotation = card['rotation'] as double;
    final isNext =
        card['kind'] == 'correct' && card['pieceIndex'] == _nextPieceIndex;
    final cardColor = isNext ? green : gold;

    if (isBomb) {
      return Positioned(
        left: left,
        top: top,
        width: cardWidth,
        height: cardHeight,
        child: Transform.rotate(
          angle: rotation,
          child: CustomPaint(
            painter: _GameTwoObjectPainter(
              kind: 'bomb',
              text: card['text'] as String,
              textColor: const Color(0xFFFF334F),
              baseWidth: card['baseWidth'] as double,
              baseHeight: card['baseHeight'] as double,
              renderScale: card['renderScale'] as double,
            ),
          ),
        ),
      );
    }

    final decoy = card['kind'] == 'wrong';
    final syntaxColor = decoy ? red : cardColor;

    return Positioned(
      left: left,
      top: top,
      width: cardWidth,
      height: cardHeight,
      child: Transform.rotate(
        angle: rotation,
        child: CustomPaint(
          painter: _GameTwoObjectPainter(
            kind: 'syntax',
            text: card['text'] as String,
            textColor: syntaxColor,
            baseWidth: card['baseWidth'] as double,
            baseHeight: card['baseHeight'] as double,
            renderScale: card['renderScale'] as double,
          ),
        ),
      ),
    );
  }

  void _retryLevel() {
    if (_resultSavePending) return;
    setState(_resetGameState);
  }

  Future<void> _submitResultIfNeeded() async {
    if (_resultSubmitted) return;
    _resultSubmitted = true;
    _resultSavePending = true;
    final runId = _runId;
    final resultLevel = _currentLevel;
    final completed = _levelCleared;
    var saved = false;
    try {
      saved = await GameData.recordLevelResult(
        game: 1,
        number: resultLevel,
        score: max(0, score),
        stars: completed ? 3 : 0,
        completed: completed,
      );
    } catch (_) {
      saved = false;
    }
    if (!mounted || runId != _runId) return;
    setState(() {
      _resultSavePending = false;
      _resultSaveSucceeded = saved;
    });
  }

  void _nextLevel() {
    if (_resultSavePending ||
        !_levelCleared ||
        _resultSaveSucceeded != true ||
        _currentLevel >= 5) {
      return;
    }
    final next = _currentLevel + 1;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameEntry(
          game: 1,
          level: next,
          builder: (_) => Game2Page(selectedLevel: next),
        ),
      ),
    );
  }

  Widget resultOverlay() {
    final successful = _levelCleared;
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final metrics = <ResultMetric>[
      ResultMetric(
        label: 'Stars',
        value: _resultSavePending ? '...' : '${_calculateStars()}',
        icon: Icons.star,
      ),
      ResultMetric(
        label: 'Outputs',
        value: '$completedOutputs/$_requiredOutputs',
        icon: Icons.circle_outlined,
      ),
      ResultMetric(
        label: 'Mistakes',
        value: '$_mistakes',
        icon: Icons.gps_fixed,
      ),
      ResultMetric(
        label: 'Time',
        value: '$minutes:${seconds.toString().padLeft(2, '0')}',
        icon: Icons.alarm,
      ),
      ResultMetric(
        label: 'Score',
        value: _resultSavePending ? '...' : '$score',
        icon: Icons.emoji_events,
      ),
    ];
    final canAdvance =
        successful &&
        _currentLevel < 5 &&
        !_resultSavePending &&
        _resultSaveSucceeded == true;
    return Positioned.fill(
      child: GameCompletionFlow(
        key: ValueKey(_runId),
        successful: successful,
        child: IllustratedResultsOverlay(
          background: 'assets/results/results-frame.png',
          metrics: metrics,
          canAdvance:
              successful &&
              _currentLevel < 5 &&
              !_resultSavePending &&
              _resultSaveSucceeded == true,
          saving: _resultSavePending,
          onNext: _nextLevel,
          onRetry: _retryLevel,
          onBack: () => Navigator.pop(context),
          retryLabel: successfulLabel(canAdvance),
        ),
      ),
    );
  }

  String successfulLabel(bool canAdvance) =>
      _levelCleared ? 'Play Again' : 'Retry Level';

  Widget _resultButton(String label, VoidCallback? onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF172134),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _guideImageButton(
    String label,
    VoidCallback onPressed, {
    double? height,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/game2/buttons.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFFFFF8DE),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Color(0xFF24551D), offset: Offset(1, 2))],
          ),
        ),
      ),
    );
  }

  Widget gameplayArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaSize = Size(constraints.maxWidth, constraints.maxHeight);
        _gameplaySize = areaSize;
        final tutorialDuration = _tutorialDurationMs(_tutorialPage);
        final tutorialProgress = tutorialDuration == 0
            ? 0.0
            : (_tutorialElapsedMs / tutorialDuration)
                  .clamp(0.0, 1.0)
                  .toDouble();
        final tutorialDemoKind =
            _tutorialPage == 2 && _tutorialElapsedMs >= 1800
            ? 'bomb'
            : _tutorialPage == 2
            ? 'wrong'
            : 'syntax';
        final tutorialDemoColor = tutorialDemoKind == 'bomb'
            ? const Color(0xFFFF334F)
            : tutorialDemoKind == 'wrong'
            ? const Color(0xFFFF334F)
            : const Color(0xFF74FF8A);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _handleSwipeStart,
          onPanUpdate: (details) => _handleSwipeUpdate(details, areaSize),
          onPanEnd: _handleSwipeEnd,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/game2/industrial-frame-background.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(color: Color(0xFF050505));
                  },
                ),
              ),
              Positioned.fill(child: _codeRain()),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0x22050A12),
                        const Color(0x99050A12),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _GameFramePainter()),
                ),
              ),
              for (final card in _syntaxCards)
                if (card['spawned'] == true && card['sliced'] != true)
                  syntaxCard(card, areaSize.width, areaSize.height),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GameTwoEffectsPainter(
                      particles: _particles,
                      trails: _trails,
                      sliceBursts: _sliceBursts,
                      floatingFeedback: _floatingFeedback,
                    ),
                  ),
                ),
              ),
              if (_tutorialVisible && _tutorialPage <= 3)
                Positioned.fromRect(
                  rect: _tutorialDemoPaintRect(areaSize),
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TutorialDemoPainter(
                        kind: tutorialDemoKind,
                        color: tutorialDemoColor,
                        progress: tutorialProgress,
                        text: tutorialDemoKind == 'bomb'
                            ? 'BOMB'
                            : tutorialDemoKind == 'wrong'
                            ? 'WRONG'
                            : 'System',
                        showSwipe: _tutorialPage == 1 || _tutorialPage == 3,
                        pieces: _tutorialPage == 3
                            ? ((_currentChallenge['pieces'] as List?) ?? [])
                                  .map((piece) => piece.toString())
                                  .toList()
                            : const [],
                      ),
                    ),
                  ),
                ),
              if (_flashMessage != null && _flashMs > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(
                          _shakeMs > 0 ? sin(_shakeMs / 28) * 10 : 0,
                          _flashMs > 0 ? -8 : 0,
                        ),
                        child: Opacity(
                          opacity: (_flashMs / 780).clamp(0.0, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0x9E030A15),
                              border: Border.all(
                                color: _flashColor.withValues(alpha: .55),
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _flashColor.withValues(alpha: .28),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              child: Text(
                                _flashMessage!,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: _flashColor,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(color: _flashColor, blurRadius: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 18,
                child: Text(
                  _feedback,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFFEAFaff),
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Color(0xCC36D9FF), blurRadius: 10)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _codeRain() {
    const rainStyle = TextStyle(
      fontFamily: 'Roboto',
      color: Color(0x2436D9FF),
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 12,
      height: 1.8,
    );
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    final entries = [
      ('public static void main', .07, 13000.0, 0.0),
      ('System.out.println();', .25, 18000.0, -7000.0),
      ('if () { return; }', .70, 15000.0, -4000.0),
      ('class JavaSlice', .89, 20000.0, -12000.0),
    ];
    return IgnorePointer(
      child: Opacity(
        opacity: 0.72,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            return Stack(
              children: [
                for (final entry in entries)
                  Positioned(
                    left: constraints.maxWidth * entry.$2,
                    top:
                        -120 +
                        ((now + entry.$4) % entry.$3) /
                            entry.$3 *
                            (height + 120),
                    child: Text(entry.$1, style: rainStyle),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _announcementOverlay() {
    final fadeOpacity = _announcementElapsedMs < 350
        ? (_announcementElapsedMs / 350).clamp(0.0, 1.0).toDouble()
        : _announcementElapsedMs >= 8150
        ? ((8500 - _announcementElapsedMs) / 350).clamp(0.0, 1.0).toDouble()
        : 1.0;
    return Positioned.fill(
      child: Opacity(
        opacity: fadeOpacity,
        child: Container(
          color: const Color(0xDB040A0E),
          padding: const EdgeInsets.all(8),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardWidth = min(
                  min(constraints.maxWidth * .94, 900.0),
                  (constraints.maxHeight - 16) * 611 / 405,
                );
                final boardHeight = boardWidth * 405 / 611;
                final challengeNumber = _challengeIndex + 1;
                final target = _currentChallenge['code'] as String;
                return SizedBox(
                  width: boardWidth,
                  height: boardHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/game2/announcement-board.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                      Positioned(
                        left: boardWidth * .125,
                        right: boardWidth * .125,
                        top: boardHeight * .21,
                        bottom: boardHeight * .12,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _announcementCountdown == 0
                                    ? 'CHALLENGE ANNOUNCEMENT'
                                    : 'GET READY!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: const Color(0xFF4B2D1A),
                                  fontSize: boardWidth < 420
                                      ? 19
                                      : min(38.0, boardWidth * .055) - 5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              SizedBox(height: boardHeight * .018),
                              if (_announcementCountdown == 0) ...[
                                Text(
                                  'READY?',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Color(0xFF7B3F22),
                                    fontSize: boardWidth < 420
                                        ? 21
                                        : min(38.0, boardWidth * .06) - 5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: boardHeight * .012),
                                const Divider(
                                  color: Color(0xFF9B6541),
                                  thickness: 1.2,
                                ),
                                Text(
                                  'LEVEL $_currentLevel · CHALLENGE '
                                  '$challengeNumber/${_currentLevelChallenges.length}: '
                                  'SLASH THE CORRECT CODE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Color(0xFF70401F),
                                    fontSize: boardWidth < 420
                                        ? 15
                                        : min(21.0, boardWidth * .033),
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                  ),
                                ),
                                SizedBox(height: boardHeight * .02),
                                Text(
                                  'TARGET CODE',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Color(0xFF7B3F22),
                                    fontSize: boardWidth < 420
                                        ? 14
                                        : min(18.0, boardWidth * .029),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: boardHeight * .012),
                                Text(
                                  target,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Color(0xFF4B2D1A),
                                    fontSize: boardWidth < 420
                                        ? 15
                                        : min(18.0, boardWidth * .029),
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  '$_announcementCountdown',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: const Color(0xFF7B3F22),
                                    fontSize: boardWidth < 420
                                        ? 70
                                        : min(108.0, boardWidth * .15),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _guidelinesOverlay() {
    final items = <Map<String, String>>[
      {
        'icon': 'icon-trophy.png',
        'text':
            'Complete $_requiredOutputs Java output(s) to clear Level $_currentLevel.',
      },
      {
        'icon': 'icon-code.png',
        'text':
            'Slice gold syntax cards in the exact order shown by Java Code.',
      },
      {
        'icon': 'icon-hazard.png',
        'text':
            'Avoid red decoy cards and bombs while protecting your 3 Lives.',
      },
      {
        'icon': 'icon-clock.png',
        'text': 'If you do not slice anything for 20 consecutive seconds, the game ends due to inactivity.',
      },
      {
        'icon': 'icon-score.png',
        'text': 'Correct syntax slices earn 40 base points, multiplied by x2 at Combo 3, x3 at Combo 5, and x5 at Combo 10.',
      },
      {
        'icon': 'icon-score.png',
        'text': 'Each completed Java output adds a 120-point completion reward using the active Combo multiplier.',
      },
      {
        'icon': 'icon-score.png',
        'text':
            'Recorded base score: syntax slice rewards + ($_requiredOutputs completed outputs x completion reward) - decoy/bomb penalties.',
      },
      {
        'icon': 'icon-score.png',
        'text':
            'With no decoy or bomb mistakes, the estimated Level $_currentLevel base score is $_noMistakeScore points across about $_requiredSyntaxSlices required syntax slices.',
      },
      {
        'icon': 'icon-trophy.png',
        'text':
            'Clear $_requiredOutputs / $_requiredOutputs Outputs to pass this level.',
      },
      {
        'icon': 'icon-trophy.png',
        'text': 'Passing the level unlocks the next available Game 2 level.',
      },
    ];

    return Positioned.fill(
      child: Container(
        color: const Color(0xAD17121C),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                image: const DecorationImage(
                  image: AssetImage('assets/game2/Guidelinesformobile.png'),
                  fit: BoxFit.fill,
                ),
                borderRadius: BorderRadius.zero,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x550F172A),
                    blurRadius: 30,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Code Ninja Guide',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Color(0xFF0F172A),
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _closeGuidelines,
                        icon: const Icon(Icons.close),
                        color: const Color(0xFF475569),
                        tooltip: 'Close guidelines',
                      ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Read the output target, hazards, score, Stars, and level-only requirements before you begin.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFF475569),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEDE9FE),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/game2/${items[index]['icon']}',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                items[index]['text']!,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Color(0xFF334155),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _guideImageButton('Back to game', _closeGuidelines),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _originalGuidelinesOverlay() {
    final items = <Map<String, String>>[
      {
        'icon': 'assets/game2/icon-code.png',
        'text': 'Slice the correct Java syntax cards in order.',
      },
      {
        'icon': 'assets/game2/icon-hazard.png',
        'text': 'Avoid decoy cards and bombs.',
      },
      {
        'icon': 'assets/game2/icon-trophy.png',
        'text': 'Complete the required Java outputs to clear the level.',
      },
      {
        'icon': 'assets/guidelines/icon-move.png',
        'text':
            'Use mouse, touch, or pointer drag to slice moving syntax cards.',
      },
      {
        'icon': 'assets/game2/icon-hazard.png',
        'text': 'Gold syntax cards are correct targets; red decoy cards and bombs are hazards.',
      },
      {
        'icon': 'assets/game2/icon-hazard.png',
        'text': 'Wrong slices and bombs remove Lives and reset Combo.',
      },
      {
        'icon': 'assets/game2/icon-score.png',
        'text': 'Correct slices build Combo and increase score rewards.',
      },
      {
        'icon': 'assets/game2/icon-trophy.png',
        'text': 'Clear the required outputs to complete the level.',
      },
      {
        'icon': 'assets/guidelines/icon-star.png',
        'text': 'Earn at least 2 Stars to unlock the next level.',
      },
    ];
    final pageItems = _guidelinesPage == 0
        ? items.sublist(0, 3)
        : items.sublist(3);
    final pageTitle = _guidelinesPage == 0
        ? 'Code Ninja Guide'
        : 'General Game Guidelines';
    final isFirst = _guidelinesPage == 0;

    return Positioned.fill(
      child: Container(
        color: const Color(0xFF142726),
        padding: const EdgeInsets.all(6),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardWidth = min(
                min(constraints.maxWidth * .94, constraints.maxHeight * 1.56),
                960.0,
              );
              final boardHeight = min(
                min(constraints.maxHeight * .94, constraints.maxWidth * .566),
                579.0,
              );
              final headingFontSize = (constraints.maxHeight * .024)
                  .clamp(15.0, 18.0)
                  .toDouble();
              final instructionFontSize = min(
                14.0,
                max(
                  10.5,
                  min(constraints.maxHeight * .018, boardHeight * .055),
                ),
              );
              final iconSize = min(22.0, max(18.0, boardWidth * .022));
              final rowVerticalPadding = pageItems.length > 3 ? 2.0 : 4.0;
              // Keep the complete footer on the upper visual centerline of
              // the source artwork's horizontal timber.
              final footerCenter = boardHeight * .86;
              final footerHeight = min(boardHeight * .16, 84.0);
              final footerButtonHeight = min(boardHeight * .14, 72.0);
              final footerFontSize = min(14.0, max(12.0, boardHeight * .024));
              final footerBottom = max(
                boardHeight - footerCenter - footerHeight / 2,
                4.0,
              );
              return SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/game2/Guidelinesformobile.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      left: boardWidth * .14,
                      right: boardWidth * .14,
                      top: boardHeight * .23,
                      bottom: boardHeight * .20,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF397E35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pageTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: Color(0xFFFFF8DA),
                                fontSize: headingFontSize,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: pageItems.length,
                              itemBuilder: (context, index) {
                                final item = pageItems[index];
                                return Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: rowVerticalPadding,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: iconSize,
                                            height: iconSize,
                                            child: Image.asset(
                                              item['icon']!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item['text']!,
                                              softWrap: true,
                                              style: TextStyle(
                                                fontFamily: 'Roboto',
                                                color: const Color(0xFF392812),
                                                fontSize: instructionFontSize,
                                                height: 1.25,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 1,
                                      width: double.infinity,
                                      child: CustomPaint(
                                        painter: _DashedLinePainter(),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: boardWidth * .20,
                      right: boardWidth * .20,
                      bottom: footerBottom,
                      height: footerHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _guideImageButton(
                              isFirst ? 'Back to game' : 'Back',
                              isFirst
                                  ? _closeGuidelines
                                  : () => setState(() => _guidelinesPage = 0),
                              height: footerButtonHeight,
                            ),
                          ),
                          SizedBox(
                            width: min(70.0, boardWidth * .12),
                            height: footerButtonHeight,
                            child: Center(
                              child: Text(
                                '${_guidelinesPage + 1} / 2',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Color(0xFFFFF2CA),
                                  fontSize: footerFontSize,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _guideImageButton(
                              _guidelinesPage == 1 ? 'Start' : 'Next',
                              _guidelinesPage == 1
                                  ? _closeGuidelines
                                  : () => setState(() => _guidelinesPage = 1),
                              height: footerButtonHeight,
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
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _twoPageGuidelinesOverlay() {
    final items = <Map<String, String>>[
      {
        'icon': 'icon-trophy.png',
        'text':
            'Complete $_requiredOutputs Java output(s) to clear Level $_currentLevel.',
      },
      {
        'icon': 'icon-code.png',
        'text':
            'Slice gold syntax cards in the exact order shown by Java Code.',
      },
      {
        'icon': 'icon-hazard.png',
        'text':
            'Avoid red decoy cards and bombs while protecting your 3 Lives.',
      },
      {
        'icon': 'icon-clock.png',
        'text': 'If you do not slice anything for 20 consecutive seconds, the game ends due to inactivity.',
      },
      {
        'icon': 'icon-score.png',
        'text': 'Correct syntax slices earn 40 base points, multiplied by x2 at Combo 3, x3 at Combo 5, and x5 at Combo 10.',
      },
      {
        'icon': 'icon-score.png',
        'text': 'Each completed Java output adds a 120-point completion reward using the active Combo multiplier.',
      },
      {
        'icon': 'icon-score.png',
        'text':
            'Recorded base score: syntax slice rewards + ($_requiredOutputs completed outputs x completion reward) - decoy/bomb penalties.',
      },
      {
        'icon': 'icon-score.png',
        'text':
            'With no decoy or bomb mistakes, the estimated Level $_currentLevel base score is $_noMistakeScore points across about $_requiredSyntaxSlices required syntax slices.',
      },
      {
        'icon': 'icon-trophy.png',
        'text':
            'Clear $_requiredOutputs / $_requiredOutputs Outputs to pass this level.',
      },
      {
        'icon': 'icon-trophy.png',
        'text': 'Passing the level unlocks the next available Game 2 level.',
      },
    ];
    final split = (items.length / 2).ceil();
    final pageItems = _guidelinesPage == 0
        ? items.sublist(0, split)
        : items.sublist(split);
    final pageTitle = _guidelinesPage == 0
        ? 'Code Ninja Guide'
        : 'Level $_currentLevel Guide';
    final isFirst = _guidelinesPage == 0;
    final isLast = _guidelinesPage == 1;

    return Positioned.fill(
      child: Container(
        color: const Color(0xDB040A0E),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = min(constraints.maxWidth * .94, 760.0);
              final height = min(constraints.maxHeight * .90, 560.0);
              return SizedBox(
                width: width,
                height: height,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    image: const DecorationImage(
                      image: AssetImage('assets/game2/Guidelinesformobile.png'),
                      fit: BoxFit.fill,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 30,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: height * .18),
                      Text(
                        pageTitle.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: pageItems.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = pageItems[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Image.asset(
                                    'assets/game2/${item['icon']}',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item['text']!,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      color: Color(0xFF334155),
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _resultButton(
                            isFirst ? 'Back to game' : 'Back',
                            isFirst
                                ? _closeGuidelines
                                : () => setState(() => _guidelinesPage = 0),
                          ),
                          Text(
                            '${_guidelinesPage + 1} / 2',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _resultButton(
                            isLast ? 'Continue' : 'Next',
                            isLast
                                ? _closeGuidelines
                                : () => setState(() => _guidelinesPage = 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  GlobalKey? _tutorialTargetKey() {
    if (_tutorialPage == 0) return _javaCodeKey;
    if (_tutorialPage == 4) return _livesKey;
    if (_tutorialPage == 5) return _outputKey;
    return null;
  }

  Rect _tutorialDemoRect(Size size) {
    final width = min(220.0, size.width * .32);
    const height = 96.0;
    return Rect.fromLTWH(
      size.width * .55 - width / 2,
      size.height * .57 - height / 2,
      width,
      height,
    );
  }

  Rect _tutorialDemoPaintRect(Size size) {
    final demo = _tutorialDemoRect(size);
    return Rect.fromLTWH(demo.left, max(0, demo.top - 42), demo.width, 180);
  }

  void _refreshTutorialHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tutorialVisible) return;
      final targetKey = _tutorialTargetKey();
      final targetBox =
          targetKey?.currentContext?.findRenderObject() as RenderBox?;
      final overlayBox =
          _tutorialOverlayKey.currentContext?.findRenderObject() as RenderBox?;
      Rect? nextRect;
      if (targetBox != null && overlayBox != null) {
        final topLeft = targetBox.localToGlobal(
          Offset.zero,
          ancestor: overlayBox,
        );
        nextRect = topLeft & targetBox.size;
      } else if (overlayBox != null &&
          (_tutorialPage == 1 || _tutorialPage == 2 || _tutorialPage == 3)) {
        nextRect = _tutorialDemoRect(overlayBox.size);
      }
      if (nextRect == _tutorialHighlightRect) return;
      setState(() => _tutorialHighlightRect = nextRect);
    });
  }

  Rect _tutorialPanelRect(Size viewport, Rect? target) {
    final panelWidth = min(520.0, max(0.0, viewport.width - 16));
    final panelHeight = min(360.0, max(0.0, viewport.height - 16));
    final maxLeft = max(8.0, viewport.width - panelWidth - 8);
    final maxTop = max(8.0, viewport.height - panelHeight - 8);
    final candidates = <Offset>[
      Offset(maxLeft, maxTop),
      Offset(8, maxTop),
      Offset(maxLeft, 8),
      const Offset(8, 8),
    ];
    final blockers = <Rect>[
      if (target != null) target.inflate(8),
      Rect.fromLTWH(max(0, viewport.width - 370), 0, 370, 82),
      const Rect.fromLTWH(0, 0, 210, 82),
    ];
    final panelSize = Size(panelWidth, panelHeight);
    double overlapScore(Offset offset) {
      final panel = offset & panelSize;
      final score = blockers.fold<double>(0, (total, blocker) {
        final overlap = panel.intersect(blocker);
        return total + overlap.width * overlap.height;
      });
      if (target != null && panel.overlaps(target.inflate(8))) {
        return score + 1000000000;
      }
      return score;
    }

    candidates.sort((a, b) => overlapScore(a).compareTo(overlapScore(b)));
    return candidates.first & panelSize;
  }

  Widget _originalTutorialOverlay() {
    _refreshTutorialHighlight();
    final step = _tutorialSteps[_tutorialPage];
    final duration = _tutorialDurationMs(_tutorialPage);
    final progress = duration == 0
        ? 0.0
        : (_tutorialElapsedMs / duration).clamp(0.0, 1.0).toDouble();
    return Positioned.fill(
      child: Container(
        key: _tutorialOverlayKey,
        color: Colors.transparent,
        child: Stack(
          children: [
            if (_tutorialHighlightRect != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                left: _tutorialHighlightRect!.left,
                top: _tutorialHighlightRect!.top,
                width: _tutorialHighlightRect!.width,
                height: _tutorialHighlightRect!.height,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _tutorialPage == 2
                            ? const Color(0xFFF0A27D)
                            : const Color(0xFFFFE08B),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _tutorialPage == 2
                              ? const Color(0x66E57E53)
                              : const Color(0x80EFBE57),
                          blurRadius: _tutorialPage == 2 ? 12 : 18,
                          spreadRadius: _tutorialPage == 2 ? 0 : 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_tutorialHighlightRect != null)
              Positioned(
                left:
                    _tutorialHighlightRect!.left +
                    _tutorialHighlightRect!.width *
                        (_tutorialPage == 1 || _tutorialPage == 3
                            ? .15 + progress * .55
                            : .72),
                top: _tutorialPage == 1 || _tutorialPage == 3
                    ? _tutorialHighlightRect!.top +
                          _tutorialHighlightRect!.height * .38
                    : _tutorialHighlightRect!.bottom - 5,
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      sin((_tutorialElapsedMs / 260) * pi) * -3,
                    ),
                    child: Image.asset(
                      'assets/game2/tutorial-hand.png',
                      width: 45,
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final panelRect = _tutorialPanelRect(
                  Size(constraints.maxWidth, constraints.maxHeight),
                  _tutorialHighlightRect,
                );
                final panelWidth = panelRect.width;
                final panelHeight = panelRect.height;
                return Stack(
                  children: [
                    Positioned(
                      left: panelRect.left,
                      top: panelRect.top,
                      child: SizedBox(
                        width: panelWidth,
                        height: panelHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/game2/tutorial4.png',
                                fit: BoxFit.fill,
                              ),
                            ),
                            Positioned(
                              left: panelWidth * .088,
                              right: panelWidth * .088,
                              top: panelHeight * .305,
                              bottom: panelHeight * .117,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, contentConstraints) {
                                        return SingleChildScrollView(
                                          padding: EdgeInsets.zero,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight:
                                                  contentConstraints.maxHeight,
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    step['title']!,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontFamily: 'Roboto',
                                                      color: Color(0xFF5C3D26),
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    step['text']!,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontFamily: 'Roboto',
                                                      color: Color(0xFF563A24),
                                                      fontSize: 15,
                                                      height: 1.4,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _tutorialButton(
                                        'Back',
                                        _previousTutorialPage,
                                        enabled: _tutorialPage > 0,
                                      ),
                                      const Spacer(),
                                      _tutorialButton(
                                        _tutorialPage ==
                                                _tutorialSteps.length - 1
                                            ? 'Return to game'
                                            : 'Next',
                                        _nextTutorialPage,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: panelHeight * .14,
                              right: panelWidth * .12,
                              child: Text(
                                '${_tutorialPage + 1} / ${_tutorialSteps.length}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Color(0xFFFFF4D9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Positioned(
                              top: panelHeight * .10,
                              right: panelWidth * .025,
                              width: panelWidth * .10,
                              height: panelHeight * .17,
                              child: TextButton(
                                onPressed: _closeTutorial,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: Colors.transparent,
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tutorialButton(
    String label,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return SizedBox(
      height: 30,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF56331E),
          backgroundColor: const Color(0xFFE6C28A),
          disabledForegroundColor: const Color(0x9956331E),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: const BorderSide(color: Color(0xFF825731)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          shadowColor: const Color(0xFFA87742),
          elevation: 2,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _tutorialOverlay() {
    _refreshTutorialHighlight();
    final step = _tutorialSteps[_tutorialPage];
    final duration = _tutorialDurationMs(_tutorialPage);
    final progress = duration == 0
        ? 0.0
        : (_tutorialElapsedMs / duration).clamp(0.0, 1.0).toDouble();
    final demoKind = _tutorialPage == 2 ? 'bomb' : 'syntax';
    final demoColor = _tutorialPage == 2
        ? const Color(0xFFFF334F)
        : const Color(0xFF74FF8A);

    return Positioned.fill(
      child: Container(
        key: _tutorialOverlayKey,
        color: const Color(0xAD17121C),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            if (_tutorialHighlightRect != null)
              Positioned.fromRect(
                rect: _tutorialHighlightRect!,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF74FF8A),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xCC74FF8A),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                  maxHeight: 650,
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD6DEE5)),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x550F172A),
                        blurRadius: 30,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: _closeTutorial,
                          icon: const Icon(Icons.close),
                          color: const Color(0xFF475569),
                          tooltip: 'Close tutorial',
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 180,
                                child: Image.asset(
                                  'assets/game2/tutorial4.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.touch_app,
                                      size: 72,
                                      color: Color(0xFF0F766E),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step['title']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Color(0xFF0F172A),
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                step['text']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Color(0xFF475569),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              if (duration > 0) ...[
                                const SizedBox(height: 14),
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0F766E),
                                      ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 112,
                                width: double.infinity,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _TutorialDemoPainter(
                                          kind: demoKind,
                                          color: demoColor,
                                          progress: progress,
                                          text: _tutorialPage == 2
                                              ? 'BUG'
                                              : 'System',
                                        ),
                                      ),
                                    ),
                                    if (_tutorialPage == 1 ||
                                        _tutorialPage == 3)
                                      Positioned(
                                        left: 72 + progress * 170,
                                        top: 30,
                                        child: IgnorePointer(
                                          child: Image.asset(
                                            'assets/game2/tutorial-hand.png',
                                            width: 58,
                                            height: 70,
                                            fit: BoxFit.contain,
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
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _tutorialSteps.length,
                          (index) => Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index == _tutorialPage
                                  ? const Color(0xFF0F766E)
                                  : const Color(0xFFCCDBE0),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _resultButton('Back', _previousTutorialPage),
                          Text(
                            '${_tutorialPage + 1} / ${_tutorialSteps.length}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _resultButton(
                            _tutorialPage == _tutorialSteps.length - 1
                                ? 'Return to game'
                                : 'Next',
                            _nextTutorialPage,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_tutorialHighlightRect != null &&
                (_tutorialPage == 1 || _tutorialPage == 3))
              Positioned(
                left:
                    _tutorialHighlightRect!.left +
                    _tutorialHighlightRect!.width * (0.15 + progress * 0.55),
                top: _tutorialHighlightRect!.bottom - 8,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/game2/tutorial-hand.png',
                    width: 58,
                    height: 70,
                    fit: BoxFit.contain,
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
    return PopScope(
      canPop: !_resultSavePending,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth <= 760;
              final missionWidth = isMobile
                  ? min(300.0, constraints.maxWidth * .58)
                  : min(230.0, constraints.maxWidth * .25);
              final leftHudInset = isMobile
                  ? 18.0
                  : min(20.0, constraints.maxWidth * .03);
              final outputWidth = isMobile
                  ? min(140.0, constraints.maxWidth * .32)
                  : min(215.0, constraints.maxWidth * .18);
              final outputRight = isMobile ? 18.0 : 44.0;
              final livesTop = isMobile ? 72.0 : 76.0;
              return Container(
                color: const Color(0xFF050505),
                child: Stack(
                  children: [
                    Positioned.fill(child: gameplayArea()),
                    Positioned(
                      top: isMobile ? 14 : 18,
                      left: isMobile ? 14 : 28,
                      child: _scoreHud(isMobile),
                    ),
                    Positioned(
                      // Keep both widgets in one coordinate system so the
                      // panel follows the actual rendered bottom of Lives.
                      top: livesTop,
                      right: outputRight,
                      width: outputWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: KeyedSubtree(
                              key: _livesKey,
                              child: _livesHud(isMobile),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _rightHud(isMobile),
                        ],
                      ),
                    ),
                    Positioned(
                      top: isMobile ? 54 : 18,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SizedBox(
                          width: missionWidth,
                          child: _missionHud(isMobile),
                        ),
                      ),
                    ),
                    Positioned(
                      top: isMobile ? 16 : 22,
                      right: isMobile ? 8 : 16,
                      child: _actionHud(isMobile),
                    ),
                    Positioned(
                      top: isMobile ? 100 : 100,
                      left: leftHudInset,
                      width: isMobile
                          ? min(164, constraints.maxWidth * .40)
                          : min(240, constraints.maxWidth * .22),
                      child: _leftHud(isMobile),
                    ),
                    if (_gameOver || _levelCleared) resultOverlay(),
                    if (_announcementVisible) _announcementOverlay(),
                    if (_guidelinesVisible) _originalGuidelinesOverlay(),
                    if (_tutorialVisible) _originalTutorialOverlay(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _hudPanel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(13),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4B463C), width: 2),
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF62F2F2A), Color(0xF60B0D0E), Color(0xF61E1B18)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FFF1CA),
            blurRadius: 0,
            offset: Offset(0, 2),
          ),
          BoxShadow(color: Color(0x99FF9927), blurRadius: 18),
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(left: -9, top: -9, child: _hudScrew()),
          Positioned(right: -9, bottom: -9, child: _hudScrew()),
        ],
      ),
    );
  }

  Widget _hudScrew() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF151515), width: 2),
        gradient: const RadialGradient(
          center: Alignment(-.3, -.35),
          colors: [Color(0xFFD6C6A6), Color(0xFF71695D), Color(0xFF1D1B18)],
          stops: [0.13, 0.42, 1],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x33FFA332), spreadRadius: 1),
          BoxShadow(color: Color(0xCC000000), blurRadius: 4),
        ],
      ),
    );
  }

  Widget _scoreHud(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLAYER SCORE',
          style: TextStyle(
            color: const Color(0xFF8ADCF2),
            fontSize: mobile ? 14 : 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          '$score',
          style: TextStyle(
            color: const Color(0xFFEAFaff),
            fontSize: mobile ? 22 : 29,
            fontWeight: FontWeight.w900,
            shadows: const [Shadow(color: Color(0xFF36D9FF), blurRadius: 18)],
          ),
        ),
      ],
    );
  }

  Widget _livesHud(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'LIVES',
          style: TextStyle(
            color: const Color(0xFF8ADCF2),
            fontSize: mobile ? 7 : 8,
            fontWeight: FontWeight.w800,
            letterSpacing: mobile ? 1.2 : 1.5,
          ),
        ),
        Text(
          '${'♥' * lives}${'♡' * (3 - lives)}',
          style: TextStyle(
            color: const Color(0xFFFF526B),
            fontSize: mobile ? 23 : 34,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: mobile ? -1.0 : -1.5,
            shadows: const [Shadow(color: Color(0xFFFF526B), blurRadius: 12)],
          ),
        ),
      ],
    );
  }

  Widget _missionHud(bool mobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 8 : 15,
        vertical: mobile ? 5 : 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4A443A), width: 2),
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xF637342E), Color(0xF60D0E0D), Color(0xF6231E18)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x44FF9927), blurRadius: 18),
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'LEVEL $_currentLevel',
          style: TextStyle(
            color: const Color(0xFFFFD15D),
            fontSize: mobile ? 13 : 18,
            fontWeight: FontWeight.w900,
            letterSpacing: mobile ? 1.5 : 1.7,
            shadows: const [Shadow(color: Color(0xB8FFB72B), blurRadius: 14)],
          ),
        ),
      ),
    );
  }

  Widget _actionHud(bool mobile) {
    final buttonHeight = mobile ? 34.0 : 42.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(
          'GUIDELINES',
          _openGuidelines,
          buttonHeight,
          mobile ? 0 : 24,
        ),
        SizedBox(width: mobile ? 10 : 24),
        _actionButton(
          'GAME TUTORIAL',
          _openTutorial,
          buttonHeight,
          mobile ? 0 : 24,
        ),
        SizedBox(width: mobile ? 10 : 24),
        _actionButton('BACK', () => Navigator.pop(context), buttonHeight, 0),
      ],
    );
  }

  Widget _actionButton(
    String label,
    VoidCallback onPressed,
    double height,
    double widthGap,
  ) {
    return SizedBox(
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFF3FBFF),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: const BorderSide(color: Color(0xFFB8752D), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          backgroundColor: const Color(0xFF29241F),
          shadowColor: const Color(0x66FF9927),
          elevation: 8,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _leftHud(bool mobile) {
    final titleStyle = TextStyle(
      color: const Color(0xFFFFD15D),
      fontSize: mobile ? 12 : 16,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
    );
    final codeStyle = TextStyle(
      color: const Color(0xFFBCFF74),
      fontFamily: 'Roboto',
      fontSize: mobile ? 11 : 15,
      fontWeight: FontWeight.w800,
      height: 1.18,
      shadows: const [Shadow(color: Color(0x73BCFF74), blurRadius: 10)],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hudPanel(
          padding: EdgeInsets.all(mobile ? 7 : 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COMBO', style: titleStyle),
              SizedBox(height: mobile ? 3 : 4),
              Text(
                '${combo}x',
                style: TextStyle(
                  color: const Color(0xFFFFD15D),
                  fontSize: mobile ? 19 : 25,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Color(0xFFFFB72B), blurRadius: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: mobile ? 7 : 10),
        KeyedSubtree(
          key: _javaCodeKey,
          child: _hudPanel(
            padding: EdgeInsets.all(mobile ? 7 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JAVA CODE', style: titleStyle),
                SizedBox(height: mobile ? 3 : 5),
                Text(
                  'Correct Code:',
                  style: TextStyle(
                    color: const Color(0xFFFFD15D),
                    fontSize: mobile ? 9 : 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(_currentChallenge['code'] as String, style: codeStyle),
                SizedBox(height: mobile ? 4 : 6),
                Text(
                  'Sliced Code:',
                  style: TextStyle(
                    color: const Color(0xFFFFD15D),
                    fontSize: mobile ? 9 : 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _slicedPieces.isEmpty ? '____' : _slicedPieces.join(' '),
                  style: codeStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _rightHud(bool mobile) {
    return KeyedSubtree(
      key: _outputKey,
      child: _hudPanel(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 7 : 10,
          vertical: mobile ? 6 : 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'OUTPUT',
              style: TextStyle(
                color: const Color(0xFFFFD15D),
                fontSize: mobile ? 11 : 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: mobile ? 4 : 7),
            SizedBox(
              height: mobile ? 38 : 52,
              child: Center(
                child: Text(
                  _currentChallenge['output'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFEAFaff),
                    fontSize: mobile ? 11 : 16,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    shadows: const [
                      Shadow(color: Color(0x5936D9FF), blurRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0x248ADCF2)),
            SizedBox(height: mobile ? 3 : 5),
            Text(
              '$completedOutputs / $_requiredOutputs',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFFFD15D),
                fontSize: mobile ? 18 : 26,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Color(0xFFFFB72B), blurRadius: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialDemoPainter extends CustomPainter {
  const _TutorialDemoPainter({
    required this.kind,
    required this.color,
    required this.progress,
    required this.text,
    this.showSwipe = false,
    this.pieces = const [],
  });

  final String kind;
  final Color color;
  final double progress;
  final String text;
  final bool showSwipe;
  final List<String> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    var displayProgress = progress;
    var displayText = text;
    if (pieces.isNotEmpty) {
      final position = (progress * pieces.length)
          .clamp(0.0, pieces.length - .0001)
          .toDouble();
      final index = position.floor();
      displayProgress = position - index;
      displayText = pieces[index];
    }
    final renderScale = min(1.0, size.width / 220);
    _GameTwoObjectPainter(
      kind: kind == 'bomb' ? 'bomb' : 'syntax',
      text: displayText,
      textColor: color,
      baseWidth: kind == 'bomb' ? 118 : 220,
      baseHeight: kind == 'bomb' ? 138 : 96,
      renderScale: renderScale,
    ).paint(canvas, size);

    if (showSwipe && displayProgress > 0) {
      final start = Offset(size.width * .12, size.height * .83);
      final end = Offset(
        size.width * (.12 + displayProgress * .76),
        size.height * .83,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFFFFF0A5)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TutorialDemoPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.text != text ||
        oldDelegate.showSwipe != showSwipe ||
        oldDelegate.pieces != pieces;
  }
}

class _GameTwoEffectsPainter extends CustomPainter {
  const _GameTwoEffectsPainter({
    required this.particles,
    required this.trails,
    required this.sliceBursts,
    required this.floatingFeedback,
  });

  final List<Map<String, dynamic>> particles;
  final List<Map<String, dynamic>> trails;
  final List<Map<String, dynamic>> sliceBursts;
  final List<Map<String, dynamic>> floatingFeedback;

  @override
  void paint(Canvas canvas, Size size) {
    for (final trail in trails) {
      final life = trail['life'] as double;
      final alpha = (life / 0.18).clamp(0.0, 1.0).toDouble();
      final start = trail['a'] as Offset;
      final end = trail['b'] as Offset;
      final outer = Paint()
        ..color = const Color(0xFFBCFF74).withValues(alpha: alpha)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawLine(start, end, outer);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final particle in particles) {
      final life = particle['life'] as double;
      final alpha = (life * 1.5).clamp(0.0, 1.0).toDouble();
      final color = particle['color'] as Color;
      final x = particle['x'] as double;
      final y = particle['y'] as double;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 6, height: 6),
        Paint()..color = color.withValues(alpha: alpha),
      );
    }

    for (final burst in sliceBursts) {
      final life = burst['life'] as double;
      final maxLife = burst['maxLife'] as double;
      final alpha = (life / maxLife).clamp(0.0, 1.0).toDouble();
      final start = burst['a'] as Offset;
      final end = burst['b'] as Offset;
      final glow = Paint()
        ..color = const Color(0xFFFFD15D).withValues(alpha: alpha)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * alpha);
      canvas.drawLine(start, end, glow);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFFFFF3B0).withValues(alpha: alpha)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final feedback in floatingFeedback) {
      final life = feedback['life'] as double;
      final maxLife = feedback['maxLife'] as double;
      final alpha = (life / maxLife).clamp(0.0, 1.0).toDouble();
      final color = feedback['color'] as Color;
      final title = feedback['title'] as String;
      final detail = feedback['detail'] as String;
      final center = Offset(feedback['x'] as double, feedback['y'] as double);
      if (detail.isEmpty) {
        _paintText(
          canvas,
          title,
          center,
          color.withValues(alpha: alpha),
          22,
          shadowColor: const Color(0xFFFF9F27),
        );
        continue;
      }

      final boxWidth = max(190.0, detail.length * 8.0 + 40);
      final boxRect = Rect.fromCenter(
        center: center,
        width: min(size.width - 24, boxWidth),
        height: 70,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(16)),
        Paint()
          ..color = const Color(0xE62C261F).withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(16)),
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _paintText(
        canvas,
        title,
        Offset(center.dx, center.dy - 13),
        color.withValues(alpha: alpha),
        title.contains('COMBO') ? 28 : 19,
        shadowColor: color,
      );
      _paintText(
        canvas,
        detail,
        Offset(center.dx, center.dy + 15),
        const Color(0xFFF7EFE0).withValues(alpha: 1),
        12,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double fontSize, {
    Color? shadowColor,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          shadows: shadowColor == null
              ? null
              : [Shadow(color: shadowColor, blurRadius: 10)],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 360);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _GameTwoEffectsPainter oldDelegate) => true;
}

class _GameTwoObjectPainter extends CustomPainter {
  const _GameTwoObjectPainter({
    required this.kind,
    required this.text,
    required this.textColor,
    required this.baseWidth,
    required this.baseHeight,
    required this.renderScale,
  });

  final String kind;
  final String text;
  final Color textColor;
  final double baseWidth;
  final double baseHeight;
  final double renderScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (kind == 'bomb') {
      _paintBomb(canvas, size);
    } else {
      _paintSyntaxCard(canvas, size);
    }
  }

  void _paintSyntaxCard(Canvas canvas, Size size) {
    final w = baseWidth;
    final h = baseHeight;
    final left = -w / 2;
    final top = -h / 2;
    final right = w / 2;
    final bottom = h / 2;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(renderScale);

    final glow = Paint()
      ..color = textColor.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left + 4, top + 4, right - 4, bottom - 4),
        const Radius.circular(12),
      ),
      glow,
    );

    final shell = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFC6BDA9),
          Color(0xFF5E5B55),
          Color(0xFF272622),
          Color(0xFF696257),
          Color(0xFF171614),
        ],
        stops: [0, .12, .5, .88, 1],
      ).createShader(Rect.fromLTRB(left, top, right, bottom));
    final shellPath = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(12),
    );
    canvas.drawRRect(shellPath, shell);
    canvas.drawRRect(
      shellPath,
      Paint()
        ..color = const Color(0xFF090807)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final insetRect = Rect.fromLTRB(
      left + 14,
      top + 13,
      right - 14,
      bottom - 13,
    );
    final inset = RRect.fromRectAndRadius(insetRect, const Radius.circular(7));
    canvas.drawRRect(inset, Paint()..color = const Color(0xFF171512));
    canvas.drawRRect(
      inset,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x14FFCE6B), Color(0x2E000000), Color(0x0AFFCE6B)],
        ).createShader(insetRect)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      inset,
      Paint()
        ..color = const Color(0xFF4A4034)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final screwPositions = [
      Offset(left + 6, top + 6),
      Offset(right - 34, top + 6),
      Offset(left + 6, bottom - 26),
      Offset(right - 34, bottom - 26),
    ];
    for (final position in screwPositions) {
      final screwRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, 28, 20),
        const Radius.circular(5),
      );
      canvas.drawRRect(screwRect, Paint()..color = const Color(0xFF3F3C36));
      canvas.drawRRect(
        screwRect,
        Paint()
          ..color = const Color(0xFF1A1815)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        Offset(position.dx + 10, position.dy + 10),
        6,
        Paint()..color = const Color(0xFF141311),
      );
      canvas.drawCircle(
        Offset(position.dx + 10, position.dy + 10),
        6,
        Paint()
          ..color = const Color(0xFF8C8373)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final tracePaint = Paint()
      ..color = const Color(0x99EE8B2B)
      ..strokeWidth = 1;
    for (var index = 0; index < 6; index++) {
      final startX = left + 36 + index * ((w - 72) / 5);
      final startY = top + 17 + (index % 3) * 15;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + 12, startY - 4),
        tracePaint,
      );
    }

    final gearCenter = Offset(right - 48, top + 13);
    final gear = Path();
    for (var index = 0; index < 12; index++) {
      final angle = index * pi / 6;
      final radius = index.isOdd ? 14.0 : 18.0;
      final point =
          gearCenter + Offset(cos(angle) * radius, sin(angle) * radius);
      if (index == 0) {
        gear.moveTo(point.dx, point.dy);
      } else {
        gear.lineTo(point.dx, point.dy);
      }
    }
    gear.close();
    canvas.drawPath(gear, Paint()..color = const Color(0xFF2A2926));
    canvas.drawPath(
      gear,
      Paint()
        ..color = const Color(0xFF70695D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(gearCenter, 6, Paint()..color = const Color(0xFF111111));

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontFamily: 'Roboto',
          fontSize: 24,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(color: textColor, blurRadius: 12)],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: w - 58);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2 + 2),
    );
    canvas.restore();
  }

  void _paintBomb(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 14 * renderScale);
    canvas.scale(renderScale);

    final glow = Paint()
      ..color = const Color(0xFFFF526B)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(const Offset(0, 7), 48, glow);

    final body = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.32, -.41),
        radius: .95,
        colors: [
          Color(0xFFFF554D),
          Color(0xFFE92027),
          Color(0xFFAE0814),
          Color(0xFF67030B),
        ],
        stops: [0, .32, .72, 1],
      ).createShader(Rect.fromCircle(center: const Offset(0, 7), radius: 56));
    canvas.drawCircle(const Offset(0, 7), 48, body);
    canvas.drawCircle(
      const Offset(0, 7),
      48,
      Paint()
        ..color = const Color(0xFF4C050B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-20, -13), width: 26, height: 14),
      Paint()..color = const Color(0x3DFFFFFF),
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, 7), radius: 42),
      .15,
      1.05,
      false,
      Paint()
        ..color = const Color(0xBF4A0007)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -39), width: 46, height: 24),
      Paint()..color = const Color(0xFF41464A),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -39), width: 46, height: 24),
      Paint()
        ..color = const Color(0xFF1F252A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -43), width: 26, height: 12),
      Paint()..color = const Color(0xFF676D70),
    );

    final fuse = Paint()
      ..color = const Color(0xFF25292B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final fusePath = Path()
      ..moveTo(0, -47)
      ..quadraticBezierTo(10, -65, 23, -71);
    canvas.drawPath(fusePath, fuse);
    canvas.drawPath(
      fusePath,
      Paint()
        ..color = const Color(0xFFEAFaff)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final flame = Path()
      ..moveTo(21, -72)
      ..cubicTo(28, -96, 46, -100, 54, -94)
      ..cubicTo(49, -85, 58, -85, 60, -77)
      ..cubicTo(47, -70, 39, -69, 30, -62)
      ..cubicTo(31, -71, 25, -67, 21, -72)
      ..close();
    canvas.drawPath(
      flame,
      Paint()
        ..color = const Color(0xFFF52A16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(flame, Paint()..color = const Color(0xFFF52A16));
    final innerFlame = Path()
      ..moveTo(28, -76)
      ..cubicTo(31, -88, 42, -91, 47, -88)
      ..cubicTo(43, -82, 49, -80, 47, -76)
      ..cubicTo(38, -73, 35, -69, 30, -68)
      ..close();
    canvas.drawPath(innerFlame, Paint()..color = const Color(0xFFFFD15D));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GameTwoObjectPainter oldDelegate) => true;
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFAD854C)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(min(x + 3.5, size.width), 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GameFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x1236D9FF)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final borderPaint = Paint()
      ..color = const Color(0x2FBCFF74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          12,
          12,
          max(0, size.width - 24),
          max(0, size.height - 24),
        ),
        const Radius.circular(18),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
