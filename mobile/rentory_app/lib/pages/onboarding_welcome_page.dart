import 'package:flutter/material.dart';

import 'role_landing_page.dart';

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  static const _brandColor = Color(0xFF204C4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(42),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCMG3aDFORJ9WQ2xlHun_mr2_I5Fm_UI1-NuAxHPhbos6EmpnCb2yElssVuds9CcwpiUQ5oo_CHEBUnQaUMjxbOSJ7Fx8JUW3VKLuSE3TzXfYeRWuZfi6q50c96N6AGsIDAIhizl-prhRwtmtI2eiJXsKTmyUlWiUxkYXaVO0LmkC7XF3NLUvB3C3-l2NL_1VwVTC6XGRgaKb7Wzxo3xuysPqTEdl3N9dbRSurPmtN5sCsvh3qw6WSlenWC7d-e3Li7ZDe2r8Uk9gSk',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Turn Your Property\nInto Opportunity',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF0F1734),
                            fontSize: 54 / 2,
                            fontWeight: FontWeight.w800,
                            height: 1.28,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            "Every home has a story. Let’s tell\nyours and turn it into real value.\nWe're here to help you sell with\nconfidence.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 21 / 2,
                              fontWeight: FontWeight.w500,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _brandColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _dot(),
                            const SizedBox(width: 10),
                            _dot(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(92 / 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        elevation: 10,
                        shadowColor: _brandColor.withOpacity(0.35),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const RoleLandingPage()),
                        );
                      },
                      icon: const Text('Get Started'),
                      label: const Icon(Icons.arrow_forward_rounded, size: 24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 120,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _dot() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFD0D7E2),
        shape: BoxShape.circle,
      ),
    );
  }
}
