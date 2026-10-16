import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

typedef GameMessage = Future<Map<String, dynamic>> Function(
  Map<String, dynamic>,
);

class OriginalSurface extends StatefulWidget {
  final Map<String, dynamic> config;
  final GameMessage onMessage;
  final VoidCallback onExit;
  const OriginalSurface({
    super.key,
    required this.config,
    required this.onMessage,
    required this.onExit,
  });
  @override
  State<OriginalSurface> createState() => _OriginalSurfaceState();
}

class _OriginalSurfaceState extends State<OriginalSurface>
    with WidgetsBindingObserver {
  static int serial = 0;
  late final String viewType = 'itechs-original-game-${serial++}';
  late final web.HTMLIFrameElement frame;
  late final JSFunction listener;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    frame = web.HTMLIFrameElement()
      ..src = Uri.base
          .resolve('assets/assets/original_games/index.html')
          .toString()
      ..title = 'Original iTECHS game'
      ..allow = 'autoplay; fullscreen; screen-wake-lock'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = '0';
    ui.platformViewRegistry.registerViewFactory(viewType, (_) => frame);
    listener = ((web.MessageEvent event) {
      () async {
        if (event.source != frame.contentWindow ||
            event.origin != Uri.base.origin) {
          return;
        }
        final raw = event.data.dartify();
        if (raw is! String) return;
        Map<String, dynamic> data;
        try {
          data = Map<String, dynamic>.from(jsonDecode(raw));
        } catch (_) {
          return;
        }
        if (data['channel'] != 'itechs-original-games') return;
        if (data['type'] == 'ready') {
          send({'type': 'configure', ...widget.config});
          return;
        }
        if (data['type'] == 'exit') {
          widget.onExit();
          return;
        }
        if (data['id'] == null && data['type'] != 'coins') return;
        try {
          final result = await widget.onMessage(data);
          if (mounted && data['id'] != null) {
            send({'type': 'response', 'id': data['id'], 'result': result});
          }
        } catch (error) {
          if (mounted) {
            send({
              'type': 'response',
              'id': data['id'],
              'error': error.toString(),
            });
          }
        }
      }();
    }).toJS;
    web.window.addEventListener('message', listener);
  }

  void send(Map<String, dynamic> value) => frame.contentWindow?.postMessage(
    jsonEncode({'channel': 'itechs-original-games', ...value}).toJS,
    Uri.base.origin.toJS,
  );
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      send({'type': 'suspend'});
    }
    if (state == AppLifecycleState.resumed) send({'type': 'resume'});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    web.window.removeEventListener('message', listener);
    frame.src = 'about:blank';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: viewType);
}
