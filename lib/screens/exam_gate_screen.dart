import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_config.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../models/country_profile.dart';
import '../services/ad_service.dart';
import '../services/app_settings_service.dart';
import '../services/entitlement_service.dart';
import '../services/local_progress_service.dart';
import '../widgets/tx_widgets.dart';
import '../widgets/banner_ad_slot.dart';
import 'question_session_screen.dart';
import 'store_screen.dart';

class ExamGateScreen extends StatefulWidget {
  final bool embedded;
  const ExamGateScreen({super.key, this.embedded = false});
  @override
  State<ExamGateScreen> createState() => _ExamGateScreenState();
}

class _ExamGateScreenState extends State<ExamGateScreen> {
  final progress = LocalProgressService();
  bool loading = true;
  int fullExamCount = 0;
  int rewardedBonus = 0;
  bool pro = false;
  bool plus = false;

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
    _refresh();
  }

  Future<void> _refresh() async {
    fullExamCount = await progress.todayExamCount();
    rewardedBonus = await progress.rewardedBonusCountToday();
    pro = await EntitlementService.instance.currentPro();
    plus = EntitlementService.instance.plus;
    if (mounted) setState(() => loading = false);
  }

  int get freeFullExamAllowance => AppConfig.freeDailyExamLimit +
      (plus ? AppConfig.maxRewardedExamBonusesPerDay : rewardedBonus);
  bool get fullExamAllowed => pro || fullExamCount < freeFullExamAllowance;
  bool get canEarnRewardedBonus => !pro && !plus && rewardedBonus < AppConfig.maxRewardedExamBonusesPerDay;

  Future<void> _watch() async {
    if (!canEarnRewardedBonus) return;
    if (kIsWeb && kDebugMode) {
      await progress.unlockExtraExamToday();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('Test bonusu: +1 tam deneme açıldı.','Bonus: +1 volledig examen.','Bonus: +1 vollständige Prüfung.','Bonus: +1 full test unlocked.'))),
        );
      return;
    }
    final earned = await AdService.instance.showRewarded();
    if (earned) {
      await progress.unlockExtraExamToday();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('+1 tam deneme hakkın açıldı.','+1 volledig examen ontgrendeld.','+1 vollständige Prüfung freigeschaltet.','+1 full test unlocked.'))),
        );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Reklam şu anda hazır değil. Biraz sonra tekrar deneyebilirsin.','Advertentie is nog niet klaar. Probeer later opnieuw.','Werbung ist noch nicht bereit. Versuche es später erneut.','The ad is not ready yet. Try again later.'))),
      );
    }
  }

  Future<void> _start({required int questions}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionSessionScreen(examMode: true, questionCount: questions),
      ),
    );
    await _refresh();
  }

  Future<void> _openPro() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
    await _refresh();
  }

  String get _fullExamSubtitle {
    if (profile.id == 'de') {
      return _t('${profile.fullExamQuestions} soru • Klasse B hata puanı mantığı • TeoriX pratik süresi','${profile.fullExamQuestions} vragen • Klasse B-foutpunten • TeoriX-oefentimer','${profile.fullExamQuestions} Fragen • Fehlerpunkte wie bei Klasse B • TeoriX-Übungstimer','${profile.fullExamQuestions} questions • Klasse B penalty-point logic • TeoriX practice timer');
    }
    if (profile.id == 'nl') {
      return _t('${profile.fullExamQuestions} puanlanan çalışma sorusu • ${profile.examMinutes} dakika • CBR konuları','${profile.fullExamQuestions} meetellende oefenvragen • ${profile.examMinutes} minuten • CBR-onderwerpen','${profile.fullExamQuestions} gewertete Übungsfragen • ${profile.examMinutes} Minuten • CBR-Themen','${profile.fullExamQuestions} scored practice questions • ${profile.examMinutes} minutes • CBR topics');
    }
    if (profile.id == 'us_ca') {
      return _t('${profile.fullExamQuestions} soruluk TeoriX pratik simülasyonu • California DMV konuları','TeoriX-oefensimulatie met ${profile.fullExamQuestions} vragen • California DMV-onderwerpen','TeoriX-Übungssimulation mit ${profile.fullExamQuestions} Fragen • California-DMV-Themen','${profile.fullExamQuestions}-question TeoriX practice simulation • California DMV topics');
    }
    final weighted = profile.categories.where((c) => c.questionWeight != null).toList();
    if (weighted.isNotEmpty) {
      final split = weighted.map((c) => '${c.questionWeight} ${profile.localizedCategoryLabel(c.id, AppSettingsService.instance.locale)}').join(' • ');
      return _t('${profile.fullExamQuestions} soru • $split','${profile.fullExamQuestions} vragen • $split','${profile.fullExamQuestions} Fragen • $split','${profile.fullExamQuestions} questions • $split');
    }
    return _t('${profile.fullExamQuestions} soru • ${profile.examAuthority} çalışma formatı','${profile.fullExamQuestions} vragen • ${profile.examAuthority}-oefenformaat','${profile.fullExamQuestions} Fragen • ${profile.examAuthority}-Übungsformat','${profile.fullExamQuestions} questions • ${profile.examAuthority} practice format');
  }

  @override
  Widget build(BuildContext context) {
    final usedText = pro ? '∞' : '$fullExamCount / $freeFullExamAllowance';
    final progressValue = pro
        ? 1.0
        : (fullExamCount / freeFullExamAllowance.clamp(1, 99)).clamp(0.0, 1.0).toDouble();
    final body = SafeArea(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(TxText.t('exams'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          Text('${profile.flag} ${profile.localizedCountryName(AppSettingsService.instance.locale)} • ${profile.localizedLicenseLabel(AppSettingsService.instance.locale)}', style: const TextStyle(color: TxColors.muted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(99)),
                      child: Text(profile.examAuthority, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF3939), Color(0xFFC80B18)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.timer_rounded)),
                      const Spacer(),
                      Text('${profile.examMinutes}:00', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ]),
                    const SizedBox(height: 22),
                    Text(TxText.t('full_exam'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(_fullExamSubtitle, style: const TextStyle(color: Colors.white70, height: 1.35)),
                    const SizedBox(height: 7),
                    Text(profile.passRuleSummary(AppSettingsService.instance.locale), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 18),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: TxColors.red),
                      onPressed: fullExamAllowed ? () => _start(questions: profile.fullExamQuestions) : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [const Icon(Icons.play_arrow_rounded), const SizedBox(width: 8), Text(TxText.t('start_exam'))],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _modeCard(TxText.t('quick10'), _t('10 soru • sınırsız pratik','10 vragen • onbeperkt oefenen','10 Fragen • unbegrenzt üben','10 questions • unlimited practice'), Icons.bolt_rounded, TxColors.blue, () => _start(questions: 10))),
                  const SizedBox(width: 10),
                  Expanded(child: _modeCard(TxText.t('quick5'), _t('5 soru • sınırsız pratik','5 vragen • onbeperkt oefenen','5 Fragen • unbegrenzt üben','5 questions • unlimited practice'), Icons.flash_on_rounded, TxColors.purple, () => _start(questions: 5))),
                ]),
                const SizedBox(height: 12),
                TxCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.fact_check_outlined, color: TxColors.gold),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_t('Bugünkü tam denemeler','Volledige examens vandaag','Heutige vollständige Prüfungen','Full tests today'), style: TextStyle(fontWeight: FontWeight.w900))),
                      Text(usedText, style: const TextStyle(fontWeight: FontWeight.w900)),
                    ]),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 7,
                        backgroundColor: Colors.white10,
                        color: fullExamAllowed ? TxColors.green : TxColors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pro
                          ? _t('Pro üyelik: tam denemeler sınırsız.','Pro: onbeperkte volledige examens.','Pro: unbegrenzte vollständige Prüfungen.','Pro: unlimited full tests.')
                          : plus
                              ? _t('Plus: reklamsız kullanım ve günde $freeFullExamAllowance tam deneme. Hızlı 5/10 sınırsız.','Plus: advertentievrij en $freeFullExamAllowance volledige examens per dag. Snel 5/10 onbeperkt.','Plus: werbefrei und $freeFullExamAllowance vollständige Prüfungen pro Tag. Schnell 5/10 unbegrenzt.','Plus: ad-free with $freeFullExamAllowance full tests per day. Quick 5/10 is unlimited.')
                              : _t('Dersler ve Hızlı 5/10 sınırsız. Günde ${AppConfig.freeDailyExamLimit} tam deneme ücretsiz${rewardedBonus > 0 ? ' + $rewardedBonus reklam bonusu' : ''}.','Lessen en Snel 5/10 zijn onbeperkt. ${AppConfig.freeDailyExamLimit} volledige examens per dag zijn gratis${rewardedBonus > 0 ? ' + $rewardedBonus advertentiebonus' : ''}.','Lektionen und Schnell 5/10 sind unbegrenzt. ${AppConfig.freeDailyExamLimit} vollständige Prüfungen pro Tag sind gratis${rewardedBonus > 0 ? ' + $rewardedBonus Werbebonus' : ''}.','Lessons and Quick 5/10 are unlimited. ${AppConfig.freeDailyExamLimit} full tests per day are free${rewardedBonus > 0 ? ' + $rewardedBonus ad bonus' : ''}.'),
                      style: const TextStyle(color: TxColors.muted, fontSize: 12, height: 1.4),
                    ),
                  ]),
                ),
                if (!fullExamAllowed) ...[
                  const SizedBox(height: 12),
                  if (canEarnRewardedBonus)
                    OutlinedButton.icon(
                      onPressed: _watch,
                      icon: const Icon(Icons.ondemand_video_rounded),
                      label: Text(TxText.t('reward_exam')),
                    ),
                  if (canEarnRewardedBonus) const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _openPro,
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: Text(_t('TeoriX Pro ile Sınırsız Aç','Ontgrendel onbeperkt met TeoriX Pro','Unbegrenzt mit TeoriX Pro','Unlock Unlimited with TeoriX Pro')),
                  ),
                ],
                const SizedBox(height: 12),
                TxCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('Sınav / Test Bilgisi','Exameninformatie','Prüfungsinfo','Test Information'), style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 9),
                    Text(profile.localizedFormatNote(AppSettingsService.instance.locale), style: const TextStyle(color: TxColors.muted, height: 1.5)),
                    const SizedBox(height: 7),
                    Text(TxText.t('practice_notice'), style: const TextStyle(color: TxColors.muted, fontSize: 10.5, height: 1.4)),
                  ]),
                ),
                const SizedBox(height: 14),
                const Center(child: BannerAdSlot()),
              ],
            ),
    );
    return widget.embedded ? body : Scaffold(appBar: AppBar(), body: body);
  }

  Widget _modeCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: TxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(subtitle, style: const TextStyle(color: TxColors.muted, fontSize: 12)),
          ]),
        ),
      );
}
