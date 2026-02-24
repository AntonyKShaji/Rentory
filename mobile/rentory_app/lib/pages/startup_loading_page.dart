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
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_outlined, color: Colors.white, size: 78),
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
                    const SizedBox(height: 52),
                    _ProgressBar(activeSegment: _activeSegment),
                  ],
                ),
              ),
              const Positioned(
                bottom: 90,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Loading...',
                    style: TextStyle(
                      color: Color(0xFFDCECEF),
                      fontSize: 29,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 40,
                right: 28,
                child: Icon(Icons.auto_awesome, size: 44, color: Color(0xFFDCECEF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
