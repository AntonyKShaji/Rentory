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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A6A72), Color(0xFF114E55)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 6),
                    const _RentoryLogoIcon(size: 92),
                    const SizedBox(height: 12),
                    const Text(
                      'rentory',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(flex: 4),
                    _ProgressBar(activeSegment: _activeSegment),
                    const SizedBox(height: 72),
                  ],
                ),
              ),
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
