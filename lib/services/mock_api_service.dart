import '../models/event.dart';

/// Simulasi backend sebelum Laravel online (Fase 1-2).
/// imageUrl bisa "assets/images/xxx.jpg" (lokal) atau URL network.
/// Nanti diganti ApiService yang hit AppConfig.apiBaseUrl via package:http.
class MockApiService {
  // Kalau file aset lokal belum ada, EventImage otomatis fallback ke picsum.
  static String img(String asset, String seed) => asset;

  static Future<List<Event>> fetchEvents() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      Event(
        id: 1,
        title: 'Sound of Tomorrow',
        description:
            'Sound of Tomorrow adalah festival musik yang menghadirkan deretan musisi terbaik dari berbagai genre. Nikmati pengalaman tak terlupakan bersama teman-teman, dengan panggung megah dan fasilitas lengkap.',
        date: DateTime(2025, 7, 12),
        location: 'Istora Senayan, Jl. Pintu Satu Senayan No. 1, Jakarta Pusat',
        price: 750000,
        quota: 3000,
        imageUrl: img('assets/images/event_sound.jpg', 'concert'),
        category: 'Konser',
        tags: const ['Musik', 'Festival', 'Food & Beverage'],
        timeRange: '15:00 - 23:00',
      ),
      Event(
        id: 2,
        title: 'We The Fest 2025',
        description: 'Festival musik tahunan terbesar di Jakarta.',
        date: DateTime(2025, 7, 25),
        location: 'Gelora Bung Karno (GBK), Jl. Pintu Satu Senayan, Jakarta Pusat',
        price: 750000,
        quota: 10000,
        imageUrl: img('assets/images/event_wtf.jpg', 'festival'),
        category: 'Konser',
        tags: const ['Musik', 'Festival'],
        timeRange: '14:00 - 23:00',
      ),
      Event(
        id: 3,
        title: 'Photography Workshop',
        description: 'Workshop fotografi untuk pemula sampai pro.',
        date: DateTime(2025, 7, 12),
        location: 'Braga Creative Hub, Jl. Braga No. 21, Bandung',
        price: 250000,
        quota: 200,
        imageUrl: img('assets/images/event_photo.jpg', 'workshop'),
        category: 'Workshop',
        tags: const ['Fotografi'],
        timeRange: '09:00 - 15:00',
      ),
      Event(
        id: 4,
        title: 'Future of Technology',
        description: 'Seminar AI, startup, dan masa depan teknologi.',
        date: DateTime(2025, 7, 18),
        location: 'Jakarta Convention Center, Jl. Gatot Subroto, Jakarta Pusat',
        price: 150000,
        quota: 1000,
        imageUrl: img('assets/images/event_tech.jpg', 'seminar'),
        category: 'Seminar',
        tags: const ['Teknologi'],
        timeRange: '09:00 - 17:00',
      ),
      Event(
        id: 5,
        title: 'Jakarta Running Festival',
        description: 'Lari bersama 5K & 10K di Monas.',
        date: DateTime(2025, 7, 27),
        location: 'Kawasan Monas, Jl. Silang Monas, Jakarta Pusat',
        price: 300000,
        quota: 5000,
        imageUrl: img('assets/images/event_run.jpg', 'running'),
        category: 'Olahraga',
        tags: const ['Lari', 'Komunitas'],
        timeRange: '05:00 - 10:00',
      ),
      Event(
        id: 6,
        title: 'UI/UX Design Workshop',
        description: 'Belajar desain produk dari praktisi.',
        date: DateTime(2025, 7, 5),
        location: 'GoWork Chubb Square, Jl. M.H. Thamrin No. 10, Jakarta Pusat',
        price: 200000,
        quota: 300,
        imageUrl: img('assets/images/event_uiux.jpg', 'uiux'),
        category: 'Workshop',
        tags: const ['Desain'],
        timeRange: '10:00 - 16:00',
      ),
      Event(
        id: 7,
        title: 'Digital Marketing Summit',
        description: 'Strategi growth & ads terbaru.',
        date: DateTime(2025, 7, 8),
        location: 'Gedung Merdeka, Jl. Asia Afrika No. 65, Bandung',
        price: 350000,
        quota: 500,
        imageUrl: img('assets/images/event_marketing.jpg', 'marketing'),
        category: 'Seminar',
        tags: const ['Bisnis'],
        timeRange: '09:00 - 17:00',
      ),
    ];
  }

  /// Network fallback saat file aset lokal belum disediakan.
  static String fallbackUrl(int id) =>
      'https://picsum.photos/seed/ajangin$id/600/400';
}
