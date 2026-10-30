import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/checkout_result.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/event_card.dart';
import '../../widgets/event_image.dart';
import '../../widgets/payment_option.dart';
import '../main_navigation.dart';

/// Layar Checkout & Pembayaran — ringkasan event, form pemesan,
/// metode pembayaran, voucher, total, dan modal sukses.
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
  int _qty = 1;
  int _discount = 0;
  String? _voucherMessage;
  bool _voucherValid = false;
  String? _appliedVoucher;
  final int _adminFee = 2500;

  /// Sisa tiket; `null` berarti kuota tidak dibatasi.
  int? get _maxQty => widget.event.available;

  bool get _soldOut => widget.event.isSoldOut;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.name ?? 'Andi Pratama');
    _email = TextEditingController(text: user?.email ?? 'andi@eventkuy.id');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _changeQty(int delta) {
    final max = _maxQty;
    final next = _qty + delta;
    if (next < 1) return;
    if (max != null && next > max) return;
    setState(() => _qty = next);
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _discount = 0;
        _voucherValid = false;
        _appliedVoucher = null;
        _voucherMessage = 'Masukkan kode voucher terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _voucherMessage = 'Memeriksa voucher...';
      _voucherValid = false;
      _appliedVoucher = null;
      _discount = 0;
    });

    try {
      final tickets = context.read<TicketProvider>();
      final voucher = await tickets.fetchVoucher(code);
      if (!mounted) return;

      if (voucher == null) {
        setState(() {
          _voucherMessage = 'Kode voucher tidak valid atau kedaluwarsa';
        });
        return;
      }

      // Voucher hanya boleh dipakai satu kali oleh user yang sama.
      final used = await tickets.fetchUsedVoucherCodes();
      if (!mounted) return;

      setState(() {
        if (used.contains(voucher.code.toUpperCase())) {
          _voucherMessage =
              'Voucher ${voucher.code} sudah pernah kamu pakai. Satu voucher '
              'hanya bisa dipakai sekali.';
        } else {
          _discount = voucher.discount;
          _voucherValid = true;
          _appliedVoucher = voucher.code;
          _voucherMessage =
              'Voucher aktif — diskon ${formatRp(voucher.discount)}';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _voucherMessage = friendlyError(error);
      });
    }
  }

  Future<void> _processPayment() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi nama dan email pemesan terlebih dahulu.'),
        ),
      );
      return;
    }

    if (_soldOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket event ini sudah habis.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await context.read<TicketProvider>().checkout(
            widget.event,
            qty: _qty,
            voucherCode: _voucherValid ? _appliedVoucher : null,
            paymentMethod: _method,
          );

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSuccess(result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(error))),
      );
    }
  }

  void _showSuccess(CheckoutResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: 430,
          padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppTheme.green,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x401AA981),
                      blurRadius: 30,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 42),
              ),
              const SizedBox(height: 22),
              const Text(
                'PEMBAYARAN TERKONFIRMASI',
                style: TextStyle(
                  color: AppTheme.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Pembayaran Berhasil!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.headingFont,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.qty > 1
                    ? '${result.qty} e-tiket untuk ${widget.event.title} sudah diterbitkan dan dikirim ke email kamu.'
                    : 'E-tiket untuk ${widget.event.title} sudah diterbitkan dan dikirim ke email kamu.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.muted,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppTheme.violetSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.confirmation_number_rounded,
                          color: AppTheme.violet, size: 20),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TICKET ID',
                            style: TextStyle(
                              color: AppTheme.violet,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            result.qty > 1
                                ? '${result.ticket.code} (+${result.qty - 1} lainnya)'
                                : result.ticket.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: 'Lihat Tiket Saya',
                icon: Icons.arrow_forward_rounded,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.event.price * _qty;
    final adminFee = _adminFee * _qty;
    final total =
        (subtotal + adminFee - _discount).clamp(0, double.infinity).toInt();

    final leftColumn = <Widget>[
      _buildSummaryCard(),
      const SizedBox(height: 18),
      _buildQtyCard(),
      const SizedBox(height: 18),
      _buildBuyerCard(),
      const SizedBox(height: 18),
      _buildPaymentCard(),
      const SizedBox(height: 18),
      _buildVoucherCard(),
    ];

    final rightColumn = <Widget>[
      _buildTotalCard(subtotal, adminFee, total),
    ];

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final twoColumns = w >= Breakpoints.mobile;

            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      contentPadding(w),
                      twoColumns ? 30 : 24,
                      contentPadding(w),
                      30,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          children: [
                                                        Text(
                              'Checkout & Pembayaran',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.headingFont,
                                fontSize: twoColumns ? 34 : 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.1,
                                color: AppTheme.ink,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildSteps(),
                            const SizedBox(height: 26),
                            if (twoColumns)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 145,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: leftColumn,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 75,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: rightColumn,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...leftColumn,
                                  const SizedBox(height: 18),
                                  ...rightColumn,
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppTheme.ink, size: 20),
            ),
          ),
          const Expanded(
            child: Center(
              child: EventKuyLogo(markSize: 26, fontSize: 15),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildSteps() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Row(
        children: [
          _stepCircle(number: '1', label: 'Pilih', done: true),
          const Expanded(child: _DashedLine()),
          _stepCircle(number: '2', label: 'Bayar', active: true),
          const Expanded(child: _DashedLine()),
          _stepCircle(number: '3', label: 'E-Tiket'),
        ],
      ),
    );
  }

  Widget _stepCircle({
    required String number,
    required String label,
    bool done = false,
    bool active = false,
  }) {
    final color = done
        ? AppTheme.green
        : active
            ? AppTheme.violet
            : Colors.white;
    final textColor = done || active ? Colors.white : AppTheme.textFaint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: done
                  ? AppTheme.green
                  : active
                      ? AppTheme.violet
                      : AppTheme.border,
            ),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
              : Text(
                  number,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: active
                ? AppTheme.violet
                : done
                    ? AppTheme.green
                    : AppTheme.textFaint,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          EventImage(
            imageUrl: widget.event.imageUrl,
            eventId: widget.event.id,
            height: 86,
            width: 116,
            borderRadius: BorderRadius.circular(13),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.category.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.violet,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.ink,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${formatTanggalSingkat(widget.event.date)} · $_qty× Regular Pass',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pemilih jumlah tiket + info sisa stok.
  Widget _buildQtyCard() {
    final max = _maxQty;
    final soldOut = _soldOut;
    final canAdd = !soldOut && (max == null || _qty < max);

    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jumlah Tiket',
                  style: TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  soldOut
                      ? 'Tiket habis — tidak bisa dibeli'
                      : max == null
                          ? 'Stok tersedia'
                          : 'Sisa $max tiket',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: soldOut ? AppTheme.red : AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          _qtyButton(
            icon: Icons.remove_rounded,
            onTap: soldOut || _qty <= 1 ? null : () => _changeQty(-1),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$_qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
          ),
          _qtyButton(
            icon: Icons.add_rounded,
            onTap: canAdd ? () => _changeQty(1) : null,
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : AppTheme.canvas,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppTheme.ink : AppTheme.textFaint,
        ),
      ),
    );
  }

  Widget _buildBuyerCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pemesan',
            style: TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 520;
              final nameField = _field(
                label: 'Nama Lengkap',
                controller: _name,
                hint: 'Andi Pratama',
              );
              final emailField = _field(
                label: 'Email Konfirmasi Tiket',
                controller: _email,
                hint: 'nama@email.com',
                keyboardType: TextInputType.emailAddress,
              );
              final phoneField = _field(
                label: 'Nomor WhatsApp / HP',
                controller: _phone,
                hint: '0812 3456 7890',
                keyboardType: TextInputType.phone,
              );

              if (!wide) {
                return Column(
                  children: [
                    nameField,
                    const SizedBox(height: 16),
                    emailField,
                    const SizedBox(height: 16),
                    phoneField,
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: nameField),
                      const SizedBox(width: 16),
                      Expanded(child: emailField),
                    ],
                  ),
                  const SizedBox(height: 16),
                  phoneField,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Metode Pembayaran',
            style: TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 18),
          PaymentOption(
            label: 'GoPay',
            subtitle: 'Saldo & QRIS instan',
            avatar: 'G',
            selected: _method == 'GoPay',
            onTap: () => setState(() => _method = 'GoPay'),
          ),
          PaymentOption(
            label: 'Virtual Account',
            subtitle: 'BCA · BNI · Mandiri',
            avatar: 'V',
            selected: _method == 'Virtual Account',
            onTap: () => setState(() => _method = 'Virtual Account'),
          ),
          PaymentOption(
            label: 'Kartu Kredit / Debit',
            subtitle: 'Visa · Mastercard',
            avatar: 'K',
            selected: _method == 'Kartu',
            onTap: () => setState(() => _method = 'Kartu'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voucher Promo',
            style: TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Punya voucher? Cth: EVENTKUY',
                  ),
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 96,
                child: OutlinedButton(
                  onPressed: _applyPromo,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(96, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Pakai'),
                ),
              ),
            ],
          ),
          if (_voucherMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _voucherMessage!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _voucherValid ? AppTheme.green : AppTheme.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalCard(int subtotal, int adminFee, int total) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 16),
          _feeRow('Harga Tiket (${_qty}x)', formatRp(subtotal)),
          const SizedBox(height: 10),
          _feeRow('Biaya Layanan (${_qty}x)', formatRp(adminFee)),
          if (_discount > 0) ...[
            const SizedBox(height: 10),
            _feeRow(
              'Diskon Voucher',
              '-${formatRp(_discount)}',
              color: AppTheme.green,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: _DashedLine(),
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 4,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.ink,
                ),
              ),
              Text(
                formatRp(total),
                style: const TextStyle(
                  fontFamily: AppTheme.headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppTheme.violetDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: AppTheme.greenSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded,
                    size: 13, color: AppTheme.green),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Pembayaran 100% aman & terenkripsi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.green,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            label: _soldOut
                ? 'Tiket Habis'
                : 'Bayar Sekarang · ${formatRp(total)}',
            loading: _isProcessing,
            onPressed: _soldOut ? null : _processPayment,
          ),
          const SizedBox(height: 12),
          const Text(
            'Dengan melanjutkan, kamu menyetujui ketentuan pembayaran EventKuy. E-tiket dikirim ke email konfirmasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 9,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }

  Widget _feeRow(String label, String value, {Color? color}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? AppTheme.ink,
          ),
        ),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: CustomPaint(
        painter: _DashedLinePainter(),
        child: const SizedBox(width: double.infinity),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD5D3DF)
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 5.0;
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
