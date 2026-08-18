import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/question_repository.dart';
import '../models/question.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../services/entitlement_service.dart';
import '../services/local_progress_service.dart';
import '../widgets/tx_widgets.dart';
import 'exam_plan_screen.dart';
import 'question_session_screen.dart';
import 'store_screen.dart';

class ProToolsScreen extends StatefulWidget {
  const ProToolsScreen({super.key});

  @override
  State<ProToolsScreen> createState() => _ProToolsScreenState();
}

class _ProToolsScreenState extends State<ProToolsScreen> {
  final progress = LocalProgressService();
  final repo = QuestionRepository();
  bool loading = true;
  bool pro = false;
  List<Question> questions = [];
  Set<String> wrongs = {};
  Map<String, Map<String, int>> categoryStats = {};
  DateTime? examDate;

  CountryProfile get profile => AppSettingsService.instance.country;
  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl,
        'de' => de,
        'en' => en,
        _ => tr,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait<dynamic>([
      EntitlementService.instance.currentPro(),
      repo.loadSeedQuestions(profile: profile),
      progress.wrongIds(),
      progress.categoryStats(),
      progress.examDate(),
    ]);
    if (!mounted) return;
    setState(() {
      pro = values[0] as bool;
      questions = values[1] as List<Question>;
      wrongs = values[2] as Set<String>;
      categoryStats = values[3] as Map<String, Map<String, int>>;
      examDate = values[4] as DateTime?;
      loading = false;
    });
  }

  double _categoryRate(String category) {
    final stat = categoryStats[category];
    if (stat == null) return .5;
    final c = stat['correct'] ?? 0;
    final w = stat['wrong'] ?? 0;
    final total = c + w;
    if (total == 0) return .5;
    return c / total;
  }

  int _readiness() {
    var attempts = 0;
    var correct = 0;
    var covered = 0;
    for (final spec in profile.categories) {
      final stat = categoryStats[spec.id];
      final c = stat?['correct'] ?? 0;
      final w = stat?['wrong'] ?? 0;
      if (c + w >= 5) covered++;
      attempts += c + w;
      correct += c;
    }
    if (attempts == 0) return 0;
    final accuracy = correct / attempts;
    final coverage = covered / max(1, profile.categories.length);
    return ((accuracy * .75 + coverage * .25) * 100).round().clamp(0, 100);
  }

  List<String> _personalSet({int count = 30, bool final48 = false}) {
    if (questions.isEmpty) return [];
    final target = min(count, questions.length);
    final selected = <String>[];
    final used = <String>{};
    void add(Question q) {
      if (used.add(q.id) && selected.length < target) selected.add(q.id);
    }

    final wrongPool = questions.where((q) => wrongs.contains(q.id)).toList()..shuffle();
    for (final q in wrongPool) {
      add(q);
    }

    final categories = [...profile.categories]
      ..sort((a, b) => _categoryRate(a.id).compareTo(_categoryRate(b.id)));
    for (final spec in categories) {
      final pool = questions.where((q) => q.category == spec.id && !used.contains(q.id)).toList()
        ..shuffle();
      final quota = final48 ? 8 : 6;
      for (final q in pool.take(quota)) {
        add(q);
      }
      if (selected.length >= target) break;
    }

    if (final48 && selected.length < target) {
      final hard = questions.where((q) => q.difficulty.toLowerCase() == 'hard' && !used.contains(q.id)).toList()..shuffle();
      for (final q in hard) {
        add(q);
      }
    }

    if (selected.length < target) {
      final rest = questions.where((q) => !used.contains(q.id)).toList()..shuffle();
      for (final q in rest) {
        add(q);
      }
    }
    selected.shuffle();
    return selected;
  }

  Future<void> _openPaywall() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
    await _load();
  }

  Future<void> _startPersonal() async {
    if (!pro) { await _openPaywall(); return; }
    final ids = _personalSet(count: min(30, profile.fullExamQuestions));
    if (ids.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: ids, examMode: true, questionCount: ids.length)),
    );
    await _load();
  }

  Future<void> _startFinal48() async {
    if (!pro) { await _openPaywall(); return; }
    final desired = profile.fullExamQuestions <= 30 ? profile.fullExamQuestions : 40;
    final ids = _personalSet(count: desired, final48: true);
    if (ids.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: ids, examMode: true, questionCount: ids.length)),
    );
    await _load();
  }

  String _examDistance() {
    final d = examDate;
    if (d == null) return _t('Sınav tarihi seçilmedi', 'Geen examendatum ingesteld', 'Kein Prüfungstermin gesetzt', 'No test date set');
    final now = DateTime.now();
    final days = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days < 0) return _t('Sınav tarihi geçti', 'Examendatum is voorbij', 'Prüfungstermin ist vorbei', 'Test date has passed');
    if (days == 0) return _t('Sınav bugün', 'Examen is vandaag', 'Prüfung ist heute', 'Test is today');
    if (days == 1) return _t('Sınava 1 gün kaldı', 'Nog 1 dag', 'Noch 1 Tag', '1 day remaining');
    return _t('Sınava $days gün kaldı', 'Nog $days dagen', 'Noch $days Tage', '$days days remaining');
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final readiness = _readiness();
    final weak = [...profile.categories]..sort((a, b) => _categoryRate(a.id).compareTo(_categoryRate(b.id)));
    return Scaffold(
      appBar: AppBar(title: Text(_t('Kişisel Çalışma Merkezi', 'Persoonlijk leercentrum', 'Persönliches Lernzentrum', 'Personal Study Center'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF23153C), Color(0xFF10192A)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: TxColors.purple.withValues(alpha: .4)),
              ),
              child: Row(children: [
                RingProgress(value: readiness / 100, center: '%$readiness', caption: _t('hazırlık', 'klaar', 'bereit', 'ready'), size: 112),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_t('Sınava Hazırlık Skoru', 'Examengereedheid', 'Prüfungsbereitschaft', 'Test Readiness Score'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 5),
                  Text(_examDistance(), style: const TextStyle(color: TxColors.gold, fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(_t('Skor; cevap doğruluğu ve konu kapsamından hesaplanır. Gerçek sınav sonucu garantisi değildir.', 'De score combineert nauwkeurigheid en onderwerpdekking. Geen garantie op het echte examen.', 'Der Wert kombiniert Trefferquote und Themenabdeckung. Keine Garantie für die echte Prüfung.', 'The score combines accuracy and topic coverage. It is not a guarantee of the real test result.'), style: const TextStyle(color: TxColors.muted, fontSize: 10, height: 1.35)),
                ])),
              ]),
            ),
            const SizedBox(height: 12),
            if (!pro)
              TxCard(
                color: const Color(0xFF18142B),
                child: Row(children: [
                  const Icon(Icons.lock_rounded, color: TxColors.gold, size: 30),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_t('Kişiye özel denemeler ve Son 48 Saat planı Pro ile açılır.', 'Persoonlijke examens en Laatste 48 Uur zijn beschikbaar met Pro.', 'Persönliche Tests und Letzte 48 Stunden sind mit Pro verfügbar.', 'Personal tests and Final 48 Hours are available with Pro.'), style: const TextStyle(fontWeight: FontWeight.w800))),
                  TextButton(onPressed: _openPaywall, child: const Text('PRO')),
                ]),
              ),
            const SizedBox(height: 12),
            _actionCard(
              icon: Icons.auto_awesome_rounded,
              color: TxColors.purple,
              title: _t('Kişiye Özel Deneme', 'Persoonlijke oefentest', 'Persönlicher Test', 'Personalized Test'),
              subtitle: _t('Yanlışların + en zayıf konularından otomatik bir set oluşturur.', 'Maakt automatisch een set van je fouten en zwakste onderwerpen.', 'Erstellt automatisch einen Test aus Fehlern und schwächsten Themen.', 'Builds a test automatically from your mistakes and weakest topics.'),
              trailing: wrongs.isEmpty ? _t('Veri topluyor', 'Data verzamelen', 'Sammelt Daten', 'Learning') : '${wrongs.length} ${_t('yanlış', 'fouten', 'Fehler', 'mistakes')}',
              onTap: _startPersonal,
            ),
            const SizedBox(height: 10),
            _actionCard(
              icon: Icons.bolt_rounded,
              color: TxColors.gold,
              title: _t('Son 48 Saat Modu', 'Laatste 48 Uur', 'Letzte 48 Stunden', 'Final 48 Hours'),
              subtitle: _t('Yanlışlarını, zayıf konuları ve zor soruları tek yoğun tekrar setinde toplar.', 'Bundelt fouten, zwakke onderwerpen en moeilijke vragen in één intensieve set.', 'Bündelt Fehler, schwache Themen und schwere Fragen in einem Intensiv-Set.', 'Combines mistakes, weak topics and difficult questions into one intensive review set.'),
              trailing: _examDistance(),
              onTap: _startFinal48,
            ),
            const SizedBox(height: 10),
            _actionCard(
              icon: Icons.event_available_rounded,
              color: TxColors.blue,
              title: _t('Sınav Tarihi ve Plan', 'Examendatum en plan', 'Prüfungstermin und Plan', 'Test Date & Plan'),
              subtitle: _t('Sınav tarihini belirle; günlük çalışma temposunu buna göre takip et.', 'Stel je examendatum in en volg het dagelijkse tempo.', 'Lege den Prüfungstermin fest und verfolge dein Lerntempo.', 'Set your test date and track your daily study pace.'),
              trailing: _examDistance(),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamPlanScreen()));
                await _load();
              },
            ),
            const SizedBox(height: 18),
            Text(_t('Konu Önceliğin', 'Onderwerpprioriteit', 'Themenpriorität', 'Topic Priority'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            ...weak.take(min(5, weak.length)).map((spec) {
              final rate = _categoryRate(spec.id);
              final stat = categoryStats[spec.id];
              final attempts = (stat?['correct'] ?? 0) + (stat?['wrong'] ?? 0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: TxCard(child: Row(children: [
                  Icon(spec.icon, color: rate < .6 ? TxColors.red : rate < .75 ? TxColors.gold : TxColors.green),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(profile.localizedCategoryLabel(spec.id, AppSettingsService.instance.locale), style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: attempts == 0 ? 0 : rate, backgroundColor: Colors.white10, color: rate < .6 ? TxColors.red : rate < .75 ? TxColors.gold : TxColors.green),
                  ])),
                  const SizedBox(width: 12),
                  Text(attempts == 0 ? '—' : '%${(rate * 100).round()}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ])),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({required IconData icon, required Color color, required String title, required String subtitle, required String trailing, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: TxCard(child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: TxColors.muted, fontSize: 11, height: 1.35)),
          const SizedBox(height: 5),
          Text(trailing, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
        ])),
        const Icon(Icons.chevron_right_rounded),
      ])),
    );
  }
}
