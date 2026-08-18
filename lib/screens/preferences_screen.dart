import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../services/app_settings_service.dart';
import '../services/local_progress_service.dart';
import '../services/sync_service.dart';
import '../widgets/tx_widgets.dart';
import 'exam_plan_screen.dart';
import 'reminder_screen.dart';
import 'update_settings_screen.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});
  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final progress = LocalProgressService();
  final name = TextEditingController();
  int goal = 20;
  bool loading = true;

  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl, 'de' => de, 'en' => en, _ => tr,
      };

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { name.dispose(); super.dispose(); }

  Future<void> _load() async {
    name.text = AppSettingsService.instance.profileName;
    goal = await progress.dailyGoal();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _saveName() async {
    if (name.text.trim().length < 2) return;
    await progress.setProfileName(name.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('Adın kaydedildi.','Naam opgeslagen.','Name gespeichert.','Name saved.'))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_t('Ayarlar','Instellingen','Einstellungen','Settings'))),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(TxText.t('edit_name'), style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          TextField(controller: name, maxLength: 32, decoration: InputDecoration(hintText: TxText.t('name_hint'))),
          const SizedBox(height: 6),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _saveName, child: Text(TxText.t('save')))),
        ])),
        const SizedBox(height: 12),
        TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(TxText.t('daily_goal'), style: const TextStyle(fontWeight: FontWeight.w900)),
          Slider(value: goal.toDouble(), min: 5, max: 100, divisions: 19, label: '$goal', onChanged: (v) => setState(() => goal = v.round()), onChangeEnd: (v) async => progress.setDailyGoal(v.round())),
          Center(child: Text(_t('$goal soru / gün','$goal vragen / dag','$goal Fragen / Tag','$goal questions / day'), style: const TextStyle(color: TxColors.muted))),
        ])),
        const SizedBox(height: 12),
        _tile(Icons.event_note_rounded, TxText.t('exam_plan'), _t('Sınava kalan güne göre kişisel tempo','Persoonlijk tempo op basis van resterende dagen','Persönliches Tempo nach verbleibenden Tagen','Personal pace based on days remaining'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamPlanScreen()))),
        _tile(Icons.system_update_rounded, _t('Uygulama Güncellemeleri','App-updates','App-Updates','App Updates'), _t('Otomatik indirme, sürüm kontrolü ve uygulama içi kurulum','Automatisch downloaden, versiecontrole en installatie in de app','Automatischer Download, Versionsprüfung und Installation in der App','Automatic download, version check and in-app installation'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateSettingsScreen()))),
        _tile(Icons.notifications_active_rounded, TxText.t('study_reminders'), _t('Günlük bildirim saatini ayarla','Stel dagelijkse meldingstijd in','Tägliche Erinnerungszeit einstellen','Set a daily reminder time'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderScreen()))),
        _tile(Icons.cloud_upload_outlined, _t('İlerlemeyi Yedekle','Voortgang back-uppen','Fortschritt sichern','Back Up Progress'), _t('Hesabınla mevcut ülke ilerlemesini eşitle','Synchroniseer voortgang met je account','Fortschritt mit deinem Konto synchronisieren','Sync this country progress with your account'), () async {
          final msg = await SyncService.uploadProgress();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }),
        _tile(Icons.delete_sweep_outlined, _t('İlerlemeyi Sıfırla','Voortgang resetten','Fortschritt zurücksetzen','Reset Progress'), _t('Bu ülkenin soru ve deneme geçmişini temizle','Wis vraag- en examengeschiedenis van dit land','Fragen- und Prüfungsverlauf dieses Landes löschen','Clear question and test history for this country'), () async {
          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
            title: Text(_t('İlerleme sıfırlansın mı?','Voortgang resetten?','Fortschritt zurücksetzen?','Reset progress?')),
            content: Text(_t('Ülke ve dil ayarların korunur; çalışma geçmişin silinir.','Land- en taalinstellingen blijven behouden; studiegegevens worden gewist.','Land- und Spracheinstellungen bleiben erhalten; Lerndaten werden gelöscht.','Country and language settings stay; study history will be deleted.')),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(TxText.t('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(_t('Sıfırla','Resetten','Zurücksetzen','Reset')))],
          )) ?? false;
          if (ok) {
            await progress.resetProgress();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('İlerleme sıfırlandı.','Voortgang gereset.','Fortschritt zurückgesetzt.','Progress reset.'))));
          }
        }),
      ],
    ),
  );

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: TxCard(padding: EdgeInsets.zero, child: ListTile(onTap: onTap, leading: Icon(icon, color: TxColors.muted), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(color: TxColors.muted, fontSize: 11)), trailing: const Icon(Icons.chevron_right_rounded, color: TxColors.muted))),
  );
}
