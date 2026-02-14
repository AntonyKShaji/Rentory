import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models/property.dart';
import 'services/api_service.dart';
import 'widgets/app_widgets.dart';

void main() {
  runApp(const RentoryApp());
}

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
      home: const RoleLandingPage(),
    );
  }
}

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
  final Map<String, String?> _errors = {};

  bool _validate() {
    final nextErrors = <String, String?>{};
    if (_isSignup && _name.text.trim().isEmpty) {
      nextErrors['name'] = 'Full name is required';
    }
    if (_phone.text.trim().isEmpty) {
      nextErrors['phone'] = 'Phone is required';
    }
    if (_isSignup && _email.text.trim().isEmpty) {
      nextErrors['email'] = 'Email is required';
    }
    if (_password.text.trim().isEmpty) {
      nextErrors['password'] = 'Password is required';
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });
    return nextErrors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      final payload = _isSignup
          ? await _api.ownerSignup(fullName: _name.text, phone: _phone.text, email: _email.text, password: _password.text)
          : await _api.login(identifier: _phone.text, password: _password.text, role: 'owner');
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OwnerDashboardPage(ownerId: payload['user_id'] as String)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
            FieldWithTopError(
              errorText: _errors['name'],
              child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
            ),
            const SizedBox(height: 10),
            FieldWithTopError(
              errorText: _errors['email'],
              child: TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            ),
            const SizedBox(height: 10),
          ],
          FieldWithTopError(
            errorText: _errors['phone'],
            child: TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
          ),
          const SizedBox(height: 10),
          FieldWithTopError(
            errorText: _errors['password'],
            child: TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          ),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _loading ? null : _submit, child: Text(_isSignup ? 'Create account' : 'Login'))),
          TextButton(onPressed: () => setState(() { _isSignup = !_isSignup; _errors.clear(); }), child: Text(_isSignup ? 'Already have an account? Login' : 'New owner? Create account')),
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
  final Map<String, String?> _errors = {};

  bool _validate() {
    final nextErrors = <String, String?>{};
    if (_isRegister && _qr.text.trim().isEmpty) nextErrors['qr'] = 'Property QR code is required';
    if (_isRegister && _name.text.trim().isEmpty) nextErrors['name'] = 'Full name is required';
    if (_isRegister && _age.text.trim().isEmpty) {
      nextErrors['age'] = 'Age is required';
    } else if (_isRegister && (int.tryParse(_age.text.trim()) ?? 0) <= 0) {
      nextErrors['age'] = 'Age must be a valid number';
    }
    if (_isRegister && _documents.text.trim().isEmpty) nextErrors['documents'] = 'Documents are required';
    if (_isRegister && _email.text.trim().isEmpty) nextErrors['email'] = 'Email is required';
    if (_identifier.text.trim().isEmpty) nextErrors['phone'] = 'Phone is required';
    if (_password.text.trim().isEmpty) nextErrors['password'] = 'Password is required';
    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });
    return nextErrors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TenantDashboardPage(tenantId: payload['user_id'] as String)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
              FieldWithTopError(
                errorText: _errors['qr'],
                child: TextField(controller: _qr, decoration: const InputDecoration(labelText: 'Property QR Code')),
              ),
              const SizedBox(height: 10),
              FieldWithTopError(
                errorText: _errors['name'],
                child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
              ),
              const SizedBox(height: 10),
              FieldWithTopError(
                errorText: _errors['age'],
                child: TextField(controller: _age, decoration: const InputDecoration(labelText: 'Age')),
              ),
              const SizedBox(height: 10),
              FieldWithTopError(
                errorText: _errors['documents'],
                child: TextField(controller: _documents, decoration: const InputDecoration(labelText: 'Documents')),
              ),
              const SizedBox(height: 10),
              FieldWithTopError(
                errorText: _errors['email'],
                child: TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              ),
              const SizedBox(height: 10),
            ],
            FieldWithTopError(
              errorText: _errors['phone'],
              child: TextField(controller: _identifier, decoration: const InputDecoration(labelText: 'Phone')),
            ),
            const SizedBox(height: 10),
            FieldWithTopError(
              errorText: _errors['password'],
              child: TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _loading ? null : _submit, child: Text(_isRegister ? 'Register' : 'Login'))),
            TextButton(onPressed: () => setState(() { _isRegister = !_isRegister; _errors.clear(); }), child: Text(_isRegister ? 'Already registered? Login' : 'New tenant? Register with QR')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyPage(ownerId: widget.ownerId)));
          _reload();
        },
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
                return SurfaceCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Portfolio Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      _metricChip('Properties', '${analytics?['total_properties'] ?? '-'}'),
                      _metricChip('Tenants', '${analytics?['total_tenants'] ?? '-'}'),
                      _metricChip('By Place', '${analytics?['grouped_by_place'] ?? '{}'}'),
                    ]),
                  ]),
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Property>>(
              future: _properties,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator()));
                final properties = snapshot.data!;
                if (properties.isEmpty) {
                  return SurfaceCard(
                    child: Column(children: [
                      const Icon(Icons.home_work_outlined, size: 44),
                      const SizedBox(height: 8),
                      const Text('No properties yet'),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyPage(ownerId: widget.ownerId))), child: const Text('Add your first property')),
                    ]),
                  );
                }
                return Column(
                  children: properties
                      .map((property) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SurfaceCard(
                              padding: EdgeInsets.zero,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsPage(property: property, ownerId: widget.ownerId))),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  RemoteOrDataImage(imageRef: property.imageUrl, height: 170, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                                  ListTile(
                                    title: Text(property.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text('${property.location} • ${property.occupiedCount}/${property.capacity} tenants'),
                                    trailing: Text('₹${property.rent.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ]),
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFF0F6F7), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]),
      );
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
  final _description = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _imageDataUri;
  final Map<String, String?> _errors = {};

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.path.toLowerCase().endsWith('png') ? 'png' : 'jpeg';
    setState(() => _imageDataUri = 'data:image/$ext;base64,${base64Encode(bytes)}');
  }

  bool _validate() {
    final nextErrors = <String, String?>{};
    if (_imageDataUri == null) nextErrors['image'] = 'Property image is required';
    if (_name.text.trim().isEmpty) nextErrors['name'] = 'Property name is required';
    if (_location.text.trim().isEmpty) nextErrors['location'] = 'Place is required';
    if (_unitType.text.trim().isEmpty) nextErrors['unit'] = 'Unit type is required';
    if ((int.tryParse(_capacity.text.trim()) ?? 0) <= 0) nextErrors['capacity'] = 'Capacity must be greater than 0';
    if ((double.tryParse(_rent.text.trim()) ?? 0) <= 0) nextErrors['rent'] = 'Rent must be greater than 0';
    if (_description.text.trim().isEmpty) nextErrors['description'] = 'Description is required';
    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });
    return nextErrors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    try {
      await _api.createProperty(
        ownerId: widget.ownerId,
        location: _location.text,
        name: _name.text,
        unitType: _unitType.text,
        capacity: int.tryParse(_capacity.text) ?? 1,
        rent: double.tryParse(_rent.text) ?? 0,
        imageUrl: _imageDataUri!,
        description: _description.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SurfaceCard(
            child: Column(
              children: [
                RemoteOrDataImage(imageRef: _imageDataUri, height: 190),
                const SizedBox(height: 10),
                FieldWithTopError(
                  errorText: _errors['image'],
                  child: OutlinedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.upload), label: const Text('Upload image')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FieldWithTopError(
            errorText: _errors['name'],
            child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'Property name')),
          ),
          const SizedBox(height: 10),
          FieldWithTopError(
            errorText: _errors['location'],
            child: TextField(controller: _location, decoration: const InputDecoration(labelText: 'Place')),
          ),
          const SizedBox(height: 10),
          FieldWithTopError(
            errorText: _errors['unit'],
            child: TextField(controller: _unitType, decoration: const InputDecoration(labelText: 'Unit type')),
          ),
          const SizedBox(height: 10),
          FieldWithTopError(
            errorText: _errors['capacity'],
            child: TextField(controller: _capacity, decoration: const InputDecoration(labelText: 'No. of tenants allowed')),
          ),
          const SizedBox(height: 10),
          FieldWithTopError(
            errorText: _errors['rent'],
            child: TextField(controller: _rent, decoration: const InputDecoration(labelText: 'Rent')),
          ),
          const SizedBox(height: 10),
          FieldWithTopError(
            errorText: _errors['description'],
            child: TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description')),
          ),
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(propertyId: widget.property.id, propertyName: widget.property.name, senderId: widget.ownerId))),
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
              RemoteOrDataImage(imageRef: data['property']['image_url'] as String?),
              const SizedBox(height: 12),
              SurfaceCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('QR: ${data['property']['qr_code']}'),
                  const SizedBox(height: 8),
                  RemoteOrDataImage(imageRef: data['property']['qr_code_url'] as String, height: 130, width: 130),
                  const SizedBox(height: 8),
                  Text('Chat group: ${data['chat_group_name']}'),
                  Text('Current bill: ₹${data['current_bill_amount']}'),
                  Row(children: [Text('Water bill: ${data['water_bill_status']}'), TextButton(onPressed: () => _toggleWaterBill(data['water_bill_status'] as String), child: const Text('Toggle'))]),
                ]),
              ),
              const SizedBox(height: 12),
              const Text('Tenants', style: TextStyle(fontWeight: FontWeight.w700)),
              ...tenants.map((tenant) => Card(
                    child: ListTile(
                      title: Text(tenant['full_name'] as String),
                      subtitle: Text(tenant['phone'] as String),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TenantDetailsPage(tenantId: tenant['tenant_id'] as String))),
                    ),
                  )),
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
              SurfaceCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Name: ${tenant['full_name']}'),
                  Text('Age: ${tenant['age']}'),
                  Text('Phone: ${tenant['phone']}'),
                  Text('Email: ${tenant['email']}'),
                  Text('Documents: ${tenant['documents']}'),
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
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  Timer? _poller;
  bool _loading = true;
  String? _pendingImage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _message.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final rows = await _api.getChatMessages(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _messages = rows;
        _loading = false;
      });
      _jumpToBottom();
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _pickChatImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.path.toLowerCase().endsWith('png') ? 'png' : 'jpeg';
    setState(() => _pendingImage = 'data:image/$ext;base64,${base64Encode(bytes)}');
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    final local = {
      'sender_id': widget.senderId,
      'sender_name': 'You',
      'text': text.isEmpty ? null : text,
      'image_url': _pendingImage,
    };
    setState(() {
      _messages = [..._messages, local];
      _message.clear();
      _pendingImage = null;
    });
    _jumpToBottom();

    try {
      await _api.sendChatMessage(propertyId: widget.propertyId, senderId: widget.senderId, text: local['text'] as String?, imageUrl: local['image_url'] as String?);
      _loadMessages(silent: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.propertyName), centerTitle: false),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE8F1F3), Color(0xFFF4F7F8)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final row = _messages[index];
                        final mine = row['sender_id'] == widget.senderId;
                        return ChatBubble(
                          isMine: mine,
                          sender: (row['sender_name'] as String?) ?? 'User',
                          text: row['text'] as String?,
                          imageUrl: row['image_url'] as String?,
                        );
                      },
                    ),
            ),
            if (_pendingImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Stack(
                  children: [
                    RemoteOrDataImage(imageRef: _pendingImage, height: 90, width: 90),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () => setState(() => _pendingImage = null),
                        child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Row(
                  children: [
                    IconButton(onPressed: _pickChatImage, icon: const Icon(Icons.attach_file_rounded)),
                    Expanded(child: TextField(controller: _message, decoration: const InputDecoration(hintText: 'Type a message...'))),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _send, style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(14)), child: const Icon(Icons.send)),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          child: Padding(padding: const EdgeInsets.all(16), child: SurfaceCard(child: child)),
        ),
      ),
    );
  }
}
