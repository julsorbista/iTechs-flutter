import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../glob/audio.dart';
import '../glob/game_data.dart';
import '../glob/user.dart';
import 'game_content.dart';
import 'original_game_bridge.dart';
import 'original_surface.dart';

class GameplayPage extends StatefulWidget {
  final int game, number;
  const GameplayPage({super.key, required this.game, required this.number});
  @override
  State<GameplayPage> createState() => _GameplayPageState();
}

class _GameplayPageState extends State<GameplayPage> {
  late final bridge = OriginalGameBridge(widget.game);
  late final ready = GameContent.load();
  @override
  void initState() {
    super.initState();
    AppAudio.stop();
    if (widget.game == 0) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    if (widget.game == 0) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    AppAudio.startMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF111827),
    body: FutureBuilder<void>(
      future: ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Game content could not load: ${snapshot.error}'),
          );
        }
        return LandscapeGameFrame(
          enabled: widget.game == 0,
          child: OriginalSurface(
            config: {
              'game': OriginalGameBridge.types[widget.game],
              'number': widget.number,
              'user': {
                ...AllUsers.activeUser!,
                'id': GameData.owner,
                'role': 'STUDENT',
              },
              'coins': GameData.coins,
              'musicVolume': AllUsers.musicVolume,
              'sfxVolume': AllUsers.sfxVolume,
            },
            onMessage: bridge.handle,
            onExit: () => Navigator.pop(context),
          ),
        );
      },
    ),
  );
}

/// A portrait browser cannot rotate physically, so rotate its game viewport.
class LandscapeGameFrame extends StatelessWidget {
  final bool enabled;
  final Widget child;
  const LandscapeGameFrame({
    super.key,
    required this.enabled,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        enabled && constraints.maxHeight > constraints.maxWidth
        ? RotatedBox(quarterTurns: 1, child: child)
        : child,
  );
}
