import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../data/lesson_repository.dart';
import '../models/country_profile.dart';
import '../models/lesson.dart';
import '../services/app_settings_service.dart';
import '../services/local_progress_service.dart';
import '../widgets/tx_widgets.dart';
import 'category_lessons_screen.dart';
import 'lesson_detail_screen.dart';

class CurriculumOverviewScreen extends StatefulWidget {
  const CurriculumOverviewScreen({super.key});
  @override
  State<CurriculumOverviewScreen> createState() => _CurriculumOverviewScreenState();
}

class _CurriculumOverviewScreenState extends State<CurriculumOverviewScreen> {
  final progress = LocalProgressService();
  List<Lesson> lessons = [];
  Set<String> completed = {};
  bool loading = true;

  CountryProfile get profile => AppSettingsService.instance.country;
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
    final all = await LessonRepository().loadLessons(profile: profile);
    final done = await progress.completedLessonIds();
    if (mounted) {
      setState(() {
        lessons = all;
        completed = done;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDone = lessons.where((l) => completed.contains(l.id)).length;
    final total = lessons.length;
    final hoursText = profile.totalStudyHours > 0 ? TxText.pick(' • ${profile.totalStudyHours} teorik ders saati',' • ${profile.totalStudyHours} theorie-uren',' • ${profile.totalStudyHours} Theoriestunden',' • ${profile.totalStudyHours} theory hours') : '';
    return Scaffold(
      appBar: AppBar(title: Text(TxText.pick('Ders Yol Haritası','Leerroute','Lernpfad','Learning Roadmap'))),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF17263F), Color(0xFF0D1728)]),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.route_rounded, color: TxColors.red),
                          const SizedBox(width: 9),
                          Expanded(child: Text(TxText.pick('${profile.flag} ${profile.localizedCountryName(AppSettingsService.instance.locale)} ders yol haritası','${profile.flag} ${profile.localizedCountryName(AppSettingsService.instance.locale)} leerroute','${profile.flag} ${profile.localizedCountryName(AppSettingsService.instance.locale)} Lernpfad','${profile.flag} ${profile.localizedCountryName(AppSettingsService.instance.locale)} learning roadmap'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                        ]),
                        const SizedBox(height: 9),
                        Text(TxText.pick('$total ders$hoursText • ${specs.length} ana konu','$total lessen$hoursText • ${specs.length} hoofdonderwerpen','$total Lektionen$hoursText • ${specs.length} Hauptthemen','$total lessons$hoursText • ${specs.length} main topics'), style: const TextStyle(color: TxColors.muted, fontSize: 12)),
                        const SizedBox(height: 5),
                        Text(profile.localizedFormatNote(AppSettingsService.instance.locale), style: const TextStyle(color: TxColors.muted, fontSize: 10.5, height: 1.35)),
                        const SizedBox(height: 15),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0.0 : totalDone / total,
                            minHeight: 8,
                            backgroundColor: Colors.white10,
                            color: TxColors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(TxText.pick('$totalDone / $total ders tamamlandı','$totalDone / $total lessen voltooid','$totalDone / $total Lektionen abgeschlossen','$totalDone / $total lessons completed'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(specs.length, (i) => _categoryCard(i, specs[i])),
                    const SizedBox(height: 4),
                    Text(
                      TxText.pick('Dersler ve sorular TeoriX için özgün çalışma içeriğidir. ${profile.examAuthority} tarafından yayımlanan resmî sınav sorularının kopyası değildir.','Lessen en vragen zijn originele TeoriX-oefeninhoud en geen kopieën van officiële examenvragen van ${profile.examAuthority}.','Lektionen und Fragen sind eigene TeoriX-Übungsinhalte und keine Kopien amtlicher Prüfungsfragen von ${profile.examAuthority}.','Lessons and questions are original TeoriX study content and are not copies of official exam questions published by ${profile.examAuthority}.'),
                      style: const TextStyle(color: TxColors.muted, fontSize: 10.5, height: 1.4),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _categoryCard(int i, ExamCategorySpec spec) {
    final catLessons = lessons.where((l) => l.category == spec.id).toList()..sort((a, b) => a.order.compareTo(b.order));
    final done = catLessons.where((l) => completed.contains(l.id)).length;
    final modules = <String>{...catLessons.map((l) => l.module)};
    final firstIncomplete = catLessons.where((l) => !completed.contains(l.id)).firstOrNull;
    final value = catLessons.isEmpty ? 0.0 : done / catLessons.length;
    final color = colors[i % colors.length];
    final meta = <String>[TxText.pick('${catLessons.length} ders','${catLessons.length} lessen','${catLessons.length} Lektionen','${catLessons.length} lessons'), TxText.pick('${modules.length} bölüm','${modules.length} onderdelen','${modules.length} Abschnitte','${modules.length} sections')];
    if (spec.studyHours != null) meta.add(TxText.pick('${spec.studyHours} saat','${spec.studyHours} uur','${spec.studyHours} Std.','${spec.studyHours} hours'));
    if (spec.questionWeight != null) meta.add(TxText.pick('sınavda ${spec.questionWeight} soru','${spec.questionWeight} vragen in examen','${spec.questionWeight} Prüfungsfragen','${spec.questionWeight} test questions'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(13)),
              child: Icon(spec.icon, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile.localizedCategoryLabel(spec.id, AppSettingsService.instance.locale), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(meta.join(' • '), style: const TextStyle(color: TxColors.muted, fontSize: 10.5)),
            ])),
            Text('%${(value * 100).round()}', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: value, minHeight: 6, backgroundColor: Colors.white10, color: color),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: modules
                .map((m) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .04), borderRadius: BorderRadius.circular(99)),
                      child: Text(m, style: const TextStyle(color: TxColors.muted, fontSize: 9.5)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 13),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CategoryLessonsScreen(category: spec.id, accent: color)),
                  );
                  _load();
                },
                child: Text(TxText.pick('Tüm Dersler','Alle lessen','Alle Lektionen','All Lessons')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: firstIncomplete == null
                    ? null
                    : () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: firstIncomplete)));
                        _load();
                      },
                child: Text(firstIncomplete == null ? TxText.pick('Tamamlandı ✓','Voltooid ✓','Abgeschlossen ✓','Completed ✓') : TxText.pick('Devam Et','Doorgaan','Weiter','Continue')),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
