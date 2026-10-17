import 'package:flutter/material.dart';

typedef GameMessage = Future<Map<String, dynamic>> Function(
  Map<String, dynamic>,
);

class OriginalSurface extends StatelessWidget {
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
  Widget build(BuildContext context) =>
      const Center(child: Text('Open on Chrome, Android, or iOS.'));
}
