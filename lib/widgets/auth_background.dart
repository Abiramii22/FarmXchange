import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFBFFF7),
            Color(0xFFEAF7E7),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _FarmBrandPainter(),
        child: child,
      ),
    );
  }
}

class _FarmBrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lightGreen = Paint()..color = const Color(0xFFDDF1D8);
    final midGreen = Paint()..color = const Color(0xFFBFE6B7);
    final deepGreen = Paint()..color = const Color(0xFF0B5A21).withOpacity(0.08);
    final orange = Paint()
      ..color = const Color(0xFFF59A00).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final h = size.height;
    final w = size.width;

    final fieldOne = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.28, h * 0.66, w * 0.55, h * 0.75)
      ..quadraticBezierTo(w * 0.78, h * 0.83, w, h * 0.76)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fieldTwo = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.35, h * 0.73, w * 0.7, h * 0.84)
      ..quadraticBezierTo(w * 0.85, h * 0.9, w, h * 0.86)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fieldThree = Path()
      ..moveTo(0, h * 0.92)
      ..quadraticBezierTo(w * 0.45, h * 0.84, w, h * 0.94)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(fieldOne, lightGreen);
    canvas.drawPath(fieldTwo, midGreen);
    canvas.drawPath(fieldThree, deepGreen);
    canvas.drawArc(
      Rect.fromLTWH(w * 0.64, h * 0.08, w * 0.5, w * 0.5),
      2.7,
      1.35,
      false,
      orange,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
