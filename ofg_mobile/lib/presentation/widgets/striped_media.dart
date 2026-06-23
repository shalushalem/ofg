// lib/presentation/widgets/striped_media.dart
import 'package:flutter/material.dart';

class StripedMedia extends StatelessWidget {
  const StripedMedia({
    super.key,
    required this.label,
    this.radius = 14,
    this.child,
  });

  final String label;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(color: const Color(0xFF1D1D1D)),
        ),
        child: CustomPaint(
          painter: _StripePainter(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (label.isNotEmpty)
                Positioned(
                  left: 10,
                  top: 9,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF5A5A5A),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0xFF151515);
    final light = Paint()..color = const Color(0xFF1E1E1E);
    canvas.drawRect(Offset.zero & size, dark);
    
    const stripe = 24.0;
    for (double x = -size.height; x < size.width + size.height; x += stripe) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 12, 0)
        ..lineTo(x + size.height + 12, size.height)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, light);
    }
    
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.035), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}