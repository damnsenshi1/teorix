import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../services/local_progress_service.dart';
import '../data/lesson_repository.dart';
import '../widgets/tx_widgets.dart';
import '../widgets/banner_ad_slot.dart';
import 'exam_plan_screen.dart';
import 'notifications_screen.dart';
import 'question_search_screen.dart';
import 'question_session_screen.dart';
import 'wrongs_screen.dart';
import 'country_language_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onTabRequested;
  const HomeScreen({super.key, this.onTabRequested});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final progress = LocalProgressService();
  CountryProfile get profile => AppSettingsService.instance.country;
  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl,
        'de' => de,
        'en' => en,
        _ => tr,
      };
  Map<String, int> stats = const {'examCount': 0, 'correct': 0, 'wrong': 0, 'answered': 0};
  Map<String, dynamic>? lastExam;
  int wrongCount = 0;
  int todaySolved = 0;
  int streak = 0;
  int goal = 20;
  DateTime? examDate;
  int lessonCount = 0;
  int completedLessonCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await progress.stats();
    final w = await progress.wrongIds();
    final last = await progress.lastExamResult();
    final solved = await progress.todaySolved();
    final st = await progress.streak();
    final g = await progress.dailyGoal();
    final d = await progress.examDate();
    final lessons = await LessonRepository().loadLessons(profile: profile);
    final completed = await progress.completedLessonIds();
    if (!mounted) return;
    setState(() {
      stats = s;
      wrongCount = w.length;
      lastExam = last;
      todaySolved = solved;
      streak = st;
      goal = g;
      examDate = d;
      lessonCount = lessons.length;
      completedLessonCount = completed.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = (stats['correct'] ?? 0) + (stats['wrong'] ?? 0);
    final rate = total == 0 ? 0 : (((stats['correct'] ?? 0) / total) * 100).round();
    final goalValue = (todaySolved / goal).clamp(0.0, 1.0).toDouble();
    final days = examDate == null ? null : examDate!.difference(DateTime.now()).inDays + 1;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
          children: [
            Row(
              children: [
                const TxLogo(size: 30),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () async {
                    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CountryLanguageScreen()));
                    if (changed == true) _load();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(99)),
                    child: Text('${profile.flag} ${profile.localizedCountryName(AppSettingsService.instance.locale)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: _t('Soru ara','Vragen zoeken','Fragen suchen','Search questions'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionSearchScreen())),
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  tooltip: TxText.t('notifications'),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    _load();
                  },
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            if (days != null && days >= 0) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamPlanScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: TxColors.purple.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: TxColors.purple.withValues(alpha: .25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_rounded, color: TxColors.purple),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          days == 0 ? _t('Sınav bugün! Planına göz at.','Examen vandaag! Bekijk je plan.','Prüfung heute! Sieh dir deinen Plan an.','Test today! Check your plan.') : _t('Sınava $days gün kaldı • çalışma planını gör','Nog $days dagen • bekijk je studieplan','Noch $days Tage • Lernplan ansehen','$days days left • view your study plan'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: TxColors.muted),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TxCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(TxText.t('daily_goal'), style: TextStyle(color: TxColors.muted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(_t('$todaySolved / $goal soru','$todaySolved / $goal vragen','$todaySolved / $goal Fragen','$todaySolved / $goal questions'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(value: goalValue, minHeight: 7, backgroundColor: Colors.white10, color: TxColors.green),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TxCard(
                    child: Column(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text('$streak', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        Text(TxText.t('day_streak'), style: TextStyle(fontSize: 11, color: TxColors.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TxCard(
              child: Row(
                children: [
                  RingProgress(value: rate / 100, center: '%$rate', caption: total == 0 ? _t('Başlamak için soru çöz','Los vragen op om te beginnen','Löse Fragen, um zu starten','Solve questions to begin') : _t('Genel başarın','Totale score','Gesamterfolg','Overall score')),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_t('Genel Başarı Oranın','Je totale slagingspercentage','Deine Gesamtquote','Your Overall Success Rate'), style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        _metric(_t('Çözülen','Beantwoord','Gelöst','Solved'), _t('$total soru','$total vragen','$total Fragen','$total questions'), TxColors.blue),
                        _metric(_t('Deneme','Examens','Prüfungen','Full tests'), _t('${stats['examCount'] ?? 0} tamamlandı','${stats['examCount'] ?? 0} voltooid','${stats['examCount'] ?? 0} abgeschlossen','${stats['examCount'] ?? 0} completed'), TxColors.purple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => widget.onTabRequested?.call(1),
              child: TxCard(
                child: Row(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: TxColors.blue.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.school_rounded, color: TxColors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('Ders Kütüphanesi','Lessenbibliotheek','Lektionsbibliothek','Lesson Library'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(_t('$completedLessonCount / $lessonCount ders tamamlandı','$completedLessonCount / $lessonCount lessen voltooid','$completedLessonCount / $lessonCount Lektionen abgeschlossen','$completedLessonCount / $lessonCount lessons completed'), style: const TextStyle(color: TxColors.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: lessonCount == 0 ? 0.0 : completedLessonCount / lessonCount, minHeight: 5, backgroundColor: Colors.white10, color: TxColors.blue)),
                  ])),
                  const SizedBox(width: 10),
                  const Icon(Icons.chevron_right_rounded, color: TxColors.muted),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => widget.onTabRequested?.call(2),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF1717)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: TxColors.red.withValues(alpha: .2), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.assignment_rounded, color: Colors.white)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(TxText.t('full_exam'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                          Text(_t('${profile.fullExamQuestions} soru • ${profile.examMinutes} dakika • ${profile.examAuthority}','${profile.fullExamQuestions} vragen • ${profile.examMinutes} min • ${profile.examAuthority}','${profile.fullExamQuestions} Fragen • ${profile.examMinutes} Min. • ${profile.examAuthority}','${profile.fullExamQuestions} questions • ${profile.examMinutes} min • ${profile.examAuthority}'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.play_arrow_rounded, color: TxColors.red)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _action(TxText.t('lessons'), _t('Kategorilere göre','Per categorie','Nach Kategorie','By category'), Icons.grid_view_rounded, TxColors.blue, () => widget.onTabRequested?.call(1))),
                const SizedBox(width: 10),
                Expanded(
                  child: _action(_t('Yanlışlarım','Mijn fouten','Meine Fehler','My Mistakes'), _t('$wrongCount soruyu tekrar çöz','$wrongCount vragen herhalen','$wrongCount Fragen wiederholen','Review $wrongCount questions'), Icons.auto_awesome_rounded, TxColors.purple, () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const WrongsScreen()));
                    _load();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lastExam == null)
              TxCard(
                child: Row(
                  children: [
                    const Icon(Icons.history_toggle_off_rounded, color: TxColors.muted),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('Henüz deneme tamamlamadın','Je hebt nog geen volledig examen voltooid','Du hast noch keine Prüfung abgeschlossen','You have not completed a full test yet'), style: TextStyle(fontWeight: FontWeight.w900)),
                          SizedBox(height: 3),
                          Text(_t('İlk denemeni bitirince sonuç kartın burada görünecek.','Na je eerste examen verschijnt je resultaat hier.','Nach deiner ersten Prüfung erscheint das Ergebnis hier.','Your result card will appear here after your first full test.'), style: TextStyle(color: TxColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              _lastExamCard(),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionSessionScreen(examMode: false, questionCount: 5)));
                _load();
              },
              child: TxCard(
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFF3B3422), child: Icon(Icons.bolt_rounded, color: TxColors.gold)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(TxText.t('quick5'), style: TextStyle(fontWeight: FontWeight.w900)),
                          Text(_t('Boş vaktinde 5 soru çöz','Los 5 vragen op in een vrij moment','Löse 5 Fragen zwischendurch','Solve 5 questions in a spare moment'), style: TextStyle(color: TxColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Center(child: BannerAdSlot()),
          ],
        ),
      ),
    );
  }

  Widget _lastExamCard() {
    final total = (lastExam?['total'] as num?)?.toInt() ?? 0;
    final c = (lastExam?['correct'] as num?)?.toInt() ?? 0;
    final w = (lastExam?['wrong'] as num?)?.toInt() ?? 0;
    final e = (lastExam?['empty'] as num?)?.toInt() ?? 0;
    final r = total == 0 ? 0 : (c * 100 / total).round();
    return GestureDetector(
      onTap: () => widget.onTabRequested?.call(3),
      child: TxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Text(_t('Son Çözdüğün Deneme','Je laatste examen','Deine letzte Prüfung','Your Last Full Test'), style: TextStyle(fontWeight: FontWeight.w900)), Spacer(), Icon(Icons.chevron_right_rounded, color: TxColors.muted)]),
            const SizedBox(height: 12),
            Row(
              children: [
                RingProgress(value: r / 100, center: '%$r', caption: _t('Son sonuç','Laatste resultaat','Letztes Ergebnis','Last result'), size: 82),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(_t('$c Doğru','$c Goed','$c Richtig','$c Correct'), style: const TextStyle(color: TxColors.green, fontWeight: FontWeight.w800)),
                      Text(_t('$w Yanlış','$w Fout','$w Falsch','$w Wrong'), style: const TextStyle(color: TxColors.red, fontWeight: FontWeight.w800)),
                      Text(_t('$e Boş','$e Leeg','$e Leer','$e Blank'), style: const TextStyle(color: TxColors.gold, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 145,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: .75)]), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 29),
              const Spacer(),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      );

  Widget _metric(String a, String b, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text(a, style: const TextStyle(color: TxColors.muted, fontSize: 11)),
            const Spacer(),
            Text(b, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
          ],
        ),
      );
}
