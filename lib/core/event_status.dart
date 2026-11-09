/// Status sederhana sebuah event berdasarkan tanggalnya.
///
/// Dipakai dashboard organizer supaya badge status tidak lagi hardcoded
/// "Sedang Berlangsung" untuk semua event.
enum EventStatus { upcoming, today, finished }

extension EventStatusLabel on EventStatus {
  String get label => switch (this) {
    EventStatus.upcoming => 'Akan Datang',
    EventStatus.today => 'Hari Ini',
    EventStatus.finished => 'Selesai',
  };
}

/// Tentukan status event relatif terhadap [now] (default: waktu sekarang).
///
/// Perbandingan dilakukan per tanggal, bukan per jam, karena model event
/// hanya menyimpan tanggal (plus `timeRange` sebagai teks).
EventStatus eventStatusFor(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final eventDay = DateTime(date.year, date.month, date.day);
  final today = DateTime(current.year, current.month, current.day);
  final difference = eventDay.difference(today).inDays;

  if (difference < 0) return EventStatus.finished;
  if (difference == 0) return EventStatus.today;
  return EventStatus.upcoming;
}
