// lib/presentation/widgets/striped_media.dart
import 'package:flutter/material.dart';

class StripedMedia extends StatelessWidget {
  const StripedMedia({
    super.key,
    required this.label,
    this.radius = 14,
    this.child,
    this.imageUrl, // <-- Here is the missing parameter!
  });

  final String label;
  final double radius;
  final Widget? child;
  final String? imageUrl; // <-- And here it is defined!

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(color: const Color(0xFF1D1D1D)),
          image: hasImage
              ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black26), // Darkens image so white text stays readable
                  if (child != null) child!,
                ],
              )
            : CustomPaint(
                painter: _StripePainter(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (label.isNotEmpty)
                      Positioned(
                        left: 10, top: 9,
                        child: Text(label, style: const TextStyle(color: Color(0xFF5A5A5A), fontSize: 9, fontWeight: FontWeight.w700)),
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
        ..moveTo(x, 0)..lineTo(x + 12, 0)..lineTo(x + size.height + 12, size.height)..lineTo(x + size.height, size.height)..close();
      canvas.drawPath(path, light);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}