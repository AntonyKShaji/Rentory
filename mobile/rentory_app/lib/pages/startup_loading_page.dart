import 'dart:async';
import 'dart:ui';

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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0E3F43),
                  Color(0xFF0A2D30),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                width: 430,
                height: 430,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xCC0F6A3A),
                      Color(0x000F6A3A),
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: const SizedBox.shrink(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 10),
                  const _RentoryLogoIcon(size: 54),
                  const SizedBox(height: 10),
                  const Text(
                    'rentory',
                    style: TextStyle(
                      color: Color(0xFFE7F4F4),
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(flex: 8),
                  _ProgressBar(activeSegment: _activeSegment),
                  const Spacer(flex: 8),
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      color: Color(0xCCDCEAEA),
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
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
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFE7F4F4);

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
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 176,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xE6FFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          ...List.generate(
            10,
            (index) {
              final isActive = index == activeSegment;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xBFF7FFFF)
                      : const Color(0x667C9A9A),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
