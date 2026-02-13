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
    const brand = Color(0xFF0C5A5F);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rentory',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: brand),
        scaffoldBackgroundColor: const Color(0xFFF4F8F8),
      ),
      home: const RoleLandingPage(),
    );
  }
}

class RoleLandingPage extends StatelessWidget {
  const RoleLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_work_rounded, size: 84, color: Color(0xFF0C5A5F)),
                  const SizedBox(height: 16),
                  Text('rentory', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: const Color(0xFF0C5A5F))),
                  const SizedBox(height: 32),
                  const Text('Choose your portal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Owner Portal'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OwnerAuthPage()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Tenant Portal'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TenantAuthPage()),
                      ),
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
}

class OwnerAuthPage extends StatefulWidget {
  const OwnerAuthPage({super.key});

  @override
  State<OwnerAuthPage> createState() => _OwnerAuthPageState();
}

class _OwnerAuthPageState extends State<OwnerAuthPage> {
  final ApiService _api = ApiService();
  final _phone = TextEditingController();
  final _name = TextEditingController(text: 'Owner');
  final _email = TextEditingController(text: 'owner@rentory.local');
  final _password = TextEditingController(text: '1234');
  bool _isSignup = false;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final payload = _isSignup
          ? await _api.ownerSignup(
              fullName: _name.text,
              phone: _phone.text,
              email: _email.text,
              password: _password.text,
            )
          : await _api.login(identifier: _phone.text, password: _password.text, role: 'owner');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerDashboardPage(ownerId: payload['user_id'] as String),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      title: _isSignup ? 'Create Owner Account' : 'Owner Login',
      child: Column(
        children: [
          if (_isSignup) ...[
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
          ],
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Please wait...' : (_isSignup ? 'Create account' : 'Login')),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _isSignup = !_isSignup),
            child: Text(_isSignup ? 'Already have an account? Login' : 'New owner? Create account'),
          ),
        ],
      ),
    );
  }
}

class TenantAuthPage extends StatefulWidget {
  const TenantAuthPage({super.key});

  @override
  State<TenantAuthPage> createState() => _TenantAuthPageState();
}

class _TenantAuthPageState extends State<TenantAuthPage> {
  final ApiService _api = ApiService();
  final _identifier = TextEditingController();
  final _password = TextEditingController(text: '1234');
  bool _isRegister = true;
  bool _loading = false;

  final _qr = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _documents = TextEditingController();
  final _email = TextEditingController();

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final payload = _isRegister
          ? await _api.tenantRegister(
              qrCode: _qr.text,
              fullName: _name.text,
              age: int.tryParse(_age.text) ?? 0,
              phone: _identifier.text,
              email: _email.text,
              documents: _documents.text,
              password: _password.text,
            )
          : await _api.login(identifier: _identifier.text, password: _password.text, role: 'tenant');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TenantDashboardPage(tenantId: payload['user_id'] as String)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      title: _isRegister ? 'Tenant Registration via QR' : 'Tenant Login',
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (_isRegister) ...[
              TextField(controller: _qr, decoration: const InputDecoration(labelText: 'Property QR Code')),
              const SizedBox(height: 12),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextField(controller: _age, decoration: const InputDecoration(labelText: 'Age')),
              const SizedBox(height: 12),
              TextField(controller: _documents, decoration: const InputDecoration(labelText: 'Document reference/url')),
              const SizedBox(height: 12),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
            ],
            TextField(controller: _identifier, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _loading ? null : _submit, child: Text(_isRegister ? 'Register' : 'Login')),
            ),
            TextButton(
              onPressed: () => setState(() => _isRegister = !_isRegister),
              child: Text(_isRegister ? 'Already registered? Login' : 'New tenant? Register with QR'),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key, required this.ownerId});
  final String ownerId;

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  final ApiService _api = ApiService();
  late Future<List<Property>> _properties;
  late Future<Map<String, dynamic>> _analytics;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _properties = _api.listOwnerProperties(widget.ownerId);
    _analytics = _api.ownerAnalytics(widget.ownerId);
    setState(() {});
  }

  Future<void> _openAddProperty() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyPage(ownerId: widget.ownerId)));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProperty,
        icon: const Icon(Icons.add),
        label: const Text('Add Property'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _analytics,
              builder: (context, snapshot) {
                final analytics = snapshot.data;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Portfolio Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Total properties: ${analytics?['total_properties'] ?? '-'}'),
                        Text('Total tenants: ${analytics?['total_tenants'] ?? '-'}'),
                        const SizedBox(height: 8),
                        Text('Grouped by place: ${analytics?['grouped_by_place'] ?? '{}'}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Property>>(
              future: _properties,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }
                final properties = snapshot.data ?? [];
                if (properties.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.home_work_outlined, size: 44),
                          const SizedBox(height: 8),
                          const Text('No properties yet'),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _openAddProperty, child: const Text('Add your first property')),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: properties
                      .map(
                        (property) => Card(
                          clipBehavior: Clip.antiAlias,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PropertyDetailsPage(property: property, ownerId: widget.ownerId)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 140,
                                  width: double.infinity,
                                  color: const Color(0xFFCADCDD),
                                  child: property.imageUrl?.isNotEmpty == true
                                      ? Image.network(property.imageUrl!, fit: BoxFit.cover)
                                      : const Icon(Icons.image_outlined, size: 40),
                                ),
                                ListTile(
                                  title: Text(property.name),
                                  subtitle: Text('${property.location} • ${property.occupiedCount}/${property.capacity} tenants'),
                                  trailing: Text('₹${property.rent.toStringAsFixed(0)}'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key, required this.ownerId});
  final String ownerId;

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final ApiService _api = ApiService();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _unitType = TextEditingController(text: '2BHK');
  final _capacity = TextEditingController(text: '2');
  final _rent = TextEditingController(text: '15000');
  final _imageUrl = TextEditingController();
  final _description = TextEditingController();

  Future<void> _submit() async {
    try {
      await _api.createProperty(
        ownerId: widget.ownerId,
        location: _location.text,
        name: _name.text,
        unitType: _unitType.text,
        capacity: int.tryParse(_capacity.text) ?? 1,
        rent: double.tryParse(_rent.text) ?? 0,
        imageUrl: _imageUrl.text,
        description: _description.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Property name')),
          TextField(controller: _location, decoration: const InputDecoration(labelText: 'Place')),
          TextField(controller: _unitType, decoration: const InputDecoration(labelText: 'Unit type')),
          TextField(controller: _capacity, decoration: const InputDecoration(labelText: 'No. of tenants allowed')),
          TextField(controller: _rent, decoration: const InputDecoration(labelText: 'Rent')),
          TextField(controller: _imageUrl, decoration: const InputDecoration(labelText: 'Single image URL')),
          TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('Create property')),
        ],
      ),
    );
  }
}

class PropertyDetailsPage extends StatefulWidget {
  const PropertyDetailsPage({super.key, required this.property, required this.ownerId});
  final Property property;
  final String ownerId;

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  final ApiService _api = ApiService();
  late Future<Map<String, dynamic>> _details;

  @override
  void initState() {
    super.initState();
    _details = _api.getPropertyDetails(widget.property.id);
  }

  Future<void> _toggleWaterBill(String currentStatus) async {
    final next = currentStatus == 'paid' ? 'unpaid' : 'paid';
    await _api.updateWaterBillStatus(propertyId: widget.property.id, status: next);
    setState(() => _details = _api.getPropertyDetails(widget.property.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(propertyId: widget.property.id, propertyName: widget.property.name, senderId: widget.ownerId),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _details,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          final tenants = (data['tenants'] as List<dynamic>).cast<Map<String, dynamic>>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('QR Code: ${data['property']['qr_code']}'),
              Text('Current bill: ₹${data['current_bill_amount']}'),
              Row(
                children: [
                  Text('Water bill status: ${data['water_bill_status']}'),
                  TextButton(onPressed: () => _toggleWaterBill(data['water_bill_status'] as String), child: const Text('Toggle')),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Tenants', style: TextStyle(fontWeight: FontWeight.w600)),
              ...tenants.map(
                (tenant) => ListTile(
                  title: Text(tenant['full_name'] as String),
                  subtitle: Text(tenant['phone'] as String),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TenantDetailsPage(tenantId: tenant['tenant_id'] as String)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

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
              Text('Name: ${tenant['full_name']}'),
              Text('Age: ${tenant['age']}'),
              Text('Phone: ${tenant['phone']}'),
              Text('Email: ${tenant['email']}'),
              Text('Documents: ${tenant['documents']}'),
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
              Card(
                child: ListTile(
                  title: Text(property['name'] as String),
                  subtitle: Text('${property['location']} • Rent ₹${data['rent']}'),
                ),
              ),
              const SizedBox(height: 8),
              Text('Owner phone: ${data['owner_phone']}'),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Open property group chat'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(propertyId: property['id'] as String, propertyName: property['name'] as String, senderId: tenantId),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.propertyId, required this.propertyName, required this.senderId});
  final String propertyId;
  final String propertyName;
  final String senderId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _api = ApiService();
  final TextEditingController _message = TextEditingController();
  final TextEditingController _image = TextEditingController();
  late Future<List<Map<String, dynamic>>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _api.getChatMessages(widget.propertyId);
  }

  Future<void> _send() async {
    await _api.sendChatMessage(
      propertyId: widget.propertyId,
      senderId: widget.senderId,
      text: _message.text.isEmpty ? null : _message.text,
      imageUrl: _image.text.isEmpty ? null : _image.text,
    );
    _message.clear();
    _image.clear();
    setState(() => _messages = _api.getChatMessages(widget.propertyId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.propertyName} Group Chat')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messages,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final rows = snapshot.data!;
                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return ListTile(
                      title: Text(row['sender_name'] as String),
                      subtitle: Text((row['text'] as String?) ?? '[image shared]'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(controller: _message, decoration: const InputDecoration(labelText: 'Message')),
                TextField(controller: _image, decoration: const InputDecoration(labelText: 'Image URL (optional)')),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _send, child: const Text('Send'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthShell extends StatelessWidget {
  const _AuthShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}
