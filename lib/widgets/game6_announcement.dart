import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class Game6Announcement extends StatelessWidget {
  const Game6Announcement({
    super.key,
    required this.level,
    required this.challenge,
    required this.objective,
    this.countdown,
  });
  final int level;
  final String challenge, objective;
  final int? countdown;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: const ColoredBox(color: Color(0xC9101714)),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final portrait = constraints.maxHeight > constraints.maxWidth;
                final aspect = portrait ? .95 : 612 / 408;
                final width = math.min(
                  constraints.maxWidth,
                  math.min(
                    constraints.maxHeight * aspect,
                    portrait ? 640.0 : 800.0,
                  ),
                );
                final height = width / aspect;
                return Center(
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/game6/announcement/announcement-board.png',
                          fit: BoxFit.fill,
                        ),
                        Positioned(
                          left: width * .15,
                          right: width * .15,
                          top: height * .29,
                          bottom: height * .25,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: 420,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'CHALLENGE ANNOUNCEMENT',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 15,
                                        letterSpacing: 2.2,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF734521),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      countdown == null
                                          ? 'READY?'
                                          : '$countdown',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Georgia',
                                        fontSize: countdown == null ? 32 : 68,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF382412),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      width: 265,
                                      height: 2,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0x00734521),
                                            Color(0xFF986338),
                                            Color(0x00734521),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'LEVEL $level: $challenge ROUND',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 22,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF734521),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      objective,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 20,
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF382412),
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
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
