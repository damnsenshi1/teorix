import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'app_settings_service.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _timeZonesInitialized = false;

  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl,
        'de' => de,
        'en' => en,
        _ => tr,
      };

  void _configureTimezone() {
    if (!_timeZonesInitialized) {
      tz.initializeTimeZones();
      _timeZonesInitialized = true;
    }
    final zone = switch (AppSettingsService.instance.countryId) {
      'nl' => 'Europe/Amsterdam',
      'de' => 'Europe/Berlin',
      'gb' => 'Europe/London',
      'us_ca' => 'America/Los_Angeles',
      _ => 'Europe/Istanbul',
    };
    try { tz.setLocalLocation(tz.getLocation(zone)); } catch (_) {}
  }

  Future<void> initialize() async {
    if (kIsWeb) return;
    _configureTimezone();
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin, macOS: darwin);
    try { await _plugin.initialize(settings); } catch (_) {}
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      return true;
    } catch (_) { return false; }
  }

  NotificationDetails _details() => NotificationDetails(
        android: AndroidNotificationDetails(
          'teorix_study',
          _t('Çalışma Hatırlatıcıları','Studieherinneringen','Lernerinnerungen','Study Reminders'),
          channelDescription: _t('TeoriX çalışma ve sınav hatırlatıcıları','TeoriX studie- en examenherinneringen','TeoriX Lern- und Prüfungserinnerungen','TeoriX study and test reminders'),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> showTest() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.show(
      9001,
      _t('TeoriX hazır 🔥','TeoriX is klaar 🔥','TeoriX ist bereit 🔥','TeoriX is ready 🔥'),
      _t('Hatırlatıcıların çalışıyor. Bugünkü hedeften birkaç soru çözelim.','Je herinneringen werken. Doe een paar vragen van je dagdoel.','Deine Erinnerungen funktionieren. Löse ein paar Fragen für dein Tagesziel.','Your reminders are working. Solve a few questions toward today’s goal.'),
      _details(),
    );
  }

  Future<void> scheduleDaily({required int hour, required int minute}) async {
    if (kIsWeb) return;
    await initialize();
    _configureTimezone();
    await _plugin.cancel(7001);
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      7001,
      _t('Bugünkü TeoriX hedefin seni bekliyor','Je TeoriX-doel van vandaag wacht','Dein heutiges TeoriX-Ziel wartet','Your TeoriX goal is waiting'),
      _t('Kısa bir çalışma bile serini korur. Hadi birkaç soru çözelim.','Zelfs een korte sessie houdt je reeks vast. Tijd voor een paar vragen.','Schon eine kurze Einheit hält deine Serie. Zeit für ein paar Fragen.','Even a short session keeps your streak alive. Let’s solve a few questions.'),
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(7001);
  }
  NotificationDetails _updateDetails() => NotificationDetails(
        android: AndroidNotificationDetails(
          'teorix_updates',
          _t('Uygulama Güncellemeleri','App-updates','App-Updates','App Updates'),
          channelDescription: _t('TeoriX yeni sürüm ve indirme bildirimleri','TeoriX meldingen voor nieuwe versies','TeoriX Benachrichtigungen für neue Versionen','TeoriX new version and download notifications'),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> showUpdateAvailable(String version, String notes) async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.show(8101, _t('TeoriX $version hazır','TeoriX $version is klaar','TeoriX $version ist verfügbar','TeoriX $version is ready'), notes.trim().isEmpty ? _t('Yeni sürüm indirilmeye hazır.','Nieuwe versie is klaar om te downloaden.','Neue Version ist zum Download bereit.','A new version is ready to download.') : notes, _updateDetails());
  }

  Future<void> showUpdateDownloaded(String version) async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.show(8102, _t('Güncelleme indirildi','Update gedownload','Update heruntergeladen','Update downloaded'), _t('TeoriX $version indirildi. Ayarlar > Uygulama Güncellemeleri bölümünden kurulumu tamamla.','TeoriX $version is gedownload. Voltooi de installatie via Instellingen > App-updates.','TeoriX $version wurde heruntergeladen. Schließe die Installation unter Einstellungen > App-Updates ab.','TeoriX $version downloaded. Finish installation in Settings > App Updates.'), _updateDetails());
  }

}
