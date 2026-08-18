import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../services/local_progress_service.dart';
import '../widgets/tx_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  String _t(String tr, String nl, String de, String en) => TxText.pick(tr, nl, de, en);

  @override
  Widget build(BuildContext context) {
    final future = LocalProgressService().examHistory();
    return Scaffold(
      appBar: AppBar(title: Text(_t('Deneme Geçmişi', 'Examenhistorie', 'Prüfungsverlauf', 'Full Test History'))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return Center(child: Padding(padding: const EdgeInsets.all(28), child: Text(_t('Henüz tamamlanmış denemen yok.', 'Je hebt nog geen volledig examen afgerond.', 'Du hast noch keine vollständige Prüfung abgeschlossen.', 'You have not completed a full test yet.'), textAlign: TextAlign.center)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final e = list[i];
              final total = (e['total'] as num?)?.toInt() ?? 0;
              final correct = (e['correct'] as num?)?.toInt() ?? 0;
              final wrong = (e['wrong'] as num?)?.toInt() ?? 0;
              final empty = (e['empty'] as num?)?.toInt() ?? 0;
              final rate = total == 0 ? 0 : (correct * 100 / total).round();
              final dt = DateTime.tryParse(e['completedAt']?.toString() ?? '');
              return TxCard(child: Row(children: [
                RingProgress(value: rate / 100, center: '%$rate', caption: _t('Başarı', 'Score', 'Erfolg', 'Score'), size: 82),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_t('${i + 1}. deneme', '${i + 1}e examen', '${i + 1}. Prüfung', 'Full test ${i + 1}'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  if (dt != null) Text('${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: TxColors.muted, fontSize: 11)),
                  const SizedBox(height: 8),
                  Text(_t('$correct doğru • $wrong yanlış • $empty boş', '$correct goed • $wrong fout • $empty leeg', '$correct richtig • $wrong falsch • $empty leer', '$correct correct • $wrong wrong • $empty blank'), style: const TextStyle(fontSize: 12)),
                ])),
              ]));
            },
          );
        },
      ),
    );
  }
}
