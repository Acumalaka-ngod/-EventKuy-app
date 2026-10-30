import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Ditampilkan saat aplikasi dijalankan tanpa --dart-define Supabase.
class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: AppTheme.violet, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'Supabase belum dikonfigurasi',
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Aplikasi membutuhkan URL project dan anon key Supabase. '
                      'Ikuti langkah berikut sebelum menjalankan aplikasi:',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.muted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _step(
                      '1',
                      'Buat project di supabase.com, lalu salin Project URL '
                          'dan anon public key (Settings > API).',
                    ),
                    _step(
                      '2',
                      'Buka SQL Editor, jalankan supabase/schema.sql '
                          'dilanjutkan supabase/seed.sql.',
                    ),
                    _step(
                      '3',
                      'Nonaktifkan konfirmasi email (Authentication > Providers '
                          '> Email) agar akun demo langsung bisa masuk.',
                    ),
                    _step(
                      '4',
                      'Jalankan aplikasi dengan kunci Supabase:',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.violetSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const SelectableText(
                        'flutter run \\\n'
                        '  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \\\n'
                        '  --dart-define=SUPABASE_ANON_KEY=eyJ...',
                        style: TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 12,
                          color: AppTheme.ink,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.violetSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.violetDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.ink,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
