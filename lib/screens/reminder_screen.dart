import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../services/local_progress_service.dart';
import '../services/notification_service.dart';
import '../widgets/tx_widgets.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});
  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final progress = LocalProgressService();
  bool enabled = false;
  int hour = 19;
  int minute = 0;
  bool loading = true;

  String _t(String tr, String nl, String de, String en) => TxText.pick(tr, nl, de, en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    enabled = await progress.reminderEnabled();
    hour = await progress.reminderHour();
    minute = await progress.reminderMinute();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    await progress.setReminder(enabled: enabled, hour: hour, minute: minute);
    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (granted) await NotificationService.instance.scheduleDaily(hour: hour, minute: minute);
    } else {
      await NotificationService.instance.cancelDaily();
    }
    if (!mounted) return;
    final message = !enabled
        ? _t('Hatırlatıcı kapatıldı.', 'Herinnering uitgeschakeld.', 'Erinnerung deaktiviert.', 'Reminder disabled.')
        : kIsWeb
            ? _t('Tercih kaydedildi. Zamanlanmış bildirimi Android/iOS cihazda test et.', 'Voorkeur opgeslagen. Test geplande meldingen op Android/iOS.', 'Einstellung gespeichert. Teste geplante Mitteilungen auf Android/iOS.', 'Preference saved. Test scheduled notifications on Android/iOS.')
            : _t('Günlük hatırlatıcı kaydedildi.', 'Dagelijkse herinnering opgeslagen.', 'Tägliche Erinnerung gespeichert.', 'Daily reminder saved.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: hour, minute: minute));
    if (t != null) setState(() { hour = t.hour; minute = t.minute; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(TxText.t('study_reminders'))),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TxCard(child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: enabled,
                    onChanged: (v) => setState(() => enabled = v),
                    title: Text(_t('Günlük çalışma bildirimi', 'Dagelijkse studiemelding', 'Tägliche Lernerinnerung', 'Daily study notification'), style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text(_t('Her gün seçtiğin saatte TeoriX seni çalışmaya çağırsın.', 'Laat TeoriX je dagelijks op het gekozen tijdstip herinneren.', 'TeoriX erinnert dich täglich zur gewählten Zeit ans Lernen.', 'Let TeoriX remind you to study every day at your chosen time.'), style: const TextStyle(color: TxColors.muted)),
                  )),
                  const SizedBox(height: 12),
                  TxCard(child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    enabled: enabled,
                    onTap: enabled ? _pickTime : null,
                    leading: const Icon(Icons.schedule_rounded, color: TxColors.blue),
                    title: Text(_t('Bildirim saati', 'Meldingstijd', 'Erinnerungszeit', 'Notification time'), style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}', style: const TextStyle(color: TxColors.muted)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  )),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: Text(TxText.t('save'))),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (kIsWeb) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('Web önizlemede ayar kaydedilir; gerçek zamanlanmış bildirimi Android/iOS cihazda test et.', 'In de webpreview wordt de instelling opgeslagen; test echte geplande meldingen op Android/iOS.', 'In der Webvorschau wird die Einstellung gespeichert; teste echte geplante Mitteilungen auf Android/iOS.', 'The setting is saved in web preview; test real scheduled notifications on Android/iOS.'))));
                        return;
                      }
                      final granted = await NotificationService.instance.requestPermission();
                      if (granted) {
                        await NotificationService.instance.showTest();
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('Bildirim izni verilmedi.', 'Meldingstoestemming niet gegeven.', 'Mitteilungsberechtigung nicht erteilt.', 'Notification permission was not granted.'))));
                      }
                    },
                    icon: const Icon(Icons.notifications_active_rounded),
                    label: Text(_t('Test Bildirimi Gönder', 'Testmelding sturen', 'Testmitteilung senden', 'Send Test Notification')),
                  ),
                ],
              ),
      );
}
