import 'dart:typed_data';

import 'package:flutter/material.dart';

class GoalCover extends StatelessWidget {
  const GoalCover({super.key, this.image, this.height = 88});
  final Uint8List? image;
  final double height;
  @override
  Widget build(BuildContext context) {
    final fallback = CustomPaint(
      painter: _CoverPainter(Theme.of(context).colorScheme),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: image == null
            ? fallback
            : Image.memory(
                image!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
                gaplessPlayback: true,
                excludeFromSemantics: true,
              ),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  const _CoverPainter(this.colors);
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colors.primaryContainer,
    );
    canvas.drawCircle(
      Offset(size.width * .77, 20),
      30,
      Paint()..color = colors.primary.withValues(alpha: .12),
    );
    final hills = Path()
      ..moveTo(0, size.height * .8)
      ..quadraticBezierTo(
        size.width * .25,
        5,
        size.width * .5,
        size.height * .7,
      )
      ..quadraticBezierTo(size.width * .8, size.height * 1.1, size.width, 25)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      hills,
      Paint()..color = colors.primary.withValues(alpha: .16),
    );
  }

  @override
  bool shouldRepaint(_CoverPainter oldDelegate) => oldDelegate.colors != colors;
}
