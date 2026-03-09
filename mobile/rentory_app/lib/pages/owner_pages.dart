import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/property.dart';
import '../services/api_service.dart';
import '../widgets/app_widgets.dart';
import 'chat_page.dart';
import 'tenant_pages.dart';

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
  int _selectedTab = 0;

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
                final previewProperties = properties.take(4).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AllPropertiesPage(ownerId: widget.ownerId, properties: properties),
                            ),
                          ),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: previewProperties
                            .map((property) => Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    width: 240,
                                    child: _propertyCard(property),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerHistoryPage(ownerId: widget.ownerId)));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerChatGroupsPage(ownerId: widget.ownerId)));
          } else if (index == 3) {
            _showMenuSheet();
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }

  Widget _propertyCard(Property property) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsPage(property: property, ownerId: widget.ownerId))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RemoteOrDataImage(imageRef: property.imageUrl, height: 140, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          ListTile(
            title: Text(property.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${property.location} • ${property.occupiedCount}/${property.capacity} tenants • ${property.unreadNotifications} alerts'),
            trailing: Text('₹${property.rent.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  void _showMenuSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.add_home_work_outlined),
              title: const Text('Add Property'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyPage(ownerId: widget.ownerId)));
                _reload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('Chat Groups'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerChatGroupsPage(ownerId: widget.ownerId)));
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

class AllPropertiesPage extends StatefulWidget {
  const AllPropertiesPage({super.key, required this.ownerId, required this.properties});

  final String ownerId;
  final List<Property> properties;

  @override
  State<AllPropertiesPage> createState() => _AllPropertiesPageState();
}

class _AllPropertiesPageState extends State<AllPropertiesPage> {
  final ApiService _api = ApiService();
  late Future<List<Property>> _properties;

  @override
  void initState() {
    super.initState();
    _properties = _api.listOwnerProperties(widget.ownerId);
  }

  Future<void> _reload() async {
    setState(() => _properties = _api.listOwnerProperties(widget.ownerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home_work_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyPage(ownerId: widget.ownerId)));
              _reload();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Property>>(
          future: _properties,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final properties = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final property = properties[index];
                return SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: RemoteOrDataImage(imageRef: property.imageUrl, width: 64, height: 64),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(property.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                        if (property.unreadNotifications > 0)
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text('${property.unreadNotifications}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                      ],
                    ),
                    subtitle: Text('${property.location} • ${property.occupiedCount}/${property.capacity} tenants • ${property.isActive ? 'Active' : 'Inactive'}'),
                    trailing: Text('₹${property.rent.toStringAsFixed(0)}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PropertyDetailsPage(property: property, ownerId: widget.ownerId)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class OwnerHistoryPage extends StatelessWidget {
  const OwnerHistoryPage({super.key, required this.ownerId});
  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(
        child: Text('History section is reserved for payment and activity logs.'),
      ),
    );
  }
}

class OwnerChatGroupsPage extends StatelessWidget {
  const OwnerChatGroupsPage({super.key, required this.ownerId});
  final String ownerId;

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Groups')),
      body: FutureBuilder<List<Property>>(
        future: api.listOwnerProperties(ownerId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return const Center(child: Text('No properties available for chats yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final property = groups[index];
              return SurfaceCard(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.group_outlined)),
                  title: Text(property.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Group chat for ${property.location}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        propertyId: property.id,
                        propertyName: property.name,
                        senderId: ownerId,
                      ),
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: groups.length,
          );
        },
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
  final _description = TextEditingController();
  final _areaSqft = TextEditingController();
  final _parkingDetails = TextEditingController();
  final _preferredResidents = TextEditingController();
  final _advanceAmount = TextEditingController(text: '0');
  final _fullAddress = TextEditingController();
  final _caretakerName = TextEditingController();
  final _caretakerContact = TextEditingController();
  final _propertyReference = TextEditingController();
  bool _isActive = true;
  bool _caretakerEnabled = false;
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
    if (_areaSqft.text.trim().isNotEmpty && (int.tryParse(_areaSqft.text.trim()) ?? 0) <= 0) nextErrors['area'] = 'Area must be greater than 0';
    if ((double.tryParse(_advanceAmount.text.trim()) ?? -1) < 0) nextErrors['advance'] = 'Advance cannot be negative';
    if (_caretakerEnabled && _caretakerName.text.trim().isEmpty) nextErrors['caretaker_name'] = 'Caretaker name is required';
    if (_caretakerEnabled && _caretakerContact.text.trim().isEmpty) nextErrors['caretaker_contact'] = 'Caretaker contact is required';
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
        isActive: _isActive,
        areaSqft: int.tryParse(_areaSqft.text.trim()),
        parkingDetails: _parkingDetails.text.trim().isEmpty ? null : _parkingDetails.text.trim(),
        preferredResidents: _preferredResidents.text.trim().isEmpty ? null : _preferredResidents.text.trim(),
        advanceAmount: double.tryParse(_advanceAmount.text.trim()) ?? 0,
        fullAddress: _fullAddress.text.trim().isEmpty ? null : _fullAddress.text.trim(),
        caretakerEnabled: _caretakerEnabled,
        caretakerName: _caretakerName.text.trim().isEmpty ? null : _caretakerName.text.trim(),
        caretakerContact: _caretakerContact.text.trim().isEmpty ? null : _caretakerContact.text.trim(),
        propertyReference: _propertyReference.text.trim().isEmpty ? null : _propertyReference.text.trim(),
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
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Listing Active'),
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
          ),
          const SizedBox(height: 10),
          FieldWithTopError(
            errorText: _errors['area'],
            child: TextField(controller: _areaSqft, decoration: const InputDecoration(labelText: 'Area (sqft)')),
          ),
          const SizedBox(height: 10),
          TextField(controller: _parkingDetails, decoration: const InputDecoration(labelText: 'Parking details')),
          const SizedBox(height: 10),
          TextField(controller: _preferredResidents, decoration: const InputDecoration(labelText: 'Preferred residents')),
          const SizedBox(height: 10),
          FieldWithTopError(
            errorText: _errors['advance'],
            child: TextField(controller: _advanceAmount, decoration: const InputDecoration(labelText: 'Advance amount')),
          ),
          const SizedBox(height: 10),
          TextField(controller: _fullAddress, decoration: const InputDecoration(labelText: 'Full address')),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable caretaker'),
            value: _caretakerEnabled,
            onChanged: (value) => setState(() => _caretakerEnabled = value),
          ),
          if (_caretakerEnabled) ...[
            FieldWithTopError(
              errorText: _errors['caretaker_name'],
              child: TextField(controller: _caretakerName, decoration: const InputDecoration(labelText: 'Caretaker name')),
            ),
            const SizedBox(height: 10),
            FieldWithTopError(
              errorText: _errors['caretaker_contact'],
              child: TextField(controller: _caretakerContact, decoration: const InputDecoration(labelText: 'Caretaker contact')),
            ),
            const SizedBox(height: 10),
          ],
          TextField(controller: _propertyReference, decoration: const InputDecoration(labelText: 'Property reference')),
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
                  Text('Status: ${((data['property']['is_active'] as bool?) ?? true) ? 'Active' : 'Inactive'}'),
                  Text('Notifications: ${data['property']['unread_notifications'] ?? 0}'),
                  Text('Chat group: ${data['chat_group_name']}'),
                  Text('Current bill: ₹${data['current_bill_amount']}'),
                  Text('Advance amount: ₹${data['advance_amount'] ?? 0}'),
                  if ((data['area_sqft'] as int?) != null) Text('Area: ${data['area_sqft']} sqft'),
                  if ((data['parking_details'] as String?) != null) Text('Parking: ${data['parking_details']}'),
                  if ((data['preferred_residents'] as String?) != null) Text('Residents: ${data['preferred_residents']}'),
                  if ((data['full_address'] as String?) != null) Text('Location: ${data['full_address']}'),
                  Text('Caretaker enabled: ${(data['caretaker_enabled'] as bool?) ?? false ? 'Yes' : 'No'}'),
                  if ((data['caretaker_name'] as String?) != null) Text('Caretaker: ${data['caretaker_name']} (${data['caretaker_contact'] ?? '-'})'),
                  if ((data['property_reference'] as String?) != null) Text('Reference: ${data['property_reference']}'),
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
