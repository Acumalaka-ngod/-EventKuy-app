/// Model User — data dari `auth.users` + `public.profiles`.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'pengguna',
    this.avatarUrl,
  });

  /// Apakah akun ini berperan organizer (atau admin).
  bool get isOrganizer => role == 'organizer' || role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      role: (json['role'] as String?) ?? 'pengguna',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
