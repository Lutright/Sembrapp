class Profile {
  final String id;
  final String? fullName;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    this.fullName,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      role: map['role'] as String? ?? 'campesino',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  bool get isCampesino => role == 'campesino';
  bool get isComprador => role == 'comprador';
}
