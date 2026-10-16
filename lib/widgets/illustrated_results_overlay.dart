import 'package:flutter/material.dart';

class ResultMetric {
  const ResultMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

/// The result board owns the complete parchment layout.  A metric is never
/// split across independent Positioned widgets: its icon, label, and value
/// are laid out together in one row.
class IllustratedResultsOverlay extends StatelessWidget {
  const IllustratedResultsOverlay({
    super.key,
    required this.background,
    required this.metrics,
    required this.canAdvance,
    required this.saving,
    required this.onNext,
    required this.onRetry,
    required this.onBack,
    required this.retryLabel,
    this.forceHorizontalFooter = false,
  });

  final String background;
  final List<ResultMetric> metrics;
  final bool canAdvance;
  final bool saving;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final String retryLabel;
  final bool forceHorizontalFooter;

  bool get _isCompleteArtwork => background.contains('complete-level');

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC020617),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // These are the real source-image dimensions. The image is always
          // fitted proportionally; only the content column is responsive.
          final boardAspect = _isCompleteArtwork ? 612 / 408 : 433 / 577;
          final maxWidth = (constraints.maxWidth - 24).clamp(
            1.0,
            double.infinity,
          );
          final maxHeight = (constraints.maxHeight - 12).clamp(
            1.0,
            double.infinity,
          );
          final landscape = constraints.maxWidth >= constraints.maxHeight;
          final boardWidth = maxWidth < maxHeight * boardAspect
              ? maxWidth
              : maxHeight * boardAspect;
          final boardHeight = boardWidth / boardAspect;
          final textSize = (boardWidth * .042).clamp(12.0, 17.0);
          final buttonTextSize = (boardWidth * .028).clamp(9.0, 12.0);
          const footerVisualOffset = 30.0;
          final contentBottomInset =
              boardHeight * (_isCompleteArtwork ? .14 : .16) -
              footerVisualOffset;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: boardWidth,
              height: boardHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(background, fit: BoxFit.contain),
                  Positioned(
                    left:
                        boardWidth *
                        (_isCompleteArtwork
                            ? .15
                            : landscape
                            ? .16
                            : .14),
                    right:
                        boardWidth *
                        (_isCompleteArtwork
                            ? .15
                            : landscape
                            ? .14
                            : .14),
                    // Source-image geometry: the baked icon centers in
                    // results-frame.png begin at about 30% of the image and
                    // end at about 71%. Moving the five-row column down to
                    // this band centers text on those existing icons.
                    top: boardHeight * (_isCompleteArtwork ? .22 : .245),
                    bottom: contentBottomInset
                        .clamp(0.0, double.infinity)
                        .toDouble(),
                    child: LayoutBuilder(
                      builder: (context, parchment) {
                        // Landscape keeps all three actions in one row, as in
                        // the reference. Only narrow portrait layouts stack.
                        final stackFooter =
                            !forceHorizontalFooter &&
                            !landscape &&
                            parchment.maxWidth < 300;
                        final footerHeight = stackFooter
                            ? 3 * 30.0 + 8
                            : (boardHeight * .095).clamp(32.0, 44.0);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              bottom: footerHeight + 8 + footerVisualOffset,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: boardWidth * .025,
                                ),
                                child: Column(
                                  children: [
                                    for (
                                      var index = 0;
                                      index < metrics.length;
                                      index++
                                    )
                                      Expanded(
                                        child: _StatisticRow(
                                          metric: metrics[index],
                                          textSize: textSize,
                                          iconSlotWidth: boardWidth * .12,
                                          showIcon: _isCompleteArtwork,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: parchment.maxHeight - footerHeight,
                              height: footerHeight,
                              child: saving
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF4B2816),
                                      ),
                                    )
                                  : _ResultFooter(
                                      stack: stackFooter,
                                      textSize: buttonTextSize,
                                      canAdvance: canAdvance,
                                      onNext: onNext,
                                      onRetry: onRetry,
                                      onBack: onBack,
                                      retryLabel: retryLabel,
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
          );
        },
      ),
    );
  }
}

class _StatisticRow extends StatelessWidget {
  const _StatisticRow({
    required this.metric,
    required this.textSize,
    required this.iconSlotWidth,
    required this.showIcon,
  });

  final ResultMetric metric;
  final double textSize;
  final double iconSlotWidth;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: iconSlotWidth,
          child: Icon(
            metric.icon,
            color: showIcon ? const Color(0xFF4B2816) : Colors.transparent,
            size: textSize * 1.7,
          ),
        ),
        SizedBox(width: iconSlotWidth * .30),
        Expanded(
          child: Text(
            metric.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF4B2816),
              fontSize: textSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(width: textSize * .5),
        Text(
          metric.value,
          maxLines: 1,
          style: TextStyle(
            color: const Color(0xFF4B2816),
            fontSize: textSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ResultFooter extends StatelessWidget {
  const _ResultFooter({
    required this.stack,
    required this.textSize,
    required this.canAdvance,
    required this.onNext,
    required this.onRetry,
    required this.onBack,
    required this.retryLabel,
  });

  final bool stack;
  final double textSize;
  final bool canAdvance;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _ResultButton(
        label: 'Next Level',
        onPressed: canAdvance ? onNext : null,
        color: const Color(0xFF166534),
        textSize: textSize,
      ),
      _ResultButton(
        label: retryLabel,
        onPressed: onRetry,
        color: const Color(0xFFD97706),
        textSize: textSize,
      ),
      _ResultButton(
        label: 'Back to Levels',
        onPressed: onBack,
        color: const Color(0xFF475569),
        textSize: textSize,
      ),
    ];
    if (stack) {
      return Column(
        children: [
          for (var index = 0; index < buttons.length; index++) ...[
            Expanded(child: buttons[index]),
            if (index < buttons.length - 1) const SizedBox(height: 4),
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var index = 0; index < buttons.length; index++) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: buttons[index],
            ),
          ),
          if (index < buttons.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.label,
    required this.onPressed,
    required this.color,
    required this.textSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: const Color(0xFF7A7468),
        foregroundColor: Colors.white,
        disabledForegroundColor: const Color(0xFFE6DDC8),
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: Color(0xFF14532D), width: 2),
        elevation: 0,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: textSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
