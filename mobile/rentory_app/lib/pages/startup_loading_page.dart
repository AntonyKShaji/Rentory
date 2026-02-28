import 'dart:async';
import 'package:flutter/material.dart';

import 'role_landing_page.dart';

class StartupLoadingPage extends StatefulWidget {
  const StartupLoadingPage({super.key});

  @override
  State<StartupLoadingPage> createState() => _StartupLoadingPageState();
}

class _StartupLoadingPageState extends State<StartupLoadingPage> {
  static const _segmentCount = 10;
  static const _loadDuration = Duration(seconds: 3);
  static const _tickDuration = Duration(milliseconds: 250);

  late final Timer _tickTimer;
  late final Timer _navigateTimer;
  int _activeSegment = 0;

  @override
  void initState() {
    super.initState();

    _tickTimer = Timer.periodic(_tickDuration, (_) {
      if (!mounted) return;
      setState(() {
        _activeSegment = (_activeSegment + 1) % _segmentCount;
      });
    });

    _navigateTimer = Timer(_loadDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleLandingPage()),
      );
    });
  }

  @override
  void dispose() {
    _tickTimer.cancel();
    _navigateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15666C),
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              const Spacer(flex: 9),
              const _RentoryLogoIcon(size: 78),
              const SizedBox(height: 14),
              const Text(
                'rentory',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.8,
                  height: 1,
                ),
              ),
              const Spacer(flex: 11),
              _ProgressBar(activeSegment: _activeSegment),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _RentoryLogoIcon extends StatelessWidget {
  const _RentoryLogoIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RentoryLogoPainter(),
    );
  }
}

class _RentoryLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.052
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;

    final outerPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.2, size.height * 0.46)
      ..lineTo(size.width * 0.26, size.height * 0.46)
      ..lineTo(size.width * 0.26, size.height * 0.78)
      ..lineTo(size.width * 0.43, size.height * 0.78)
      ..lineTo(size.width * 0.43, size.height * 0.59)
      ..lineTo(size.width * 0.57, size.height * 0.59)
      ..lineTo(size.width * 0.57, size.height * 0.78)
      ..lineTo(size.width * 0.74, size.height * 0.78)
      ..lineTo(size.width * 0.74, size.height * 0.46)
      ..lineTo(size.width * 0.8, size.height * 0.46)
      ..close();

    final accentPath = Path()
      ..moveTo(size.width * 0.43, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.33)
      ..lineTo(size.width * 0.57, size.height * 0.4);

    canvas.drawPath(outerPath, strokePaint);
    canvas.drawPath(accentPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.activeSegment});

  final int activeSegment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (index) {
          final isActive = index == activeSegment;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 70 : 10,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }
}
