import 'package:flutter/material.dart';

import '../theme.dart';

/// Значок TeachLog: два аркуші зошита й кружечок з галочкою (viewBox 32×32).
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _LogoPainter()),
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32);
    RRect r(double x, double y, double w, double h, double rad) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rad));
    final white = Paint()..color = Colors.white;
    canvas
      ..drawRRect(r(3, 5, 22, 24, 5), Paint()..color = const Color(0xFFC9B8FB))
      ..drawRRect(r(7, 3, 22, 24, 5), Paint()..color = const Color(0xFF3B1F7A))
      ..drawRRect(r(11, 9, 13, 2.6, 1.3), white)
      ..drawRRect(r(11, 14, 10, 2.6, 1.3), white)
      ..drawCircle(const Offset(23, 21), 4.5, Paint()..color = const Color(0xFF9A74F2))
      ..drawPath(
        Path()
          ..moveTo(21, 21)
          ..relativeLineTo(1.4, 1.4)
          ..relativeLineTo(2.6, -2.8),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}

/// Логотип з назвою: «Teach» кольором тексту, «Log» середнім фіолетовим.
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 30, this.inkColor});
  final double size;
  final Color? inkColor;

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMark(size: size),
        SizedBox(width: size * .27),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Teach'),
              TextSpan(
                text: 'Log',
                style: TextStyle(color: tl.md),
              ),
            ],
          ),
          style: TextStyle(fontSize: size * .7, fontWeight: FontWeight.w900, color: inkColor ?? tl.ink),
        ),
      ],
    );
  }
}

/// Смужка-градієнт під шапкою, як у дизайні.
class GradientStripe extends StatelessWidget implements PreferredSizeWidget {
  const GradientStripe({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(4);

  @override
  Widget build(BuildContext context) {
    final tl = context.tl;
    return Container(
      height: 4,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [tl.dk, tl.md, tl.lt])),
    );
  }
}
