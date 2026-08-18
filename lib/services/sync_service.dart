import 'dart:convert';
import 'local_progress_service.dart';
import 'supabase_service.dart';
import 'app_settings_service.dart';

class SyncService {
  static Future<String> uploadProgress() async {
    final client = SupabaseService.client;
    if (client == null) return _msg('Bulut yedekleme henüz etkin değil. İlerlemen bu cihazda güvende.','Cloudback-up is nog niet ingesteld. Je voortgang blijft veilig op dit apparaat.','Cloud-Backup ist noch nicht eingerichtet. Dein Fortschritt bleibt auf diesem Gerät sicher.','Cloud backup is not configured yet. Your progress remains safe on this device.');
    final uid = client.auth.currentUser?.id;
    if (uid == null || !SupabaseService.signedInPermanently) {
      return _msg('Buluta yedeklemek için önce hesabına giriş yap.','Log eerst in om een cloudback-up te maken.','Melde dich zuerst an, um ein Cloud-Backup zu erstellen.','Sign in first to back up to the cloud.');
    }
    final snapshot = await LocalProgressService().exportSnapshot();
    await client.from('user_progress_snapshots').upsert({
      'user_id': uid,
      'country_id': AppSettingsService.instance.countryId,
      'payload': snapshot,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,country_id');
    await _upsertProfile(uid);
    return _msg('İlerlemen başarıyla yedeklendi.','Je voortgang is succesvol opgeslagen.','Dein Fortschritt wurde erfolgreich gesichert.','Your progress was backed up successfully.');
  }

  static Future<String> restoreProgress() async {
    final client = SupabaseService.client;
    if (client == null) return _msg('Bulut hesabı henüz etkin değil.','Cloudaccount is nog niet ingesteld.','Cloud-Konto ist noch nicht eingerichtet.','Cloud account is not configured yet.');
    final uid = client.auth.currentUser?.id;
    if (uid == null) return _msg('Önce hesabına giriş yap.','Log eerst in.','Melde dich zuerst an.','Sign in first.');
    try {
      final row = await client
          .from('user_progress_snapshots')
          .select('payload,updated_at')
          .eq('user_id', uid)
          .eq('country_id', AppSettingsService.instance.countryId)
          .maybeSingle();
      if (row == null) return _msg('Bu ülke için bulut yedeği bulunamadı.','Geen cloudback-up gevonden voor dit land.','Für dieses Land wurde kein Cloud-Backup gefunden.','No cloud backup was found for this country.');
      final payload = row['payload'];
      if (payload is! Map) return _msg('Bulut yedeği okunamadı.','Cloudback-up kon niet worden gelezen.','Cloud-Backup konnte nicht gelesen werden.','Cloud backup could not be read.');
      await LocalProgressService().importSnapshot(Map<String, dynamic>.from(payload));
      return _msg('Bulut yedeğin bu cihaza geri yüklendi.','Je cloudback-up is op dit apparaat hersteld.','Dein Cloud-Backup wurde auf diesem Gerät wiederhergestellt.','Your cloud backup was restored to this device.');
    } catch (_) {
      return _msg('Geri yükleme sırasında bağlantı hatası oluştu.','Er is een verbindingsfout opgetreden tijdens het herstellen.','Beim Wiederherstellen ist ein Verbindungsfehler aufgetreten.','A connection error occurred while restoring.');
    }
  }

  static Future<void> _upsertProfile(String uid) async {
    final client = SupabaseService.client;
    if (client == null) return;
    try {
      await client.from('profiles').upsert({
        'user_id': uid,
        'display_name': AppSettingsService.instance.profileName,
        'ui_locale': AppSettingsService.instance.locale,
        'study_locale': AppSettingsService.instance.contentLocale,
        'active_country_id': AppSettingsService.instance.countryId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {}
  }

  static Future<String> submitQuestionReport({required String questionId, required String reason, required String detail}) async {
    await LocalProgressService().reportQuestion(questionId, reason, detail: detail);
    final client = SupabaseService.client;
    if (client == null) return _msg('Rapor cihazda kaydedildi.','Rapport is op dit apparaat opgeslagen.','Bericht wurde auf diesem Gerät gespeichert.','Report saved on this device.');
    await client.from('question_reports').insert({
      'user_id': client.auth.currentUser?.id,
      'country_id': AppSettingsService.instance.countryId,
      'question_id': questionId,
      'reason': reason,
      'detail': detail,
      'created_at': DateTime.now().toIso8601String(),
    });
    return _msg('Rapor gönderildi. Teşekkürler.','Rapport verzonden. Bedankt.','Bericht gesendet. Danke.','Report sent. Thank you.');
  }

  static String _msg(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) { 'tr' => tr, 'nl' => nl, 'de' => de, _ => en };
  static String prettyJson(Map<String, dynamic> value) => const JsonEncoder.withIndent('  ').convert(value);
}
