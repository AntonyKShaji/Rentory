import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/notification_item.dart';
import '../models/property.dart';
import '../services/api_service.dart';
import '../services/owner_profile_store.dart';
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
    final profile = OwnerProfileStore.getByOwnerId(widget.ownerId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OwnerNotificationsPage(ownerId: widget.ownerId)),
            ),
            icon: const Icon(Icons.notifications_none),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OwnerProfilePage(ownerId: widget.ownerId)),
                );
                if (!context.mounted) return;
                setState(() {});
              },
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF204C4F),
                child: ClipOval(
                  child: RemoteOrDataImage(
                    imageRef: profile.avatarImage,
                    width: 32,
                    height: 32,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
              final profile = OwnerProfileStore.getByOwnerId(ownerId);
              return SurfaceCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0x1A204C4F),
                    child: ClipOval(
                      child: RemoteOrDataImage(
                        imageRef: profile.avatarImage,
                        width: 36,
                        height: 36,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
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

class OwnerProfilePage extends StatefulWidget {
  const OwnerProfilePage({super.key, required this.ownerId});

  final String ownerId;

  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  final ImagePicker _picker = ImagePicker();
  late OwnerProfile _profile;
  bool _twoFactorEnabled = true;

  @override
  void initState() {
    super.initState();
    _profile = OwnerProfileStore.getByOwnerId(widget.ownerId);
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 65, maxWidth: 960, maxHeight: 960);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.path.toLowerCase().endsWith('png') ? 'png' : 'jpeg';
    final dataUri = 'data:image/$ext;base64,${base64Encode(bytes)}';
    final updated = _profile.copyWith(avatarImage: dataUri);
    OwnerProfileStore.update(widget.ownerId, updated);
    setState(() => _profile = updated);
  }

  void _info(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _info('Notifications feature is coming soon.'),
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: RemoteOrDataImage(
                        imageRef: _profile.avatarImage,
                        width: 108,
                        height: 108,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF204C4F)),
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.edit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_profile.fullName, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
              Text(_profile.roleLabel.toUpperCase(), style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  Chip(label: Text(_profile.memberBadge)),
                  Chip(label: Text(_profile.memberSince)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _header('Account Information'),
          SurfaceCard(
            child: Column(
              children: [
                _infoTile(Icons.person, 'Full Name', _profile.fullName),
                const Divider(height: 16),
                _infoTile(Icons.mail, 'Email Address', _profile.email),
                const Divider(height: 16),
                _infoTile(Icons.phone, 'Phone Number', _profile.phone),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _header('Asset Overview'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF16565A), borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                const CircleAvatar(radius: 24, backgroundColor: Color(0x338DB4B7), child: Icon(Icons.domain, color: Colors.white)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL PORTFOLIO', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                      Text('5 Properties', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF204C4F)),
                  onPressed: () => _info('Navigating to all properties...'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _header('Security & Access'),
          SurfaceCard(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.lock, color: Color(0xFF204C4F)), title: const Text('Change Password'), trailing: const Icon(Icons.chevron_right), onTap: () => _info('Change password flow is coming soon.')),
                ListTile(
                  leading: const Icon(Icons.verified_user, color: Color(0xFF204C4F)),
                  title: const Text('Two-Factor Authentication'),
                  trailing: Switch(value: _twoFactorEnabled, onChanged: (value) => setState(() => _twoFactorEnabled = value)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _header('Preferences'),
          SurfaceCard(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.language, color: Color(0xFF204C4F)), title: const Text('App Language'), trailing: const Text('English (US)'), onTap: () => _info('Language settings will be configurable soon.')),
                ListTile(leading: const Icon(Icons.notifications_active, color: Color(0xFF204C4F)), title: const Text('Notification Settings'), trailing: const Icon(Icons.chevron_right), onTap: () => _info('Notification settings will be configurable soon.')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _header('Resources'),
          SurfaceCard(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.help, color: Color(0xFF204C4F)), title: const Text('Help Center'), onTap: () => _info('Help center will be available soon.')),
                ListTile(leading: const Icon(Icons.policy, color: Color(0xFF204C4F)), title: const Text('Privacy Policy'), onTap: () => _info('Privacy policy page will be available soon.')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.red),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),
          const Center(child: Text('RENTORY PREMIUM V2.4.1', style: TextStyle(letterSpacing: 3, color: Colors.blueGrey, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _header(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF5B6F92), fontWeight: FontWeight.w800, letterSpacing: 1.2)),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: const Color(0xFFE4ECED), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF204C4F)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF94A2BA))),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ],
          ),
        ),
      ],
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
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OwnerNotificationsPage(ownerId: widget.ownerId, propertyId: widget.property.id, propertyName: widget.property.name),
              ),
            ),
          ),
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
                  Text(widget.property.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(data['full_address'] as String? ?? widget.property.location, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text('Status: ${((data['property']['is_active'] as bool?) ?? true) ? 'Active' : 'Inactive'}'),
                  Text('Current bill: ₹${data['current_bill_amount']}'),
                  Text('Advance amount: ₹${data['advance_amount'] ?? 0}'),
                  if ((data['area_sqft'] as int?) != null) Text('Area: ${data['area_sqft']} sqft'),
                  if ((data['parking_details'] as String?) != null) Text('Parking: ${data['parking_details']}'),
                  if ((data['preferred_residents'] as String?) != null) Text('Residents: ${data['preferred_residents']}'),
                  Text('Caretaker enabled: ${(data['caretaker_enabled'] as bool?) ?? false ? 'Yes' : 'No'}'),
                  if ((data['caretaker_name'] as String?) != null) Text('Caretaker: ${data['caretaker_name']} (${data['caretaker_contact'] ?? '-'})'),
                  if ((data['property_reference'] as String?) != null) Text('Reference: ${data['property_reference']}'),
                  Row(children: [Text('Water bill: ${data['water_bill_status']}'), TextButton(onPressed: () => _toggleWaterBill(data['water_bill_status'] as String), child: const Text('Toggle'))]),
                ]),
              ),
              const SizedBox(height: 12),
              SurfaceCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(radius: 22, child: Icon(Icons.qr_code_2)),
                  title: const Text('Property QR Code', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('For tenant payments & access'),
                  trailing: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Generate', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(width: 4), Icon(Icons.chevron_right)]),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyQrCodePage(
                        propertyName: widget.property.name,
                        address: data['full_address'] as String? ?? widget.property.location,
                        qrCodeUrl: data['property']['qr_code_url'] as String,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Current Tenants', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CurrentTenantsPage(tenants: tenants)),
                ),
              ),
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

class CurrentTenantsPage extends StatelessWidget {
  const CurrentTenantsPage({super.key, required this.tenants});

  final List<Map<String, dynamic>> tenants;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Tenants', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
        toolbarHeight: 96,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () {},
              child: const Text('Remove All', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...tenants.map(
            (tenant) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SurfaceCard(
                child: Stack(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.only(right: 56),
                      leading: CircleAvatar(radius: 30, backgroundImage: NetworkImage((tenant['profile_image_url'] ?? tenant['photo_url'] ?? 'https://i.pravatar.cc/120') as String)),
                      title: Text(tenant['full_name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      subtitle: Text('${tenant['occupation'] ?? tenant['job_title'] ?? 'Tenant'}\n${tenant['phone'] ?? '-'}\n${tenant['address'] ?? tenant['full_address'] ?? 'Address not added'}'),
                      isThreeLine: true,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('REMOVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const Positioned(top: 48, right: 12, child: Icon(Icons.description, color: Color(0xFF204C4F))),
                  ],
                ),
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
            onPressed: () {},
            child: const Text('Add New Tenant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

class PropertyQrCodePage extends StatelessWidget {
  const PropertyQrCodePage({super.key, required this.propertyName, required this.address, required this.qrCodeUrl});

  final String propertyName;
  final String address;
  final String qrCodeUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate QR Code')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SurfaceCard(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF204C4F), width: 3), borderRadius: BorderRadius.circular(16)),
                  child: RemoteOrDataImage(imageRef: qrCodeUrl, height: 280),
                ),
                const SizedBox(height: 18),
                Text(propertyName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(address, style: const TextStyle(color: Colors.black54, fontSize: 18), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Download'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.share), label: const Text('Share'))),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.print), label: const Text('Print QR Code')),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info, color: Color(0xFF204C4F)),
                SizedBox(width: 10),
                Expanded(
                  child: Text('This QR code allows tenants to quickly access the property dashboard, report maintenance issues, or view rental agreements.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class OwnerNotificationsPage extends StatefulWidget {
  const OwnerNotificationsPage({super.key, required this.ownerId, this.propertyId, this.propertyName});

  final String ownerId;
  final String? propertyId;
  final String? propertyName;

  @override
  State<OwnerNotificationsPage> createState() => _OwnerNotificationsPageState();
}

class _OwnerNotificationsPageState extends State<OwnerNotificationsPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _tabs = const ['all', 'payment', 'maintenance', 'general'];
  String _selected = 'all';
  bool _loading = true;
  List<NotificationItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _api.listOwnerNotifications(
        ownerId: widget.ownerId,
        propertyId: widget.propertyId,
        category: _selected,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() => _items = items);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await _api.markOwnerNotificationsRead(ownerId: widget.ownerId, propertyId: widget.propertyId);
    _load();
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'payment':
        return Icons.payments_outlined;
      case 'maintenance':
        return Icons.build_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propertyName == null ? 'Notifications' : 'Notifications • ${widget.propertyName}'),
        actions: [
          TextButton(onPressed: _markAllRead, child: const Text('Mark all as read')),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                final tab = _tabs[i];
                final selected = tab == _selected;
                return ChoiceChip(
                  selected: selected,
                  label: Text(tab == 'all' ? 'All' : '${tab[0].toUpperCase()}${tab.substring(1)}s'),
                  onSelected: (_) {
                    setState(() => _selected = tab);
                    _load();
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _tabs.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search notifications...',
                filled: true,
                fillColor: const Color(0xFFF1F4F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      return SurfaceCard(
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: const Color(0x1A204C4F), child: Icon(_iconFor(n.category), color: const Color(0xFF204C4F))),
                          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: n.isRead ? null : const Icon(Icons.brightness_1, size: 10, color: Color(0xFF204C4F)),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _items.length,
                  ),
          ),
        ],
      ),
    );
  }
}
