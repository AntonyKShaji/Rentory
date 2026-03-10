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
  int _selectedTab = 0;
  static const Color _brandDark = Color(0xFF114C52);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _properties = _api.listOwnerProperties(widget.ownerId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = OwnerProfileStore.getByOwnerId(widget.ownerId);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
          children: [
            FutureBuilder<List<Property>>(
              future: _properties,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator()));
                final properties = snapshot.data!;
                final previewProperties = properties.take(2).toList();
                final totalRent = properties.fold<double>(0, (sum, property) => sum + property.rent);
                final totalTenants = properties.fold<int>(0, (sum, property) => sum + property.occupiedCount);
                final unreadAlerts = properties.fold<int>(0, (sum, property) => sum + property.unreadNotifications);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dashboardHeader(profile: profile, unreadAlerts: unreadAlerts),
                    const SizedBox(height: 22),
                    if (properties.isEmpty)
                      SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brandDark)),
                            const SizedBox(height: 10),
                            const Text('No properties yet', style: TextStyle(color: Color(0xFF5E738E))),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyPage(ownerId: widget.ownerId))),
                              style: FilledButton.styleFrom(backgroundColor: _brandDark),
                              child: const Text('Add your first property'),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          const Text('Properties', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: _brandDark)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyPage(ownerId: widget.ownerId)));
                              _reload();
                            },
                            child: const CircleAvatar(
                              radius: 13,
                              backgroundColor: _brandDark,
                              child: Icon(Icons.add, size: 16, color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AllPropertiesPage(ownerId: widget.ownerId, properties: properties)),
                            ),
                            child: const Text('See All', style: TextStyle(fontSize: 18, color: Color(0xFF607B80), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 240,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: previewProperties.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 18),
                          itemBuilder: (context, index) => SizedBox(width: 315, child: _propertyCard(previewProperties[index])),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _overviewCard(icon: Icons.payments_outlined, title: 'Payment Due', value: '₹${totalRent.toStringAsFixed(0)}')),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _overviewCard(
                              icon: Icons.history_toggle_off,
                              title: 'History',
                              value: 'View All',
                              trailing: const Icon(Icons.chevron_right, color: Color(0xFF97A5BB)),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerHistoryPage(ownerId: widget.ownerId))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _revenueCard(totalRent)),
                          const SizedBox(width: 16),
                          Expanded(child: _tenantsCard(totalTenants, theme)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _financialGrowthCard(),
                    ],
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
          RemoteOrDataImage(imageRef: property.imageUrl, height: 160, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _brandDark)),
                const SizedBox(height: 4),
                Text(property.location, style: const TextStyle(fontSize: 14, color: Color(0xFF5E738E))),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _dashboardHeader({required OwnerProfile profile, required int unreadAlerts}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE3EA)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundColor: _brandDark, child: Icon(Icons.apartment, color: Colors.white)),
          const SizedBox(width: 14),
          const Text('Rentory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _brandDark)),
          const Spacer(),
          _roundIconButton(icon: Icons.search, onTap: () {}),
          const SizedBox(width: 8),
          _roundIconButton(
            icon: Icons.notifications,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerNotificationsPage(ownerId: widget.ownerId))),
            badgeCount: unreadAlerts == 0 ? null : unreadAlerts,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerProfilePage(ownerId: widget.ownerId)));
              if (!context.mounted) return;
              setState(() {});
            },
            child: CircleAvatar(
              radius: 21,
              backgroundColor: _brandDark,
              child: ClipOval(
                child: RemoteOrDataImage(
                  imageRef: profile.avatarImage,
                  width: 42,
                  height: 42,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({required IconData icon, VoidCallback? onTap, int? badgeCount}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(color: Color(0xFFF1F4F7), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF30455E)),
          ),
          if (badgeCount != null)
            Positioned(
              right: -2,
              top: -5,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: Color(0xFFFF4D4D), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _overviewCard({required IconData icon, required String title, required String value, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SurfaceCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: _brandDark), const Spacer(), if (trailing != null) trailing]),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF5F7594))),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: _brandDark)),
        ]),
      ),
    );
  }

  Widget _revenueCard(double totalRent) {
    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            const Expanded(child: Text('Total\nRevenue', style: TextStyle(fontSize: 16, color: Color(0xFF5F7594)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE8EEF3), borderRadius: BorderRadius.circular(8)),
              child: const Text('+12%', style: TextStyle(fontWeight: FontWeight.w700, color: _brandDark)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('₹${totalRent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _brandDark)),
        const SizedBox(height: 20),
        Container(
          height: 5,
          decoration: BoxDecoration(color: const Color(0xFFE8EDF1), borderRadius: BorderRadius.circular(99)),
          child: FractionallySizedBox(
            widthFactor: 0.74,
            alignment: Alignment.centerLeft,
            child: Container(decoration: BoxDecoration(color: _brandDark, borderRadius: BorderRadius.circular(99))),
          ),
        ),
      ]),
    );
  }

  Widget _tenantsCard(int totalTenants, ThemeData theme) {
    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Total Tenants', style: TextStyle(fontSize: 16, color: Color(0xFF5F7594))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE8EEF3), borderRadius: BorderRadius.circular(8)),
            child: const Text('+5%', style: TextStyle(fontWeight: FontWeight.w700, color: _brandDark)),
          ),
        ]),
        const SizedBox(height: 8),
        Text('$totalTenants', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _brandDark)),
        const SizedBox(height: 18),
        Row(
          children: [
            CircleAvatar(radius: 12, backgroundColor: const Color(0xFFDDB09A), child: Text('👩', style: theme.textTheme.bodySmall)),
            const SizedBox(width: 3),
            CircleAvatar(radius: 12, backgroundColor: const Color(0xFFC8D8E8), child: Text('👨', style: theme.textTheme.bodySmall)),
            const SizedBox(width: 3),
            const CircleAvatar(radius: 12, backgroundColor: _brandDark, child: Text('+126', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
          ],
        ),
      ]),
    );
  }

  Widget _financialGrowthCard() {
    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Financial Growth', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: _brandDark)),
                  SizedBox(height: 4),
                  Text('Monthly revenue tracking', style: TextStyle(color: Color(0xFF647790))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF0F3F7), borderRadius: BorderRadius.circular(20)),
              child: const Text('6 Months', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3D4C65))),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: CustomPaint(size: const Size(double.infinity, 180), painter: _SimpleChartPainter()),
        ),
        const SizedBox(height: 18),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('JAN', style: TextStyle(fontWeight: FontWeight.w700, color: _brandDark)),
            Text('FEB', style: TextStyle(fontWeight: FontWeight.w700, color: _brandDark)),
            Text('MAR', style: TextStyle(fontWeight: FontWeight.w700, color: _brandDark)),
            Text('APR', style: TextStyle(fontWeight: FontWeight.w700, color: _brandDark)),
            Text('MAY', style: TextStyle(fontWeight: FontWeight.w700, color: _brandDark)),
            Text('JUN', style: TextStyle(fontWeight: FontWeight.w700, color: _brandDark)),
          ],
        ),
      ]),
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

}

class _SimpleChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF114C52)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = const Color(0x1A114C52)
      ..style = PaintingStyle.fill;

    final points = [
      Offset(0, size.height * 0.82),
      Offset(size.width * 0.25, size.height * 0.48),
      Offset(size.width * 0.43, size.height * 0.6),
      Offset(size.width * 0.65, size.height * 0.25),
      Offset(size.width * 0.83, size.height * 0.4),
      Offset(size.width, size.height * 0.12),
    ];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final control = Offset((prev.dx + current.dx) / 2, prev.dy);
      final control2 = Offset((prev.dx + current.dx) / 2, current.dy);
      linePath.cubicTo(control.dx, control.dy, control2.dx, control2.dy, current.dx, current.dy);
    }

    final areaPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(areaPath, fill);
    canvas.drawPath(linePath, stroke);

    final markerPaint = Paint()..color = const Color(0xFF114C52);
    canvas.drawCircle(points[1], 5, markerPaint);
    canvas.drawCircle(points[3], 5, markerPaint);
    canvas.drawCircle(points.last, 5, markerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  final ApiService _api = ApiService();
  late OwnerProfile _profile;
  bool _twoFactorEnabled = true;
  int _totalPortfolio = 0;

  @override
  void initState() {
    super.initState();
    _profile = OwnerProfileStore.getByOwnerId(widget.ownerId);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final payload = await _api.getOwnerProfile(widget.ownerId);
      final profile = OwnerProfile.fromApi(payload).copyWith(avatarImage: _profile.avatarImage);
      OwnerProfileStore.update(widget.ownerId, profile);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _totalPortfolio = payload['total_properties'] as int? ?? 0;
      });
    } catch (_) {
      // keep locally cached fallback
    }
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL PORTFOLIO', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                      Text('$_totalPortfolio Properties', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
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

class AddPropertyPage extends StatelessWidget {
  const AddPropertyPage({super.key, required this.ownerId});
  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return PropertyEditorPage(ownerId: ownerId);
  }
}

class PropertyDetailsPage extends StatelessWidget {
  const PropertyDetailsPage({super.key, required this.property, required this.ownerId});
  final Property property;
  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return PropertyEditorPage(ownerId: ownerId, property: property);
  }
}

class PropertyEditorPage extends StatefulWidget {
  const PropertyEditorPage({super.key, required this.ownerId, this.property});

  final String ownerId;
  final Property? property;

  bool get isEdit => property != null;

  @override
  State<PropertyEditorPage> createState() => _PropertyEditorPageState();
}

class _PropertyEditorPageState extends State<PropertyEditorPage> {
  static const Color _primary = Color(0xFF204C4F);

  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _unitType = TextEditingController();
  final _capacity = TextEditingController();
  final _rent = TextEditingController();
  final _description = TextEditingController();
  final _areaSqft = TextEditingController();
  final _parkingDetails = TextEditingController();
  final _preferredResidents = TextEditingController();
  final _advanceAmount = TextEditingController();
  final _fullAddress = TextEditingController();
  final _caretakerName = TextEditingController();
  final _caretakerContact = TextEditingController();
  final _propertyReference = TextEditingController();

  bool _isActive = true;
  bool _caretakerEnabled = false;
  String? _imageDataUri;
  bool _isSaving = false;
  bool _loading = false;
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _hydrateFromCard();
      _loadDetails();
    } else {
      _unitType.text = '2BHK';
      _capacity.text = '2';
      _rent.text = '15000';
      _advanceAmount.text = '0';
      _preferredResidents.text = 'Bachelors';
      _parkingDetails.text = 'Car Parking Available';
    }
  }

  void _hydrateFromCard() {
    final property = widget.property!;
    _name.text = property.name;
    _location.text = property.location;
    _unitType.text = property.unitType;
    _capacity.text = property.capacity.toString();
    _rent.text = property.rent.toStringAsFixed(0);
    _imageDataUri = property.imageUrl;
    _isActive = property.isActive;
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getPropertyDetails(widget.property!.id);
      if (!mounted) return;
      setState(() {
        _description.text = data['description'] as String? ?? '';
        _areaSqft.text = (data['area_sqft'] as int?)?.toString() ?? '';
        _parkingDetails.text = data['parking_details'] as String? ?? _parkingDetails.text;
        _preferredResidents.text = data['preferred_residents'] as String? ?? _preferredResidents.text;
        _advanceAmount.text = (data['advance_amount'] ?? 0).toString();
        _fullAddress.text = data['full_address'] as String? ?? '';
        _caretakerEnabled = (data['caretaker_enabled'] as bool?) ?? false;
        _caretakerName.text = data['caretaker_name'] as String? ?? '';
        _caretakerContact.text = data['caretaker_contact'] as String? ?? '';
        _propertyReference.text = data['property_reference'] as String? ?? '';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.path.toLowerCase().endsWith('png') ? 'png' : 'jpeg';
    setState(() => _imageDataUri = 'data:image/$ext;base64,${base64Encode(bytes)}');
  }

  bool _validate() {
    final nextErrors = <String, String?>{};
    if (_imageDataUri == null || _imageDataUri!.trim().isEmpty) nextErrors['image'] = 'Property image is required';
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
    if (!_validate() || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      if (widget.isEdit) {
        await _api.updateProperty(
          propertyId: widget.property!.id,
          location: _location.text.trim(),
          name: _name.text.trim(),
          unitType: _unitType.text.trim(),
          capacity: int.tryParse(_capacity.text.trim()) ?? 1,
          rent: double.tryParse(_rent.text.trim()) ?? 0,
          imageUrl: _imageDataUri!,
          description: _description.text.trim(),
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
      } else {
        await _api.createProperty(
          ownerId: widget.ownerId,
          location: _location.text.trim(),
          name: _name.text.trim(),
          unitType: _unitType.text.trim(),
          capacity: int.tryParse(_capacity.text.trim()) ?? 1,
          rent: double.tryParse(_rent.text.trim()) ?? 0,
          imageUrl: _imageDataUri!,
          description: _description.text.trim(),
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
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(title: const Text('Property Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      RemoteOrDataImage(imageRef: _imageDataUri, height: 220),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _primary),
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Change Photo'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errors['image'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_errors['image']!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 16),
                Card(
                  child: SwitchListTile(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: const Text('Listing Status', style: TextStyle(fontWeight: FontWeight.w700, color: _primary)),
                    subtitle: Text(_isActive ? 'Active' : 'Inactive'),
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  title: 'Property Specifications',
                  child: Column(children: [
                    _field(_name, 'Property name', errorKey: 'name'),
                    _field(_location, 'Location', errorKey: 'location'),
                    Row(children: [Expanded(child: _field(_unitType, 'Type', errorKey: 'unit')), const SizedBox(width: 10), Expanded(child: _field(_areaSqft, 'Area sqft', errorKey: 'area'))]),
                    Row(children: [Expanded(child: _field(_capacity, 'Capacity', errorKey: 'capacity')), const SizedBox(width: 10), Expanded(child: _field(_preferredResidents, 'Residents'))]),
                    Row(children: [Expanded(child: _field(_rent, 'Monthly rent', errorKey: 'rent')), const SizedBox(width: 10), Expanded(child: _field(_advanceAmount, 'Advance amount', errorKey: 'advance'))]),
                    _field(_parkingDetails, 'Parking details'),
                    _field(_fullAddress, 'Full address'),
                    _field(_description, 'Description', errorKey: 'description', maxLines: 3),
                  ]),
                ),
                const SizedBox(height: 12),
                _section(
                  title: 'Caretaker Details',
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [const Text('Enabled'), Checkbox(value: _caretakerEnabled, onChanged: (v) => setState(() => _caretakerEnabled = v ?? false))]),
                  child: Column(children: [
                    if (_caretakerEnabled) ...[
                      Row(children: [Expanded(child: _field(_caretakerName, 'Name', errorKey: 'caretaker_name')), const SizedBox(width: 10), Expanded(child: _field(_caretakerContact, 'Contact', errorKey: 'caretaker_contact'))]),
                    ],
                    _field(_propertyReference, 'Property reference'),
                  ]),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        color: const Color(0xFFF6F8F6),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _primary, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _isSaving ? null : _submit,
          icon: const Icon(Icons.save),
          label: Text(_isSaving ? 'Saving...' : (widget.isEdit ? 'Save Changes' : 'Create Property')),
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child, Widget? trailing}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E0E3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFFF0F2F2), borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
            child: Row(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: _primary)), const Spacer(), if (trailing != null) trailing]),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {String? errorKey, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, errorText: errorKey == null ? null : _errors[errorKey]),
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
