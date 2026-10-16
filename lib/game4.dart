import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'widgets/illustrated_results_overlay.dart';

import 'package:flutter/services.dart';

import 'glob/coin_storage.dart';
import 'glob/game_data.dart';
import 'glob/user.dart';

class Game4Page extends StatefulWidget {
  const Game4Page({
    super.key,
    this.selectedLevel = 1,
    this.suppressIntroTutorial = false,
    this.continueToTutorialAfterGuide = false,
    this.startWithGuide = false,
    this.isTutorialLevel = false,
  });

  final int selectedLevel;
  final bool suppressIntroTutorial;
  final bool continueToTutorialAfterGuide;
  final bool startWithGuide;
  final bool isTutorialLevel;

  @override
  State<Game4Page> createState() => _Game4PageState();
}

class _Game4Statement {
  const _Game4Statement({
    this.qualifier,
    required this.type,
    required this.name,
    required this.value,
    required this.valueLabel,
    required this.concept,
  });

  final String? qualifier;
  final String type;
  final String name;
  final String value;
  final String valueLabel;
  final String concept;

  List<String> get tokens {
    final result = <String>[type, name, '=', value, ';'];
    if (qualifier != null) result.insert(0, qualifier!);
    return result;
  }
}

class _Game4Round {
  const _Game4Round({
    required this.id,
    required this.prompt,
    required this.targetTokens,
    required this.hints,
    required this.shuffledTokens,
  });

  final String id;
  final String prompt;
  final List<String> targetTokens;
  final List<String> hints;
  final List<String> shuffledTokens;
}

class _Game4Token {
  const _Game4Token({required this.id, required this.value});

  final int id;
  final String value;
}

class _Game4LevelSettings {
  const _Game4LevelSettings({
    required this.title,
    required this.subtitle,
    required this.objective,
    required this.spawnIntervalMs,
    required this.fallSpeed,
    required this.moveSpeed,
    required this.statementReward,
  });

  final String title;
  final String subtitle;
  final String objective;
  final int spawnIntervalMs;
  final int fallSpeed;
  final int moveSpeed;
  final int statementReward;
}

enum _Game4ItemKind { token, bomb, coin, bonus }

class _Game4FallingItem {
  _Game4FallingItem({
    required this.id,
    required this.kind,
    required this.value,
    required this.x,
    required this.y,
    required this.speed,
  });

  final int id;
  final _Game4ItemKind kind;
  final String value;
  double x;
  double y;
  final double speed;
}

class _Game4PageState extends State<Game4Page>
    with SingleTickerProviderStateMixin {
  late int _levelNumber;
  late _Game4LevelSettings _settings;
  late List<_Game4Round> _rounds;

  static const double _playfieldWidth = 780;
  static const double _playfieldHeight = 540;
  static const double _itemSize = 65;
  static const double _playerWidth = 146;
  static const double _playerHeight = 110;
  static const double _playerStartX = 330;
  static const double _playerMaxX = 660;
  static const double _playerBottomOffset = 5;
  static const double _codeTokenEdgeInset = 76;
  static const double _itemHitboxInset = 8;
  static const double _basketHitboxOffsetX = 42;
  static const double _basketHitboxWidth = 62;
  static const double _basketHitboxHeight = 18;
  static const double _missLineY = 540;
  static const int _maxCoinSpawnsPerRound = 2;
  static const int _maxLives = 3;
  static const int _bonusPickupsForLife = 3;

  final FocusNode _gameFocusNode = FocusNode();
  Timer? _gameTimer;
  final AudioPlayer _musicPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _effectPlayers = {
    'token': AudioPlayer(),
    'bonus': AudioPlayer(),
    'coin': AudioPlayer(),
    'bomb': AudioPlayer(),
    'combo': AudioPlayer(),
    'correct': AudioPlayer(),
    'incorrect': AudioPlayer(),
    'hint': AudioPlayer(),
    'game-over': AudioPlayer(),
  };
  final Map<AudioPlayer, Future<void>> _audioOperations = {};
  bool _audioDisposed = false;
  bool _audioShutdownStarted = false;
  bool _musicPlaying = false;
  bool _musicStarting = false;
  bool _musicDesired = false;
  bool _musicRestartRequested = false;
  int _musicGeneration = 0;
  DateTime? _lastTick;
  double _spawnAccumulatorMs = 0;
  int _nextItemId = 0;
  int _nextTokenId = 0;
  int _coinsSpawnedThisRound = 0;
  bool _leftHeld = false;
  bool _rightHeld = false;
  bool _gameplayPaused = false;
  String _mode = 'catch';
  double _playerX = _playerStartX;
  List<_Game4FallingItem> _fallingItems = [];
  List<_Game4Token> _inventory = [];
  List<_Game4Token> _assemblyChoices = [];
  List<_Game4Token> _assembledTokens = [];
  List<int> _incorrectTokenIndexes = [];
  int _roundIndex = 0;
  int _roundsCleared = 0;
  int _points = 0;
  int _lives = _maxLives;
  int _mistakes = 0;
  int _coins = 0;
  int _bonusPoints = 0;
  int _bonusStreak = 0;
  int _bonusPickupCount = 0;
  int _hintsUsed = 0;
  int _revealedHintCount = 0;
  String _hintMessage = '';
  bool _hintPurchasePending = false;
  bool _coinsLoading = true;
  int _pendingCoinOperations = 0;
  int _coinOperationVersion = 0;
  final Set<int> _processedCoinIds = <int>{};
  bool _resultSavePending = false;
  bool? _resultSaveSucceeded;
  bool _resultSubmitted = false;
  int _runId = 0;
  DateTime _runStartedAt = DateTime.now();
  String _instructionOverlay = 'none';
  int _storyPageIndex = 0;
  int _guidePageIndex = 0;
  int _tutorialStepIndex = 0;
  Timer? _tutorialTimer;
  late final AnimationController _storyAnimationController;
  bool _storyExiting = false;
  int _tutorialAnimationTick = 0;
  Rect? _tutorialTargetRect;
  final GlobalKey<State<StatefulWidget>> _tutorialCatcherKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _tutorialLivesKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _tutorialCoinsKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _tutorialRoundKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _tutorialTokenBankKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _tutorialCheckAnswerKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _tutorialPlayfieldKey =
      GlobalKey<State<StatefulWidget>>();
  bool _guideOpenedDuringGameplay = false;
  Timer? _visualEffectTimer;
  String _visualEffectLabel = '';
  Color _visualEffectColor = Colors.white;
  bool _screenShake = false;
  String _feedback = 'SWIPE ACROSS A CARD';

  _Game4Round get _activeRound => _rounds[_roundIndex];

  static const Color darkPurple = Color(0xFF432644);
  static const Color purple = Color(0xFF70415F);
  static const Color sand = Color(0xFFF5D98C);
  static const Color cream = Color(0xFFFFF3C8);
  static const Color paleCream = Color(0xFFFFF8DF);
  static const Color teal = Color(0xFF0F766E);
  static const Color darkText = Color(0xFF24192A);

  bool get _usesInteractiveTutorial => !widget.isTutorialLevel;

  @override
  void initState() {
    super.initState();
    _storyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _initializeLevel(widget.selectedLevel);
    _startCatchPhase();
    if (_levelNumber == 1 && !widget.suppressIntroTutorial) {
      _instructionOverlay = 'story';
      _gameplayPaused = true;
      _storyAnimationController.forward();
    }
    if (widget.startWithGuide && _instructionOverlay == 'none') {
      _instructionOverlay = 'guide';
      _gameplayPaused = true;
    }
    if (_instructionOverlay == 'none') {
      unawaited(_startBackgroundMusic());
    }
    _loadCoins();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _gameFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant Game4Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLevel != widget.selectedLevel) {
      _initializeLevel(widget.selectedLevel);
      _startCatchPhase();
      _instructionOverlay = _levelNumber == 1 && !widget.suppressIntroTutorial
          ? 'story'
          : 'none';
      if (_instructionOverlay != 'none') {
        _gameplayPaused = true;
        _storyExiting = false;
        _storyAnimationController.forward(from: 0);
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _stopMovement();
    _gameTimer?.cancel();
    _tutorialTimer?.cancel();
    _visualEffectTimer?.cancel();
    _storyAnimationController.dispose();
    _musicDesired = false;
    _musicRestartRequested = false;
    _musicGeneration++;
    _audioDisposed = true;
    _stopAndDisposeAudio();
    _gameFocusNode.dispose();
    super.dispose();
  }

  void _initializeLevel(int level) {
    _runStartedAt = DateTime.now();
    _levelNumber = _clamp(level, 1, 5);
    _settings = _settingsForLevel(_levelNumber);
    _rounds = _buildGeneratedRounds(_levelNumber, randomizeStatements: true);
  }

  Future<void> _loadCoins() async {
    final result = await GameCoinStorage.load();
    if (!mounted) return;
    if (_coinOperationVersion == 0 && result.success) {
      setState(() {
        _coins = result.balance;
      });
    }
    setState(() {
      _coinsLoading = false;
      if (!result.success && result.message != null) {
        _feedback = result.message!;
      }
    });
  }

  Future<void> _startBackgroundMusic() async {
    if (_audioDisposed ||
        _instructionOverlay != 'none' ||
        _mode == 'completed' ||
        _mode == 'failed') {
      return;
    }

    _musicDesired = true;
    final generation = ++_musicGeneration;
    if (_musicPlaying) return;
    if (_musicStarting) {
      _musicRestartRequested = true;
      return;
    }

    _musicStarting = true;
    try {
      await _queueAudioOperation(_musicPlayer, () async {
        if (_audioDisposed ||
            _instructionOverlay != 'none' ||
            _mode == 'completed' ||
            _mode == 'failed' ||
            !_musicDesired ||
            generation != _musicGeneration) {
          return;
        }
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        if (_audioDisposed ||
            !_musicDesired ||
            generation != _musicGeneration) {
          return;
        }
        await _musicPlayer.play(
          AssetSource('game4/audio/background-music.mp3'),
          volume: _musicVolume,
        );
        if (_musicDesired && generation == _musicGeneration) {
          _musicPlaying = true;
        }
      });
    } catch (error) {
      _reportAudioError('background music', error);
    } finally {
      _musicStarting = false;
      if (_musicRestartRequested &&
          _musicDesired &&
          !_musicPlaying &&
          !_audioDisposed &&
          _instructionOverlay == 'none' &&
          _mode != 'completed' &&
          _mode != 'failed') {
        _musicRestartRequested = false;
        unawaited(_startBackgroundMusic());
      } else {
        _musicRestartRequested = false;
      }
    }
  }

  Future<void> _pauseBackgroundMusic() async {
    if (_audioDisposed) return;
    _musicDesired = false;
    _musicRestartRequested = false;
    _musicGeneration++;
    _musicPlaying = false;
    try {
      await _queueAudioOperation(_musicPlayer, () async {
        if (!_musicDesired) await _musicPlayer.pause();
        _musicPlaying = false;
      });
    } catch (error) {
      _reportAudioError('pause background music', error);
    }
  }

  Future<void> _playGameSound(String key, String assetName) async {
    if (_audioDisposed || _instructionOverlay != 'none') return;
    final player = _effectPlayers[key];
    if (player == null) return;
    try {
      await _queueAudioOperation(player, () async {
        if (_audioDisposed || _instructionOverlay != 'none') return;
        await player.stop();
        await player.play(
          AssetSource('game4/audio/$assetName'),
          volume: _sfxVolume,
        );
      });
    } catch (error) {
      _reportAudioError(assetName, error);
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

  void _stopAndDisposeAudio() {
    if (_audioShutdownStarted) return;
    _audioShutdownStarted = true;
    unawaited(_stopAndDisposePlayer(_musicPlayer));
    for (final player in _effectPlayers.values) {
      unawaited(_stopAndDisposePlayer(player));
    }
  }

  Future<void> _stopAndDisposePlayer(AudioPlayer player) async {
    try {
      await _queueAudioOperation(player, () async {
        try {
          await player.stop();
        } catch (error) {
          _reportAudioError('stop', error);
        }
        try {
          await player.dispose();
        } catch (error) {
          _reportAudioError('dispose', error);
        }
      }, allowAfterDispose: true);
    } catch (error) {
      _reportAudioError('shutdown', error);
    }
  }

  double get _musicVolume =>
      (AllUsers.musicVolume / 100).clamp(0.0, 1.0).toDouble();

  double get _sfxVolume =>
      (AllUsers.sfxVolume / 100).clamp(0.0, 1.0).toDouble();

  void _reportAudioError(String operation, Object error) {
    final message = error.toString();
    if (message.contains('AbortError') ||
        message.contains('NotAllowedError') ||
        message.contains('interrupted')) {
      return;
    }
    debugPrint('Game 4 audio $operation failed: $message');
  }

  void _showVisualEffect(String label, Color color) {
    if (!mounted || _instructionOverlay != 'none') return;
    _visualEffectTimer?.cancel();
    setState(() {
      _visualEffectLabel = label;
      _visualEffectColor = color;
    });
    _visualEffectTimer = Timer(const Duration(milliseconds: 760), () {
      if (mounted) setState(() => _visualEffectLabel = '');
    });
  }

  Future<void> _awardCollectedCoin() async {
    final operationRunId = _runId;
    _coinOperationVersion++;
    _pendingCoinOperations++;
    final result = await GameCoinStorage.add(1);
    if (!mounted) return;
    _pendingCoinOperations = max(0, _pendingCoinOperations - 1);
    if (operationRunId != _runId) return;
    if (result.success) {
      setState(() => _coins = result.balance);
    } else {
      setState(() {
        _coins = result.balance;
        _feedback = result.message ?? 'Coin balance could not be saved.';
      });
    }
  }

  int get _concurrentFallingCount => _roundIndex >= 2 ? 2 : 1;

  int get _spawnIntervalMs {
    if (_levelNumber == 1) return 1200;
    if (_levelNumber == 2) return 1080;
    if (_levelNumber == 3) return 980;
    if (_levelNumber == 4) return 920;
    return _settings.spawnIntervalMs.clamp(700, 1800).toInt();
  }

  double get _fallSpeed {
    if (_levelNumber <= 2) return 180;
    if (_levelNumber == 3) return 210;
    if (_levelNumber == 4) return 240;
    return _settings.fallSpeed.clamp(160, 420).toDouble();
  }

  int get _maxConcurrentItems => _rounds.isEmpty ? 1 : _concurrentFallingCount;

  void _startCatchPhase({bool resetRun = true}) {
    _gameTimer?.cancel();
    _mode = 'catch';
    _gameplayPaused = false;
    _playerX = _playerStartX;
    _fallingItems = [];
    _inventory = [];
    _assemblyChoices = [];
    _assembledTokens = [];
    _incorrectTokenIndexes = [];
    _hintMessage = '';
    _revealedHintCount = 0;
    _hintPurchasePending = false;
    if (resetRun) {
      _roundIndex = 0;
      _roundsCleared = 0;
      _points = 0;
      _lives = _maxLives;
      _mistakes = 0;
      _bonusPoints = 0;
      _bonusStreak = 0;
      _bonusPickupCount = 0;
      _hintsUsed = 0;
    }
    _nextTokenId = 0;
    _screenShake = false;
    _feedback = 'SWIPE ACROSS A CARD';
    _spawnAccumulatorMs = 0;
    _coinsSpawnedThisRound = 0;
    _processedCoinIds.clear();
    _nextItemId = 0;
    _spawnInitialItems();
    _lastTick = DateTime.now();
    _gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _tick(),
    );
  }

  void _spawnInitialItems() {
    if (_rounds.isEmpty) return;
    _fallingItems.add(_createItem(forceCoin: true, startY: 0));
  }

  _Game4FallingItem _createItem({
    String? forceToken,
    bool forceCoin = false,
    double startY = 0,
    List<_Game4FallingItem>? itemsOnScreen,
  }) {
    final visibleItems = itemsOnScreen ?? _fallingItems;
    final target = _activeRound.targetTokens;
    final inventoryCounts = <String, int>{};
    for (final token in _inventory) {
      inventoryCounts[token.value] = (inventoryCounts[token.value] ?? 0) + 1;
    }
    final visibleCounts = <String, int>{};
    for (final item in visibleItems) {
      if (item.kind == _Game4ItemKind.token) {
        visibleCounts[item.value] = (visibleCounts[item.value] ?? 0) + 1;
      }
    }
    final targetCounts = <String, int>{};
    for (final token in target) {
      targetCounts[token] = (targetCounts[token] ?? 0) + 1;
    }
    final remaining = target
        .where(
          (token) =>
              (inventoryCounts[token] ?? 0) + (visibleCounts[token] ?? 0) <
              (targetCounts[token] ?? 0),
        )
        .toList();
    _Game4ItemKind kind;
    String value;
    if (forceToken != null) {
      kind = _Game4ItemKind.token;
      value = forceToken;
    } else if (forceCoin && _coinsSpawnedThisRound < _maxCoinSpawnsPerRound) {
      kind = _Game4ItemKind.coin;
      value = 'coin';
    } else if (remaining.isNotEmpty && Random().nextDouble() < 0.45) {
      kind = _Game4ItemKind.token;
      value = remaining[Random().nextInt(remaining.length)];
    } else {
      final candidates = <_Game4ItemKind>[
        if (_coinsSpawnedThisRound < _maxCoinSpawnsPerRound)
          _Game4ItemKind.coin,
        _Game4ItemKind.bomb,
        _Game4ItemKind.bonus,
        _Game4ItemKind.bonus,
        _Game4ItemKind.bonus,
      ];
      kind = candidates[Random().nextInt(candidates.length)];
      value = kind == _Game4ItemKind.coin
          ? 'coin'
          : kind == _Game4ItemKind.bomb
          ? 'bomb'
          : ['banana', 'carrot', 'orange'][Random().nextInt(3)];
    }
    if (kind == _Game4ItemKind.coin) _coinsSpawnedThisRound++;
    final edgeInset = kind == _Game4ItemKind.token ? _codeTokenEdgeInset : 0;
    final maxX = max(0.0, _playfieldWidth - _itemSize - (edgeInset * 2));
    return _Game4FallingItem(
      id: ++_nextItemId,
      kind: kind,
      value: value,
      x: edgeInset + Random().nextDouble() * maxX,
      y: startY,
      speed: _fallSpeed,
    );
  }

  double _respawnY(List<_Game4FallingItem> visibleItems) {
    final minGap = _levelNumber <= 2
        ? 190
        : _levelNumber == 3
        ? 170
        : 150;
    final highest = visibleItems.fold<double>(
      0,
      (value, item) => min(value, item.y),
    );
    return min(-40, highest - minGap);
  }

  bool _intersectsBasket(_Game4FallingItem item, double nextY) {
    final itemLeft = item.x + _itemHitboxInset;
    final itemRight = item.x + _itemSize - _itemHitboxInset;
    final itemTop = nextY + _itemHitboxInset;
    final itemBottom = nextY + _itemSize;
    final playerTop = _playfieldHeight - _playerBottomOffset - _playerHeight;
    final basketLeft = _playerX + _basketHitboxOffsetX;
    final basketRight = basketLeft + _basketHitboxWidth;
    final basketBottom = playerTop + _basketHitboxHeight;
    return itemRight >= basketLeft &&
        itemLeft <= basketRight &&
        itemBottom >= playerTop &&
        itemTop <= basketBottom;
  }

  void _tick() {
    if (!mounted || _gameplayPaused || _mode != 'catch') return;
    final now = DateTime.now();
    final deltaMs = min(80, now.difference(_lastTick ?? now).inMilliseconds);
    _lastTick = now;
    final deltaSeconds = deltaMs / 1000;
    final movement = _settings.moveSpeed * deltaSeconds;
    if (_leftHeld) _playerX -= movement;
    if (_rightHeld) _playerX += movement;
    _playerX = _playerX.clamp(0.0, _playerMaxX).toDouble();
    _spawnAccumulatorMs += deltaMs;
    final nextItems = <_Game4FallingItem>[];
    final caught = <_Game4FallingItem>[];
    final missed = <_Game4FallingItem>[];
    for (final item in _fallingItems) {
      final nextY = item.y + item.speed * deltaSeconds;
      if (_intersectsBasket(item, nextY)) {
        caught.add(item);
      } else if (nextY > _missLineY) {
        missed.add(item);
      } else {
        item.y = nextY;
        nextItems.add(item);
      }
    }
    while (_spawnAccumulatorMs >= _spawnIntervalMs &&
        nextItems.length < _maxConcurrentItems) {
      _spawnAccumulatorMs -= _spawnIntervalMs;
      nextItems.add(_createItem(itemsOnScreen: nextItems));
    }
    for (final item in caught) {
      _handleCaught(item, nextItems);
    }
    for (final item in missed) {
      _handleMissed(item, nextItems);
    }
    if (_mode == 'catch' &&
        _inventory.length < _activeRound.targetTokens.length) {
      while (_spawnAccumulatorMs >= _spawnIntervalMs &&
          nextItems.length < _maxConcurrentItems) {
        _spawnAccumulatorMs -= _spawnIntervalMs;
        nextItems.add(_createItem(itemsOnScreen: nextItems));
      }
    }
    if (_mode == 'catch') _fallingItems = nextItems;
    if (mounted) setState(() {});
  }

  void _handleCaught(
    _Game4FallingItem item,
    List<_Game4FallingItem> nextItems,
  ) {
    if (item.kind == _Game4ItemKind.token) {
      final collectedCount = _inventory
          .where((token) => token.value == item.value)
          .length;
      final targetCount = _activeRound.targetTokens
          .where((token) => token == item.value)
          .length;
      if (collectedCount < targetCount) {
        _inventory.add(_Game4Token(id: ++_nextTokenId, value: item.value));
      }
      _feedback = 'Caught ${item.value}.';
      unawaited(_playGameSound('token', 'fruits.mp3'));
      _showVisualEffect('CODE CAUGHT', const Color(0xFFDFF8E9));
      if (_hasCollectedTarget()) {
        _assemblyChoices = _shuffle(_inventory, Random());
        _assembledTokens = [];
        _incorrectTokenIndexes = [];
        _mode = 'assemble';
        _fallingItems = [];
        _stopGameplayTimer();
        _feedback = 'All code parts collected. Assemble Phase is ready.';
        unawaited(_startBackgroundMusic());
      } else {
        nextItems.add(
          _createItem(
            forceToken: _missingToken(),
            startY: _respawnY(nextItems),
            itemsOnScreen: nextItems,
          ),
        );
      }
    } else if (item.kind == _Game4ItemKind.coin) {
      if (_processedCoinIds.add(item.id)) {
        unawaited(_awardCollectedCoin());
        unawaited(_playGameSound('coin', 'coins.mp3'));
        _showVisualEffect('+1 COIN', Colors.amber);
      }
      _feedback = 'Coin collected.';
      nextItems.add(
        _createItem(startY: _respawnY(nextItems), itemsOnScreen: nextItems),
      );
    } else if (item.kind == _Game4ItemKind.bonus) {
      _bonusStreak++;
      _bonusPoints += 5 * _comboMultiplier(_bonusStreak);
      _bonusPickupCount++;
      if (_bonusPickupCount >= _bonusPickupsForLife) {
        _bonusPickupCount = 0;
        _lives = min(_maxLives, _lives + 1);
      }
      _feedback =
          'Bonus $_bonusStreak combo ×${_comboMultiplier(_bonusStreak)}.';
      unawaited(_playGameSound('bonus', 'fruits.mp3'));
      _showVisualEffect('BONUS +${5 * _comboMultiplier(_bonusStreak)}', teal);
      if ([3, 5, 10].contains(_bonusStreak)) {
        unawaited(_playGameSound('combo', 'game4combo.mp3'));
        _showVisualEffect('COMBO ×${_comboMultiplier(_bonusStreak)}', sand);
      }
      nextItems.add(
        _createItem(startY: _respawnY(nextItems), itemsOnScreen: nextItems),
      );
    } else {
      unawaited(_playGameSound('bomb', 'bomb.mp3'));
      _showVisualEffect('BOMB HIT', const Color(0xFFEF4444));
      _damage('Bomb caught.');
    }
  }

  void _handleMissed(
    _Game4FallingItem item,
    List<_Game4FallingItem> nextItems,
  ) {
    if (item.kind == _Game4ItemKind.token) {
      _damage('Missed ${item.value}.');
      if (_mode == 'catch' && _lives > 0) {
        nextItems.add(
          _createItem(
            forceToken: item.value,
            startY: _respawnY(nextItems),
            itemsOnScreen: nextItems,
          ),
        );
      }
    } else {
      nextItems.add(
        _createItem(startY: _respawnY(nextItems), itemsOnScreen: nextItems),
      );
    }
  }

  bool _hasCollectedTarget() {
    final counts = <String, int>{};
    for (final token in _inventory) {
      counts[token.value] = (counts[token.value] ?? 0) + 1;
    }
    for (final token in _activeRound.targetTokens) {
      final count = counts[token] ?? 0;
      if (count == 0) return false;
      counts[token] = count - 1;
    }
    return true;
  }

  String _missingToken() {
    final counts = <String, int>{};
    for (final token in _inventory) {
      counts[token.value] = (counts[token.value] ?? 0) + 1;
    }
    for (final token in _activeRound.targetTokens) {
      final count = counts[token] ?? 0;
      if (count == 0) return token;
      counts[token] = count - 1;
    }
    return _activeRound.targetTokens.last;
  }

  int _comboMultiplier(int streak) {
    if (streak >= 10) return 5;
    if (streak >= 5) return 3;
    if (streak >= 3) return 2;
    return 1;
  }

  void _damage(String message) {
    _lives = max(0, _lives - 1);
    _mistakes++;
    _bonusStreak = 0;
    _screenShake = true;
    _feedback = '$_feedback $message Lives: $_lives/$_maxLives.';
    _showVisualEffect(
      message.toLowerCase().contains('bomb') ? 'BOMB HIT' : 'TOKEN MISSED',
      const Color(0xFFEF4444),
    );
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _screenShake = false);
    });
    if (_lives == 0) {
      _mode = 'failed';
      _stopGameplayTimer();
      unawaited(_playGameSound('game-over', 'game-over.mp3'));
      unawaited(_pauseBackgroundMusic());
      _feedback = 'Catch Phase ended: no lives remaining.';
      unawaited(_submitResultOnce());
    }
  }

  void _stopGameplayTimer() {
    _gameplayPaused = true;
    _stopMovement();
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void _openInstructionOverlay(
    String overlay, {
    bool openedDuringGameplay = false,
  }) {
    if (!mounted || _mode == 'completed' || _mode == 'failed') return;
    _stopMovement();
    _gameplayPaused = true;
    unawaited(_pauseBackgroundMusic());
    if (overlay == 'tutorial') {
      _tutorialStepIndex = 0;
      _tutorialAnimationTick = 0;
      _tutorialTimer?.cancel();
      _tutorialTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        if (!mounted || _instructionOverlay != 'tutorial') return;
        setState(() => _tutorialAnimationTick++);
      });
    }
    setState(() {
      _instructionOverlay = overlay;
      _tutorialTargetRect = null;
      if (overlay == 'guide') {
        _guideOpenedDuringGameplay = openedDuringGameplay;
      }
      if (overlay == 'guide') _guidePageIndex = 0;
      if (overlay == 'story') _storyPageIndex = 0;
    });
  }

  void _closeInstructionOverlay() {
    _tutorialTimer?.cancel();
    _tutorialTimer = null;
    _tutorialTargetRect = null;
    _instructionOverlay = 'none';
    if (_mode == 'catch') _gameplayPaused = false;
    if (_mode != 'completed' && _mode != 'failed') {
      unawaited(_startBackgroundMusic());
    }
    if (mounted) setState(() {});
  }

  void _advanceStory() {
    if (_storyPageIndex < 7) {
      setState(() => _storyPageIndex++);
      return;
    }
    if (widget.continueToTutorialAfterGuide) {
      _openInstructionOverlay('guide');
    } else {
      _openInstructionOverlay('guide');
    }
  }

  List<List<String>> _guidePages() {
    final roundCount = _rounds.length;
    final reward = _settings.statementReward;
    final items = <String>[
      _settings.objective,
      '$roundCount declaration round${roundCount == 1 ? '' : 's'} must be completed.',
      'You have $_maxLives lives while objects fall at the configured Level $_levelNumber speed.',
      'The on-screen statement reward is $reward points per round.',
      'Each caught gear adds 5 bonus points.',
      'Recorded gameplay score: $roundCount cleared rounds × $reward, plus verified gear bonuses.',
      'With no gear bonus, completing all rounds earns ${roundCount * reward} base points.',
      'You begin with 3 platform Stars; the first 3 mistakes do not reduce them.',
      'Each additional mistake removes 1 Star; hints cost 1 coin and do not remove Stars.',
      'Retries and the number of Stars earned can lower the final recorded score.',
    ];
    final splitIndex = (items.length / 2).ceil();
    return [items.take(splitIndex).toList(), items.skip(splitIndex).toList()];
  }

  void _advanceGuide() {
    final pages = _guidePages();
    if (_guidePageIndex < pages.length - 1) {
      setState(() => _guidePageIndex++);
      return;
    }
    if (widget.continueToTutorialAfterGuide && !_guideOpenedDuringGameplay) {
      _openInstructionOverlay('tutorial');
    } else {
      _closeInstructionOverlay();
    }
  }

  int get _tutorialStepCount => _usesInteractiveTutorial ? 6 : 5;

  String _tutorialTitle() {
    final titles = _usesInteractiveTutorial
        ? const [
            'Move the robot',
            'Catch the required code',
            'Avoid bombs',
            'Pickups & hints',
            'Arrange, then check',
            'Complete every round',
          ]
        : const [
            'Move the robot',
            'Catch A Gear',
            'Bombs Remove Lives',
            'Catch Code Parts',
            'Arrange The Code',
          ];
    return titles[_tutorialStepIndex.clamp(0, titles.length - 1)];
  }

  String _tutorialText() {
    final texts = _usesInteractiveTutorial
        ? const [
            'A / Left Arrow moves left. D / Right Arrow moves right. Watch the robot and basket move.',
            'Move the basket under the code. Collect every required piece to unlock Arrange Phase.',
            'Watch the robot move away. Bombs and missed required code cost a life in real play; this demo causes no damage.',
            'Three bonus pickups restore one missing life, up to 3. Coins pay for hints: 1 coin each.',
            'Watch the collected pieces build the Java statement in order, then Check Answer.',
            'Catch required pieces, avoid hazards, and arrange the code correctly. Complete all rounds to finish.',
          ]
        : const [
            'Hold ← Left or → Right to move the robot and basket. Watch the controls below.',
            'Gear fills the gear meter. Catch 3 gears to gain 1 extra life, but lives can only go up to 3/3.',
            'A bomb normally removes 1 life. In this tutorial, catch this bomb so you can see the lives display change without losing.',
            'Now catch the Java code pieces. Missing one in the real level is dangerous, but here it will respawn so you can practice.',
            'Great. Click the collected parts in the correct order, then press Show Answer to finish the tutorial and start Level 1.',
          ];
    return texts[_tutorialStepIndex.clamp(0, texts.length - 1)];
  }

  String? _tutorialTip() {
    if (_usesInteractiveTutorial) {
      return switch (_tutorialStepIndex) {
        3 => 'These counters stay unchanged in the demonstration.',
        4 => 'An incorrect full answer costs a life in real play. Drag pieces to reorder or click to return them.',
        5 => 'No score, coins, lives or progress are changed.',
        _ => null,
      };
    }
    return const [
      null,
      null,
      'This practice demonstration causes no real damage.',
      null,
      'The demonstration is isolated from the real round and saved progress.',
    ][_tutorialStepIndex];
  }

  List<String> _tutorialKeys() {
    if (!_usesInteractiveTutorial) {
      return _tutorialStepIndex == 0 ? const ['← Left', '→ Right'] : const [];
    }
    return switch (_tutorialStepIndex) {
      0 => const ['A / Left Arrow', 'D / Right Arrow'],
      1 => const ['← Left'],
      2 => const ['→ Right'],
      _ => const [],
    };
  }

  Widget _tutorialDemo() {
    final durationMs = _usesInteractiveTutorial
        ? switch (_tutorialStepIndex) {
            0 => 3600,
            1 || 2 => 3300,
            3 => 2400,
            4 => _activeRound.targetTokens.length * 700 + 2100,
            _ => 3000,
          }
        : switch (_tutorialStepIndex) {
            0 => 3600,
            1 || 2 || 3 => 3300,
            _ => _activeRound.targetTokens.length * 700 + 2100,
          };
    final elapsedMs = _tutorialAnimationTick * 120;
    final phase = (elapsedMs % durationMs) / durationMs;
    final playerAlignment = _tutorialStepIndex == 0
        ? (phase < 0.5 ? -0.45 + phase : 0.05 + phase)
        : 0.0;
    final showingGear = !_usesInteractiveTutorial && _tutorialStepIndex == 1;
    final showingBomb = _tutorialStepIndex == 2;
    final showingToken = _usesInteractiveTutorial
        ? _tutorialStepIndex == 1
        : _tutorialStepIndex == 3;
    final showingAssembly = _tutorialStepIndex == 4;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        border: Border.all(color: purple, width: 3),
        image: const DecorationImage(
          image: AssetImage('assets/game4/images/backgroundofgame4.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          if (showingGear || showingToken || showingBomb)
            Positioned(
              left: 50,
              top: 18 + (phase * 150),
              width: 58,
              height: 58,
              child: showingGear
                  ? Image.asset('assets/game4/images/gear.png')
                  : showingBomb
                  ? Image.asset('assets/game4/images/bomb.png')
                  : Container(
                      alignment: Alignment.center,
                      color: Colors.black,
                      child: Text(
                        _activeRound.targetTokens.first,
                        textAlign: TextAlign.center,
                        style: _textStyle(size: 11, color: Colors.white),
                      ),
                    ),
            ),
          if (showingAssembly)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final token in _activeRound.targetTokens.take(
                      max(
                        0,
                        min(
                          _activeRound.targetTokens.length,
                          ((elapsedMs - 300) / 700).floor(),
                        ),
                      ),
                    ))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 6,
                        ),
                        color: const Color(0xE6FFF8DF),
                        child: Text(
                          token,
                          style: _textStyle(size: 11, weight: FontWeight.w900),
                        ),
                      ),
                    _assembleActionButton('Check Answer', () {}, teal),
                  ],
                ),
              ),
            ),
          if (_usesInteractiveTutorial && _tutorialStepIndex == 3)
            Positioned.fill(
              child: Center(
                child: Text(
                  'COINS  •  HINTS',
                  style: _textStyle(
                    size: 18,
                    weight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (_usesInteractiveTutorial && _tutorialStepIndex == 5)
            Positioned.fill(
              child: Center(
                child: Text(
                  'ROUND 1 / 3',
                  style: _textStyle(
                    size: 18,
                    weight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment(
              playerAlignment.clamp(-0.8, 0.8).toDouble(),
              0.75,
            ),
            child: Image.asset(
              'assets/game4/images/robotofgame4.png',
              width: 92,
              height: 86,
              fit: BoxFit.contain,
            ),
          ),
          if (_tutorialStepIndex == 0)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                '← Left                 → Right',
                textAlign: TextAlign.center,
                style: _textStyle(
                  size: 12,
                  color: Colors.white,
                  weight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryOverlay() {
    return Positioned.fill(
      child: Material(
        color: const Color(0xA30F172A),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = min(constraints.maxWidth * .96, 980.0);
              final maxCardHeight = constraints.maxHeight * .92;
              final storyImageHeight = max(
                80.0,
                min(cardWidth * .68, maxCardHeight - 185),
              );
              final buttonEnabled = !_storyExiting;
              return Center(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _storyAnimationController,
                    curve: Curves.easeOut,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, .035),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _storyAnimationController,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .95, end: 1).animate(
                        CurvedAnimation(
                          parent: _storyAnimationController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: cardWidth,
                          maxHeight: maxCardHeight,
                        ),
                        child: Container(
                          width: cardWidth,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: paleCream,
                            border: Border.all(color: purple, width: 4),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xBF432644),
                                offset: Offset(12, 12),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CATCH THE CODE STORY',
                                          style: _textStyle(
                                            size: 12,
                                            color: purple,
                                            weight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Page ${_storyPageIndex + 1} of 8',
                                          style: _textStyle(
                                            size: 24,
                                            color: darkText,
                                            weight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _storyReactButton(
                                    'Back',
                                    onPressed: buttonEnabled
                                        ? _closeStoryOverlay
                                        : null,
                                    primary: false,
                                    icon: Icons.logout,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: storyImageHeight,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F1530),
                                    border: Border.all(
                                      color: const Color(0xFF70415F),
                                      width: 3,
                                    ),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Image.asset(
                                    'assets/game4/story/${_storyPageIndex + 1}.png',
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Text(
                                            'Story page unavailable.',
                                            style: _textStyle(color: purple),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (var index = 0; index < 8; index++)
                                        Container(
                                          width: 12,
                                          height: 12,
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: index == _storyPageIndex
                                                ? const Color(0xFF2563EB)
                                                : Colors.white,
                                            border: Border.all(
                                              color: purple,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  _storyReactButton(
                                    _storyPageIndex == 7
                                        ? 'Start Level'
                                        : 'Next',
                                    onPressed: buttonEnabled
                                        ? _advanceStory
                                        : null,
                                    primary: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _storyReactButton(
    String label, {
    required VoidCallback? onPressed,
    required bool primary,
    IconData? icon,
  }) {
    final background = primary ? teal : Colors.white.withValues(alpha: .92);
    final foreground = primary ? Colors.white : darkText;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: .55),
          disabledForegroundColor: foreground.withValues(alpha: .55),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: primary
                  ? const Color(0x590F766E)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          elevation: 2,
          shadowColor: const Color(0x3315233A),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closeStoryOverlay() {
    if (_storyExiting || !mounted) return;
    _storyExiting = true;
    _storyAnimationController.reverse().whenCompleteOrCancel(() {
      if (!mounted) return;
      _storyExiting = false;
      _instructionOverlay = 'none';
      _gameplayPaused = false;
      unawaited(_startBackgroundMusic());
      setState(() {});
    });
  }

  String _guideIconAsset(String item) {
    final text = item.toLowerCase();
    if (text.contains('speed') ||
        text.contains('time') ||
        text.contains('second')) {
      return 'assets/game4/guidelines/icon-clock.png';
    }
    if (text.contains('gear') || text.contains('restore')) {
      return 'assets/game4/guidelines/icon-fruit.png';
    }
    if (text.contains('bomb') || text.contains('hazard')) {
      return 'assets/game4/guidelines/icon-hazard.png';
    }
    if (text.contains('coin')) return 'assets/game4/guidelines/icon-coin.png';
    if (text.contains('hint')) return 'assets/game4/guidelines/icon-hint.png';
    if (text.contains('star')) return 'assets/game4/guidelines/icon-star.png';
    if (text.contains('life') || text.contains('lives')) {
      return 'assets/game4/guidelines/icon-heart.png';
    }
    if (text.contains('score') ||
        text.contains('point') ||
        text.contains('reward')) {
      return 'assets/game4/guidelines/icon-score.png';
    }
    if (text.contains('wrong') ||
        text.contains('mistake') ||
        text.contains('fail')) {
      return 'assets/game4/guidelines/icon-wrong.png';
    }
    if (text.contains('retry') || text.contains('restart')) {
      return 'assets/game4/guidelines/icon-retry.png';
    }
    if (text.contains('pass') ||
        text.contains('unlock') ||
        text.contains('complete') ||
        text.contains('objective')) {
      return 'assets/game4/guidelines/icon-trophy.png';
    }
    if (text.contains('code') ||
        text.contains('java') ||
        text.contains('token')) {
      return 'assets/game4/guidelines/icon-code.png';
    }
    if (text.contains('move') ||
        text.contains('control') ||
        text.contains('arrow')) {
      return 'assets/game4/guidelines/icon-move.png';
    }
    return 'assets/game4/guidelines/icon-dot.png';
  }

  Widget _guideButton(String label, VoidCallback onPressed) {
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
    );
  }

  Widget _buildGuideOverlay() {
    final pages = _guidePages();
    final items = pages[_guidePageIndex];
    return Positioned.fill(
      child: Material(
        color: const Color(0xFF142726),
        child: SafeArea(
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
              final footerHeight = max(30.0, min(72.0, boardHeight * .14));
              return Center(
                child: SizedBox(
                  width: boardWidth,
                  height: boardHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/game4/guidelines/Guidelinesformobile.png',
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
                                vertical: 5,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF397E35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Falling Objects Game Guide',
                                textAlign: TextAlign.center,
                                style: _textStyle(
                                  size: min(20, max(12, boardHeight * .032)),
                                  weight: FontWeight.w700,
                                  color: const Color(0xFFFFF8DA),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFAD854C),
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          _guideIconAsset(items[index]),
                                          width: 26,
                                          height: 26,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            items[index],
                                            style: _textStyle(
                                              size: min(
                                                18,
                                                max(12, boardHeight * .03),
                                              ),
                                              weight: FontWeight.w600,
                                              height: 1.35,
                                              color: const Color(0xFF392812),
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
                        left: boardWidth * .20,
                        right: boardWidth * .20,
                        bottom: boardHeight * .06 + 10,
                        height: footerHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: _guideButton(
                                _guidePageIndex == 0 ? 'Exit' : 'Back',
                                _guidePageIndex == 0
                                    ? _closeInstructionOverlay
                                    : () => setState(() => _guidePageIndex--),
                              ),
                            ),
                            SizedBox(width: boardWidth * .02),
                            SizedBox(
                              width: 70,
                              child: Center(
                                child: Text(
                                  '${_guidePageIndex + 1} / ${pages.length}',
                                  style: _textStyle(
                                    size: min(18, max(12, boardHeight * .03)),
                                    weight: FontWeight.w700,
                                    color: const Color(0xFFFFF2CA),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: boardWidth * .02),
                            Expanded(
                              child: _guideButton(
                                _guidePageIndex == pages.length - 1
                                    ? 'Start'
                                    : 'Next',
                                _advanceGuide,
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
        ),
      ),
    );
  }

  GlobalKey<State<StatefulWidget>>? _tutorialTargetKey() {
    if (_usesInteractiveTutorial) {
      switch (_tutorialStepIndex) {
        case 0:
          return _tutorialCatcherKey;
        case 1:
        case 2:
          return _tutorialPlayfieldKey;
        case 3:
          return _tutorialCoinsKey;
        case 4:
          return _tutorialAnimationTick % 24 < 17
              ? _tutorialTokenBankKey
              : _tutorialCheckAnswerKey;
        case 5:
          return _tutorialRoundKey;
      }
      return null;
    }
    switch (_tutorialStepIndex) {
      case 0:
      case 1:
        return _tutorialCatcherKey;
      case 2:
        return _tutorialLivesKey;
      case 3:
        return _tutorialCatcherKey;
      case 4:
        return _tutorialAnimationTick % 24 < 17
            ? _tutorialTokenBankKey
            : _tutorialCheckAnswerKey;
    }
    return null;
  }

  void _refreshTutorialTargetRect() {
    if (!mounted || _instructionOverlay != 'tutorial') return;
    final targetKey = _tutorialTargetKey();
    if (targetKey == null) {
      if (_tutorialTargetRect != null && mounted) {
        setState(() => _tutorialTargetRect = null);
      }
      return;
    }
    final targetContext = targetKey.currentContext;
    if (targetContext == null || !targetContext.mounted) {
      if (_tutorialTargetRect != null && mounted) {
        setState(() => _tutorialTargetRect = null);
      }
      return;
    }
    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final nextRect =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (_tutorialTargetRect == nextRect) return;
    setState(() => _tutorialTargetRect = nextRect);
  }

  Widget _tutorialPanel({required double width, required double height}) {
    final isLast = _tutorialStepIndex == _tutorialStepCount - 1;
    // Match InGameTutorial.css: the compact layout is selected by the
    // viewport, not by the panel width alone. This is important for the
    // 915x412 landscape presentation, where the panel is still wide but the
    // available height uses the compact parchment spacing.
    final compactViewport = width <= 540 || height <= 540;
    final panelPadding = compactViewport
        ? const EdgeInsets.fromLTRB(34, 96, 34, 32)
        : const EdgeInsets.fromLTRB(46, 110, 46, 42);
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/game4/tutorial/tutorial4.png',
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          top: height * .14,
          right: width * .03,
          width: width * .08,
          height: height * .12,
          child: Semantics(
            button: true,
            label: 'Close tutorial',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeInstructionOverlay,
            ),
          ),
        ),
        Positioned(
          top: height * .21,
          right: width * .13,
          child: Text(
            '${_tutorialStepIndex + 1} / $_tutorialStepCount',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFF4D9),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: panelPadding,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _tutorialTitle(),
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: width <= 380 ? 18 : 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            color: const Color(0xFF5C3D26),
                          ),
                        ),
                        if (!_usesInteractiveTutorial) ...[
                          const SizedBox(height: 10),
                          _tutorialDemo(),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          _tutorialText(),
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: width <= 380 ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                            color: const Color(0xFF563A24),
                          ),
                        ),
                        if (_tutorialKeys().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            children: [
                              for (final key in _tutorialKeys())
                                _tutorialKeyCap(key),
                            ],
                          ),
                        ],
                        if (_tutorialTip() != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _tutorialTip()!,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              height: 1.5,
                              color: Color(0xFF795E43),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
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
                SizedBox(height: compactViewport ? 12 : 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _instructionButton(
                        'Back',
                        _tutorialStepIndex == 0
                            ? _closeInstructionOverlay
                            : () => setState(() => _tutorialStepIndex--),
                        compact: compactViewport,
                      ),
                      _instructionButton(
                        isLast
                            ? (_usesInteractiveTutorial
                                  ? (widget.continueToTutorialAfterGuide
                                        ? 'Start Level'
                                        : 'Return to game')
                                  : (widget.continueToTutorialAfterGuide
                                        ? 'Start Level'
                                        : 'Return to game'))
                            : 'Next',
                        isLast
                            ? _closeInstructionOverlay
                            : () => setState(() => _tutorialStepIndex++),
                        compact: compactViewport,
                        finish: isLast,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tutorialKeyCap(String value) {
    final pressed =
        _tutorialAnimationTick % 24 >= 7 && _tutorialAnimationTick % 24 < 14;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      transform: pressed
          ? Matrix4.translationValues(0, 2, 0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: pressed ? const Color(0xFFDCE6AE) : const Color(0xFFFFF5DB),
        border: Border.all(color: const Color(0xFF967047)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA7804C),
            offset: Offset(0, pressed ? 1 : 3),
          ),
        ],
      ),
      child: Text(
        value,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          color: Color(0xFF563A24),
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTutorialTargetRect();
    });
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = min(520.0, max(0.0, constraints.maxWidth - 16));
          final height = min(360.0, max(0.0, constraints.maxHeight - 16));
          final target = _tutorialTargetRect;
          final panelSize = Size(width, height);
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final candidates = <Offset>[
            const Offset(8, 8),
            Offset(max(8, viewport.width - width - 8), 8),
            Offset(8, max(8, viewport.height - height - 8)),
            Offset(
              max(8, viewport.width - width - 8),
              max(8, viewport.height - height - 8),
            ),
          ];
          final panelOffset = target == null
              ? (_usesInteractiveTutorial
                    ? const Offset(8, 8)
                    : Offset(
                        max(8, (viewport.width - width) / 2),
                        max(8, (viewport.height - height) / 2),
                      ))
              : candidates.reduce((best, candidate) {
                  final bestOverlap =
                      (Rect.fromLTWH(
                        best.dx,
                        best.dy,
                        panelSize.width,
                        panelSize.height,
                      ).overlaps(target))
                      ? 1
                      : 0;
                  final candidateOverlap =
                      (Rect.fromLTWH(
                        candidate.dx,
                        candidate.dy,
                        panelSize.width,
                        panelSize.height,
                      ).overlaps(target))
                      ? 1
                      : 0;
                  return candidateOverlap < bestOverlap ? candidate : best;
                });
          final handLeft = target == null
              ? null
              : max(8.0, min(viewport.width - 53, target.right - 4));
          final handTop = target == null
              ? null
              : max(8.0, min(viewport.height - 60, target.bottom - 5));
          final handPressed =
              _tutorialAnimationTick % 24 >= 7 &&
              _tutorialAnimationTick % 24 < 14;
          return Stack(
            children: [
              const ModalBarrier(dismissible: false, color: Color(0x88000000)),
              if (target != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  left: target.left - 5,
                  top: target.top - 5,
                  width: target.width + 10,
                  height: target.height + 10,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFFE08B),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4DE6B451),
                            spreadRadius: 4,
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: panelOffset.dx,
                top: panelOffset.dy,
                width: width,
                height: height,
                child: _tutorialPanel(width: width, height: height),
              ),
              if (handLeft != null && handTop != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 240),
                  left: handLeft,
                  top: handTop,
                  width: 45,
                  height: 52,
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(0, handPressed ? 3 : 0),
                      child: Image.asset(
                        'assets/game4/tutorial/tutorial-hand.png',
                        width: 45,
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _instructionModal({required Widget child}) {
    return Positioned.fill(
      child: Material(
        color: const Color(0xB324192A),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760, maxHeight: 700),
              child: Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: paleCream,
                  border: Border.all(color: purple, width: 4),
                  boxShadow: const [
                    BoxShadow(color: darkPurple, offset: Offset(8, 8)),
                  ],
                ),
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _instructionButton(
    String label,
    VoidCallback onPressed, {
    bool compact = false,
    bool finish = false,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: finish ? 112 : 70,
        maxWidth: compact ? (finish ? 150 : 112) : 150,
        minHeight: 30,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF56331E),
          backgroundColor: const Color(0xFFE6C28A),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: const Size(70, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: Color(0xFF825731), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          shadowColor: const Color(0xFFA87742),
          elevation: 2,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: compact ? 12 : 13,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _stopMovement() {
    _leftHeld = false;
    _rightHeld = false;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_gameplayPaused || _mode != 'catch') return KeyEventResult.ignored;
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;
    if (!isDown && !isUp) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      _leftHeld = isDown;
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      _rightHeld = isDown;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _resetAssembly() {
    if (_mode != 'assemble' || !mounted) return;
    setState(() {
      _assemblyChoices = [..._assemblyChoices, ..._assembledTokens];
      _assembledTokens = [];
      _incorrectTokenIndexes = [];
      _feedback = '';
    });
  }

  void _selectAssemblyToken(_Game4Token token) {
    if (_mode != 'assemble' || !mounted) return;
    if (!_assemblyChoices.any((candidate) => candidate.id == token.id)) return;
    setState(() {
      _assemblyChoices.removeWhere((candidate) => candidate.id == token.id);
      _assembledTokens.add(token);
      _incorrectTokenIndexes = [];
      _feedback = '';
    });
  }

  void _removeAssemblyToken(int index) {
    if (_mode != 'assemble' ||
        !mounted ||
        index < 0 ||
        index >= _assembledTokens.length) {
      return;
    }
    setState(() {
      final token = _assembledTokens.removeAt(index);
      _assemblyChoices.add(token);
      _incorrectTokenIndexes = [];
      _feedback = '';
    });
  }

  void _reorderAssemblyToken(int tokenId, int targetIndex) {
    if (_mode != 'assemble' || !mounted) return;
    final sourceIndex = _assembledTokens.indexWhere(
      (token) => token.id == tokenId,
    );
    if (sourceIndex < 0 || sourceIndex == targetIndex) return;
    setState(() {
      if (targetIndex >= _assembledTokens.length) {
        final token = _assembledTokens.removeAt(sourceIndex);
        _assembledTokens.add(token);
      } else {
        final source = _assembledTokens[sourceIndex];
        final target = _assembledTokens[targetIndex];
        _assembledTokens[sourceIndex] = target;
        _assembledTokens[targetIndex] = source;
      }
      _incorrectTokenIndexes = [];
      _feedback = '';
    });
  }

  void _checkAssembly() {
    if (_mode != 'assemble' || !mounted) return;
    final target = _activeRound.targetTokens;
    final mismatchedIndexes = <int>[];
    for (var index = 0; index < _assembledTokens.length; index++) {
      if (index >= target.length ||
          _assembledTokens[index].value != target[index]) {
        mismatchedIndexes.add(index);
      }
    }
    final missingCount = max(0, target.length - _assembledTokens.length);
    final isCorrect = missingCount == 0 && mismatchedIndexes.isEmpty;

    if (!isCorrect) {
      unawaited(_playGameSound('incorrect', 'incorrect-answer.mp3'));
      _showVisualEffect(
        missingCount > 0 ? 'INCOMPLETE ANSWER' : 'INCORRECT ORDER',
        const Color(0xFFEF4444),
      );
      setState(() {
        _incorrectTokenIndexes = mismatchedIndexes;
        if (missingCount > 0) {
          final placedWrongly = mismatchedIndexes.length;
          _feedback =
              'The statement is missing $missingCount code piece(s). '
              '${placedWrongly > 0 ? '$placedWrongly placed piece(s) also in the wrong position.' : ''}';
        } else {
          _lives = max(0, _lives - 1);
          _mistakes++;
          _bonusStreak = 0;
          _feedback =
              'Incorrect order. You lost 1 heart ($_lives/$_maxLives remaining). '
              '${mismatchedIndexes.length} code piece(s) is/are out of place.';
          if (_lives == 0) {
            _mode = 'failed';
            _stopGameplayTimer();
            unawaited(_playGameSound('game-over', 'game-over.mp3'));
            unawaited(_pauseBackgroundMusic());
            _feedback = 'Assembly Phase ended: no lives remaining.';
          }
        }
      });
      if (_lives == 0) unawaited(_submitResultOnce());
      return;
    }

    final reward = _settings.statementReward;
    unawaited(_playGameSound('correct', 'correct-answer.mp3'));
    _showVisualEffect('CORRECT +$reward', const Color(0xFFDFF8E9));
    final isFinalRound = _roundIndex >= _rounds.length - 1;
    if (isFinalRound) {
      setState(() {
        _roundsCleared++;
        _points += reward;
        _incorrectTokenIndexes = [];
        _feedback = 'All three rounds completed locally.';
        _mode = 'completed';
        _stopGameplayTimer();
        unawaited(_pauseBackgroundMusic());
      });
      unawaited(_submitResultOnce());
      return;
    }

    _roundsCleared++;
    _points += reward;
    _roundIndex++;
    _startCatchPhase(resetRun: false);
    if (mounted) setState(() {});
  }

  int get _calculatedStars {
    final stars = 3 - max(0, _mistakes - 3) - _hintsUsed;
    return stars.clamp(0, 3).toInt();
  }

  bool get _runPassed =>
      _mode == 'completed' &&
      _roundsCleared >= _rounds.length &&
      _calculatedStars >= 1;

  bool get _nextLevelAvailable {
    if (AllUsers.activeUser == null ||
        !_runPassed ||
        _resultSaveSucceeded != true ||
        _levelNumber >= 5) {
      return false;
    }
    final nextLevel = GameData.level(3, _levelNumber + 1);
    final status = nextLevel['status'];
    return status == 'Ready' || status == 'Cleared';
  }

  Future<void> _submitResultOnce() async {
    if (!mounted || _resultSubmitted || _resultSavePending) return;
    if (_mode != 'completed' && _mode != 'failed') return;

    final submissionRunId = _runId;
    final passed = _runPassed;
    final score = _points + _bonusPoints;
    final stars = _calculatedStars;
    _resultSubmitted = true;
    setState(() {
      _resultSavePending = true;
      _resultSaveSucceeded = null;
    });

    bool saved = false;
    try {
      saved = await GameData.recordLevelResult(
        game: 3,
        number: _levelNumber,
        score: score,
        stars: stars,
        completed: passed,
        unlockStarRequirement: 1,
      );
    } catch (error) {
      debugPrint('Game 4 result save failed: $error');
    }

    if (!mounted || submissionRunId != _runId) return;
    setState(() {
      _resultSavePending = false;
      _resultSaveSucceeded = saved;
    });
  }

  void _retryRun() {
    if (_resultSavePending) return;
    _runId++;
    _resultSubmitted = false;
    _resultSaveSucceeded = null;
    _instructionOverlay = 'none';
    _initializeLevel(_levelNumber);
    _startCatchPhase();
    unawaited(_startBackgroundMusic());
    if (mounted) setState(() {});
  }

  void _openLevelsFromResult() {
    if (_resultSavePending) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {});
  }

  Future<void> _goToNextLevel() async {
    if (!_nextLevelAvailable || _resultSavePending) return;
    final nextLevel = _levelNumber + 1;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Game4Page(
          selectedLevel: nextLevel,
          suppressIntroTutorial: true,
          continueToTutorialAfterGuide: false,
        ),
      ),
    );
  }

  Future<void> _revealHint() async {
    if (_mode != 'assemble' || !mounted) return;
    final activeHints = _activeRound.hints;
    if (activeHints.isEmpty) {
      setState(() => _feedback = 'No hint available for this level.');
      return;
    }
    if (_revealedHintCount >= activeHints.length) {
      setState(() {
        _hintMessage = activeHints
            .asMap()
            .entries
            .map((entry) => 'Hint ${entry.key + 1}: ${entry.value}')
            .join('\n');
        _feedback = 'All available hints are already shown.';
      });
      return;
    }
    if (_coinsLoading || _pendingCoinOperations > 0) {
      setState(
        () =>
            _feedback = 'Coin balance is still being saved. Please try again.',
      );
      return;
    }
    if (_hintPurchasePending) return;
    if (_coins < 1) {
      setState(() => _feedback = 'You need at least 1 coin to use a hint.');
      return;
    }

    setState(() {
      _hintPurchasePending = true;
      _feedback = 'Using 1 coin for a hint...';
    });
    final result = await GameCoinStorage.spend(1);
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _hintPurchasePending = false;
        _coins = result.balance;
        _feedback = result.message == 'Insufficient coins.'
            ? 'You need at least 1 coin to use a hint.'
            : result.message ?? 'Coin balance could not be saved.';
      });
      return;
    }

    final nextHintCount = min(activeHints.length, _revealedHintCount + 1);
    final nextHint = activeHints[nextHintCount - 1];
    setState(() {
      _hintPurchasePending = false;
      _coins = result.balance;
      _hintsUsed++;
      _revealedHintCount = nextHintCount;
      _hintMessage = [
        if (_hintMessage.isNotEmpty) _hintMessage,
        'Hint $nextHintCount: $nextHint',
      ].join('\n');
      _feedback = '';
    });
    unawaited(_playGameSound('hint', 'hint.mp3'));
    _showVisualEffect('HINT REVEALED', teal);
  }

  int _clamp(int value, int min, int max) => value.clamp(min, max).toInt();

  _Game4LevelSettings _settingsForLevel(int level) {
    const settings = <int, _Game4LevelSettings>{
      1: _Game4LevelSettings(
        title: 'Variable Catch Basics',
        subtitle:
            'Catch the tokens and build simple Java variable declarations.',
        objective: 'Collect the correct code parts, avoid hazards, and arrange each Java variable statement in the right order.',
        spawnIntervalMs: 920,
        fallSpeed: 230,
        moveSpeed: 460,
        statementReward: 120,
      ),
      2: _Game4LevelSettings(
        title: 'Numbers and Text',
        subtitle: 'Work with whole numbers, decimals, and character data.',
        objective: 'Catch the needed tokens for each Java variable statement and assemble them correctly.',
        spawnIntervalMs: 860,
        fallSpeed: 245,
        moveSpeed: 475,
        statementReward: 130,
      ),
      3: _Game4LevelSettings(
        title: 'Variable Types in Action',
        subtitle: 'Handle floating-point, long, and String declarations under more pressure.',
        objective: 'Catch each correct token set and arrange every Java variable declaration before mistakes run out.',
        spawnIntervalMs: 820,
        fallSpeed: 260,
        moveSpeed: 490,
        statementReward: 140,
      ),
      4: _Game4LevelSettings(
        title: 'Mixed Declarations',
        subtitle: 'Combine constants, booleans, and decimal values while hazards speed up.',
        objective: 'Stay accurate under pressure by collecting the needed tokens and arranging each declaration correctly.',
        spawnIntervalMs: 780,
        fallSpeed: 275,
        moveSpeed: 505,
        statementReward: 150,
      ),
      5: _Game4LevelSettings(
        title: 'Variable Master Catch',
        subtitle: 'Finish the catch challenge with multi-type Java variable declarations.',
        objective: 'Complete all Java Variables rounds by catching the right parts, avoiding hazards, and arranging each declaration correctly.',
        spawnIntervalMs: 740,
        fallSpeed: 290,
        moveSpeed: 520,
        statementReward: 170,
      ),
    };
    return settings[level]!;
  }

  List<_Game4Statement> _statementPoolForLevel(int level) {
    const Map<int, List<_Game4Statement>> pools = {
      1: [
        _Game4Statement(
          type: 'int',
          name: 'score',
          value: '10',
          valueLabel: 'integer',
          concept: 'whole-number variable declaration',
        ),
        _Game4Statement(
          type: 'String',
          name: 'name',
          value: '"Java"',
          valueLabel: 'text',
          concept: 'String variable declaration',
        ),
        _Game4Statement(
          type: 'boolean',
          name: 'isReady',
          value: 'true',
          valueLabel: 'boolean',
          concept: 'boolean variable declaration',
        ),
        _Game4Statement(
          type: 'int',
          name: 'level',
          value: '1',
          valueLabel: 'integer',
          concept: 'whole-number variable declaration',
        ),
        _Game4Statement(
          type: 'String',
          name: 'section',
          value: '"ICT"',
          valueLabel: 'text',
          concept: 'String variable declaration',
        ),
      ],
      2: [
        _Game4Statement(
          type: 'double',
          name: 'price',
          value: '99.99',
          valueLabel: 'decimal',
          concept: 'decimal variable declaration',
        ),
        _Game4Statement(
          type: 'char',
          name: 'grade',
          value: "'A'",
          valueLabel: 'character',
          concept: 'character variable declaration',
        ),
        _Game4Statement(
          type: 'int',
          name: 'lives',
          value: '3',
          valueLabel: 'integer',
          concept: 'whole-number variable declaration',
        ),
        _Game4Statement(
          type: 'double',
          name: 'distance',
          value: '15.5',
          valueLabel: 'decimal',
          concept: 'decimal variable declaration',
        ),
        _Game4Statement(
          type: 'char',
          name: 'initial',
          value: "'J'",
          valueLabel: 'character',
          concept: 'character variable declaration',
        ),
      ],
      3: [
        _Game4Statement(
          type: 'float',
          name: 'temperature',
          value: '36.5f',
          valueLabel: 'float',
          concept: 'float variable declaration',
        ),
        _Game4Statement(
          type: 'long',
          name: 'population',
          value: '1000000L',
          valueLabel: 'long integer',
          concept: 'long variable declaration',
        ),
        _Game4Statement(
          type: 'String',
          name: 'course',
          value: '"Variables"',
          valueLabel: 'text',
          concept: 'String variable declaration',
        ),
        _Game4Statement(
          type: 'float',
          name: 'speed',
          value: '12.75f',
          valueLabel: 'float',
          concept: 'float variable declaration',
        ),
        _Game4Statement(
          type: 'long',
          name: 'viewCount',
          value: '250000L',
          valueLabel: 'long integer',
          concept: 'long variable declaration',
        ),
      ],
      4: [
        _Game4Statement(
          qualifier: 'final',
          type: 'int',
          name: 'MAX_STUDENTS',
          value: '40',
          valueLabel: 'constant integer',
          concept: 'constant declaration',
        ),
        _Game4Statement(
          type: 'boolean',
          name: 'hasPassed',
          value: 'false',
          valueLabel: 'boolean',
          concept: 'boolean variable declaration',
        ),
        _Game4Statement(
          type: 'double',
          name: 'averageScore',
          value: '87.5',
          valueLabel: 'decimal',
          concept: 'decimal variable declaration',
        ),
        _Game4Statement(
          qualifier: 'final',
          type: 'String',
          name: 'COURSE_NAME',
          value: '"Java I"',
          valueLabel: 'constant text',
          concept: 'constant String declaration',
        ),
        _Game4Statement(
          type: 'long',
          name: 'fileSize',
          value: '4096L',
          valueLabel: 'long integer',
          concept: 'long variable declaration',
        ),
      ],
      5: [
        _Game4Statement(
          qualifier: 'final',
          type: 'String',
          name: 'userName',
          value: '"Coder"',
          valueLabel: 'constant text',
          concept: 'constant String declaration',
        ),
        _Game4Statement(
          type: 'int',
          name: 'attemptCount',
          value: '1',
          valueLabel: 'integer',
          concept: 'whole-number variable declaration',
        ),
        _Game4Statement(
          type: 'boolean',
          name: 'debugMode',
          value: 'true',
          valueLabel: 'boolean',
          concept: 'boolean variable declaration',
        ),
        _Game4Statement(
          qualifier: 'final',
          type: 'double',
          name: 'PASSING_RATE',
          value: '75.5',
          valueLabel: 'constant decimal',
          concept: 'constant decimal declaration',
        ),
        _Game4Statement(
          qualifier: 'final',
          type: 'char',
          name: 'GRADE_MARK',
          value: "'B'",
          valueLabel: 'constant character',
          concept: 'constant character declaration',
        ),
      ],
    };
    return pools[level]!;
  }

  List<T> _shuffle<T>(List<T> values, Random random) {
    final result = [...values];
    for (var index = result.length - 1; index > 0; index--) {
      final swapIndex = random.nextInt(index + 1);
      final value = result[index];
      result[index] = result[swapIndex];
      result[swapIndex] = value;
    }
    if (result.length > 1 && _sameOrder(result, values)) {
      final first = result[0];
      result[0] = result[1];
      result[1] = first;
    }
    return result;
  }

  bool _sameOrder<T>(List<T> first, List<T> second) {
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  List<String> _buildGeneratedHints(_Game4Statement statement) {
    final hints = <String>[];
    if (statement.qualifier == 'final') {
      hints.add(
        'This statement starts with a Java modifier before the data type.',
      );
    }
    hints.add(
      'Start with ${statement.qualifier == null ? 'the ${statement.type} data type' : 'the modifier and the ${statement.type} data type'}.',
    );
    hints.add(
      '${statement.name} is the variable name, so place it before the equals sign.',
    );
    if (statement.type == 'String') {
      hints.add('String values stay inside double quotation marks.');
    } else if (statement.type == 'char') {
      hints.add(
        'A char value uses single quotation marks around one character.',
      );
    } else if (statement.type == 'boolean') {
      hints.add('Boolean values use true or false without quotation marks.');
    } else if (statement.type == 'float') {
      hints.add('A float literal keeps the f suffix at the end of the number.');
    } else if (statement.type == 'long') {
      hints.add('A long literal keeps the L suffix at the end of the number.');
    } else {
      hints.add(
        'Place the value after the equals sign, then end the statement with a semicolon.',
      );
    }
    return hints.take(3).toList();
  }

  List<_Game4Round> _buildGeneratedRounds(
    int level, {
    required bool randomizeStatements,
  }) {
    final random = Random();
    final pool = _statementPoolForLevel(level);
    final selectedPool = randomizeStatements
        ? _shuffle(pool, random)
        : [...pool];
    final startIndex = (level - 1) % pool.length;

    return List.generate(3, (roundIndex) {
      final templateIndex = randomizeStatements
          ? roundIndex % selectedPool.length
          : (startIndex + roundIndex) % pool.length;
      final statement = selectedPool[templateIndex];
      final targetTokens = statement.tokens;
      return _Game4Round(
        id: 'generated-g4-l$level-r${roundIndex + 1}',
        prompt: 'Build a valid ${statement.concept} for ${statement.name}.',
        targetTokens: targetTokens,
        hints: _buildGeneratedHints(statement),
        shuffledTokens: _shuffle(targetTokens, random),
      );
    });
  }

  TextStyle _textStyle({
    double size = 14,
    FontWeight weight = FontWeight.bold,
    Color color = darkText,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Roboto',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  Widget _hudItem(
    String label,
    String value, {
    IconData? icon,
    Key? key,
    bool compact = false,
  }) {
    return Container(
      key: key,
      alignment: compact ? Alignment.center : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 10,
        vertical: compact ? 2 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DC),
        border: Border.all(color: purple, width: compact ? 2 : 3),
        boxShadow: const [BoxShadow(color: darkPurple, offset: Offset(4, 4))],
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: compact
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 16 : 20, color: darkPurple),
            SizedBox(width: compact ? 2 : 5),
          ],
          Flexible(
            child: Text(
              '$label: ',
              overflow: TextOverflow.ellipsis,
              style: _textStyle(
                size: compact ? 9 : 12,
                weight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(size: compact ? 10 : 13, weight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  double _tutorialDisplayPlayerX() {
    if (!_usesInteractiveTutorial ||
        _instructionOverlay != 'tutorial' ||
        _tutorialStepIndex != 0) {
      return _playerX;
    }
    final elapsed = (_tutorialAnimationTick * 120) % 3600;
    final phase = elapsed / 3600;
    final normalized = phase < .5 ? -.45 + phase : .05 + phase;
    return (normalized * (_playfieldWidth - _playerWidth)).clamp(
      0.0,
      _playfieldWidth - _playerWidth,
    );
  }

  _Game4FallingItem? _tutorialDisplayItem() {
    if (!_usesInteractiveTutorial || _instructionOverlay != 'tutorial') {
      return null;
    }
    final isToken = _tutorialStepIndex == 1;
    final isBomb = _tutorialStepIndex == 2;
    if (!isToken && !isBomb) return null;
    final duration = isToken ? 3300 : 3300;
    final phase = ((_tutorialAnimationTick * 120) % duration) / duration;
    return _Game4FallingItem(
      id: -1000 - _tutorialStepIndex,
      kind: isToken ? _Game4ItemKind.token : _Game4ItemKind.bomb,
      value: isToken ? _activeRound.targetTokens.first : 'bomb',
      x: isToken ? 160 : 220,
      y: 40 + phase * (_playfieldHeight - _itemSize - 40),
      speed: 0,
    );
  }

  Widget _buildPlayfield({double? height}) {
    final playfield = Focus(
      focusNode: _gameFocusNode,
      onFocusChange: (focused) {
        if (!focused) _stopMovement();
      },
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaleX = constraints.maxWidth / _playfieldWidth;
          final scaleY = constraints.maxHeight / _playfieldHeight;
          return Container(
            key: _tutorialPlayfieldKey,
            decoration: BoxDecoration(
              border: Border.all(color: darkPurple, width: 3),
              image: const DecorationImage(
                image: AssetImage('assets/game4/images/backgroundofgame4.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Listener(
              onPointerDown: (_) => _gameFocusNode.requestFocus(),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_screenShake),
                tween: _screenShake
                    ? Tween(begin: -6.0, end: 6.0)
                    : Tween(begin: 0.0, end: 0.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, offset, child) => Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                ),
                child: Stack(
                  children: [
                    for (final item in _fallingItems)
                      _buildFallingItem(item, scaleX, scaleY),
                    if (_tutorialDisplayItem() case final demoItem?)
                      _buildFallingItem(demoItem, scaleX, scaleY),
                    Positioned(
                      left: _tutorialDisplayPlayerX() * scaleX,
                      bottom: _playerBottomOffset * scaleY,
                      width: _playerWidth * scaleX,
                      height: _playerHeight * scaleY,
                      child: Image.asset(
                        'assets/game4/images/robotofgame4.png',
                        key: _tutorialCatcherKey,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        color: Colors.white,
                        child: Text(_feedback, style: _textStyle(size: 11)),
                      ),
                    ),
                    if (_visualEffectLabel.isNotEmpty)
                      _buildVisualEffectBanner(),
                    if (_screenShake)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(color: const Color(0x22FF0000)),
                        ),
                      ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _movementButton('←', left: true),
                          _movementButton('→', left: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (height == null) {
      return AspectRatio(aspectRatio: 780 / 540, child: playfield);
    }
    return SizedBox(width: double.infinity, height: height, child: playfield);
  }

  Widget _buildFallingItem(
    _Game4FallingItem item,
    double scaleX,
    double scaleY,
  ) {
    Widget child;
    if (item.kind == _Game4ItemKind.token) {
      child = Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          item.value,
          textAlign: TextAlign.center,
          style: _textStyle(size: 13, color: Colors.white),
        ),
      );
    } else {
      final path = switch (item.kind) {
        _Game4ItemKind.bomb => 'assets/game4/images/bomb.png',
        _Game4ItemKind.coin => 'assets/game4/images/coins.png',
        _Game4ItemKind.bonus =>
          item.value == 'banana'
              ? 'assets/game4/images/gas.png'
              : item.value == 'carrot'
              ? 'assets/game4/images/gear.png'
              : 'assets/game4/images/program.png',
        _ => 'assets/game4/images/bomb.png',
      };
      child = Image.asset(path, fit: BoxFit.contain);
    }
    return Positioned(
      left: item.x * scaleX,
      top: item.y * scaleY,
      width: _itemSize * scaleX,
      height: _itemSize * scaleY,
      child: child,
    );
  }

  Widget _movementButton(String label, {required bool left}) {
    return Listener(
      onPointerDown: (event) {
        _gameFocusNode.requestFocus();
        if (left) {
          _leftHeld = true;
        } else {
          _rightHeld = true;
        }
      },
      onPointerUp: (_) => left ? _leftHeld = false : _rightHeld = false,
      onPointerCancel: (_) => left ? _leftHeld = false : _rightHeld = false,
      child: _controlPlaceholder(label),
    );
  }

  Widget _controlPlaceholder(String label) {
    return Container(
      width: 64,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xCC1769AA),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: darkPurple, offset: Offset(0, 3))],
      ),
      child: Text(
        label,
        style: _textStyle(
          size: 28,
          weight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSidebar(_Game4Round round) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: paleCream,
        border: Border.all(color: purple, width: 3),
        boxShadow: const [BoxShadow(color: darkPurple, offset: Offset(5, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'OBJECTIVE',
            style: _textStyle(size: 12, weight: FontWeight.w900, color: purple),
          ),
          const SizedBox(height: 5),
          Text(
            _settings.title,
            style: _textStyle(size: 21, weight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(round.prompt, style: _textStyle(size: 13, height: 1.35)),
          const SizedBox(height: 12),
          Text(_settings.objective, style: _textStyle(size: 12, height: 1.35)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Text(
              _mode == 'catch'
                  ? 'Catch the required code tokens. Bombs and missed tokens cost lives. Bonus pickups build the life meter.'
                  : _mode == 'assemble'
                  ? 'Arrange every collected token in the exact Java declaration order.'
                  : _mode == 'completed'
                  ? 'This local run is complete. Result submission is deferred.'
                  : 'This local run failed. Result submission and retry are deferred.',
              style: _textStyle(size: 11, color: teal),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Level speed: ${_settings.fallSpeed}',
            style: _textStyle(size: 12),
          ),
          Text('Bonus points: $_bonusPoints', style: _textStyle(size: 12)),
          Text('Mistakes: $_mistakes', style: _textStyle(size: 12)),
          Text('Hints used: $_hintsUsed', style: _textStyle(size: 12)),
        ],
      ),
    );
  }

  Widget _buildVisualEffectBanner({bool inline = false}) {
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey(_visualEffectLabel),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xE624192A),
          border: Border.all(color: _visualEffectColor, width: 3),
          boxShadow: [BoxShadow(color: _visualEffectColor, blurRadius: 12)],
        ),
        child: Text(
          _visualEffectLabel,
          textAlign: TextAlign.center,
          style: _textStyle(
            size: 18,
            weight: FontWeight.w900,
            color: _visualEffectColor,
          ),
        ),
      ),
    );
    if (inline) return Center(child: child);
    return Positioned(left: 0, right: 0, top: 150, child: Center(child: child));
  }

  Widget _buildAssemblePlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final mobile =
            width <= 820 ||
            (height.isFinite && width > height && height <= 640);
        final blue = mobile;
        final edge = blue ? const Color(0xFF5AA9E6) : purple;
        final text = blue ? const Color(0xFF0D2F50) : darkText;
        final heading = blue ? const Color(0xFF1769AA) : darkPurple;
        final shellBackground = blue ? const Color(0xFFEAF5FF) : paleCream;
        final cardBackground = blue
            ? const Color(0xFFF5FAFF)
            : const Color(0xE6FFFFFF);
        final answerBackground = blue
            ? const Color(0xFFEAF5FF)
            : const Color(0xFFFFFDF1);
        final horizontalPadding = mobile ? 8.0 : 12.0;
        final actionTextSize = mobile ? 12.0 : 16.0;

        final answerArea = DragTarget<_Game4Token>(
          onAcceptWithDetails: (details) =>
              _reorderAssemblyToken(details.data.id, _assembledTokens.length),
          builder: (context, candidateData, rejectedData) {
            return Container(
              constraints: BoxConstraints(minHeight: mobile ? 52 : 92),
              padding: EdgeInsets.all(mobile ? 7 : 16),
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty
                    ? const Color(0xFFDFF8E9)
                    : answerBackground,
                border: Border.all(color: edge, width: 3),
              ),
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: mobile ? 5 : 12,
                runSpacing: mobile ? 5 : 10,
                children: [
                  for (var index = 0; index < _assembledTokens.length; index++)
                    _buildAssembledToken(
                      _assembledTokens[index],
                      index,
                      mobile: mobile,
                    ),
                  if (_assembledTokens.isEmpty)
                    Text(
                      'Tap a code piece below to place it here.',
                      style: _textStyle(size: mobile ? 10 : 12, color: text),
                    ),
                ],
              ),
            );
          },
        );

        final actionButtons = Wrap(
          alignment: WrapAlignment.center,
          spacing: mobile ? 6 : 12,
          runSpacing: mobile ? 6 : 10,
          children: [
            KeyedSubtree(
              key: _tutorialCheckAnswerKey,
              child: _assembleActionButton(
                'Check Answer',
                _checkAssembly,
                blue ? const Color(0xFF1769AA) : const Color(0xFFDFF3FF),
                textSize: actionTextSize,
                foreground: blue ? Colors.white : darkPurple,
                borderColor: edge,
                shadowColor: blue ? const Color(0x472369AA) : darkPurple,
              ),
            ),
            _assembleActionButton(
              'Reset',
              _resetAssembly,
              blue ? const Color(0xFFF5FAFF) : Colors.white,
              textSize: actionTextSize,
              foreground: text,
              borderColor: edge,
              shadowColor: blue ? const Color(0x472369AA) : darkPurple,
            ),
            _assembleActionButton(
              _revealedHintCount >= _activeRound.hints.length
                  ? 'All Hints Shown'
                  : 'Reveal Hint (-1 Coin)',
              _coinsLoading ||
                      _pendingCoinOperations > 0 ||
                      _hintPurchasePending ||
                      _revealedHintCount >= _activeRound.hints.length
                  ? null
                  : _revealHint,
              blue ? const Color(0xFFF5FAFF) : Colors.white,
              textSize: actionTextSize,
              foreground: text,
              borderColor: edge,
              shadowColor: blue ? const Color(0x472369AA) : darkPurple,
            ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(mobile ? 5 : 12),
          decoration: BoxDecoration(
            color: shellBackground,
            border: Border.all(color: edge, width: 4),
            boxShadow: blue
                ? const []
                : const [
                    BoxShadow(color: Color(0xCC432644), offset: Offset(8, 8)),
                  ],
            image: blue
                ? null
                : const DecorationImage(
                    image: AssetImage('assets/game4/images/background2.png'),
                    fit: BoxFit.cover,
                  ),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(horizontalPadding),
            decoration: BoxDecoration(
              color: cardBackground,
              border: Border.all(color: edge, width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, headerConstraints) {
                    final stackHeader = headerConstraints.maxWidth < 480;
                    final headingBlock = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ARRANGE PHASE',
                          style: _textStyle(
                            size: mobile ? 10 : 12,
                            weight: FontWeight.w900,
                            color: heading,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Arrange the Java Code',
                          style: _textStyle(
                            size: mobile ? 22 : 30,
                            weight: FontWeight.w900,
                            color: heading,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Click the collected parts in the correct order to compile the declaration.',
                          style: _textStyle(
                            size: mobile ? 12 : 16,
                            weight: FontWeight.w900,
                            color: text,
                            height: 1.16,
                          ),
                        ),
                      ],
                    );
                    final coinBadge = Container(
                      constraints: BoxConstraints(
                        maxWidth: stackHeader
                            ? headerConstraints.maxWidth
                            : 160,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: blue
                            ? const Color(0xFFD7F0FF)
                            : const Color(0xFFFFF7DC),
                        border: Border.all(color: edge, width: 3),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: mobile ? 18 : 22,
                            color: heading,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Coins $_coins',
                              overflow: TextOverflow.ellipsis,
                              style: _textStyle(
                                size: mobile ? 11 : 14,
                                weight: FontWeight.w900,
                                color: text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (stackHeader) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          headingBlock,
                          const SizedBox(height: 7),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: coinBadge,
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: headingBlock),
                        const SizedBox(width: 12),
                        coinBadge,
                      ],
                    );
                  },
                ),
                if (_visualEffectLabel.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildVisualEffectBanner(inline: true),
                ],
                SizedBox(height: mobile ? 8 : 16),
                answerArea,
                SizedBox(height: mobile ? 10 : 20),
                Text(
                  'AVAILABLE CODE PIECES',
                  style: _textStyle(
                    size: mobile ? 10 : 12,
                    weight: FontWeight.w900,
                    color: heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drag pieces to reorder them. Click an assembled piece to return it.',
                  style: _textStyle(
                    size: mobile ? 11 : 16,
                    weight: FontWeight.w900,
                    color: text,
                  ),
                ),
                SizedBox(height: mobile ? 7 : 12),
                if (_assemblyChoices.isEmpty)
                  Text(
                    'No more tokens left for this round.',
                    style: _textStyle(size: mobile ? 10 : 12, color: text),
                  )
                else
                  KeyedSubtree(
                    key: _tutorialTokenBankKey,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: mobile ? 6 : 12,
                      runSpacing: mobile ? 6 : 10,
                      children: [
                        for (final token in _assemblyChoices)
                          _buildAvailableToken(token, mobile: mobile),
                      ],
                    ),
                  ),
                SizedBox(height: mobile ? 9 : 20),
                actionButtons,
                SizedBox(height: mobile ? 9 : 20),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: mobile ? 42 : 58),
                  padding: EdgeInsets.all(mobile ? 7 : 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: blue
                        ? const Color(0xFFEAF5FF)
                        : const Color(0xFFFFFDF1),
                    border: Border.all(color: edge, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hintMessage.isNotEmpty)
                        Text(
                          _hintMessage,
                          textAlign: TextAlign.center,
                          style: _textStyle(
                            size: mobile ? 10 : 14,
                            weight: FontWeight.w900,
                            color: blue ? const Color(0xFF0F8F6F) : teal,
                          ),
                        ),
                      if (_feedback.isNotEmpty)
                        Text(
                          _feedback,
                          textAlign: TextAlign.center,
                          style: _textStyle(
                            size: mobile ? 10 : 14,
                            weight: FontWeight.bold,
                            color: text,
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
    );
  }

  Widget _buildAvailableToken(_Game4Token token, {bool mobile = false}) {
    return Material(
      color: const Color(0xFFE9F7FF),
      child: InkWell(
        onTap: () => _selectAssemblyToken(token),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 8 : 16,
            vertical: mobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: darkPurple, width: 3),
          ),
          child: Text(
            token.value,
            style: _textStyle(size: mobile ? 12 : 16, weight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _buildAssembledToken(
    _Game4Token token,
    int index, {
    bool mobile = false,
  }) {
    final isWrong = _incorrectTokenIndexes.contains(index);
    final isCorrectPosition =
        index < _activeRound.targetTokens.length &&
        token.value == _activeRound.targetTokens[index];
    final background = isWrong
        ? const Color(0xFFFFD6D6)
        : mobile
        ? const Color(0xFFEAF5FF)
        : isCorrectPosition
        ? const Color(0xFFDFF8E9)
        : const Color(0xFFE9F7FF);
    return DragTarget<_Game4Token>(
      onAcceptWithDetails: (details) =>
          _reorderAssemblyToken(details.data.id, index),
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<_Game4Token>(
          data: token,
          feedback: Material(
            color: Colors.transparent,
            child: _tokenChip(
              token.value,
              background,
              borderColor: mobile ? const Color(0xFF5AA9E6) : darkPurple,
              shadowColor: mobile
                  ? const Color(0x472369AA)
                  : const Color(0x73432644),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: _tokenChip(token.value, background),
          ),
          child: InkWell(
            onTap: () => _removeAssemblyToken(index),
            child: _tokenChip(
              token.value,
              candidateData.isNotEmpty ? const Color(0xFFDFF8E9) : background,
              borderColor: mobile ? const Color(0xFF5AA9E6) : darkPurple,
              shadowColor: mobile
                  ? const Color(0x472369AA)
                  : const Color(0x73432644),
            ),
          ),
        );
      },
    );
  }

  Widget _tokenChip(
    String value,
    Color background, {
    Color borderColor = darkPurple,
    Color shadowColor = const Color(0x73432644),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(3, 3))],
      ),
      child: Text(value, style: _textStyle(size: 14, weight: FontWeight.w900)),
    );
  }

  Widget _assembleActionButton(
    String label,
    VoidCallback? onPressed,
    Color color, {
    double textSize = 14,
    Color? foreground,
    Color borderColor = darkPurple,
    Color shadowColor = darkPurple,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground ?? darkPurple,
        disabledForegroundColor: foreground ?? darkPurple,
        padding: EdgeInsets.symmetric(
          horizontal: textSize <= 12 ? 10 : 18,
          vertical: textSize <= 12 ? 8 : 12,
        ),
        minimumSize: const Size(0, 44),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: BorderSide(color: borderColor, width: 3),
        elevation: 4,
        shadowColor: shadowColor,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: _textStyle(size: textSize, weight: FontWeight.w900),
      ),
    );
  }

  Widget _buildLocalStatePlaceholder() {
    final completed = _mode == 'completed';
    return Container(
      constraints: const BoxConstraints(minHeight: 360),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: paleCream,
        border: Border.all(color: purple, width: 3),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              completed ? Icons.emoji_events : Icons.lock,
              size: 54,
              color: completed ? teal : const Color(0xFF991B1B),
            ),
            const SizedBox(height: 12),
            Text(
              completed ? 'LOCAL RUN COMPLETED' : 'LOCAL RUN FAILED',
              style: _textStyle(size: 22, weight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              'Rounds cleared: $_roundsCleared/${_rounds.length}',
              style: _textStyle(size: 14),
            ),
            Text(
              'Final score: ${_points + _bonusPoints}',
              style: _textStyle(size: 14),
            ),
            const SizedBox(height: 10),
            Text(
              'Result submission, retry, and next-level navigation are deferred.',
              textAlign: TextAlign.center,
              style: _textStyle(size: 12, color: purple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    final passed = _runPassed;
    final isFinal = passed && _levelNumber >= 5;
    final elapsed = DateTime.now().difference(_runStartedAt).inSeconds;
    final resultMetrics = <ResultMetric>[
      ResultMetric(
        label: 'Stars',
        value: _resultSavePending ? '...' : '$_calculatedStars',
        icon: Icons.star,
      ),
      ResultMetric(
        label: 'Outputs',
        value: '$_roundsCleared/${_rounds.length}',
        icon: Icons.circle_outlined,
      ),
      ResultMetric(
        label: 'Mistakes',
        value: '$_mistakes',
        icon: Icons.gps_fixed,
      ),
      ResultMetric(
        label: 'Time',
        value: '${elapsed ~/ 60}:${(elapsed % 60).toString().padLeft(2, '0')}',
        icon: Icons.alarm,
      ),
      ResultMetric(
        label: 'Score',
        value: _resultSavePending ? '...' : '${_points + _bonusPoints}',
        icon: Icons.emoji_events,
      ),
    ];
    return Positioned.fill(
      child: IllustratedResultsOverlay(
        background: isFinal
            ? 'assets/results/complete-level.png'
            : 'assets/results/results-frame.png',
        metrics: resultMetrics,
        canAdvance: _nextLevelAvailable && !_resultSavePending,
        saving: _resultSavePending,
        onNext: _goToNextLevel,
        onRetry: _retryRun,
        onBack: _openLevelsFromResult,
        retryLabel: passed ? 'Play Again' : 'Retry Level',
      ),
    );
  }

  Widget _illustratedGame4Result({
    required String background,
    required List<List<String>> metrics,
    required bool canAdvance,
    required bool saving,
    required VoidCallback onNext,
    required VoidCallback onRetry,
    required VoidCallback onBack,
    required String retryLabel,
  }) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xCC020617),
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final resultTextSize = max(
              9.0,
              min(13.0, constraints.maxWidth * .028),
            );
            final resultButtonHeight = max(
              38.0,
              min(44.0, constraints.maxWidth * .10),
            );
            final resultButtonTextSize = max(
              8.0,
              min(11.0, constraints.maxWidth * .025),
            );
            final width = min(
              410.0,
              min(
                constraints.maxWidth * .94,
                constraints.maxHeight * .92 * .85,
              ),
            );
            final height = width * 482 / 410;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: max(1, width),
                height: max(1, height),
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
                                                  color: const Color(
                                                    0xFF4B2816,
                                                  ),
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
                                          child: _game4ResultButton(
                                            'Next Level',
                                            onNext,
                                            const Color(0xFF166534),
                                            resultButtonTextSize,
                                          ),
                                        ),
                                      if (canAdvance) const SizedBox(width: 4),
                                      Expanded(
                                        child: _game4ResultButton(
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
                                        child: _game4ResultButton(
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
      ),
    );
  }

  Widget _game4ResultButton(
    String label,
    VoidCallback onPressed,
    Color color,
    double textSize,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: Color(0xFF14532D), width: 2),
        elevation: 0,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: textSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildGameHud({required bool compact}) {
    final hudItems = <Widget>[
      _hudItem('Level', '$_levelNumber', icon: Icons.star, compact: compact),
      _hudItem(
        'Coins',
        _coinsLoading || _pendingCoinOperations > 0 ? '...' : '$_coins',
        icon: Icons.monetization_on,
        key: _tutorialCoinsKey,
        compact: compact,
      ),
      _hudItem(
        'Lives',
        '$_lives',
        icon: Icons.favorite,
        key: _tutorialLivesKey,
        compact: compact,
      ),
      if (_mode == 'catch')
        _instructionButton(
          'Guidelines',
          () => _openInstructionOverlay('guide', openedDuringGameplay: true),
        ),
      if (_mode == 'catch')
        _instructionButton(
          'Game Tutorial',
          () => _openInstructionOverlay('tutorial'),
        ),
      _hudItem(
        'Round',
        '${_roundIndex + 1}/${_rounds.length}',
        icon: Icons.flag,
        key: _tutorialRoundKey,
        compact: compact,
      ),
    ];

    if (!compact) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 6,
        runSpacing: 6,
        children: hudItems,
      );
    }

    return GridView.count(
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 2.2,
      children: hudItems,
    );
  }

  Widget _buildGameHeader({required bool compact}) {
    final stackCompactHeader =
        compact && MediaQuery.sizeOf(context).width < 600;
    final title = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GAME 4 MISSION',
          style: _textStyle(
            size: compact ? 8 : 12,
            weight: FontWeight.w900,
            color: purple,
          ),
        ),
        SizedBox(height: compact ? 1 : 3),
        Text(
          'Catch the Falling Java Code',
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: _textStyle(
            size: compact ? 16 : 25,
            weight: FontWeight.w900,
            height: 1.05,
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 16,
        vertical: compact ? 4 : 12,
      ),
      decoration: BoxDecoration(
        color: cream,
        border: Border.all(color: purple, width: 3),
      ),
      child: compact
          ? stackCompactHeader
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      const SizedBox(height: 5),
                      _buildGameHud(compact: true),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 2, child: title),
                      const SizedBox(width: 5),
                      Expanded(flex: 5, child: _buildGameHud(compact: true)),
                    ],
                  )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: title),
                const SizedBox(width: 12),
                Flexible(child: _buildGameHud(compact: false)),
              ],
            ),
    );
  }

  Widget _buildStageContent({
    required bool compact,
    required double viewportHeight,
  }) {
    final round = _activeRound;
    final playfield = _mode == 'catch'
        ? _buildPlayfield(
            height: compact
                ? min(
                    viewportHeight * .82,
                    720.0,
                  ).clamp(390.0, 720.0).toDouble()
                : null,
          )
        : _mode == 'assemble'
        ? _buildAssemblePlaceholder()
        : _buildLocalStatePlaceholder();

    if (_mode == 'assemble' || _mode == 'completed' || _mode == 'failed') {
      return playfield;
    }

    final sidebar = _buildSidebar(round);
    if (compact) {
      return Column(
        children: [
          Align(
            alignment: Alignment.center,
            child: FractionallySizedBox(widthFactor: .96, child: playfield),
          ),
          const SizedBox(height: 7),
          sidebar,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 300, child: sidebar),
        const SizedBox(width: 12),
        Expanded(child: playfield),
      ],
    );
  }

  Widget _buildStage({required bool compact, required double viewportHeight}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 5 : 12),
      decoration: BoxDecoration(
        color: sand,
        border: compact ? null : Border.all(color: purple, width: 4),
        boxShadow: compact
            ? const []
            : const [BoxShadow(color: darkPurple, offset: Offset(10, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGameHeader(compact: compact),
          SizedBox(height: compact ? 5 : 12),
          if (compact || _mode != 'catch')
            _buildStageContent(compact: compact, viewportHeight: viewportHeight)
          else
            Expanded(
              child: _buildStageContent(
                compact: false,
                viewportHeight: viewportHeight,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParentLevelHeading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: sand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GAME_FOUR · LEVEL ${_levelNumber.toString().padLeft(2, '0')}',
            style: _textStyle(
              size: 14,
              weight: FontWeight.w900,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _settings.title,
            style: _textStyle(
              size: 30,
              weight: FontWeight.w900,
              color: darkText,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameFrame({
    required bool compact,
    required double viewportHeight,
  }) {
    final stage = _buildStage(compact: compact, viewportHeight: viewportHeight);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 4 : 8),
      decoration: BoxDecoration(
        color: paleCream,
        border: Border.all(color: purple, width: compact ? 2 : 3),
        boxShadow: compact
            ? const []
            : const [BoxShadow(color: darkPurple, offset: Offset(4, 4))],
      ),
      child: stage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkText,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPortrait = constraints.maxHeight > constraints.maxWidth;
            final isShortLandscape =
                !isPortrait && constraints.maxHeight <= 640;
            final isNarrow = constraints.maxWidth < 900;
            final compact = isPortrait || isShortLandscape || isNarrow;
            final viewportHeight = constraints.maxHeight;
            final preserveDesktopAspect = !compact && _mode == 'catch';
            final rawFrame = !preserveDesktopAspect
                ? _buildGameFrame(
                    compact: compact,
                    viewportHeight: viewportHeight,
                  )
                : AspectRatio(
                    aspectRatio: 1280 / 720,
                    child: _buildGameFrame(
                      compact: false,
                      viewportHeight: viewportHeight,
                    ),
                  );
            final frame = ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: compact ? max(0, viewportHeight - 78) : 0,
              ),
              child: rawFrame,
            );
            final pageWidth = min(constraints.maxWidth, 1280.0);
            final page = SizedBox(
              width: pageWidth,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewportHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_buildParentLevelHeading(), frame],
                ),
              ),
            );

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Align(alignment: Alignment.topCenter, child: page),
                ),
                if (_instructionOverlay == 'story') _buildStoryOverlay(),
                if (_instructionOverlay == 'guide') _buildGuideOverlay(),
                if (_instructionOverlay == 'tutorial') _buildTutorialOverlay(),
                if (_mode == 'completed' || _mode == 'failed')
                  _buildResultOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }
}
