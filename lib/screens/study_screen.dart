import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../data/lesson_repository.dart';
import '../data/question_repository.dart';
import '../models/country_profile.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../services/app_settings_service.dart';
import '../services/local_progress_service.dart';
import '../widgets/tx_widgets.dart';
import 'category_lessons_screen.dart';
import 'question_session_screen.dart';
import 'question_search_screen.dart';
import 'traffic_signs_screen.dart';
import 'curriculum_overview_screen.dart';
import 'flashcards_screen.dart';
import 'pro_tools_screen.dart';

class StudyScreen extends StatefulWidget {
  final bool embedded;
  const StudyScreen({super.key, this.embedded = false});
  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final repo = QuestionRepository();
  final progress = LocalProgressService();
  List<Question> questions = [];
  List<Lesson> lessons = [];
  Map<String, Map<String, int>> categoryStats = {};
  Set<String> favorites = {};
  Set<String> wrongs = {};
  bool loading = true;
  int filter = 0;

  CountryProfile get profile => AppSettingsService.instance.country;
  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl,
        'de' => de,
        'en' => en,
        _ => tr,
      };
  List<ExamCategorySpec> get specs => profile.categories;

  static const colors = <Color>[
    TxColors.green,
    Color(0xFFFF4C58),
    TxColors.gold,
    TxColors.purple,
    TxColors.blue,
    Color(0xFF42C9C2),
    Color(0xFFFF8A3D),
    Color(0xFFB4D455),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final active = profile;
    final all = await repo.loadSeedQuestions(profile: active);
    final lessonData = await LessonRepository().loadLessons(profile: active);
    final stats = await progress.categoryStats();
    final favs = await progress.favoriteIds();
    final w = await progress.wrongIds();
    if (mounted) {
      setState(() {
        questions = all;
        lessons = lessonData;
        categoryStats = stats;
        favorites = favs;
        wrongs = w;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            Row(children: [
              Expanded(child: Text(TxText.t('lessons'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionSearchScreen())),
                icon: const Icon(Icons.search_rounded),
                tooltip: _t('Soru ara','Vragen zoeken','Fragen suchen','Search questions'),
              ),
            ]),
            const SizedBox(height: 5),
            Text(TxText.t('study_topics'), style: const TextStyle(color: TxColors.muted)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF14243B), Color(0xFF101827)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(children: [
                Text(profile.flag, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${profile.localizedCountryName(AppSettingsService.instance.locale)} • ${profile.localizedLicenseLabel(AppSettingsService.instance.locale)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(profile.localizedFormatNote(AppSettingsService.instance.locale), style: const TextStyle(color: TxColors.muted, fontSize: 11, height: 1.35)),
                ])),
              ]),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurriculumOverviewScreen())),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF152C4B), Color(0xFF111A2B)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TxColors.blue.withValues(alpha: .35)),
                ),
                child: Row(children: [
                  const Icon(Icons.menu_book_rounded, color: TxColors.blue, size: 34),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('Tam Ders Programı','Volledig lesprogramma','Vollständiger Lernplan','Full Curriculum'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(_t('${lessons.length} ayrıntılı ders • ${specs.length} ana konu • ilerlemeni takip et','${lessons.length} uitgebreide lessen • ${specs.length} hoofdonderwerpen • volg je voortgang','${lessons.length} ausführliche Lektionen • ${specs.length} Hauptthemen • Fortschritt verfolgen','${lessons.length} detailed lessons • ${specs.length} main topics • track progress'), style: const TextStyle(color: TxColors.muted, fontSize: 11)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: TxColors.blue),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardsScreen())),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF251A48), Color(0xFF111A2B)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TxColors.purple.withValues(alpha: .35)),
                ),
                child: Row(children: [
                  const Icon(Icons.style_rounded, color: TxColors.purple, size: 32),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('Hızlı Tekrar Kartları','Snelle herhaalkaarten','Schnelle Lernkarten','Quick Review Cards'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    SizedBox(height: 3),
                    Text(_t('Derslerin kritik bilgilerini kart kart tekrar et','Herhaal kernpunten kaart voor kaart','Wichtige Punkte Karte für Karte wiederholen','Review key lesson facts card by card'), style: TextStyle(color: TxColors.muted, fontSize: 11)),
                  ])),
                  Icon(Icons.chevron_right_rounded, color: TxColors.purple),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProToolsScreen())),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF24173D), Color(0xFF111A2B)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TxColors.gold.withValues(alpha: .35)),
                ),
                child: Row(children: [
                  const Icon(Icons.auto_graph_rounded, color: TxColors.gold, size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('Kişisel Çalışma Merkezi','Persoonlijk leercentrum','Persönliches Lernzentrum','Personal Study Center'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(_t('Hazırlık skoru • kişiye özel deneme • Son 48 Saat','Gereedheid • persoonlijke test • Laatste 48 Uur','Bereitschaft • persönlicher Test • Letzte 48 Stunden','Readiness • personal test • Final 48 Hours'), style: const TextStyle(color: TxColors.muted, fontSize: 11)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: TxColors.gold),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrafficSignsScreen())),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2A1720), Color(0xFF111A2B)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TxColors.red.withValues(alpha: .35)),
                ),
                child: Row(children: [
                  const Icon(Icons.traffic_rounded, color: TxColors.red, size: 32),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('Trafik İşaretleri','Verkeersborden','Verkehrszeichen','Traffic Signs'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    SizedBox(height: 3),
                    Text(_t('İşaret kütüphanesi • anlamlar • hafıza ipuçları','Bordenbibliotheek • betekenissen • geheugentips','Zeichenbibliothek • Bedeutungen • Merkhilfen','Sign library • meanings • memory tips'), style: TextStyle(color: TxColors.muted, fontSize: 11)),
                  ])),
                  Icon(Icons.chevron_right_rounded, color: TxColors.red),
                ]),
              ),
            ),
            const SizedBox(height: 15),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _filterChip(TxText.t('lessons'), 0),
              _filterChip(_t('Favoriler','Favorieten','Favoriten','Favorites'), 1),
              _filterChip(_t('Zayıf Olduklarım','Zwakke onderwerpen','Schwache Themen','Weak Topics'), 2),
            ]),
            const SizedBox(height: 18),
            if (loading) const Center(child: CircularProgressIndicator()) else ..._buildContent(),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: wrongs.isEmpty
                  ? null
                  : () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionSessionScreen(wrongOnly: true)));
                      _load();
                    },
              child: TxCard(
                child: Row(children: [
                  const Icon(Icons.auto_awesome_rounded, color: TxColors.gold),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('Akıllı Tekrar','Slim herhalen','Smarte Wiederholung','Smart Review'), style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      wrongs.isEmpty
                          ? _t('Yanlışların oluştuğunda kişisel tekrar setin burada açılır.','Je persoonlijke herhaalset verschijnt hier zodra je fouten hebt.','Dein persönliches Wiederholungsset erscheint hier nach Fehlern.','Your personal review set will appear here once you make mistakes.')
                          : _t('${wrongs.length} yanlış sorundan kişisel tekrar seti hazır.','Persoonlijke set klaar met ${wrongs.length} fouten.','Persönliches Set mit ${wrongs.length} Fehlern ist bereit.','Personal review set ready from ${wrongs.length} mistakes.'),
                      style: const TextStyle(color: TxColors.muted, fontSize: 12),
                    ),
                  ])),
                  Icon(wrongs.isEmpty ? Icons.lock_outline_rounded : Icons.play_circle_fill_rounded, color: TxColors.gold),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
    return widget.embedded ? body : Scaffold(appBar: AppBar(), body: body);
  }

  List<Widget> _buildContent() {
    if (filter == 1) {
      final favQuestions = questions.where((q) => favorites.contains(q.id)).toList();
      if (favQuestions.isEmpty) {
        return [_empty(_t('Henüz favori sorun yok','Nog geen favoriete vragen','Noch keine Favoriten','No favorite questions yet'), _t('Soru ekranındaki yıldız simgesinden favori ekleyebilirsin.','Gebruik de ster bij een vraag om favorieten toe te voegen.','Nutze den Stern bei einer Frage, um Favoriten hinzuzufügen.','Use the star on a question to add favorites.'))];
      }
      return [
        _customSetCard(
          _t('Favori Sorularım','Mijn favoriete vragen','Meine Favoriten','My Favorite Questions'),
          _t('${favQuestions.length} soru','${favQuestions.length} vragen','${favQuestions.length} Fragen','${favQuestions.length} questions'),
          Icons.star_rounded,
          TxColors.gold,
          () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: favQuestions.map((e) => e.id).toList())),
            );
            _load();
          },
        ),
      ];
    }
    if (filter == 2) {
      final weak = specs.where((spec) {
        final s = categoryStats[spec.id];
        if (s == null) return false;
        final c = s['correct'] ?? 0, w = s['wrong'] ?? 0;
        return c + w >= 3 && c / (c + w) < .70;
      }).toList();
      if (weak.isEmpty) {
        return [_empty(_t('Henüz zayıf konu belirlenmedi','Nog geen zwak onderwerp','Noch kein schwaches Thema','No weak topic detected yet'), _t('Birkaç soru çözdüğünde başarı oranına göre burada otomatik oluşacak.','Na enkele vragen verschijnt dit automatisch op basis van je score.','Nach einigen Fragen erscheint dies automatisch anhand deiner Leistung.','After a few questions this will appear automatically based on your performance.'))];
      }
      return weak.map((spec) => _categoryCard(specs.indexOf(spec), spec)).toList();
    }
    return List.generate(specs.length, (i) => _categoryCard(i, specs[i]));
  }

  Widget _categoryCard(int i, ExamCategorySpec spec) {
    final category = spec.id;
    final color = colors[i % colors.length];
    final count = questions.where((q) => q.category == category).length;
    final lessonCount = lessons.where((l) => l.category == category).length;
    final s = categoryStats[category] ?? const {'correct': 0, 'wrong': 0};
    final c = s['correct'] ?? 0, w = s['wrong'] ?? 0, attempts = c + w;
    final performance = attempts == 0 ? null : c / attempts;
    final meta = <String>[_t('$lessonCount ders','$lessonCount lessen','$lessonCount Lektionen','$lessonCount lessons'), _t('$count soru','$count vragen','$count Fragen','$count questions')];
    if (spec.studyHours != null) meta.add(_t('${spec.studyHours} saat','${spec.studyHours} uur','${spec.studyHours} Std.','${spec.studyHours} hours'));
    if (spec.questionWeight != null) meta.add(_t('sınavda ${spec.questionWeight} soru','${spec.questionWeight} vragen in examen','${spec.questionWeight} Fragen in Prüfung','${spec.questionWeight} questions in test'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CategoryLessonsScreen(category: category, accent: color)),
          );
          _load();
        },
        child: TxCard(
          child: Column(children: [
            Row(children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
                child: Icon(spec.icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile.localizedCategoryLabel(spec.id, AppSettingsService.instance.locale), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(meta.join(' • '), style: const TextStyle(color: TxColors.muted, fontSize: 11)),
              ])),
              Text(
                performance == null ? '—' : '%${(performance * 100).round()}',
                style: TextStyle(color: performance == null ? TxColors.muted : color, fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: performance ?? 0.0, minHeight: 5, backgroundColor: Colors.white10, color: color),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Text(attempts == 0 ? _t('Henüz başlanmadı','Nog niet gestart','Noch nicht begonnen','Not started yet') : _t('$attempts cevaplandı','$attempts beantwoord','$attempts beantwortet','$attempts answered'), style: const TextStyle(color: TxColors.muted, fontSize: 11)),
              const Spacer(),
              Text(_t('Dersleri Aç →','Open lessen →','Lektionen öffnen →','Open Lessons →'), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _customSetCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: TxCard(
          child: Row(children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              Text(subtitle, style: const TextStyle(color: TxColors.muted)),
            ])),
            const Icon(Icons.chevron_right),
          ]),
        ),
      );

  Widget _empty(String title, String subtitle) => TxCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(children: [
            const Icon(Icons.inbox_outlined, color: TxColors.muted, size: 42),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: TxColors.muted, fontSize: 12)),
          ]),
        ),
      );

  Widget _filterChip(String text, int value) => GestureDetector(
        onTap: () => setState(() => filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: filter == value ? TxColors.red : TxColors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: filter == value ? TxColors.red : Colors.white10),
          ),
          child: Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: filter == value ? Colors.white : TxColors.muted),
          ),
        ),
      );
}
