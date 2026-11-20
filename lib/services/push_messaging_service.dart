import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/notification_router.dart';
import 'push_notification_payload.dart';
import 'supabase_api.dart';

/// Handler pesan saat aplikasi tidak aktif.
///
/// Edge Function mengirim field `notification`, sehingga sistem Android
/// menampilkan notifikasi walau isolate Dart belum berjalan. Handler ini
/// hanya dipakai untuk pesan data-only dan logging.
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}

/// Abstraksi layanan push messaging EventKuy.
abstract class PushMessagingService {
  PushMessagingService._();

  /// Inisialisasi push messaging. Implementasi dasar tidak melakukan apa-apa.
  Future<void> initialize() async {}

  /// Minta izin notifikasi dari user.
  Future<bool> requestPermission() async => false;

  /// Dapatkan token push perangkat.
  Future<String?> getToken() async => null;

  /// Simpan token perangkat tanpa memunculkan dialog izin.
  Future<void> syncToken() async {}

  /// Hapus token perangkat saat pengguna logout.
  Future<void> clearToken() async {}

  /// Apakah push messaging tersedia (FCM aktif)?
  bool get isAvailable => false;

  /// Implementasi aktif sesuai platform dan status inisialisasi Firebase.
  static PushMessagingService get instance {
    if (kIsWeb) return UnavailablePushMessagingService.instance;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
      default:
        return UnavailablePushMessagingService.instance;
    }
    if (Firebase.apps.isEmpty) {
      return UnavailablePushMessagingService.instance;
    }
    return FirebasePushMessagingService.instance;
  }
}

/// Implementasi no-op — dipakai saat Firebase belum dikonfigurasi.
class UnavailablePushMessagingService extends PushMessagingService {
  UnavailablePushMessagingService._() : super._();
  static final UnavailablePushMessagingService instance =
      UnavailablePushMessagingService._();
}

/// Implementasi Firebase Cloud Messaging.
///
/// Token perangkat disimpan ke tabel `device_tokens` lewat [SupabaseApi]
/// setelah pengguna login. Panggil [initialize] setelah
/// `Firebase.initializeApp()` berhasil.
///
/// Saat aplikasi aktif, pesan FCM ditampilkan ulang lewat
/// `flutter_local_notifications` karena FCM tidak menampilkan notifikasi
/// secara otomatis di foreground. Ketukan notifikasi diteruskan ke
/// [NotificationRouter] sehingga sampai ke halaman Detail Event.
class FirebasePushMessagingService extends PushMessagingService {
  FirebasePushMessagingService._() : super._();
  static final FirebasePushMessagingService instance =
      FirebasePushMessagingService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'eventkuy_push',
    'Notifikasi EventKuy',
    description: 'Info tiket, pesanan, dan event terbaru.',
    importance: Importance.max,
  );

  bool _available = false;
  bool _localReady = false;
  String? _token;

  @override
  bool get isAvailable => _available;

  @override
  Future<void> initialize() async {
    // FCM web butuh VAPID key dan service worker terpisah; belum disiapkan.
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _token = token;
        registerToken();
      });

      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_routeOpenedMessage);

      await _initLocalNotifications();

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _routeOpenedMessage(initial);

      _available = true;
    } catch (error) {
      _available = false;
      debugPrint('FCM belum tersedia: $error');
    }
  }

  Future<void> _initLocalNotifications() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }

    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsDarwin = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          NotificationRouter.routeToEvent(payload);
        }
      },
    );

    // Callback di atas hanya dipanggil saat aplikasi sudah berjalan. Bila
    // notifikasi lokal yang membuka aplikasi dari kondisi terminated, baca
    // detail peluncuran secara eksplisit.
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchPayload != null && launchPayload.isNotEmpty) {
      NotificationRouter.routeToEvent(launchPayload);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }
    _localReady = true;
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    if (!_localReady) return;
    final payload = PushNotificationPayload.fromRemoteMessage(message);
    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: payload.title,
        body: payload.body,
        payload: payload.eventId,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Gagal menampilkan notifikasi foreground: $error');
    }
  }

  void _routeOpenedMessage(RemoteMessage message) {
    final payload = PushNotificationPayload.fromRemoteMessage(message);
    NotificationRouter.routeToEvent(payload.eventId);
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = settings.authorizationStatus;
      final granted =
          status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
      if (granted) {
        await registerToken();
      }
      return granted;
    } catch (error) {
      debugPrint('Gagal meminta izin notifikasi: $error');
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      _token ??= await FirebaseMessaging.instance.getToken();
      return _token;
    } catch (error) {
      debugPrint('Gagal mendapatkan token FCM: $error');
      return null;
    }
  }

  @override
  Future<void> syncToken() => registerToken();

  @override
  Future<void> clearToken() async {
    final token = await getToken();
    if (token != null) {
      try {
        await SupabaseApi().unregisterDeviceToken(token: token);
      } catch (error) {
        debugPrint('Gagal menghapus token FCM: $error');
      }
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
      _token = null;
    } catch (error) {
      debugPrint('Gagal menghapus token Firebase: $error');
    }
  }

  /// Simpan token perangkat ke Supabase untuk pengguna yang sedang login.
  Future<void> registerToken() async {
    final token = await getToken();
    if (token == null) return;
    try {
      await SupabaseApi().registerDeviceToken(
        token: token,
        platform: _platform,
      );
    } catch (error) {
      debugPrint('Gagal menyimpan token FCM: $error');
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name.toLowerCase();
  }
}
