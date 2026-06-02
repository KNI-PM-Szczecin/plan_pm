import 'package:flutter/material.dart';

class DiagonalStripesPainter extends CustomPainter {
  final Color color;
  final double stripeWidth;
  final double spacing;

  DiagonalStripesPainter({
    required this.color,
    this.stripeWidth = 2.0,
    this.spacing = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;

    // Rysowanie ukośnych linii przez cały obszar widgetu
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}