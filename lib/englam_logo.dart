import 'package:flutter/material.dart';

class EngLamLogo extends StatelessWidget {
  const EngLamLogo({
    super.key,
    this.size = 44,
    this.backgroundColor,
    this.iconColor,
  });

  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EngLamLogoPainter(
          backgroundColor: backgroundColor ?? scheme.surfaceContainerHighest,
          iconColor: iconColor ?? scheme.primary,
        ),
      ),
    );
  }
}

class _EngLamLogoPainter extends CustomPainter {
  _EngLamLogoPainter({required this.backgroundColor, required this.iconColor});

  final Color backgroundColor;
  final Color iconColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.shortestSide * 0.28));
    final bg = Paint()..color = backgroundColor;
    canvas.drawRRect(r, bg);

    final iconPaint = Paint()
      ..color = iconColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final pad = size.shortestSide * 0.22;

    final bubble = Path()
      ..moveTo(pad * 1.2, h * 0.62)
      ..quadraticBezierTo(pad * 1.2, h * 0.36, w * 0.46, h * 0.34)
      ..quadraticBezierTo(w * 0.74, h * 0.34, w * 0.78, h * 0.56)
      ..quadraticBezierTo(w * 0.80, h * 0.76, w * 0.58, h * 0.78)
      ..lineTo(w * 0.42, h * 0.78)
      ..lineTo(w * 0.34, h * 0.86)
      ..lineTo(w * 0.34, h * 0.78)
      ..quadraticBezierTo(pad * 1.2, h * 0.78, pad * 1.2, h * 0.62)
      ..close();

    canvas.drawPath(bubble, iconPaint);

    final fill = Paint()..color = iconColor;
    final eLeft = w * 0.46;
    final eTop = h * 0.46;
    final eW = w * 0.22;
    final eH = h * 0.26;
    final bar = eH * 0.18;
    final gap = eH * 0.12;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(eLeft, eTop, bar, eH), Radius.circular(bar * 0.6)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(eLeft, eTop, eW, bar), Radius.circular(bar * 0.6)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(eLeft, eTop + bar + gap, eW * 0.86, bar), Radius.circular(bar * 0.6)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(eLeft, eTop + (bar + gap) * 2, eW, bar), Radius.circular(bar * 0.6)),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
