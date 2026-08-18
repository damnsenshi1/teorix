import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../services/local_progress_service.dart';
import '../services/entitlement_service.dart';
import '../widgets/tx_widgets.dart';
import 'store_screen.dart';

class ExamPlanScreen extends StatefulWidget {
  const ExamPlanScreen({super.key});
  @override
  State<ExamPlanScreen> createState() => _ExamPlanScreenState();
}

class _ExamPlanScreenState extends State<ExamPlanScreen> {
  final progress = LocalProgressService();
  CountryProfile get profile => AppSettingsService.instance.country;
  DateTime? date;
  int goal = 20;
  int solved = 0;
  Map<String, Map<String, int>> categories = {};
  bool pro = false;

  String _t(String tr, String nl, String de, String en) => TxText.pick(tr, nl, de, en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    date = await progress.examDate();
    goal = await progress.dailyGoal();
    solved = await progress.todaySolved();
    categories = await progress.categoryStats();
    pro = await EntitlementService.instance.currentPro();
    if (mounted) setState(() {});
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: date != null && date!.isAfter(now) ? date! : now.add(const Duration(days: 14)),
    );
    if (d != null) {
      await progress.setExamDate(d);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = date == null ? null : date!.difference(DateTime.now()).inDays + 1;
    final remaining = (goal - solved).clamp(0, goal);
    return Scaffold(
      appBar: AppBar(title: Text(TxText.t('exam_plan'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7B2CFF), Color(0xFF35106D)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(children: [
                const Icon(Icons.event_rounded, size: 38, color: Colors.white),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_t('Sınav Tarihi', 'Examendatum', 'Prüfungstermin', 'Test Date'), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(
                    date == null ? _t('Tarih seç', 'Kies datum', 'Datum wählen', 'Choose date') : '${date!.day.toString().padLeft(2, '0')}.${date!.month.toString().padLeft(2, '0')}.${date!.year}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  if (days != null)
                    Text(
                      days <= 0 ? _t('Sınav günü geldi!', 'Examendag is aangebroken!', 'Prüfungstag ist da!', 'Test day is here!') : _t('$days gün kaldı', 'Nog $days dagen', 'Noch $days Tage', '$days days left'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                ])),
                const Icon(Icons.edit_calendar_rounded),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t('Bugünün Planı', 'Plan van vandaag', 'Heutiger Plan', 'Today’s Plan'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 12),
            Text(_t('$solved / $goal soru', '$solved / $goal vragen', '$solved / $goal Fragen', '$solved / $goal questions'), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (solved / goal).clamp(0.0, 1.0).toDouble(), minHeight: 7, backgroundColor: Colors.white10, color: TxColors.green),
            const SizedBox(height: 8),
            Text(
              remaining == 0
                  ? _t('Bugünkü hedef tamamlandı. 🔥', 'Dagdoel voltooid. 🔥', 'Tagesziel geschafft. 🔥', 'Today’s goal is complete. 🔥')
                  : _t('$remaining soru daha çözerek hedefi tamamla.', 'Nog $remaining vragen om je doel te halen.', 'Noch $remaining Fragen bis zum Ziel.', 'Solve $remaining more questions to complete your goal.'),
              style: const TextStyle(color: TxColors.muted),
            ),
          ])),
          const SizedBox(height: 12),
          if (pro)
            TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.auto_awesome_rounded, color: TxColors.gold),
                const SizedBox(width: 8),
                Text(_t('Pro Kişisel Çalışma Planı', 'Pro persoonlijk studieplan', 'Pro persönlicher Lernplan', 'Pro Personal Study Plan'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ]),
              const SizedBox(height: 10),
              Text(_planText(days), style: const TextStyle(color: Color(0xFFD5DEED), height: 1.55)),
            ]))
          else
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
                await _load();
              },
              child: Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF28143F), Color(0xFF111A2B)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TxColors.gold.withValues(alpha: .35)),
                ),
                child: Row(children: [
                  const Icon(Icons.workspace_premium_rounded, color: TxColors.gold, size: 30),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('Kişisel Çalışma Planını Aç', 'Open persoonlijk studieplan', 'Persönlichen Lernplan öffnen', 'Unlock Personal Study Plan'), style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(_t('Zayıf konuların + sınava kalan gün + günlük hedefin birlikte analiz edilir.', 'Zwakke onderwerpen + resterende dagen + dagdoel worden samen geanalyseerd.', 'Schwache Themen + verbleibende Tage + Tagesziel werden gemeinsam analysiert.', 'Weak topics + days left + daily goal are analyzed together.'), style: const TextStyle(color: TxColors.muted, fontSize: 11, height: 1.35)),
                  ])),
                  const Icon(Icons.lock_rounded, color: TxColors.gold),
                ]),
              ),
            ),
          const SizedBox(height: 12),
          TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t('Günlük Soru Hedefi', 'Dagelijks vragendoel', 'Tägliches Frageziel', 'Daily Question Goal'), style: const TextStyle(fontWeight: FontWeight.w900)),
            Slider(
              value: goal.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              label: '$goal',
              onChanged: (v) => setState(() => goal = v.round()),
              onChangeEnd: (v) async => progress.setDailyGoal(v.round()),
            ),
            Center(child: Text(_t('$goal soru / gün', '$goal vragen / dag', '$goal Fragen / Tag', '$goal questions / day'), style: const TextStyle(color: TxColors.muted))),
          ])),
        ],
      ),
    );
  }

  String _planText(int? days) {
    final weakest = _weakest();
    final weak = weakest ?? _t('zayıf konularına', 'je zwakke onderwerpen', 'deine schwachen Themen', 'your weak topics');
    if (days == null) {
      return _t(
        'Sınav tarihini girersen kalan güne göre tempo önerebilirim. Şimdilik günlük $goal soru ve haftada en az 3 tam deneme iyi bir başlangıç.',
        'Vul je examendatum in voor een tempo op maat. Voor nu is $goal vragen per dag en minstens 3 volledige examens per week een goed begin.',
        'Gib deinen Prüfungstermin ein, damit ich das Tempo anpassen kann. Bis dahin sind $goal Fragen pro Tag und mindestens 3 vollständige Prüfungen pro Woche ein guter Start.',
        'Enter your test date for a pace recommendation. For now, $goal questions per day and at least 3 full tests per week is a strong start.',
      );
    }
    if (days <= 3) return _t('Son düzlüktesin. Yeni konu yerine tam deneme, yanlış tekrarları ve $weak odaklan. Hatalarını incele.', 'Laatste sprint: focus op volledige examens, fout-herhaling en $weak. Analyseer je fouten.', 'Endspurt: Fokus auf vollständige Prüfungen, Fehlerwiederholung und $weak. Analysiere deine Fehler.', 'Final stretch: focus on full tests, mistake review and $weak. Review why you missed questions.');
    if (days <= 7) return _t('Son hafta: her gün 1 tam deneme + $goal hedef soru. Özellikle $weak tekrar et.', 'Laatste week: elke dag 1 volledig examen + $goal doelvragen. Herhaal vooral $weak.', 'Letzte Woche: täglich 1 vollständige Prüfung + $goal Zielfragen. Wiederhole besonders $weak.', 'Final week: 1 full test each day + $goal target questions. Prioritize $weak.');
    if (days <= 21) return _t('Dengeli plan: günlük $goal soru, iki günde bir deneme ve haftada iki yanlış tekrar oturumu. Öncelik: $weak.', 'Gebalanceerd plan: $goal vragen per dag, om de dag een examen en twee fout-herhaalsessies per week. Prioriteit: $weak.', 'Ausgewogener Plan: $goal Fragen täglich, jeden zweiten Tag eine Prüfung und zweimal pro Woche Fehlerwiederholung. Priorität: $weak.', 'Balanced plan: $goal questions daily, a full test every other day and two mistake-review sessions per week. Priority: $weak.');
    return _t('Vaktin iyi. Konu konu ilerle, günlük $goal soruyu tamamla ve haftada 2 denemeyle gelişimini ölç. Öncelik: $weak.', 'Je hebt tijd. Werk onderwerp voor onderwerp, haal $goal vragen per dag en meet je voortgang met 2 examens per week. Prioriteit: $weak.', 'Du hast Zeit. Arbeite Thema für Thema, schaffe $goal Fragen täglich und miss deinen Fortschritt mit 2 Prüfungen pro Woche. Priorität: $weak.', 'You have time. Work topic by topic, complete $goal questions daily and measure progress with 2 full tests per week. Priority: $weak.');
  }

  String? _weakest() {
    String? key;
    double worst = 2;
    for (final e in categories.entries) {
      final c = e.value['correct'] ?? 0;
      final w = e.value['wrong'] ?? 0;
      if (c + w < 2) continue;
      final r = c / (c + w);
      if (r < worst) {
        worst = r;
        key = e.key;
      }
    }
    return key == null ? null : profile.localizedCategoryLabel(key, AppSettingsService.instance.locale);
  }
}
