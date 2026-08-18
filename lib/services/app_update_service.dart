import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_settings_service.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class AppRelease {
  final String versionName;
  final int versionCode;
  final String title;
  final String notes;
  final String? apkUrl;
  final String? storeUrl;
  final String delivery;
  final bool mandatory;
  const AppRelease({required this.versionName, required this.versionCode, required this.title, required this.notes, this.apkUrl, this.storeUrl, required this.delivery, required this.mandatory});

  factory AppRelease.fromMap(Map<String, dynamic> m) => AppRelease(
    versionName: (m['version_name'] ?? '').toString(),
    versionCode: int.tryParse('${m['version_code']}') ?? 0,
    title: (m['title'] ?? 'Yeni sürüm hazır').toString(),
    notes: (m['notes'] ?? '').toString(),
    apkUrl: m['apk_url']?.toString(),
    storeUrl: m['store_url']?.toString(),
    delivery: (m['delivery'] ?? 'direct').toString(),
    mandatory: m['mandatory'] == true,
  );
}

class AppUpdateService extends ChangeNotifier {
  AppUpdateService._();
  static final instance = AppUpdateService._();
  static const _autoKey = 'update_auto_download_v1';
  static const _wifiKey = 'update_wifi_only_v1';
  static const _lastCheckKey = 'update_last_check_v1';
  static const _channel = MethodChannel('com.senshilabs.teorix/app_update');

  bool autoDownload = false;
  bool wifiOnly = false;
  bool checking = false;
  bool downloading = false;
  double progress = 0;
  String currentVersion = '';
  int currentBuild = 0;
  DateTime? lastCheck;
  AppRelease? available;
  String? error;

  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) { 'nl' => nl, 'de' => de, 'en' => en, _ => tr };

  Future<void> initialize({bool checkOnStart = true}) async {
    final prefs = await SharedPreferences.getInstance();
    autoDownload = prefs.getBool(_autoKey) ?? false;
    wifiOnly = prefs.getBool(_wifiKey) ?? false;
    final stamp = prefs.getInt(_lastCheckKey);
    if (stamp != null) lastCheck = DateTime.fromMillisecondsSinceEpoch(stamp);
    try {
      final info = await PackageInfo.fromPlatform();
      currentVersion = info.version;
      currentBuild = int.tryParse(info.buildNumber) ?? 0;
    } catch (_) {}
    notifyListeners();
    if (checkOnStart && !kIsWeb) {
      unawaited(Future<void>.delayed(const Duration(seconds: 4), () => checkForUpdates(background: true)));
    }
  }

  Future<void> setAutoDownload(bool value) async {
    autoDownload = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoKey, value);
    notifyListeners();
  }

  Future<void> setWifiOnly(bool value) async {
    wifiOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiKey, value);
    notifyListeners();
  }

  Future<AppRelease?> checkForUpdates({bool background = false}) async {
    if (kIsWeb || checking) return available;
    final client = SupabaseService.client;
    if (client == null) {
      if (!background) error = _t('Güncelleme sunucusuna bağlanılamadı.','Kan updateserver niet bereiken.','Updateserver nicht erreichbar.','Could not reach update server.');
      notifyListeners();
      return null;
    }
    checking = true; error = null; notifyListeners();
    try {
      final data = await client.from('app_releases').select().eq('platform','android').eq('channel','stable').eq('active',true).order('version_code', ascending:false).limit(1).maybeSingle();
      lastCheck = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, lastCheck!.millisecondsSinceEpoch);
      available = data == null ? null : AppRelease.fromMap(Map<String,dynamic>.from(data));
      if (available != null && available!.versionCode <= currentBuild) available = null;
      if (available != null) {
        await NotificationService.instance.requestPermission();
        await NotificationService.instance.showUpdateAvailable(available!.versionName, available!.notes);
        if (autoDownload && available!.delivery == 'direct' && (available!.apkUrl?.isNotEmpty ?? false)) {
          unawaited(downloadAndInstall(available!));
        }
      }
      return available;
    } catch (_) {
      if (!background) error = _t('Güncelleme kontrolü başarısız oldu.','Updatecontrole mislukt.','Updateprüfung fehlgeschlagen.','Update check failed.');
      return null;
    } finally { checking = false; notifyListeners(); }
  }

  Future<void> installOrOpenStore(AppRelease release) async {
    if (release.delivery == 'store') {
      try {
        await _channel.invokeMethod<String>('openStore', {'url': release.storeUrl ?? 'market://details?id=com.senshilabs.teorix'});
      } catch (_) {
        error = _t('Play Store açılamadı.','Play Store kon niet worden geopend.','Play Store konnte nicht geöffnet werden.','Could not open Play Store.');
        notifyListeners();
      }
      return;
    }
    await downloadAndInstall(release);
  }

  Future<void> downloadAndInstall(AppRelease release) async {
    if (kIsWeb || downloading || release.apkUrl == null || release.apkUrl!.isEmpty) return;
    if (wifiOnly) {
      final networks = await Connectivity().checkConnectivity();
      if (!networks.contains(ConnectivityResult.wifi) && !networks.contains(ConnectivityResult.ethernet)) {
        error = _t('Wi‑Fi bekleniyor. Wi‑Fi bağlantısı gelince tekrar deneyebilirsin.','Wachten op wifi. Probeer opnieuw zodra wifi beschikbaar is.','Warte auf WLAN. Versuche es erneut, sobald WLAN verfügbar ist.','Waiting for Wi‑Fi. Try again when Wi‑Fi is available.');
        notifyListeners();
        return;
      }
    }
    downloading = true; progress = 0; error = null; notifyListeners();
    try {
      final req = http.Request('GET', Uri.parse(release.apkUrl!));
      final res = await http.Client().send(req);
      if (res.statusCode < 200 || res.statusCode >= 300) throw HttpException('HTTP ${res.statusCode}');
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/TeoriX-${release.versionName}-${release.versionCode}.apk');
      final sink = file.openWrite();
      final total = res.contentLength ?? 0;
      var received = 0;
      await for (final chunk in res.stream) {
        sink.add(chunk); received += chunk.length;
        if (total > 0) { progress = received / total; notifyListeners(); }
      }
      await sink.flush(); await sink.close();
      progress = 1; notifyListeners();
      await NotificationService.instance.showUpdateDownloaded(release.versionName);
      final result = await _channel.invokeMethod<String>('installApk', {'path': file.path});
      if (result == 'permission_required') {
        error = _t('Android, TeoriX için “bilinmeyen uygulama yükleme” izni istiyor. İzni açıp tekrar Güncellemeyi Kur’a bas.','Android vraagt toestemming om apps van TeoriX te installeren. Geef toestemming en probeer opnieuw.','Android benötigt die Berechtigung, Apps aus TeoriX zu installieren. Erlaube sie und versuche erneut.','Android requires permission to install apps from TeoriX. Allow it and try again.');
      }
    } catch (_) {
      error = _t('Güncelleme indirilemedi. Bağlantını kontrol edip tekrar dene.','Update kon niet worden gedownload. Controleer je verbinding.','Update konnte nicht heruntergeladen werden. Prüfe deine Verbindung.','Update could not be downloaded. Check your connection and try again.');
    } finally { downloading = false; notifyListeners(); }
  }
}
