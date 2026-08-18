import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../services/local_progress_service.dart';
import '../widgets/tx_widgets.dart';
import 'question_session_screen.dart';

class StudyHistoryScreen extends StatefulWidget {
  const StudyHistoryScreen({super.key});
  @override
  State<StudyHistoryScreen> createState() => _StudyHistoryScreenState();
}

class _StudyHistoryScreenState extends State<StudyHistoryScreen> {
  final progress = LocalProgressService();
  String _t(String tr, String nl, String de, String en) => TxText.pick(tr, nl, de, en);

  Future<List<Map<String, dynamic>>> _load() => progress.studyHistory();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_t('Çalışma Geçmişi', 'Studiegeschiedenis', 'Lernverlauf', 'Study History'))),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _load(),
          builder: (_, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final list = snap.data!;
            if (list.isEmpty) {
              return Center(child: Padding(padding: const EdgeInsets.all(28), child: Text(_t('Henüz tamamlanmış çalışma oturumun yok.', 'Je hebt nog geen studiesessie afgerond.', 'Du hast noch keine Lerneinheit abgeschlossen.', 'You have not completed a study session yet.'), textAlign: TextAlign.center)));
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
                final wrongIds = (e['wrongIds'] as List?)?.map((x) => x.toString()).toList() ?? <String>[];
                final mode = e['mode']?.toString() ?? '';
                return TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    RingProgress(value: rate / 100, center: '%$rate', caption: _t('Başarı', 'Score', 'Erfolg', 'Score'), size: 76),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_modeLabel(mode), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(_t('$correct doğru • $wrong yanlış • $empty boş', '$correct goed • $wrong fout • $empty leeg', '$correct richtig • $wrong falsch • $empty leer', '$correct correct • $wrong wrong • $empty blank'), style: const TextStyle(fontSize: 11, color: TxColors.muted)),
                    ])),
                  ]),
                  if (wrongIds.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: wrongIds)));
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.replay_rounded),
                        label: Text(_t('Bu Oturumdaki Yanlışları Çöz (${wrongIds.length})', 'Oefen fouten uit deze sessie (${wrongIds.length})', 'Fehler dieser Einheit üben (${wrongIds.length})', 'Practice Mistakes From This Session (${wrongIds.length})')),
                      ),
                    ),
                  ],
                ]));
              },
            );
          },
        ),
      );

  String _modeLabel(String mode) => switch (mode) {
        'quick_exam' => _t('Hızlı Deneme', 'Snelle test', 'Schnelltest', 'Quick Test'),
        'lesson_test' => _t('Ders Testi', 'Lestoets', 'Lektionstest', 'Lesson Test'),
        'category_test' => _t('Konu Testi', 'Onderwerptest', 'Thementest', 'Topic Test'),
        'wrong_review' => _t('Yanlış Tekrarı', 'Fouten herhalen', 'Fehler wiederholen', 'Mistake Review'),
        _ => _t('Serbest Çalışma', 'Vrij oefenen', 'Freies Lernen', 'Free Practice'),
      };
}
