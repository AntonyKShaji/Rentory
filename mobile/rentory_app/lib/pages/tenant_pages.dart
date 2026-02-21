import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/app_widgets.dart';
import 'chat_page.dart';

class TenantDetailsPage extends StatelessWidget {
  const TenantDetailsPage({super.key, required this.tenantId});
  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    return Scaffold(
      appBar: AppBar(title: const Text('Tenant Details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: api.getTenantDetails(tenantId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final tenant = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SurfaceCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Name: ${tenant['full_name']}'),
                  Text('Age: ${tenant['age']}'),
                  Text('Phone: ${tenant['phone']}'),
                  Text('Email: ${tenant['email']}'),
                  const SizedBox(height: 10),
                  const Text('Aadhar', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  RemoteOrDataImage(imageRef: tenant['documents'] as String?, height: 220),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TenantDashboardPage extends StatelessWidget {
  const TenantDashboardPage({super.key, required this.tenantId});
  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    return Scaffold(
      appBar: AppBar(title: const Text('Tenant Dashboard')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: api.getTenantDashboard(tenantId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          final property = data['property'] as Map<String, dynamic>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SurfaceCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(property['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${property['location']} • Rent ₹${data['rent']}'),
                ),
              ),
              const SizedBox(height: 8),
              Text('Owner phone: ${data['owner_phone']}'),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Open property group chat'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(propertyId: property['id'] as String, propertyName: property['name'] as String, senderId: tenantId))),
              ),
            ],
          );
        },
      ),
    );
  }
}
