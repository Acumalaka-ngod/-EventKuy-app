import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/errors.dart';
import '../core/theme.dart';
import '../models/ticket.dart';
import '../services/ticket_pdf_service.dart';
import 'app_logo.dart';
import 'custom_button.dart';

/// E-Ticket EventKuy — header gradien, garis potong, QR, status check-in,
/// pemilik tiket, dan unduh PDF.
class TicketItem extends StatelessWidget {
  final Ticket ticket;
  final String dateLocation;
  final String attendeeName;
  final VoidCallback? onViewDetail;
  final VoidCallback? onCheckIn;

  const TicketItem({
    super.key,
    required this.ticket,
    this.dateLocation = '',
    this.attendeeName = 'Andi Pratama',
    this.onViewDetail,
    this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = ticket.status.toLowerCase() == 'checked_in';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Column(
          children: [
            // === Header gradien ===
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 190),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppTheme.ticketGradient,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const EventKuyMark(size: 25, onDark: true),
                          const SizedBox(width: 8),
                          const Text(
                            'EVENTKUY',
                            style: TextStyle(
                              fontFamily: AppTheme.headingFont,
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              isCheckedIn ? 'SUDAH CHECK-IN' : 'TIKET AKTIF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: onViewDetail,
                        child: Text(
                          ticket.eventTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.headingFont,
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (dateLocation.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded,
                                color: Colors.white70, size: 13),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                dateLocation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xB8FFFFFF),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // === Garis potong ===
            const SizedBox(height: 22, child: _TicketCut()),

            // === Body: QR + aksi ===
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 15, 24, 24),
              child: Column(
                children: [
                  QrImageView(
                    data: ticket.code,
                    size: 128,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppTheme.ink,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TICKET ID',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ticket.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.headingFont,
                      color: AppTheme.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 17),
                  if (isCheckedIn)
                    Container(
                      constraints: const BoxConstraints(minHeight: 46),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.greenSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: AppTheme.green, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Check-in berhasil',
                            style: TextStyle(
                              color: AppTheme.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    CustomButton(
                      label: 'Check-in Tiket',
                      height: 46,
                      icon: Icons.qr_code_scanner_rounded,
                      onPressed: onCheckIn,
                    ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.only(top: 17),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PEMILIK TIKET',
                                style: TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                attendeeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.ink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _DownloadPdfButton(
                          ticket: ticket,
                          attendeeName: attendeeName,
                          dateLocation: dateLocation,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Garis putus-putus + lekukan tiket kiri/kanan.
class _TicketCut extends StatelessWidget {
  const _TicketCut();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(-11, 0),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppTheme.canvas,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Expanded(
            child: CustomPaint(painter: _DashedLinePainter()),
          ),
          Transform.translate(
            offset: const Offset(11, 0),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppTheme.canvas,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dash = 7.0;
    const gap = 6.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dash).clamp(0, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DownloadPdfButton extends StatefulWidget {
  const _DownloadPdfButton({
    required this.ticket,
    required this.attendeeName,
    required this.dateLocation,
  });

  final Ticket ticket;
  final String attendeeName;
  final String dateLocation;

  @override
  State<_DownloadPdfButton> createState() => _DownloadPdfButtonState();
}

class _DownloadPdfButtonState extends State<_DownloadPdfButton> {
  bool _downloading = false;

  Future<void> _download() async {
    if (_downloading) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloading = true);

    try {
      final shared = await TicketPdfService.shareTicketPdf(
        ticket: widget.ticket,
        attendeeName: widget.attendeeName,
        dateLocation: widget.dateLocation,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            shared
                ? 'E-tiket PDF siap dibagikan.'
                : 'E-tiket PDF berhasil dibuat.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _downloading ? null : _download,
      icon: _downloading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_rounded, size: 15),
      label: Text(
        _downloading ? 'Menyiapkan...' : 'Unduh PDF',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.violet,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
