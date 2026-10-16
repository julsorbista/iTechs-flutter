import 'package:flutter/material.dart';

/// Flutter equivalent of the React StudentStoryFrame image-only presentation.
class StudentStoryFrame extends StatelessWidget {
  const StudentStoryFrame({
    super.key,
    required this.imagePath,
    required this.worldTitle,
    required this.page,
    required this.totalPages,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.onPrimary,
  });

  final String imagePath;
  final String worldTitle;
  final int page;
  final int totalPages;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onPrimary;

  bool get isFirstPage => page == 0;
  bool get isLastPage => page == totalPages - 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth <= 760 &&
            constraints.maxHeight >= constraints.maxWidth;
        final stageWidth = (constraints.maxWidth - (compact ? 20 : 32))
            .clamp(0.0, 1180.0)
            .toDouble();
        final availableHeight = constraints.maxHeight - (compact ? 20 : 32);
        final stageHeight = compact
            ? availableHeight.clamp(520.0, 900.0).toDouble()
            : (stageWidth * 9 / 16).clamp(0.0, availableHeight).toDouble();

        return Center(
          child: SizedBox(
            width: stageWidth,
            height: stageHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0E1B2F),
                border: Border.all(color: const Color(0xE6C5E7FF), width: 5),
                borderRadius: BorderRadius.circular(34),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 32,
                    offset: Offset(0, 24),
                  ),
                  BoxShadow(
                    color: Color(0x33FFFFFF),
                    blurRadius: 0,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(29),
                          gradient: const RadialGradient(
                            center: Alignment(-.85, -.2),
                            radius: 1.4,
                            colors: [Color(0x996FD7FF), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: compact ? 10 : 24,
                    right: compact ? 10 : 24,
                    top: compact ? 12 : 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _pill(worldTitle, dark: true),
                        _pill('INTRO  ${page + 1}/$totalPages'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 14 : 34,
                      compact ? 84 : 92,
                      compact ? 14 : 34,
                      compact ? 84 : 78,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: const Offset(0, .03),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: Image.asset(
                          imagePath,
                          key: ValueKey(imagePath),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Text(
                                  'Story page unavailable.',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Color(0xFFC5E7FF),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: compact ? 10 : null,
                    right: compact ? 10 : 34,
                    bottom: compact ? 10 : 24,
                    child: SizedBox(
                      width: compact ? stageWidth - 20 : 360,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: compact
                              ? const Color(0xC70A1628)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: compact
                              ? Border.all(color: const Color(0x61D8F0FF))
                              : null,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(compact ? 9 : 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _storyButton('Skip', onSkip, pale: true),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _storyButton(
                                  isFirstPage ? 'Back' : 'Previous',
                                  isFirstPage ? onBack : onBack,
                                  pale: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _storyButton(
                                  isLastPage ? 'Start' : 'Next',
                                  isLastPage ? onPrimary : onNext,
                                  primary: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: compact ? 82 : 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        totalPages,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: index == page ? 22 : 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == page
                                ? const Color(0xFF9EE8FF)
                                : const Color(0x59FFFFFF),
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: const Color(0xBFFFFFFF)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pill(String text, {bool dark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? const Color(0xD94A2948) : const Color(0xE6FFF7C9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x6674405F)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
          color: dark ? Colors.white : const Color(0xFF512744),
        ),
      ),
    );
  }

  Widget _storyButton(
    String label,
    VoidCallback onPressed, {
    bool primary = false,
    bool pale = false,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          foregroundColor: const Color(0xFF512744),
          backgroundColor: primary
              ? const Color(0xFFFFD467)
              : (pale ? const Color(0xFFFFF9DF) : const Color(0xFFFFF9DF)),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: const BorderSide(color: Color(0xFF74405F), width: 2),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ),
      ),
    );
  }
}
