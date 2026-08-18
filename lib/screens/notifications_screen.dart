import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../services/app_settings_service.dart';
import '../services/local_progress_service.dart';
import '../widgets/tx_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final progress = LocalProgressService();
  bool loading = true;
  List<_Notice> notices = [];
  Set<String> read = {};
  Set<String> dismissed = {};

  String get lang => AppSettingsService.instance.locale;
  String _txt(String tr, String nl, String de, String en) => switch (lang) {'tr'=>tr,'nl'=>nl,'de'=>de,_=>en};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final today = await progress.todaySolved();
    final goal = await progress.dailyGoal();
    final streak = await progress.streak();
    final wrongs = (await progress.wrongIds()).length;
    final examDate = await progress.examDate();
    final last = await progress.lastExamResult();
    final items = <_Notice>[];
    if (today < goal) {
      items.add(_Notice(
        'daily-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}', Icons.track_changes_rounded,
        _txt('Günlük hedef','Dagdoel','Tagesziel','Daily goal'),
        _txt('Bugün $today/$goal soru çözdün. ${goal-today} soru daha hedefi tamamlar.','Vandaag $today/$goal vragen. Nog ${goal-today} te gaan.','Heute $today/$goal Fragen. Noch ${goal-today} bis zum Ziel.','You solved $today/$goal questions today. ${goal-today} to go.'),
        TxColors.blue,
      ));
    }
    if (streak > 0) {
      items.add(_Notice('streak-$streak', Icons.local_fire_department_rounded,
        _txt('$streak günlük seri 🔥','$streak dagen reeks 🔥','$streak-Tage-Serie 🔥','$streak-day streak 🔥'),
        _txt('Serini korumak için bugün kısa da olsa çalış.','Doe vandaag een korte sessie om je reeks te behouden.','Lerne heute kurz, um deine Serie zu halten.','Do a short session today to keep your streak.'), TxColors.gold));
    }
    if (wrongs > 0) {
      items.add(_Notice('wrongs-$wrongs', Icons.replay_circle_filled_rounded,
        _txt('$wrongs yanlış tekrar bekliyor','$wrongs fouten wachten op herhaling','$wrongs Fehler warten auf Wiederholung','$wrongs mistakes are waiting'),
        _txt('Yanlışlarını tekrar çözerek zayıf noktalarını kapat.','Herhaal je fouten en sluit je zwakke punten.','Wiederhole Fehler und schließe Wissenslücken.','Review your mistakes and close weak spots.'), TxColors.red));
    }
    if (examDate != null) {
      final days = examDate.difference(DateTime.now()).inDays + 1;
      if (days >= 0) {
        items.add(_Notice('exam-${examDate.toIso8601String().split('T').first}', Icons.event_available_rounded,
          days == 0 ? _txt('Sınav bugün!','Examen vandaag!','Prüfung heute!','Test today!') : _txt('Sınava $days gün kaldı','Nog $days dagen','$days Tage bis zur Prüfung','$days days until your test'),
          days <= 7 ? _txt('Son hafta: deneme ve yanlış tekrarına ağırlık ver.','Laatste week: focus op examens en fouten.','Letzte Woche: Prüfungen und Fehler wiederholen.','Final week: focus on full tests and mistakes.') : _txt('Planına sadık kal ve günlük hedefini tamamla.','Blijf bij je plan en dagdoel.','Bleib bei deinem Plan und Tagesziel.','Stick to your plan and daily target.'), TxColors.purple));
      }
    }
    if (last != null) {
      final total = (last['total'] as num?)?.toInt() ?? 0;
      final correct = (last['correct'] as num?)?.toInt() ?? 0;
      final rate = total == 0 ? 0 : (correct * 100 / total).round();
      items.add(_Notice('last-${last['id'] ?? last['completedAt']}', Icons.analytics_rounded,
        _txt('Son denemen %$rate','Laatste test $rate%','Letzte Prüfung $rate%','Last test $rate%'),
        rate >= 70 ? _txt('Yanlışlarını temizleyip istikrarı koru.','Werk je fouten weg en blijf consistent.','Fehler korrigieren und konstant bleiben.','Clear your mistakes and stay consistent.') : _txt('Biraz konu tekrarı iyi gelir.','Wat extra herhaling helpt.','Etwas Wiederholung hilft.','A little topic review will help.'), rate >= 70 ? TxColors.green : TxColors.gold));
    }
    final r = await progress.readNotificationIds();
    final d = await progress.dismissedNotificationIds();
    if (mounted) setState(() { notices = items.where((e) => !d.contains(e.id)).toList(); read = r; dismissed = d; loading = false; });
  }

  Future<void> _mark(_Notice n) async { await progress.markNotificationRead(n.id); if (mounted) setState(() => read.add(n.id)); }
  Future<void> _markAll() async { await progress.markAllNotificationsRead(notices.map((e) => e.id)); if (mounted) setState(() => read.addAll(notices.map((e) => e.id))); }
  Future<void> _delete(_Notice n) async { await progress.dismissNotification(n.id); if (mounted) setState(() { dismissed.add(n.id); notices.removeWhere((e) => e.id == n.id); }); }
  Future<void> _clearAll() async { await progress.dismissAllNotifications(notices.map((e) => e.id)); if (mounted) setState(() => notices.clear()); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(TxText.t('notifications')),
      actions: [
        IconButton(onPressed: notices.isEmpty ? null : _markAll, tooltip: TxText.t('mark_all_read'), icon: const Icon(Icons.done_all_rounded)),
        IconButton(onPressed: notices.isEmpty ? null : _clearAll, tooltip: TxText.t('clear_all'), icon: const Icon(Icons.delete_sweep_outlined)),
      ],
    ),
    body: loading ? const Center(child: CircularProgressIndicator()) : notices.isEmpty
      ? Center(child: Padding(padding: const EdgeInsets.all(28), child: Text(TxText.t('no_notifications'), textAlign: TextAlign.center)))
      : RefreshIndicator(onRefresh: _load, child: ListView.separated(
          padding: const EdgeInsets.all(16), itemCount: notices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final n = notices[i]; final isRead = read.contains(n.id);
            return Dismissible(
              key: ValueKey(n.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _delete(n),
              background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 22), decoration: BoxDecoration(color: TxColors.red.withValues(alpha: .2), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.delete_rounded, color: TxColors.red)),
              child: InkWell(onTap: () => _mark(n), borderRadius: BorderRadius.circular(20), child: TxCard(
                color: isRead ? TxColors.surface : TxColors.surface2,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: n.color.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)), child: Icon(n.icon, color: n.color)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w900))), if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: TxColors.red, shape: BoxShape.circle))]),
                    const SizedBox(height: 5),
                    Text(n.body, style: const TextStyle(color: TxColors.muted, height: 1.4)),
                  ])),
                  IconButton(onPressed: () => _delete(n), tooltip: TxText.t('delete'), icon: const Icon(Icons.close_rounded, size: 19, color: TxColors.muted)),
                ]),
              )),
            );
          },
        )),
  );
}

class _Notice {
  final String id; final IconData icon; final String title; final String body; final Color color;
  const _Notice(this.id, this.icon, this.title, this.body, this.color);
}
