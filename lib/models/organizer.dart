/// Model Organizer — mirror tabel `public.organizers` di Supabase.
class Organizer {
  final String id;
  final String? ownerId;
  final String name;
  final String bio;
  final String? avatarUrl;
  final String city;
  final bool verified;

  const Organizer({
    required this.id,
    this.ownerId,
    required this.name,
    required this.bio,
    this.avatarUrl,
    required this.city,
    required this.verified,
  });

  /// Inisial huruf pertama dari nama, untuk avatar placeholder.
  String get initial =>
      name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  /// Nama singkat ditampilkan di UI (nama lengkap bila pendek, lalu inisial).
  String get displayName => name.trim().isEmpty ? '-' : name.trim();

  factory Organizer.fromJson(Map<String, dynamic> json) {
    return Organizer(
      id: json['id'].toString(),
      ownerId: json['owner_id'] as String?,
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String? ?? '',
      verified: (json['verified'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'name': name,
    'bio': bio,
    'avatar_url': avatarUrl,
    'city': city,
    'verified': verified,
  };
}
