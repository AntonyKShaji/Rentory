import 'package:flutter/material.dart';

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
              const Text(
                'Choose your role',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.apartment),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OwnerHomePage()),
                    );
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TenantHomePage()),
                    );
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

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final properties = [
      {'name': 'Kaloor Residency A', 'type': '2BHK', 'occupied': 3, 'capacity': 4},
      {'name': 'Kaloor Residency B', 'type': '3BHK', 'occupied': 2, 'capacity': 3},
      {'name': 'Edappally Homes', 'type': '1BHK', 'occupied': 1, 'capacity': 2},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: const [
          Icon(Icons.search),
          SizedBox(width: 16),
          Icon(Icons.notifications_none),
          SizedBox(width: 16),
          Icon(Icons.account_circle_outlined),
          SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Properties by Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Kaloor (2 properties)'),
          const SizedBox(height: 8),
          ...properties.take(2).map((p) => _PropertyCard(property: p)),
          const SizedBox(height: 12),
          const Text('Edappally (1 property)'),
          const SizedBox(height: 8),
          _PropertyCard(property: properties.last),
          const SizedBox(height: 16),
          const Text('Quick Broadcast', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {},
            child: const Text('Send announcement to all tenants'),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final Map<String, Object> property;

  @override
  Widget build(BuildContext context) {
    final occupied = property['occupied'] as int;
    final capacity = property['capacity'] as int;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(property['type'].toString().substring(0, 1)),
        ),
        title: Text(property['name'].toString()),
        subtitle: Text('${property['type']} • Occupancy: $occupied/$capacity'),
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
            MaterialPageRoute(
              builder: (_) => PropertyDetailPage(propertyName: property['name'].toString()),
            ),
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
      child: Tooltip(
        message: label,
        child: Icon(Icons.circle, color: color, size: 12),
      ),
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
        children: [
          const Text('Tenants', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _tenantTile('Akhil', '+91 90000 11111', 'Broker: Sunil'),
          _tenantTile('Nima', '+91 90000 22222', 'Broker: David'),
          const SizedBox(height: 16),
          const Text('Supervisor', style: TextStyle(fontWeight: FontWeight.bold)),
          const ListTile(
            leading: Icon(Icons.support_agent),
            title: Text('Assigned: Rajeev'),
            subtitle: Text('+91 90000 88888'),
          ),
          const SizedBox(height: 16),
          const Text('Pending Actions', style: TextStyle(fontWeight: FontWeight.bold)),
          const ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('Electricity Bill due'),
            subtitle: Text('Tap to notify tenant or pay now'),
          ),
        ],
      ),
    );
  }

  Widget _tenantTile(String name, String phone, String broker) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text('$phone\n$broker'),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 8,
          children: const [
            Icon(Icons.call),
            Icon(Icons.message),
            Icon(Icons.chat),
          ],
        ),
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
              title: const Text('Assigned Property: Kaloor Residency A'),
              subtitle: const Text('Owner approval: Active'),
              trailing: FilledButton(onPressed: () {}, child: const Text('Pay Rent')),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Current Dues', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const _DueTile(title: 'Rent Bill', status: 'Pending'),
          const _DueTile(title: 'Electricity Bill', status: 'Paid'),
          const _DueTile(title: 'Water Bill', status: 'Pending'),
          const SizedBox(height: 16),
          const Text('Maintenance Request', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'e.g., Water leakage in kitchen',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: () {}, child: const Text('Send request to owner')),
        ],
      ),
    );
  }
}

class _DueTile extends StatelessWidget {
  const _DueTile({required this.title, required this.status});

  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status.toLowerCase() == 'paid';
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Chip(
          label: Text(status),
          backgroundColor: isPaid ? Colors.green.shade100 : Colors.red.shade100,
        ),
      ),
    );
  }
}
