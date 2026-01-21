import 'dart:math' as math;
import 'package:flutter/material.dart';

class CircularDownloadProgress extends StatelessWidget {
  final double progress;
  final bool hasError;
  final VoidCallback? onRetry;
  final double size;

  const CircularDownloadProgress({
    super.key,
    required this.progress,
    this.hasError = false,
    this.onRetry,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasError ? onRetry : null,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CircularProgressPainter(
            progress: progress,
            hasError: hasError,
          ),
          child: hasError
              ? Center(
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: size * 0.45,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool hasError;

  _CircularProgressPainter({
    required this.progress,
    required this.hasError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = hasError ? Colors.red.withValues(alpha: 0.7) : Colors.black54
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc (only for non-error state)
    if (!hasError && progress > 0) {
      final arcPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      final arcRadius = radius - 6.0;
      final rect = Rect.fromCircle(center: center, radius: arcRadius);

      // Start at top (-π/2) and sweep clockwise
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.hasError != hasError;
  }
}
