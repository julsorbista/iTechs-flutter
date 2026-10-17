import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  WebViewController? controller;
  HttpServer? server;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      prepare();
    } else {
      error = 'Run the original games on Chrome, Android, or iOS.';
    }
  }

  Future<void> prepare() async {
    try {
      // Serves packaged frontend files on loopback only; no backend/API exists.
      final local = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      if (!mounted) {
        await local.close(force: true);
        return;
      }
      server = local;
      local.listen((request) async {
        try {
          final path = request.uri.path == '/'
              ? 'index.html'
              : request.uri.path.substring(1);
          if (path.contains('..') ||
              path.contains('\\') ||
              request.method != 'GET') {
            request.response.statusCode = 403;
            await request.response.close();
            return;
          }
          final data = await rootBundle.load('assets/original_games/$path');
          const mime = {
            'html': 'text/html',
            'js': 'application/javascript',
            'css': 'text/css',
            'png': 'image/png',
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'avif': 'image/avif',
            'webp': 'image/webp',
            'svg': 'image/svg+xml',
            'mp3': 'audio/mpeg',
            'wav': 'audio/wav',
            'mp4': 'video/mp4',
            'woff2': 'font/woff2',
            'woff': 'font/woff',
            'ttf': 'font/ttf',
          };
          request.response.headers.set(
            'Content-Type',
            mime[path.split('.').last] ?? 'application/octet-stream',
          );
          request.response.add(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
        } catch (_) {
          request.response.statusCode = 404;
        }
        await request.response.close();
      });
      final origin = 'http://127.0.0.1:${local.port}';
      final webview = WebViewController();
      controller = webview;
      await webview.setJavaScriptMode(JavaScriptMode.unrestricted);
      await webview.setBackgroundColor(const Color(0xFF111827));
      await webview.addJavaScriptChannel(
        'ItechsBridge',
        onMessageReceived: (event) async {
          if (!mounted) return;
          try {
            final data = Map<String, dynamic>.from(jsonDecode(event.message));
            if (data['channel'] != 'itechs-original-games') return;
            if (data['type'] == 'ready') {
              await send({'type': 'configure', ...widget.config});
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
                await send({
                  'type': 'response',
                  'id': data['id'],
                  'result': result,
                });
              }
            } catch (e) {
              if (mounted) {
                await send({
                  'type': 'response',
                  'id': data['id'],
                  'error': e.toString(),
                });
              }
            }
          } catch (_) {
            /* Ignore messages outside the game protocol. */
          }
        },
      );
      await webview.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => request.url.startsWith('$origin/')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      );
      await webview.loadRequest(Uri.parse('$origin/index.html'));
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> send(Map<String, dynamic> data) async {
    await controller?.runJavaScript(
      'window.itechsReceive(${jsonEncode(jsonEncode({'channel': 'itechs-original-games', ...data}))});',
    );
  }

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
    controller?.loadRequest(Uri.parse('about:blank'));
    server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) return Center(child: Text(error!));
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(controller: controller!);
  }
}
