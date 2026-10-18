import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/event_card.dart';
import '../../widgets/event_image.dart';
import '../../widgets/payment_option.dart';
import '../main_navigation.dart';

/// Layar Pendaftaran & Pembayaran — sesuai desain baru:
/// ringkasan event, Data Peserta, Metode Pembayaran (radio),
/// total pembayaran, tombol "Bayar Sekarang".
class CheckoutScreen extends StatefulWidget {
  final Event event;
  const CheckoutScreen({super.key, required this.event});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _phone = TextEditingController(text: '0812 3456 7890');
  final _promoController = TextEditingController();

  String _method = 'GoPay';
  bool _isProcessing = false;
  int _discount = 0;
  final int _adminFee = 2500;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.name ?? 'Andi Pratama');
    _email = TextEditingController(text: user?.email ?? 'andi@ajangin.id');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code == 'AJANGSERU' || code == 'DISKON10') {
      setState(() => _discount = 25000);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voucher berhasil digunakan! Diskon Rp 25.000'),
          backgroundColor: AppTheme.accentEmerald,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode voucher tidak valid atau kedaluwarsa'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() => _isProcessing = false);

    context.read<TicketProvider>().buyDummy(widget.event);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.accentEmerald.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.accentEmerald,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pembayaran Berhasil!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'E-tiket untuk ${widget.event.title} telah diterbitkan dan tersimpan di menu Tiket Saya.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            CustomButton(
              label: 'Lihat Tiket Saya',
              icon: Icons.confirmation_number_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainNavigation(initialIndex: 2),
                  ),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.event.price;
    final total =
        (subtotal + _adminFee - _discount).clamp(0, double.infinity).toInt();

    final leftColumn = <Widget>[
      _buildSummaryCard(),
      const SizedBox(height: 22),
      _buildSectionTitle('Data Peserta'),
      const SizedBox(height: 10),
      _buildAttendeeForm(),
      const SizedBox(height: 22),
      _buildSectionTitle('Metode Pembayaran'),
      const SizedBox(height: 10),
      PaymentOption(
        label: 'GoPay',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFF00AED6),
        selected: _method == 'GoPay',
        onTap: () => setState(() => _method = 'GoPay'),
      ),
      PaymentOption(
        label: 'Virtual Account',
        icon: Icons.account_balance_rounded,
        iconColor: AppTheme.primary,
        selected: _method == 'Virtual Account',
        onTap: () => setState(() => _method = 'Virtual Account'),
      ),
      PaymentOption(
        label: 'Kartu Kredit / Debit',
        icon: Icons.credit_card_rounded,
        iconColor: const Color(0xFFF59E0B),
        selected: _method == 'Kartu',
        onTap: () => setState(() => _method = 'Kartu'),
      ),
      const SizedBox(height: 8),
      _buildVoucherCard(),
    ];

    final rightColumn = <Widget>[
      _buildFeeCard(subtotal, total),
      const SizedBox(height: 16),
      _buildTrustBadge(),
      const SizedBox(height: 14),
      _buildPayButton(total),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Daftar Event'),
        leading: const BackButton(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          // Desktop/Tablet lebar: 2 kolom
          if (w >= Breakpoints.tablet) {
            return ConstrainedContent(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: contentPadding(w),
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: leftColumn,
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: rightColumn,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Mobile & tablet kecil: 1 kolom
          return ConstrainedContent(
            maxWidth: 760,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding(w),
                vertical: 12,
              ),
              children: [
                ...leftColumn,
                const SizedBox(height: 22),
                ...rightColumn,
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        color: AppTheme.textDark,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          EventImage(
            imageUrl: widget.event.imageUrl,
            eventId: widget.event.id,
            height: 64,
            width: 64,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatTanggal(widget.event.date)} • ${cityOf(widget.event.location)}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRp(widget.event.price),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeForm() {
    return Column(
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Nama Lengkap'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _email,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Nomor HP'),
        ),
      ],
    );
  }

  Widget _buildVoucherCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.field,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined,
              color: AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _promoController,
              textCapitalization: TextCapitalization.characters,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Punya voucher? Cth: AJANGSERU',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          TextButton(
            onPressed: _applyPromo,
            child: const Text(
              'Pakai',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(int subtotal, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Biaya',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildFeeRow('Harga Tiket (1x)', formatRp(subtotal)),
          const SizedBox(height: 8),
          _buildFeeRow('Biaya Layanan', formatRp(_adminFee)),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            _buildFeeRow('Diskon Voucher', '-${formatRp(_discount)}',
                color: AppTheme.accentEmerald),
          ],
          const Divider(height: 26),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Pembayaran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatRp(total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, size: 13, color: AppTheme.textGrey),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Pembayaran 100% aman & terenkripsi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppTheme.textGrey, fontSize: 11.5),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton(int total) {
    return CustomButton(
      label: 'Bayar Sekarang',
      loading: _isProcessing,
      onPressed: _processPayment,
    );
  }

  Widget _buildFeeRow(String label, String value, {Color? color}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
