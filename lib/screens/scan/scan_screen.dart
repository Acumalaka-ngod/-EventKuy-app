import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../models/check_in_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

/// Layar Scan QR Check-in (Mode Petugas).
///
/// Memakai kamera asli lewat [MobileScanner] dan RPC `check_in_ticket`.
/// Kode tiket juga bisa dimasukkan manual sebagai fallback ketika kamera
/// tidak tersedia atau izin kamera ditolak.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.enableCamera = true});

  /// Dimatikan pada widget test karena platform kamera tidak tersedia.
  final bool enableCamera;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double _frameSize = 260;

  late final AnimationController _scanController;
  MobileScannerController? _cameraController;

  bool _flashOn = false;
  bool _processing = false;
  bool _manualDialogOpen = false;
  String? _lastScannedCode;
  DateTime? _lastScanAt;
  CheckInResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    if (widget.enableCamera) {
      _cameraController = MobileScannerController(
        facing: CameraFacing.back,
        detectionSpeed: DetectionSpeed.normal,
        torchEnabled: false,
      );
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (widget.enableCamera) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _scanController.dispose();
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_startCamera(controller));
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_stopCamera(controller));
    }
  }

  Future<void> _startCamera(MobileScannerController controller) async {
    try {
      if (!controller.value.isRunning) await controller.start();
    } catch (_) {
      // Error kamera ditampilkan oleh `errorBuilder` pada widget MobileScanner.
    }
  }

  Future<void> _stopCamera(MobileScannerController controller) async {
    try {
      await controller.stop();
    } catch (_) {
      // Abaikan kegagalan saat aplikasi masuk background.
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null) return;

    try {
      if (!controller.value.isRunning) {
        _showSnackBar('Kamera belum siap. Coba beberapa saat lagi.');
        return;
      }
      await controller.toggleTorch();
      if (!mounted) return;
      setState(() => _flashOn = !_flashOn);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Senter tidak tersedia pada perangkat ini.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onDetect(BarcodeCapture capture) {
    if (!widget.enableCamera || _processing || _manualDialogOpen) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim() ?? '';
      if (raw.isEmpty) continue;

      final code = _normalizeCode(raw);
      if (code.isEmpty) continue;

      // Cegah pembacaan berulang dari QR yang sama dalam waktu singkat.
      final now = DateTime.now();
      if (code == _lastScannedCode &&
          _lastScanAt != null &&
          now.difference(_lastScanAt!) < const Duration(seconds: 3)) {
        return;
      }
      _lastScannedCode = code;
      _lastScanAt = now;
      unawaited(_processCode(code));
      return;
    }
  }

  /// QR EventKuy berisi kode tiket. URL e-tiket juga didukung apabila
  /// formatnya `.../ticket/KODE`.
  String _normalizeCode(String raw) {
    var text = raw.trim();
    if (text.isEmpty || text.length > 120) return '';

    final uri = Uri.tryParse(text);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.pathSegments.isNotEmpty) {
      final segments = uri.pathSegments;
      final ticketIndex =
          segments.indexWhere((segment) => segment.toLowerCase() == 'ticket');
      if (ticketIndex >= 0 && ticketIndex + 1 < segments.length) {
        text = segments[ticketIndex + 1];
      } else {
        text = segments.last;
      }
    }

    return text.trim().toUpperCase();
  }

  Future<void> _processCode(String code) async {
    if (_processing) return;

    final provider = context.read<TicketProvider>();
    setState(() => _processing = true);

    try {
      final result = await provider.checkIn(code);
      if (!mounted) return;
      setState(() => _lastResult = result);
      await _showSuccessDialog(result);
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog(
        title: 'Check-in Gagal',
        message: friendlyError(error),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _openManualInput() async {
    var input = '';
    setState(() => _manualDialogOpen = true);

    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Masukkan Kode Tiket'),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onChanged: (value) => input = value,
          onSubmitted: (value) => Navigator.pop(ctx, value),
          decoration: InputDecoration(
            hintText: 'Contoh: EVK-ABC123',
            helperText: 'Kode tertera di bawah QR e-tiket peserta.',
            filled: true,
            fillColor: AppTheme.fieldBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, input),
            child: const Text('Check-in'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    setState(() => _manualDialogOpen = false);

    final normalized = _normalizeCode(code ?? '');
    if (normalized.isEmpty) return;
    await _processCode(normalized);
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(CheckInResult result) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.accentEmerald,
                size: 36,
              ),
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
              result.eventTitle.isEmpty
                  ? result.code
                  : '${result.eventTitle}\n${result.code}',
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
                child: const Text('Scan Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    if (authUser != null && !authUser.isOrganizer) {
      return Scaffold(
        backgroundColor: AppTheme.canvas,
        appBar: AppBar(title: const Text('Akses ditolak')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Halaman ini hanya untuk akun organizer.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final compact = MediaQuery.sizeOf(context).height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      children: [
                        _buildTopBar(),
                        SizedBox(height: compact ? 16 : 26),
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
                          padding: EdgeInsets.symmetric(horizontal: 28),
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
                        SizedBox(height: compact ? 20 : 34),
                        _buildScanner(),
                        const SizedBox(height: 12),
                        Text(
                          'Posisikan QR di dalam kotak',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextButton.icon(
                          onPressed: _openManualInput,
                          icon: const Icon(Icons.keyboard_rounded, size: 17),
                          label: const Text('Masukkan Kode Manual'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFB9B5FF),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 20),
                        _buildStatusCard(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _circleAction(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
          tooltip: 'Kembali',
        ),
        _circleAction(
          icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          onTap: _toggleFlash,
          tooltip: _flashOn ? 'Matikan senter' : 'Nyalakan senter',
          active: _flashOn,
        ),
      ],
    );
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: active ? AppTheme.accentAmber : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanner() {
    final controller = _cameraController;

    return Center(
      child: SizedBox(
        width: _frameSize,
        height: _frameSize,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF151925)),
              if (controller != null)
                MobileScanner(
                  controller: controller,
                  fit: BoxFit.cover,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => const _CameraError(),
                )
              else
                const _CameraPlaceholder(),
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) {
                  final top = _scanController.value * (_frameSize - 3);
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
              IgnorePointer(
                child: CustomPaint(painter: _CornerPainter()),
              ),
              if (_processing)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Memproses check-in…',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final result = _lastResult;
    final hasResult = result != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181C28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (hasResult ? AppTheme.green : AppTheme.violet)
                  .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasResult
                  ? Icons.verified_rounded
                  : Icons.qr_code_scanner_rounded,
              color: hasResult ? AppTheme.green : const Color(0xFF9B94FF),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasResult
                      ? (result.eventTitle.isEmpty
                          ? 'Check-in berhasil'
                          : result.eventTitle)
                      : 'Mode Petugas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasResult
                      ? '${result.code} · tercatat'
                      : 'Masuk dengan akun organizer pemilik event. '
                          'Setiap check-in tersimpan ke Supabase.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF151925),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_rounded, color: Colors.white38, size: 34),
            SizedBox(height: 10),
            Text(
              'Kamera nonaktif',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF151925),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 34),
              SizedBox(height: 10),
              Text(
                'Kamera tidak dapat dibuka',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Periksa izin kamera atau masukkan kode tiket manual.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 10.5),
              ),
            ],
          ),
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
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(len, 0),
      paint,
    );
    // Kanan atas
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
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
