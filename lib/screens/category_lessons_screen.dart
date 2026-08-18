import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../data/lesson_repository.dart';
import '../data/question_repository.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../services/local_progress_service.dart';
import '../widgets/tx_widgets.dart';
import 'lesson_detail_screen.dart';
import 'question_session_screen.dart';

class CategoryLessonsScreen extends StatefulWidget {
  final String category;
  final Color accent;
  const CategoryLessonsScreen({super.key, required this.category, required this.accent});

  @override
  State<CategoryLessonsScreen> createState() => _CategoryLessonsScreenState();
}

class _CategoryLessonsScreenState extends State<CategoryLessonsScreen> {
  final progress = LocalProgressService();
  CountryProfile get profile => AppSettingsService.instance.country;
  List<Lesson> lessons = [];
  Set<String> completed = {};
  Map<String, Map<String, int>> lessonStats = {};
  List<String> categoryWrongIds = [];
  Map<String, int> lessonWrongCounts = {};
  List<Question> categoryQuestions = [];
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await LessonRepository().loadLessons(profile: profile);
    final done = await progress.completedLessonIds();
    final stats = await progress.lessonStats();
    final allQuestions = await QuestionRepository().loadSeedQuestions(profile: profile);
    final wrongSet = await progress.wrongIds();
    final categoryQuestionsLocal = allQuestions.where((q) => q.category == widget.category).toList();
    final wrongIds = categoryQuestionsLocal.where((q) => wrongSet.contains(q.id)).map((q) => q.id).toList();
    final wrongPerLesson = <String, int>{};
    for (final q in categoryQuestionsLocal) {
      if (wrongSet.contains(q.id) && q.lessonId.isNotEmpty) {
        wrongPerLesson[q.lessonId] = (wrongPerLesson[q.lessonId] ?? 0) + 1;
      }
    }
    if (!mounted) return;
    setState(() {
      lessons = all.where((e) => e.category == widget.category).toList()..sort((a, b) => a.order.compareTo(b.order));
      completed = done;
      lessonStats = stats;
      categoryWrongIds = wrongIds;
      lessonWrongCounts = wrongPerLesson;
      categoryQuestions = categoryQuestionsLocal;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = query.trim().isEmpty
        ? lessons
        : lessons.where((l) {
            final q = query.toLowerCase();
            return '${l.title} ${l.module} ${l.tags.join(' ')}'.toLowerCase().contains(q);
          }).toList();
    final doneCount = lessons.where((l) => completed.contains(l.id)).length;
    final progressValue = lessons.isEmpty ? 0.0 : doneCount / lessons.length;

    return Scaffold(
      appBar: AppBar(title: Text(_pretty(widget.category))),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: widget.accent.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.accent.withValues(alpha: .35)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 50, height: 50, decoration: BoxDecoration(color: widget.accent.withValues(alpha: .18), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.school_rounded, color: widget.accent)),
                          const SizedBox(width: 13),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(TxText.pick('${lessons.length} Ders','${lessons.length} lessen','${lessons.length} Lektionen','${lessons.length} lessons'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 3),
                            Text(TxText.pick('$doneCount tamamlandı • Önce öğren, sonra soruyla pekiştir.','$doneCount voltooid • Leer eerst, oefen daarna.','$doneCount abgeschlossen • Erst lernen, dann üben.','$doneCount completed • Learn first, then reinforce with questions.'), style: const TextStyle(color: TxColors.muted, fontSize: 12)),
                          ])),
                        ]),
                        const SizedBox(height: 14),
                        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progressValue, minHeight: 7, backgroundColor: Colors.white10, color: widget.accent)),
                        if (categoryWrongIds.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.error_outline_rounded, color: TxColors.red, size: 18),
                            const SizedBox(width: 7),
                            Text(TxText.pick('${categoryWrongIds.length} hatalı sorun tekrar bekliyor','${categoryWrongIds.length} fouten wachten op herhaling','${categoryWrongIds.length} Fehler warten auf Wiederholung','${categoryWrongIds.length} mistakes are waiting for review'), style: const TextStyle(color: TxColors.red, fontSize: 12, fontWeight: FontWeight.w800)),
                          ]),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => query = v),
                      decoration: InputDecoration(
                        hintText: TxText.pick('Bu derste ara...','Zoek in deze lessen...','In diesen Lektionen suchen...','Search these lessons...'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: TxColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 13),
                    ..._lessonTiles(shown),
                    if (shown.isEmpty)
                      TxCard(child: Padding(padding: const EdgeInsets.all(18), child: Center(child: Text(TxText.pick('Aramana uygun ders bulunamadı.','Geen passende les gevonden.','Keine passende Lektion gefunden.','No matching lesson found.'))))),
                    const SizedBox(height: 5),
                    if (categoryWrongIds.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: categoryWrongIds)));
                          _load();
                        },
                        icon: const Icon(Icons.replay_circle_filled_rounded, color: TxColors.red),
                        label: Text(TxText.pick('Bu Konudaki Yanlışlarımı Çöz (${categoryWrongIds.length})','Mijn fouten in dit onderwerp oefenen (${categoryWrongIds.length})','Meine Fehler in diesem Thema üben (${categoryWrongIds.length})','Practice My Mistakes in This Topic (${categoryWrongIds.length})')),
                      ),
                      const SizedBox(height: 9),
                    ],
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionSessionScreen(category: widget.category, questionCount: 20)));
                        _load();
                      },
                      icon: const Icon(Icons.quiz_rounded),
                      label: Text(TxText.pick('Bu Konudan 20 Soru Çöz','Oefen 20 vragen uit dit onderwerp','20 Fragen aus diesem Thema üben','Practice 20 Questions From This Topic')),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _lessonTiles(List<Lesson> shown) {
    String? lastModule;
    final out = <Widget>[];
    for (final l in shown) {
      if (l.module != lastModule) {
        lastModule = l.module;
        final moduleLessonIds = lessons.where((x) => x.module == l.module).map((x) => x.id).toSet();
        final moduleQuestionIds = categoryQuestions.where((q) => moduleLessonIds.contains(q.lessonId)).map((q) => q.id).toList();
        out.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 9, 4, 9),
          child: Row(children: [
            Expanded(child: Text(l.module.toUpperCase(), style: TextStyle(color: widget.accent, fontSize: 11, letterSpacing: .7, fontWeight: FontWeight.w900))),
            if (moduleQuestionIds.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: moduleQuestionIds, questionCount: moduleQuestionIds.length > 10 ? 10 : moduleQuestionIds.length)));
                  _load();
                },
                icon: const Icon(Icons.quiz_outlined, size: 15),
                label: Text(TxText.pick('Bölüm Testi','Onderdeeltest','Abschnittstest','Section Test'), style: const TextStyle(fontSize: 10)),
              ),
          ]),
        ));
      }
      final s = lessonStats[l.id] ?? const {'correct': 0, 'wrong': 0};
      final c = s['correct'] ?? 0;
      final w = s['wrong'] ?? 0;
      final attempts = c + w;
      final rate = attempts == 0 ? null : c / attempts;
      final done = completed.contains(l.id);
      final wrongCount = lessonWrongCounts[l.id] ?? 0;
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TxCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: l)));
              _load();
            },
            leading: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: widget.accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
              child: done ? const Icon(Icons.check_rounded, color: TxColors.green) : Text('${l.order}', style: TextStyle(color: widget.accent, fontWeight: FontWeight.w900)),
            ),
            title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                TxText.pick('${l.minutes} dk${attempts == 0 ? '' : ' • $attempts soru • %${(rate! * 100).round()}'}${wrongCount == 0 ? '' : ' • $wrongCount yanlış'}','${l.minutes} min${attempts == 0 ? '' : ' • $attempts vragen • ${((rate ?? 0) * 100).round()}%'}${wrongCount == 0 ? '' : ' • $wrongCount fouten'}','${l.minutes} Min.${attempts == 0 ? '' : ' • $attempts Fragen • ${((rate ?? 0) * 100).round()}%'}${wrongCount == 0 ? '' : ' • $wrongCount Fehler'}','${l.minutes} min${attempts == 0 ? '' : ' • $attempts questions • ${((rate ?? 0) * 100).round()}%'}${wrongCount == 0 ? '' : ' • $wrongCount wrong'}'),
                style: TextStyle(color: wrongCount > 0 ? TxColors.red : TxColors.muted, fontSize: 11),
              ),
            ),
            trailing: wrongCount > 0
                ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: TxColors.red.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)), child: Text('$wrongCount', style: const TextStyle(color: TxColors.red, fontWeight: FontWeight.w900, fontSize: 11)))
                : const Icon(Icons.chevron_right_rounded, color: TxColors.muted),
          ),
        ),
      ));
    }
    return out;
  }

  String _pretty(String value) => profile.localizedCategoryLabel(value, AppSettingsService.instance.locale);

}
