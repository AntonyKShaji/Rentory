import 'package:flutter/material.dart';

class AnimatedWelcomeLogo extends StatefulWidget {
  const AnimatedWelcomeLogo({super.key});

  @override
  State<AnimatedWelcomeLogo> createState() => _AnimatedWelcomeLogoState();
}

class _AnimatedWelcomeLogoState extends State<AnimatedWelcomeLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoEntrance;
  late final Animation<double> _logoFloat;
  late final Animation<double> _textReveal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _logoEntrance = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.35, curve: Curves.easeOutBack));
    _logoFloat = Tween<double>(begin: -5, end: 5).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.35, 1, curve: Curves.easeInOutSine)));
    _textReveal = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.55, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 1.2,
      color: const Color(0xFF15666C),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final entrance = _logoEntrance.value;
        return Column(
          children: [
            Transform.translate(
              offset: Offset(0, (1 - entrance) * 18 + _logoFloat.value),
              child: Transform.scale(
                scale: 0.82 + (entrance * 0.18),
                child: Opacity(
                  opacity: entrance,
                  child: const _RentoryHouseIcon(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Opacity(
              opacity: _textReveal.value,
              child: Transform.translate(
                offset: Offset((1 - _textReveal.value) * -12, 0),
                child: Text('rentory', style: titleStyle),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RentoryHouseIcon extends StatelessWidget {
  const _RentoryHouseIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 74,
      child: CustomPaint(painter: _HouseLinePainter()),
    );
  }
}

class _HouseLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const iconColor = Color(0xFF15666C);
    final stroke = Paint()
      ..color = iconColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roofTop = Offset(size.width / 2, 5);
    final roofLeft = Offset(13, 30);
    final roofRight = Offset(size.width - 13, 30);
    final baseLeft = Offset(13, size.height - 7);
    final baseRight = Offset(size.width - 13, size.height - 7);

    final roof = Path()
      ..moveTo(roofLeft.dx, roofLeft.dy)
      ..lineTo(roofTop.dx, roofTop.dy)
      ..lineTo(roofRight.dx, roofRight.dy);

    final walls = Path()
      ..moveTo(roofLeft.dx, roofLeft.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(size.width * 0.38, baseLeft.dy)
      ..lineTo(size.width * 0.38, size.height * 0.62)
      ..lineTo(size.width * 0.62, size.height * 0.62)
      ..lineTo(size.width * 0.62, baseLeft.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..lineTo(baseRight.dx, roofRight.dy);

    final innerRoof = Path()
      ..moveTo(size.width * 0.4, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.6, size.height * 0.3);

    canvas.drawPath(roof, stroke);
    canvas.drawPath(walls, stroke);
    canvas.drawPath(innerRoof, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
