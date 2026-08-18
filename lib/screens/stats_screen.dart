import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../services/local_progress_service.dart';
import '../services/entitlement_service.dart';
import 'store_screen.dart';
import '../widgets/tx_widgets.dart';
import 'wrongs_screen.dart';
import 'history_screen.dart';

class StatsScreen extends StatefulWidget {
  final bool embedded;
  const StatsScreen({super.key, this.embedded = false});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final progress = LocalProgressService();
  CountryProfile get profile => AppSettingsService.instance.country;
  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl,
        'de' => de,
        'en' => en,
        _ => tr,
      };
  late Future<_StatsBundle> _future = _load();

  Future<_StatsBundle> _load() async => _StatsBundle(
        stats: await progress.stats(),
        categories: await progress.categoryStats(),
        lastExam: await progress.lastExamResult(),
        wrongCount: (await progress.wrongIds()).length,
        pro: await EntitlementService.instance.currentPro(),
      );

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: FutureBuilder<_StatsBundle>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          final correct = data.stats['correct'] ?? 0;
          final wrong = data.stats['wrong'] ?? 0;
          final total = correct + wrong;
          final rate = total == 0 ? 0 : ((correct / total) * 100).round();
          final lastEmpty = (data.lastExam?['empty'] as num?)?.toInt() ?? 0;

          return RefreshIndicator(
            onRefresh: () async { _reload(); await _future; },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Text(TxText.t('stats'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(_t('İlerlemeni gör, zayıf noktalarını kapat.','Bekijk je voortgang en pak zwakke punten aan.','Sieh deinen Fortschritt und schließe Lücken.','Track your progress and close weak spots.'), style: TextStyle(color: TxColors.muted)),
                const SizedBox(height: 18),
                if (total == 0 && (data.stats['examCount'] ?? 0) == 0)
                  TxCard(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(children: [
                      Icon(Icons.insights_rounded, size: 52, color: TxColors.muted),
                      SizedBox(height: 12),
                      Text(_t('Henüz istatistik oluşmadı','Nog geen statistieken','Noch keine Statistiken','No statistics yet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      SizedBox(height: 6),
                      Text(_t('Soru çözdükçe ve deneme tamamladıkça gerçek performansın burada oluşacak.','Je echte prestaties verschijnen hier zodra je vragen en examens maakt.','Deine echte Leistung erscheint hier nach Fragen und Prüfungen.','Your real performance will appear here as you solve questions and complete tests.'), textAlign: TextAlign.center, style: TextStyle(color: TxColors.muted, height: 1.4)),
                    ]),
                  ))
                else ...[
                  TxCard(child: Column(children: [
                    RingProgress(value: rate / 100, center: '%$rate', caption: _t('Başarı Oranı','Succespercentage','Erfolgsquote','Success Rate'), size: 146),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: _numberBox('$correct', TxText.t('correct'), TxColors.green)),
                      const SizedBox(width: 8),
                      Expanded(child: _numberBox('$wrong', TxText.t('wrong'), TxColors.red)),
                      const SizedBox(width: 8),
                      Expanded(child: _numberBox('$lastEmpty', _t('Son Deneme Boş','Leeg in laatste examen','Leer in letzter Prüfung','Blank in Last Test'), TxColors.gold)),
                    ])
                  ])),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())), child: _miniAction(Icons.history_rounded, _t('Deneme Geçmişi','Examengeschiedenis','Prüfungsverlauf','Test History'), TxColors.blue))),
                    const SizedBox(width: 10),
                    Expanded(child: GestureDetector(onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const WrongsScreen())); _reload(); }, child: _miniAction(Icons.library_books_rounded, _t('Yanlışlarım (${data.wrongCount})','Mijn fouten (${data.wrongCount})','Meine Fehler (${data.wrongCount})','My Mistakes (${data.wrongCount})'), TxColors.purple))),
                  ]),
                  const SizedBox(height: 12),
                  TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('Konu Bazlı Performans','Prestaties per onderwerp','Leistung nach Thema','Performance by Topic'), style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    ..._categoryRows(data.categories),
                  ])),
                  const SizedBox(height: 12),
                  data.pro ? _readinessCard(data.categories, rate) : _proInsightsLocked(),
                ],
              ],
            ),
          );
        },
      ),
    );
    return widget.embedded ? body : Scaffold(appBar: AppBar(), body: body);
  }

  List<Widget> _categoryRows(Map<String, Map<String, int>> stats) {
    return profile.categories.map((entry) {
      final s = stats[entry.id] ?? const {'correct': 0, 'wrong': 0};
      final c = s['correct'] ?? 0;
      final w = s['wrong'] ?? 0;
      final total = c + w;
      final value = total == 0 ? 0.0 : c / total;
      final color = total == 0 ? TxColors.muted : value >= .75 ? TxColors.green : value >= .55 ? TxColors.gold : TxColors.red;
      return _bar(profile.localizedCategoryLabel(entry.id, AppSettingsService.instance.locale), value, color, attempts: total);
    }).toList();
  }


  Widget _proInsightsLocked() => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF26143D), Color(0xFF111A2B)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: TxColors.gold.withValues(alpha: .35))),
      child: Row(children: [
        Icon(Icons.workspace_premium_rounded, color: TxColors.gold, size: 30),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_t('Pro Hazırlık Analizi','Pro voorbereidingsanalyse','Pro-Vorbereitungsanalyse','Pro Readiness Analysis'), style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 4), Text(_t('Zayıf konuna göre sınava hazırlık yorumu ve kişisel önerileri aç.','Ontgrendel persoonlijke aanbevelingen op basis van zwakke onderwerpen.','Persönliche Empfehlungen anhand schwacher Themen freischalten.','Unlock personal recommendations based on your weak topics.'), style: TextStyle(color: TxColors.muted, fontSize: 12))])),
        Icon(Icons.lock_rounded, color: TxColors.gold),
      ]),
    ),
  );

  Widget _readinessCard(Map<String, Map<String, int>> categories, int overallRate) {
    String message;
    if (overallRate == 0) {
      message = _t('Hazırlık seviyeni hesaplamak için biraz soru çöz.','Los eerst een paar vragen op om je voorbereiding te berekenen.','Löse zuerst einige Fragen, um deine Bereitschaft zu berechnen.','Solve a few questions first to calculate your readiness.');
    } else {
      String? weakest;
      double weakestRate = 2;
      for (final e in categories.entries) {
        final c = e.value['correct'] ?? 0;
        final w = e.value['wrong'] ?? 0;
        if (c + w < 3) continue;
        final r = c / (c + w);
        if (r < weakestRate) { weakestRate = r; weakest = e.key; }
      }
      final pretty = weakest == null ? null : profile.localizedCategoryLabel(weakest, AppSettingsService.instance.locale);
      if (overallRate >= 80) {
        message = pretty == null ? _t('Hazırlık seviyen güçlü görünüyor.','Je voorbereiding ziet er sterk uit.','Deine Vorbereitung wirkt stark.','Your readiness looks strong.') : _t('Hazırlık seviyen güçlü. $pretty konusunu biraz daha pekiştir.','Je voorbereiding is sterk. Versterk $pretty nog wat.','Deine Vorbereitung ist stark. Festige $pretty noch etwas.','Your readiness is strong. Reinforce $pretty a little more.');
      } else if (overallRate >= 70) {
        message = pretty == null ? _t('Sınırın üzerindesin; birkaç deneme daha çöz.','Je zit boven de grens; doe nog een paar examens.','Du liegst über der Grenze; löse noch ein paar Prüfungen.','You are above the threshold; complete a few more full tests.') : _t('İyi gidiyorsun. Özellikle $pretty konusuna ağırlık ver.','Je gaat goed. Focus vooral op $pretty.','Du bist auf gutem Weg. Konzentriere dich besonders auf $pretty.','You are doing well. Focus especially on $pretty.');
      } else {
        message = pretty == null ? _t('Biraz daha çalışma gerekiyor.','Je hebt nog wat extra oefening nodig.','Du brauchst noch etwas Übung.','A bit more study is needed.') : _t('Şimdilik tekrar faydalı olur. Önceliğin: $pretty.','Extra herhaling helpt. Prioriteit: $pretty.','Weitere Wiederholung hilft. Priorität: $pretty.','More review will help. Priority: $pretty.');
      }
    }
    return TxCard(child: Row(children: [const Icon(Icons.psychology_alt_rounded, color: TxColors.purple), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_t('Sınava Hazır mısın?','Ben je klaar voor het examen?','Bist du prüfungsbereit?','Are You Test Ready?'), style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(message, style: const TextStyle(color: TxColors.muted, fontSize: 12))]))]));
  }

  Widget _numberBox(String number, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .035), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [Text(number, style: TextStyle(fontSize: 23, color: color, fontWeight: FontWeight.w900)), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: TxColors.muted))]),
  );

  Widget _miniAction(IconData icon, String text, Color color) => TxCard(child: Row(children: [Icon(icon, color: color), const SizedBox(width: 9), Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)))]));

  Widget _bar(String label, double value, Color color, {required int attempts}) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(children: [SizedBox(width: 110, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12)), Text(_t('$attempts cevap','$attempts antwoorden','$attempts Antworten','$attempts answers'), style: const TextStyle(fontSize: 9, color: TxColors.muted))])), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: value, minHeight: 5, backgroundColor: Colors.white10, color: color))), const SizedBox(width: 9), SizedBox(width: 34, child: Text(attempts == 0 ? '—' : '%${(value * 100).round()}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)))]),
  );
}

class _StatsBundle {
  final Map<String, int> stats;
  final Map<String, Map<String, int>> categories;
  final Map<String, dynamic>? lastExam;
  final int wrongCount;
  final bool pro;
  const _StatsBundle({required this.stats, required this.categories, required this.lastExam, required this.wrongCount, required this.pro});
}
