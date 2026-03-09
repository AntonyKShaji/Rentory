import 'package:flutter/material.dart';

import '../pages/onboarding_welcome_page.dart';

class RentoryApp extends StatelessWidget {
  const RentoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF15666C);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rentory',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: brand),
        scaffoldBackgroundColor: const Color(0xFFF3F6F9),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Color(0xFF3F5961), fontWeight: FontWeight.w600),
          hintStyle: const TextStyle(color: Color(0xFF6F848A)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFAAC0C5), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFAAC0C5), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: brand, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.4),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      home: const OnboardingWelcomePage(),
    );
  }
}
