import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../models/lesson.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../data/question_repository.dart';
import '../data/lesson_repository.dart';
import '../services/local_progress_service.dart';
import '../widgets/tx_widgets.dart';
import 'question_session_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  CountryProfile get profile => AppSettingsService.instance.country;
  final progress = LocalProgressService();
  bool completed = false;
  Map<String, int> stats = const {'correct': 0, 'wrong': 0};
  List<String> lessonWrongIds = [];
  Lesson? nextLesson;
  Lesson? localizedLesson;
  int lessonQuestionCount = 0;

  Lesson get lesson => localizedLesson ?? widget.lesson;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sourceLessons = await LessonRepository().loadLessons(profile: profile, localizePreviews: false);
    final sourceLesson = sourceLessons.firstWhere((l) => l.id == widget.lesson.id, orElse: () => widget.lesson);
    final translatedLesson = await LessonRepository().localizeLesson(sourceLesson, profile: profile);
    final done = await progress.isLessonCompleted(sourceLesson.id);
    final allStats = await progress.lessonStats();
    final allQuestions = await QuestionRepository().loadSeedQuestions(profile: profile);
    final allLessons = sourceLessons;
    final wrongSet = await progress.wrongIds();
    final wrongIds = allQuestions.where((q) => q.lessonId == lesson.id && wrongSet.contains(q.id)).map((q) => q.id).toList();
    final categoryLessons = allLessons.where((l) => l.category == lesson.category).toList()..sort((a, b) => a.order.compareTo(b.order));
    final currentIndex = categoryLessons.indexWhere((l) => l.id == lesson.id);
    final next = currentIndex >= 0 && currentIndex + 1 < categoryLessons.length ? categoryLessons[currentIndex + 1] : null;
    if (!mounted) return;
    setState(() {
      localizedLesson = translatedLesson;
      completed = done;
      stats = allStats[lesson.id] ?? const {'correct': 0, 'wrong': 0};
      lessonWrongIds = wrongIds;
      nextLesson = next;
      lessonQuestionCount = allQuestions.where((q) => q.lessonId == lesson.id).length;
    });
  }

  Future<void> _toggleCompleted() async {
    await progress.setLessonCompleted(lesson.id, !completed);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(completed ? TxText.pick('Ders tamamlandı olarak işaretlendi.','Les gemarkeerd als voltooid.','Lektion als abgeschlossen markiert.','Lesson marked complete.') : TxText.pick('Tamamlandı işareti kaldırıldı.','Voltooid-markering verwijderd.','Abgeschlossen-Markierung entfernt.','Completion mark removed.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final attempts = (stats['correct'] ?? 0) + (stats['wrong'] ?? 0);
    final rate = attempts == 0 ? null : (stats['correct'] ?? 0) / attempts;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF16243C), Color(0xFF0E1728)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _badge(_pretty(lesson.category), TxColors.blue),
                  const SizedBox(width: 7),
                  Flexible(child: _badge(lesson.module, TxColors.purple)),
                  const Spacer(),
                  const Icon(Icons.schedule_rounded, size: 16, color: TxColors.muted),
                  const SizedBox(width: 5),
                  Text(TxText.pick('${lesson.minutes} dk','${lesson.minutes} min','${lesson.minutes} Min.','${lesson.minutes} min'), style: const TextStyle(color: TxColors.muted, fontSize: 12)),
                ]),
                const SizedBox(height: 18),
                Text(lesson.title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text(lesson.summary, style: const TextStyle(color: Color(0xFFD5DEEC), height: 1.55, fontSize: 15)),
                if (attempts > 0) ...[
                  const SizedBox(height: 15),
                  Row(children: [
                    const Icon(Icons.insights_rounded, color: TxColors.green, size: 18),
                    const SizedBox(width: 7),
                    Text(TxText.pick('$attempts cevap • %${((rate ?? 0) * 100).round()} başarı','$attempts antwoorden • ${((rate ?? 0) * 100).round()}% score','$attempts Antworten • ${((rate ?? 0) * 100).round()}% Erfolg','$attempts answers • ${((rate ?? 0) * 100).round()}% score'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            ...lesson.sections.map((section) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TxCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(section.heading, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      if (section.body.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(section.body, style: const TextStyle(color: Color(0xFFD5DEEC), height: 1.55)),
                      ],
                      if (section.bullets.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...section.bullets.map((p) => _point(Icons.check_circle_rounded, TxColors.green, p)),
                      ],
                    ]),
                  ),
                )),
            TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.checklist_rounded, color: TxColors.blue), const SizedBox(width: 8), Text(TxText.pick('Bu dersten aklında kalmalı','Onthoud dit uit deze les','Das solltest du aus dieser Lektion behalten','Remember this from the lesson'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
              const SizedBox(height: 14),
              ...lesson.keyPoints.map((p) => _point(Icons.bookmark_added_rounded, TxColors.blue, p)),
            ])),
            const SizedBox(height: 12),
            TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.lightbulb_rounded, color: TxColors.gold), const SizedBox(width: 8), Text(TxText.pick('Sınav püf noktaları','Examentips','Prüfungstipps','Test tips'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
              const SizedBox(height: 14),
              ...lesson.examTips.map((p) => _point(Icons.bolt_rounded, TxColors.gold, p)),
            ])),
            const SizedBox(height: 16),
            if (lessonWrongIds.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF25131B), borderRadius: BorderRadius.circular(16), border: Border.all(color: TxColors.red.withValues(alpha: .35))),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: TxColors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Text(TxText.pick('Bu derste ${lessonWrongIds.length} yanlış sorun var. Önce onları kapatabilirsin.','Je hebt ${lessonWrongIds.length} fouten in deze les. Werk die eerst weg.','Du hast ${lessonWrongIds.length} Fehler in dieser Lektion. Arbeite sie zuerst auf.','You have ${lessonWrongIds.length} mistakes in this lesson. You can clear those first.'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, height: 1.35))),
                ]),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: lessonWrongIds)));
                  _load();
                },
                icon: const Icon(Icons.replay_rounded, color: TxColors.red),
                label: Text(TxText.pick('Bu Dersteki Yanlışlarımı Çöz (${lessonWrongIds.length})','Mijn fouten uit deze les oefenen (${lessonWrongIds.length})','Meine Fehler aus dieser Lektion üben (${lessonWrongIds.length})','Practice My Mistakes From This Lesson (${lessonWrongIds.length})')),
              ),
              const SizedBox(height: 9),
            ],
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionSessionScreen(lessonId: lesson.id, questionCount: lessonQuestionCount == 0 ? 10 : lessonQuestionCount.clamp(1, 10).toInt())));
                _load();
              },
              icon: const Icon(Icons.quiz_rounded),
              label: Text(lessonQuestionCount == 0 ? TxText.pick('Ders Testini Aç','Open lestoets','Lektionstest öffnen','Open Lesson Test') : TxText.pick('Bu Dersten ${lessonQuestionCount.clamp(1, 10).toInt()} Soru Çöz','Oefen ${lessonQuestionCount.clamp(1, 10).toInt()} vragen uit deze les','${lessonQuestionCount.clamp(1, 10).toInt()} Fragen aus dieser Lektion üben','Practice ${lessonQuestionCount.clamp(1, 10).toInt()} Questions From This Lesson')),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: _toggleCompleted,
              icon: Icon(completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
              label: Text(completed ? TxText.pick('Ders Tamamlandı ✓','Les voltooid ✓','Lektion abgeschlossen ✓','Lesson Completed ✓') : TxText.pick('Dersi Tamamladım','Les afronden','Lektion abschließen','Mark Lesson Complete')),
            ),
            const SizedBox(height: 9),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionSessionScreen(category: lesson.category, questionCount: 20))),
              icon: const Icon(Icons.all_inclusive_rounded),
              label: Text(TxText.pick('Bu Kategoride Karışık Çalış','Gemengd oefenen in dit onderwerp','Gemischt in diesem Thema üben','Mixed Practice in This Topic')),
            ),
            if (nextLesson != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: TxColors.blue),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: nextLesson!))),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(TxText.pick('Sonraki Ders: ${nextLesson!.title}','Volgende les: ${nextLesson!.title}','Nächste Lektion: ${nextLesson!.title}','Next Lesson: ${nextLesson!.title}')),
              ),
            ],
            const SizedBox(height: 12),
            Text(TxText.pick('TeoriX içeriği ${profile.examAuthority} kapsamındaki konuları çalışmayı kolaylaştırmak için hazırlanmış özgün eğitim içeriğidir; resmî sınav soru bankasının kopyası değildir.','TeoriX-inhoud is originele studie-inhoud voor onderwerpen binnen ${profile.examAuthority}; het is geen kopie van een officiële examenvragenbank.','TeoriX-Inhalte sind eigene Lerninhalte für Themen im Bereich ${profile.examAuthority}; sie sind keine Kopie eines amtlichen Fragenkatalogs.','TeoriX content is original study material for topics covered by ${profile.examAuthority}; it is not a copy of an official test question bank.'), style: TextStyle(color: TxColors.muted, fontSize: 11, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _point(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45, color: Color(0xFFD5DEEC)))),
        ]),
      );

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(99)),
        child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      );

  String _pretty(String value) => profile.localizedCategoryLabel(value, AppSettingsService.instance.locale);

}
