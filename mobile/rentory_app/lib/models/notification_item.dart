class NotificationItem {
  NotificationItem({
    required this.id,
    required this.ownerId,
    required this.propertyId,
    required this.title,
    required this.body,
    required this.category,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String? propertyId;
  final String title;
  final String body;
  final String category;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      propertyId: json['property_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      category: (json['category'] as String?) ?? 'general',
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
