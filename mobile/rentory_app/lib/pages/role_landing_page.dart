import 'package:flutter/material.dart';

import '../widgets/app_widgets.dart';
import 'auth_pages.dart';

class RoleLandingPage extends StatelessWidget {
  const RoleLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F747B), Color(0xFF5F9EA0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SurfaceCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_work_rounded, size: 66, color: Color(0xFF15666C)),
                    const SizedBox(height: 8),
                    Text('Rentory', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Owner Portal'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerAuthPage())),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.apartment_rounded),
                        label: const Text('Tenant Portal'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TenantAuthPage())),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
