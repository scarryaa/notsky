import 'package:flutter/material.dart';

class CharacterCountPainter extends CustomPainter {
  final double progress;
  final double innerProgress;
  final Color primaryColor;
  final Color backgroundColor;

  CharacterCountPainter({
    required this.progress,
    required this.innerProgress,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius - 1.5, backgroundPaint);

    final outlinePaint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.5),
      -1.5708,
      progress * 2 * 3.14159,
      false,
      outlinePaint,
    );

    if (innerProgress > 0) {
      final fillPaint =
          Paint()
            ..color = primaryColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 3.0),
        -1.5708,
        innerProgress * 2 * 3.14159,
        true,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CharacterCountPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.innerProgress != innerProgress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
