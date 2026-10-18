import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/ticket.dart';
import '../../providers/event_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/event_card.dart';
import '../../widgets/event_image.dart';

/// Layar Scan QR Check-in (Mode Panitia) — sesuai desain baru:
/// latar gelap, judul & petunjuk, bingkai scan berkurung sudut,
/// tombol flash, dan kartu event di bawah.
/// TODO Fase 6: ganti simulasi tap dengan kamera mobile_scanner asli.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  void _simulateScan() {
    final provider = context.read<TicketProvider>();
    Ticket? target;
    for (final t in provider.tickets) {
      if (t.status.toLowerCase() != 'checked_in') {
        target = t;
        break;
      }
    }

    if (target == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Tidak Ada Tiket Aktif'),
          content: const Text(
            'Semua tiket sudah check-in. Beli tiket terlebih dahulu di menu Tiket Saya untuk mencoba simulasi ini.',
            style: TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    final ticket = target;
    provider.checkIn(ticket.code);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accentEmerald.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppTheme.accentEmerald, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Check-in Berhasil',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${ticket.eventTitle}\n${ticket.code}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Selesai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>().events;
    final event = events.isNotEmpty ? events.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: kembali & flash
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _flashOn = !_flashOn),
                    icon: Icon(
                      _flashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color: _flashOn
                          ? AppTheme.accentAmber
                          : Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),
            const Text(
              'Scan QR Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Arahkan kamera ke kode QR peserta untuk melakukan check-in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 34),

            // Bingkai scan (tap untuk simulasi)
            GestureDetector(
              onTap: _simulateScan,
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(painter: _CornerPainter()),
                    ),
                    // Garis scan berjalan
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, _) {
                        final top = _scanController.value * (260 - 3);
                        return Positioned(
                          top: top,
                          left: 22,
                          right: 22,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary.withValues(alpha: 0),
                                  const Color(0xFF8B8FF5),
                                  const Color(0xFF8B8FF5),
                                  AppTheme.primary.withValues(alpha: 0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B8FF5)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ketuk bingkai untuk simulasi scan',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11.5,
              ),
            ),

            const Spacer(),

            // Kartu event di bawah
            if (event != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181C28),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      EventImage(
                        imageUrl: event.imageUrl,
                        eventId: event.id,
                        height: 46,
                        width: 46,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${venueOf(event.location)} · ${formatTanggal(event.date)} · ${event.timeRange}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kurung sudut bingkai scan.
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 30.0;
    const r = 20.0;

    // Kiri atas
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0),
            radius: const Radius.circular(r))
        ..lineTo(len, 0),
      paint,
    );
    // Kanan atas
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..arcToPoint(Offset(size.width, r),
            radius: const Radius.circular(r))
        ..lineTo(size.width, len),
      paint,
    );
    // Kanan bawah
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - len)
        ..lineTo(size.width, size.height - r)
        ..arcToPoint(Offset(size.width - r, size.height),
            radius: const Radius.circular(r))
        ..lineTo(size.width - len, size.height),
      paint,
    );
    // Kiri bawah
    canvas.drawPath(
      Path()
        ..moveTo(len, size.height)
        ..lineTo(r, size.height)
        ..arcToPoint(Offset(0, size.height - r),
            radius: const Radius.circular(r))
        ..lineTo(0, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
