import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/transaction_record.dart';
import '../../services/api_service.dart';
import '../../services/supabase_api.dart';
import '../../widgets/event_card.dart' show formatRp;

/// Riwayat transaksi user, dibaca dari tabel `transactions`.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key, this.api});

  /// Diisi pada test supaya tidak menyentuh Supabase.
  final EventKuyApi? api;

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<TransactionRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TransactionRecord>> _load() {
    final api = widget.api ?? SupabaseApi();
    return api.fetchTransactions();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    try {
      await _future;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: FutureBuilder<List<TransactionRecord>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _ErrorState(onRetry: _refresh);
                }

                final transactions =
                    snapshot.data ?? const <TransactionRecord>[];
                if (transactions.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      key: const ValueKey('transaction-empty'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 110, 24, 32),
                      children: const [_EmptyState()],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    key: const ValueKey('transaction-list'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _TransactionCard(transaction: transactions[index]),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final TransactionRecord transaction;

  @override
  Widget build(BuildContext context) {
    final title = transaction.eventTitle.trim().isEmpty
        ? 'Transaksi EventKuy'
        : transaction.eventTitle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.violetSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.violet,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                    height: 1.35,
                  ),
                ),
                if (transaction.ticketCode.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.ticketCode,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${transaction.paymentMethod} · '
                  '${_formatDateTime(transaction.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textFaint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRp(transaction.total.round()),
                style: const TextStyle(
                  fontFamily: AppTheme.headingFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              _StatusChip(status: transaction.status),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    try {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('d MMM yyyy, HH:mm').format(date);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final (label, color, background) = switch (normalized) {
      'paid' => ('Berhasil', AppTheme.green, AppTheme.greenSoft),
      'pending' => ('Menunggu', AppTheme.amber, AppTheme.amberSoft),
      'failed' => ('Gagal', AppTheme.red, AppTheme.redSoft),
      'refunded' => ('Dikembalikan', AppTheme.red, AppTheme.redSoft),
      _ => (status, AppTheme.muted, AppTheme.fieldBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppTheme.violetSoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: AppTheme.violet,
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Belum ada transaksi',
          style: TextStyle(
            fontFamily: AppTheme.headingFont,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Transaksi akan muncul di sini setelah kamu membeli tiket event.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.6, color: AppTheme.muted),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.textFaint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat riwayat transaksi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Periksa koneksi internet lalu coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
