class HotelUser {
  final String id;
  final String? hotelId;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final String? avatarUrl;
  final DateTime createdAt;

  const HotelUser({
    required this.id,
    this.hotelId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    this.avatarUrl,
    required this.createdAt,
  });

  factory HotelUser.fromJson(Map<String, dynamic> j) => HotelUser(
    id: j['id'] as String,
    hotelId: j['hotel_id'] as String?,
    fullName: j['full_name'] as String,
    email: j['email'] as String,
    role: j['role'] as String,
    isActive: j['is_active'] as bool,
    avatarUrl: j['avatar_url'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}
