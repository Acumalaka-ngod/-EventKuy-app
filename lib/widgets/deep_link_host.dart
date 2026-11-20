import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/deep_link.dart';
import '../core/notification_router.dart';
import '../providers/deep_link_provider.dart';

/// Host inisialisasi deep link dan pengerahan event ID ke Detail Event.
///
/// - Native: memakai [app_links] untuk custom scheme `eventkuy`.
/// - Web: memakai `Uri.base` untuk route hash `/#/event/<id>`.
///
/// Child biasanya adalah [MainNavigation].
class DeepLinkHost extends StatefulWidget {
  final Widget child;

  const DeepLinkHost({super.key, required this.child});

  @override
  State<DeepLinkHost> createState() => _DeepLinkHostState();
}

class _DeepLinkHostState extends State<DeepLinkHost> {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _initialLink;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    NotificationRouter.setHandler(_handleNotificationUri);
    _initDeepLink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _handleInitialLink();
    }
  }

  @override
  void dispose() {
    NotificationRouter.clearHandler();
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// Ketukan notifikasi push diteruskan ke antrean deep link yang sama
  /// dengan tautan `eventkuy://event/<id>`.
  void _handleNotificationUri(String uri) {
    try {
      context.read<DeepLinkProvider>().handleUri(uri);
    } catch (_) {
      // Provider belum terdaftar (mis. dalam beberapa widget test).
    }
  }

  Future<void> _initDeepLink() async {
    _appLinks = AppLinks();

    // Handle initial link (aplikasi dibuka melalui deep link).
    try {
      final initialLink = await _appLinks!.getInitialLink();
      if (initialLink != null) {
        _initialLink = initialLink.toString();
      }
    } catch (_) {
      // Abaikan: platform tidak mendukung initial link.
    }

    // Handle link saat aplikasi sudah berjalan (foreground).
    _linkSubscription = _appLinks!.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (_) {},
    );

    if (mounted) setState(() {});
  }

  void _handleInitialLink() {
    if (_initialLink != null) {
      final provider =
          context.read<DeepLinkProvider>();
      provider.handleUri(_initialLink?.toString());
    }

    // Web: baca dari Uri.base hash.
    // Uri.base hanya tersedia pada platform web.
    try {
      final webUri = Uri.base;
      if (DeepLink.isEventLink(webUri.toString())) {
        context.read<DeepLinkProvider>().handleUri(webUri.toString());
      }
    } catch (_) {
      // Bukan web, abaikan.
    }
  }

  void _handleUri(Uri uri) {
    final provider = context.read<DeepLinkProvider>();
    provider.handleUri(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
