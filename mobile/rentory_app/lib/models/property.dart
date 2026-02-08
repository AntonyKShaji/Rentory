class Property {
  Property({
    required this.id,
    required this.ownerId,
    required this.location,
    required this.name,
    required this.unitType,
    required this.capacity,
    required this.occupiedCount,
  });

  final String id;
  final String ownerId;
  final String location;
  final String name;
  final String unitType;
  final int capacity;
  final int occupiedCount;

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      location: json['location'] as String,
      name: json['name'] as String,
      unitType: json['unit_type'] as String,
      capacity: json['capacity'] as int,
      occupiedCount: json['occupied_count'] as int,
    );
  }
}
