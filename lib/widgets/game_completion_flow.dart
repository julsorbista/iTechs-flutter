import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A completed level celebrates before revealing its score board.
class GameCompletionFlow extends StatefulWidget {
  const GameCompletionFlow({
    super.key,
    required this.successful,
    required this.child,
  });
  final bool successful;
  final Widget child;
  @override
  State<GameCompletionFlow> createState() => _GameCompletionFlowState();
}

class _GameCompletionFlowState extends State<GameCompletionFlow>
    with SingleTickerProviderStateMixin {
  bool viewed = false;
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  @override
  void initState() {
    super.initState();
    if (widget.successful) animation.repeat();
  }

  @override
  void didUpdateWidget(covariant GameCompletionFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.successful && !oldWidget.successful) animation.repeat();
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.successful || viewed) return widget.child;
    return ColoredBox(
      color: const Color(0xCC020617),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, _) =>
                  CustomPaint(painter: _Confetti(animation.value)),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 612,
                  height: 408,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/results/complete-level.png'),
                      Positioned(
                        left: 145,
                        right: 133,
                        top: 42,
                        height: 43,
                        child: Container(
                          color: const Color(0xFFA9381C),
                          alignment: Alignment.center,
                          child: const Text(
                            'CONGRATULATIONS!',
                            style: TextStyle(
                              color: Color(0xFFFFF2CA),
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 280,
                        right: 85,
                        top: 130,
                        child: Column(
                          children: [
                            Text(
                              'Level Complete!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4B2816),
                              ),
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Great job! Review your results\nand continue your adventure.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4B2816),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 280,
                        right: 85,
                        bottom: 85,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF166534),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            animation.stop();
                            setState(() => viewed = true);
                          },
                          child: const Text('View Results'),
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
    );
  }
}

class _Confetti extends CustomPainter {
  _Confetti(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Colors.amber,
      Colors.pink,
      Colors.lightBlue,
      Colors.green,
      Colors.purple,
    ];
    final random = math.Random(42);
    for (var i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y =
          ((progress + random.nextDouble()) % 1) * (size.height + 30) - 15;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 4 + i);
      canvas.drawRect(
        const Rect.fromLTWH(-3, -5, 6, 10),
        Paint()..color = colors[i % colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Confetti oldDelegate) =>
      oldDelegate.progress != progress;
}
