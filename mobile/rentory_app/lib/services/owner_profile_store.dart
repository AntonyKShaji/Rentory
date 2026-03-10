class OwnerProfile {
  const OwnerProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.roleLabel,
    required this.memberBadge,
    required this.memberSince,
    this.avatarImage,
  });

  final String fullName;
  final String email;
  final String phone;
  final String roleLabel;
  final String memberBadge;
  final String memberSince;
  final String? avatarImage;

  factory OwnerProfile.fromApi(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'] as String?;
    final createdAt = DateTime.tryParse(createdAtRaw ?? '');
    final memberYear = createdAt?.year.toString() ?? 'N/A';
    return OwnerProfile(
      fullName: (json['full_name'] as String?)?.trim().isNotEmpty == true ? json['full_name'] as String : 'Owner',
      email: ((json['email'] as String?)?.trim().isNotEmpty ?? false) ? json['email'] as String : 'Not provided',
      phone: (json['phone'] as String?) ?? 'Not provided',
      roleLabel: ((json['role'] as String?) ?? 'owner').replaceAll('_', ' '),
      memberBadge: 'Member',
      memberSince: 'Since $memberYear',
    );
  }

  OwnerProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? roleLabel,
    String? memberBadge,
    String? memberSince,
    String? avatarImage,
  }) {
    return OwnerProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roleLabel: roleLabel ?? this.roleLabel,
      memberBadge: memberBadge ?? this.memberBadge,
      memberSince: memberSince ?? this.memberSince,
      avatarImage: avatarImage ?? this.avatarImage,
    );
  }
}

class OwnerProfileStore {
  static final Map<String, OwnerProfile> _profiles = {};

  static OwnerProfile getByOwnerId(String ownerId) {
    return _profiles.putIfAbsent(
      ownerId,
      () => const OwnerProfile(
        fullName: 'Owner',
        email: 'Not provided',
        phone: 'Not provided',
        roleLabel: 'Owner',
        memberBadge: 'Member',
        memberSince: 'Since N/A',
      ),
    );
  }

  static void update(String ownerId, OwnerProfile profile) {
    _profiles[ownerId] = profile;
  }
}
