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
        fullName: 'Alexander Chen',
        email: 'a.chen@rentory.com',
        phone: '+1 (555) 892-0412',
        roleLabel: 'Property Owner',
        memberBadge: 'Gold Member',
        memberSince: 'Since 2021',
        avatarImage: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD8j3kktyuCy7YjZORPPyaXvpOWHFRYqvd1fQ9DW4EyfyvuNsHb6hkoTIBYojs1rbhB5GzDZCrN5obWubGfkO7AKyGG1fYKbD9jWGY1enVRF6aEyZ5ODj1BEcQfz2xy8FHfk0TBslqkF_N5OMkKBXUPBvmHkMyk0Ly0Nj909Z1T6PT5cTe7cc0Gv-gtKJigT66gEDsFDE2K_Se1e0z_CpefGh3q-ZPmlemuHl6iUtoigFcT7b0Bnk2bSKVdvh6bgF-qC2w7-R1HN9sV',
      ),
    );
  }

  static void update(String ownerId, OwnerProfile profile) {
    _profiles[ownerId] = profile;
  }
}
