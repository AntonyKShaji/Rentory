import 'package:flutter/material.dart';

import 'models/property.dart';
import 'services/api_service.dart';

void main() {
  runApp(const RentoryApp());
}

class RentoryApp extends StatelessWidget {
  const RentoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentory MVP',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const RoleSelectionPage(),
    );
  }
}

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rentory')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Choose your role', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.apartment),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerHomePage()));
                  },
                  label: const Text('I am an Owner'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TenantHomePage()));
                  },
                  label: const Text('I am a Tenant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  final ApiService _apiService = ApiService();
  late Future<List<Property>> _propertiesFuture;
  bool _apiHealthy = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    _propertiesFuture = _apiService.listOwnerProperties('owner-1');
    final healthy = await _apiService.healthCheck().catchError((_) => false);
    if (mounted) {
      setState(() {
        _apiHealthy = healthy;
      });
    }
  }

  Future<void> _addSampleProperty() async {
    await _apiService.createProperty(
      ownerId: 'owner-1',
      location: 'Kaloor',
      name: 'New Property ${DateTime.now().second}',
      unitType: '2BHK',
      capacity: 3,
    );

    if (mounted) {
      setState(() {
        _propertiesFuture = _apiService.listOwnerProperties('owner-1');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          const Icon(Icons.search),
          const SizedBox(width: 12),
          const Icon(Icons.notifications_none),
          const SizedBox(width: 12),
          Icon(_apiHealthy ? Icons.cloud_done : Icons.cloud_off, color: _apiHealthy ? Colors.green : Colors.red),
          const SizedBox(width: 12),
          const Icon(Icons.account_circle_outlined),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSampleProperty,
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Add Property'),
      ),
      body: FutureBuilder<List<Property>>(
        future: _propertiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Backend connection failed. Start API and set --dart-define=API_BASE_URL.\nError: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final properties = snapshot.data ?? [];
          if (properties.isEmpty) {
            return const Center(
              child: Text('No properties found yet. Use "Add Property" to create one from frontend.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Properties from Backend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...properties.map((property) => _PropertyCard(property: property)),
            ],
          );
        },
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(property.unitType.substring(0, 1))),
        title: Text(property.name),
        subtitle: Text('${property.location} • ${property.unitType} • Occupancy: ${property.occupiedCount}/${property.capacity}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _BillStatusDot(color: Colors.green, label: 'Rent'),
            _BillStatusDot(color: Colors.red, label: 'E-Bill'),
            _BillStatusDot(color: Colors.green, label: 'Water'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PropertyDetailPage(propertyName: property.name)),
          );
        },
      ),
    );
  }
}

class _BillStatusDot extends StatelessWidget {
  const _BillStatusDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(message: label, child: Icon(Icons.circle, color: color, size: 12)),
    );
  }
}

class PropertyDetailPage extends StatelessWidget {
  const PropertyDetailPage({super.key, required this.propertyName});

  final String propertyName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(propertyName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Tenant details and bills will be loaded from /properties/{id} in next iteration.'),
        ],
      ),
    );
  }
}

class TenantHomePage extends StatelessWidget {
  const TenantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant Dashboard'),
        actions: const [
          Icon(Icons.qr_code_scanner),
          SizedBox(width: 16),
          Icon(Icons.notifications_none),
          SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.home_work),
              title: const Text('Assigned Property: via owner approval'),
              subtitle: const Text('QR onboarding supported by backend endpoint'),
              trailing: FilledButton(onPressed: () {}, child: const Text('Pay Rent')),
            ),
          ),
        ],
      ),
    );
  }
}
