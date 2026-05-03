/// Firestore `users/{uid}` hujjatidan profil ma'lumotlari.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.name,
    this.role,
    this.email,
    this.phone,
    this.organization,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? name;
  final String? role;
  final String? email;
  final String? phone;
  final String? organization;
  final String? avatarUrl;

  factory UserProfile.fromMap(Map<String, dynamic> d, String uid) {
    return UserProfile(
      id: uid,
      username: (d['username'] as String?) ?? '',
      name: d['name'] as String?,
      role: d['role'] as String?,
      email: d['email'] as String?,
      phone: d['phone'] as String?,
      organization: d['organization'] as String?,
      avatarUrl: d['avatarUrl'] as String?,
    );
  }

  bool get isTeacher => role == 'teacher';
}
