import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_config.dart';
import '../core/app_localizations.dart';
import '../models/country_profile.dart';
import '../data/question_repository.dart';
import '../data/lesson_repository.dart';
import '../data/traffic_sign_repository.dart';
import '../models/question.dart';
import '../models/lesson.dart';
import '../models/traffic_sign.dart';
import '../services/ad_service.dart';
import '../services/local_progress_service.dart';
import '../services/entitlement_service.dart';
import '../services/sync_service.dart';
import '../services/supabase_service.dart';
import '../services/app_settings_service.dart';
import '../widgets/tx_widgets.dart';
import '../widgets/traffic_sign_visual.dart';
import '../widgets/banner_ad_slot.dart';
import 'store_screen.dart';
import 'lesson_detail_screen.dart';

class QuestionSessionScreen extends StatefulWidget {
  final String? category;
  final String? lessonId;
  final bool examMode;
  final bool wrongOnly;
  final int? questionCount;
  final List<String>? questionIds;
  const QuestionSessionScreen({
    super.key,
    this.category,
    this.lessonId,
    this.examMode = false,
    this.wrongOnly = false,
    this.questionCount,
    this.questionIds,
  });

  @override
  State<QuestionSessionScreen> createState() => _QuestionSessionScreenState();
}

class _QuestionSessionScreenState extends State<QuestionSessionScreen> {
  final repo = QuestionRepository();
  final progress = LocalProgressService();
  List<Question> questions = [];
  final Map<int, int> answers = {};
  final Set<int> flagged = {};
  Set<String> favorites = {};
  Map<String, Lesson> lessonMap = {};
  Map<String, TrafficSignInfo> signMap = {};
  int index = 0;
  bool loading = true;
  bool finished = false;
  bool finishing = false;
  Timer? timer;
  int secondsLeft = 45 * 60;

  CountryProfile get profile => AppSettingsService.instance.country;
  bool get isFullExam => widget.examMode && questions.length == profile.fullExamQuestions;
  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl, 'de' => de, 'en' => en, _ => tr,
      };

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    var all = await repo.loadSeedQuestions(profile: profile);
    if (widget.category != null) all = repo.byCategory(all, widget.category!);
    if (widget.lessonId != null) all = repo.byLesson(all, widget.lessonId!);
    if (widget.questionIds != null) {
      final ids = widget.questionIds!.toSet();
      all = all.where((q) => ids.contains(q.id)).toList();
    }
    if (widget.wrongOnly) {
      final ids = await progress.wrongIds();
      all = all.where((q) => ids.contains(q.id)).toList();
    }
    favorites = await progress.favoriteIds();
    final lessons = await LessonRepository().loadLessons(profile: profile);
    final signs = await TrafficSignRepository().load(profile: profile);
    lessonMap = {for (final lesson in lessons) lesson.id: lesson};
    signMap = {for (final sign in signs) sign.id: sign};
    final wanted = widget.questionCount ?? (widget.examMode ? profile.fullExamQuestions : all.length);
    if (all.isNotEmpty && wanted < all.length) all = repo.examFrom(all, count: wanted, profile: profile);
    all = await repo.localizeQuestions(all, profile: profile);
    if (widget.examMode) {
      secondsLeft = wanted == profile.fullExamQuestions
          ? profile.examMinutes * 60
          : wanted <= 5
              ? 5 * 60
              : wanted <= 10
                  ? 10 * 60
                  : ((wanted * 55).clamp(300, profile.examMinutes * 60)).toInt();
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || finished) return;
        if (secondsLeft <= 1) { _finish(); } else { setState(() => secondsLeft--); }
      });
    }
    if (mounted) setState(() { questions = all; loading = false; });
  }

  Future<void> _choose(int choice) async {
    if (widget.examMode) { setState(() => answers[index] = choice); return; }
    if (answers.containsKey(index)) return;
    final q = questions[index];
    final correct = choice == q.correctIndex;
    await progress.markAnswer(q.id, correct, category: q.category, lessonId: q.lessonId, selectedIndex: choice, correctIndex: q.correctIndex);
    if (mounted) setState(() => answers[index] = choice);
  }

  Future<void> _toggleFavorite() async {
    if (questions.isEmpty) return;
    final id = questions[index].id;
    await progress.toggleFavorite(id);
    if (!mounted) return;
    setState(() => favorites.contains(id) ? favorites.remove(id) : favorites.add(id));
  }


  Future<void> _openNote() async {
    if (questions.isEmpty) return;
    final q = questions[index];
    final controller = TextEditingController(text: await progress.noteFor(q.id));
    if (!mounted) return;
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(_t('Soru Notum','Mijn notitie','Meine Notiz','My Question Note')),
      content: TextField(controller: controller, maxLines: 5, decoration: InputDecoration(hintText: _t('Bu soruyla ilgili kendi notunu yaz...','Schrijf je eigen notitie over deze vraag...','Schreibe deine eigene Notiz zu dieser Frage...','Write your own note about this question...'))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(TxText.t('cancel'))), FilledButton(onPressed: () async { await progress.saveNote(q.id, controller.text); if (mounted) Navigator.pop(context); }, child: Text(TxText.t('save')))],
    ));
    controller.dispose();
  }

  Future<void> _reportCurrent() async {
    if (questions.isEmpty) return;
    final q = questions[index];
    String reason = _t('Yanlış / şüpheli cevap','Fout / twijfelachtig antwoord','Falsche / fragliche Antwort','Wrong / questionable answer');
    final detail = TextEditingController();
    if (!mounted) return;
    final send = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(
      title: Text(_t('Hatalı Soru Bildir','Vraag melden','Frage melden','Report Question')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<String>(initialValue: reason, items: [_t('Yanlış / şüpheli cevap','Fout / twijfelachtig antwoord','Falsche / fragliche Antwort','Wrong / questionable answer'), _t('Yazım hatası','Taalfout','Schreibfehler','Typo'), _t('Açıklama yetersiz','Uitleg onvoldoende','Erklärung unzureichend','Explanation is insufficient'), _t('Güncelliğini yitirmiş','Verouderd','Veraltet','Outdated'), _t('Diğer','Anders','Sonstiges','Other')].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setLocal(() => reason = v ?? reason)), const SizedBox(height: 10), TextField(controller: detail, maxLines: 3, decoration: InputDecoration(hintText: _t('Detay (isteğe bağlı)','Detail (optioneel)','Details (optional)','Detail (optional)')))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(TxText.t('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(_t('Gönder','Versturen','Senden','Send')))],
    ))) ?? false;
    if (send) {
      final msg = await SyncService.submitQuestionReport(questionId: q.id, reason: reason, detail: detail.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    detail.dispose();
  }

  Future<void> _teacher() async {
    if (questions.isEmpty) return;
    await _openTeacherForQuestion(questions[index]);
  }

  Future<void> _openTeacherForQuestion(Question q) async {
    final pro = await EntitlementService.instance.currentPro();
    final plus = EntitlementService.instance.plus;
    if (pro) {
      if (mounted) _showTeacherSheet(q, pro: true);
      return;
    }
    final used = await progress.teacherUsesToday();
    final bonus = await progress.teacherBonusToday();
    final limit = AppConfig.freeDailyTeacherLimit +
        (plus ? AppConfig.maxRewardedTeacherBonusesPerDay : bonus);
    if (used < limit) {
      await progress.consumeTeacherUse();
      if (mounted) _showTeacherSheet(q, pro: false);
      return;
    }
    if (!mounted) return;
    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_t('Akıllı Öğretmen Limiti','Limiet Slimme Leraar','Limit Smarter Lehrer','Smart Teacher Limit')),
        content: Text(plus
            ? _t('Plus ile reklamsız günlük $limit Akıllı Öğretmen hakkını kullandın. Sınırsız gelişmiş kullanım için Pro’ya geçebilirsin.','Je hebt je $limit advertentievrije Slimme-Leraar-gebruiken van vandaag met Plus gebruikt. Ga naar Pro voor onbeperkt uitgebreid gebruik.','Du hast deine $limit werbefreien Smarter-Lehrer-Nutzungen mit Plus heute verwendet. Für unbegrenzte erweiterte Nutzung kannst du Pro wählen.','You used today’s $limit ad-free Smart Teacher uses with Plus. Upgrade to Pro for unlimited advanced use.')
            : _t('Bugünkü ${AppConfig.freeDailyTeacherLimit} ücretsiz akıllı açıklamanı kullandın. İstersen reklam izleyerek +1 hak açabilir veya Pro ile gelişmiş kullanıma geçebilirsin.','Je hebt vandaag ${AppConfig.freeDailyTeacherLimit} gratis slimme uitleg gebruikt. Bekijk een advertentie voor +1 of ga naar Pro.','Du hast heute ${AppConfig.freeDailyTeacherLimit} kostenlose smarte Erklärungen genutzt. Werbung ansehen für +1 oder zu Pro wechseln.','You used today’s ${AppConfig.freeDailyTeacherLimit} free smart explanations. Watch an ad for +1 or upgrade to Pro.')), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_t('Kapat','Sluiten','Schließen','Close'))),
          if (!plus && bonus < AppConfig.maxRewardedTeacherBonusesPerDay) TextButton(onPressed: () => Navigator.pop(context, 'ad'), child: Text(_t('Reklam İzle • +1','Bekijk advertentie • +1','Werbung ansehen • +1','Watch Ad • +1'))),
          FilledButton(onPressed: () => Navigator.pop(context, 'pro'), child: Text(_t('Pro’ya Geç','Naar Pro','Zu Pro','Go Pro'))),
        ],
      ),
    );
    if (action == 'pro') {
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
      return;
    }
    if (action == 'ad') {
      bool earned = false;
      if (kIsWeb && kDebugMode) {
        earned = true;
      } else {
        earned = await AdService.instance.showRewarded();
      }
      if (earned) {
        await progress.unlockTeacherUseToday();
        await progress.consumeTeacherUse();
        if (!mounted) return;
        _showTeacherSheet(q, pro: false);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('Reklam şu anda hazır değil. Biraz sonra tekrar deneyebilirsin.','De advertentie is nog niet klaar. Probeer het straks opnieuw.','Die Werbung ist noch nicht bereit. Versuche es später erneut.','The ad is not ready yet. Try again shortly.'))));
      }
    }
  }

  void _showTeacherSheet(Question q, {required bool pro}) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.psychology_alt_rounded, color: TxColors.purple),
            const SizedBox(width: 9),
            Text(TxText.t('smart_teacher'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const Spacer(),
            if (pro) const Text('PRO', style: TextStyle(color: TxColors.gold, fontSize: 10, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 12),
          Text(q.explanation, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 14),
          TxCard(child: Text(_t('Hafıza ipucu: Sorunun anahtar kelimelerini bul, kuralı önce belirle; sonra şıkları ele. “${_pretty(q.category)}” sorularında kavramı ezberlemek yerine nedenini anlamaya odaklan.','Geheugentip: zoek de sleutelwoorden, bepaal eerst de regel en elimineer daarna de opties. Begrijp bij “${_pretty(q.category)}” vooral waarom de regel geldt.','Merktipp: Finde die Schlüsselwörter, bestimme zuerst die Regel und schließe dann Antworten aus. Verstehe bei „${_pretty(q.category)}“ vor allem das Warum.','Memory tip: find the keywords, identify the rule first, then eliminate options. For “${_pretty(q.category)}”, focus on understanding why the rule works.'), style: const TextStyle(color: TxColors.muted, height: 1.45))),
          if (!pro) ...[
            const SizedBox(height: 10),
            Text(TxText.t('basic_explanation_free'), style: const TextStyle(color: TxColors.muted, fontSize: 10, height: 1.35)),
          ],
        ]),
      )),
    );
  }

  Future<void> _next() async {
    if (index >= questions.length - 1) { await _finish(); return; }
    setState(() => index++);
  }

  Future<void> _finish() async {
    if (finished || finishing || questions.isEmpty) return;
    finishing = true;
    timer?.cancel();
    int correct = 0, wrong = 0;
    int penaltyPoints = 0, wrongFivePointQuestions = 0;
    final categoryResult = <String, Map<String, int>>{};
    final wrongIds = <String>[];
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final selected = answers[i];
      final bucket = categoryResult.putIfAbsent(q.category, () => {'correct': 0, 'wrong': 0, 'empty': 0});
      if (selected == null) {
        bucket['empty'] = (bucket['empty'] ?? 0) + 1;
        if (profile.passRuleType == PassRuleType.germanPenalty) {
          penaltyPoints += q.penaltyPoints;
          if (q.penaltyPoints == 5) wrongFivePointQuestions++;
        }
        continue;
      }
      final ok = selected == q.correctIndex;
      if (ok) {
        correct++;
        bucket['correct'] = (bucket['correct'] ?? 0) + 1;
      } else {
        wrong++;
        wrongIds.add(q.id);
        bucket['wrong'] = (bucket['wrong'] ?? 0) + 1;
        if (profile.passRuleType == PassRuleType.germanPenalty) {
          penaltyPoints += q.penaltyPoints;
          if (q.penaltyPoints == 5) wrongFivePointQuestions++;
        }
      }
      if (widget.examMode) {
        await progress.markAnswer(q.id, ok, category: q.category, lessonId: q.lessonId, selectedIndex: selected, correctIndex: q.correctIndex);
      }
    }
    final empty = questions.length - correct - wrong;
    // Only a real full simulation belongs in the formal exam count/history.
    // Quick 5/10 still updates question statistics and study history, but it
    // must not look like a completed full exam on the home/statistics screens.
    if (widget.examMode && questions.length == profile.fullExamQuestions) {
      await progress.registerExamResult(
        total: questions.length,
        correct: correct,
        wrong: wrong,
        empty: empty,
        categories: categoryResult,
        penaltyPoints: penaltyPoints,
        wrongFivePointQuestions: wrongFivePointQuestions,
        countTowardsDailyLimit: true,
      );
    }
    await progress.registerStudySession(
      mode: widget.examMode
          ? (questions.length == profile.fullExamQuestions ? 'full_exam' : 'quick_exam')
          : widget.wrongOnly
              ? 'wrong_review'
              : widget.lessonId != null
                  ? 'lesson_test'
                  : widget.category != null
                      ? 'category_test'
                      : 'practice',
      total: questions.length,
      correct: correct,
      wrong: wrong,
      empty: empty,
      category: widget.category,
      lessonId: widget.lessonId,
      questionIds: questions.map((q) => q.id).toList(),
      wrongQuestionIds: wrongIds,
    );
    if (widget.lessonId != null && questions.isNotEmpty) {
      final rate = correct / questions.length;
      if (rate >= .70) await progress.setLessonCompleted(widget.lessonId!, true);
    }
    // Basic cloud backup is available to every signed-in account, not just Pro.
    // Do it in the background so a slow network never blocks the result screen.
    if (SupabaseService.signedInPermanently) {
      unawaited(SyncService.uploadProgress());
    }
    if (!mounted) return;
    setState(() {
      finished = true;
      finishing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (questions.isEmpty) return Scaffold(appBar: AppBar(), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_t('Bu bölümde henüz soru bulunmuyor.','Er zijn nog geen vragen in dit onderdeel.','In diesem Bereich gibt es noch keine Fragen.','There are no questions in this section yet.'))))); 
    if (finished) return _resultView();
    final q = questions[index];
    final selected = answers[index];
    final showFeedback = !widget.examMode && selected != null;
    final isFavorite = favorites.contains(q.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examMode ? (isFullExam ? TxText.t('full_exam') : questions.length <= 5 ? TxText.t('quick5') : TxText.t('quick10')) : widget.wrongOnly ? TxText.t('wrong_book') : TxText.t('lessons')),
        actions: [
          IconButton(onPressed: _toggleFavorite, tooltip: _t('Favori','Favoriet','Favorit','Favorite'), icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: isFavorite ? TxColors.gold : Colors.white)),
          if (widget.examMode) IconButton(onPressed: () => setState(() => flagged.contains(index) ? flagged.remove(index) : flagged.add(index)), tooltip: _t('İşaretle','Markeren','Markieren','Flag'), icon: Icon(flagged.contains(index) ? Icons.flag_rounded : Icons.flag_outlined, color: flagged.contains(index) ? TxColors.gold : Colors.white)),
          PopupMenuButton<String>(onSelected: (v) { if (v == 'note') _openNote(); if (v == 'teacher') _teacher(); if (v == 'report') _reportCurrent(); }, itemBuilder: (_) => [PopupMenuItem(value: 'teacher', child: ListTile(leading: const Icon(Icons.psychology_alt_rounded), title: Text(TxText.t('smart_teacher')))), PopupMenuItem(value: 'note', child: ListTile(leading: const Icon(Icons.note_alt_outlined), title: Text(_t('Not Al','Notitie','Notiz','Note')))), PopupMenuItem(value: 'report', child: ListTile(leading: const Icon(Icons.flag_outlined), title: Text(_t('Hata Bildir','Melden','Melden','Report'))))]),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: Column(children: [
            Row(children: [Text(_t('Soru ${index + 1} / ${questions.length}','Vraag ${index + 1} / ${questions.length}','Frage ${index + 1} / ${questions.length}','Question ${index + 1} / ${questions.length}'), style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), if (widget.examMode) _timerPill()]),
            const SizedBox(height: 10), ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: (index + 1) / questions.length, minHeight: 5, backgroundColor: Colors.white10, color: TxColors.red)),
          ])),
          Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
            TxCard(color: const Color(0xFF0D1728), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: TxColors.blue.withValues(alpha: .15), borderRadius: BorderRadius.circular(99)), child: Text(_pretty(q.category), style: const TextStyle(color: Color(0xFF79A5FF), fontSize: 11, fontWeight: FontWeight.w800))), const Spacer(), Text(_difficulty(q.difficulty), style: const TextStyle(color: TxColors.muted, fontSize: 10, fontWeight: FontWeight.w700))]),
              if (q.visualKey != null && signMap[q.visualKey] != null) ...[
                const SizedBox(height: 18),
                Center(child: TrafficSignVisual(sign: signMap[q.visualKey]!, size: 126)),
                const SizedBox(height: 18),
              ] else
                const SizedBox(height: 18),
              Text(q.text, style: const TextStyle(fontSize: 20, height: 1.35, fontWeight: FontWeight.w900)),
            ])),
            const SizedBox(height: 14),
            ...List.generate(q.options.length, (i) => _option(q, i, selected, showFeedback)),
            if (showFeedback) ...[
              const SizedBox(height: 6),
              TxCard(color: selected == q.correctIndex ? const Color(0xFF0B2A22) : const Color(0xFF2A1117), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(selected == q.correctIndex ? Icons.check_circle_rounded : Icons.cancel_rounded, color: selected == q.correctIndex ? TxColors.green : TxColors.red), const SizedBox(width: 8), Text(selected == q.correctIndex ? _t('Doğru cevap!','Goed!','Richtig!','Correct!') : _t('Bu kez olmadı','Niet deze keer','Diesmal nicht','Not this time'), style: const TextStyle(fontWeight: FontWeight.w900))]),
                const SizedBox(height: 10), Text(q.explanation, style: const TextStyle(color: Color(0xFFD4DCE9), height: 1.45)), const SizedBox(height: 10), Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _teacher, icon: const Icon(Icons.psychology_alt_rounded), label: Text(TxText.t('smart_teacher')))),
              ])),
            ],
            if (widget.examMode) ...[
              const SizedBox(height: 12),
              TxCard(child: Wrap(spacing: 7, runSpacing: 7, children: List.generate(questions.length, (i) {
                final answered = answers.containsKey(i), active = i == index, marked = flagged.contains(i);
                return GestureDetector(onTap: () => setState(() => index = i), child: Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: active ? TxColors.red : answered ? TxColors.green.withValues(alpha: .18) : Colors.white.withValues(alpha: .045), shape: BoxShape.circle, border: Border.all(color: marked ? TxColors.gold : answered ? TxColors.green : Colors.white12, width: marked ? 2 : 1)), child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: active ? Colors.white : answered ? TxColors.green : TxColors.muted))));
              }))),
            ],
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: index == 0 ? null : () => setState(() => index--), icon: const Icon(Icons.chevron_left), label: Text(_t('Geri','Terug','Zurück','Back')))), const SizedBox(width: 10),
            Expanded(flex: 2, child: FilledButton(onPressed: widget.examMode || selected != null ? _next : null, child: Text(index == questions.length - 1 ? (widget.examMode ? _t('Sınavı Bitir','Examen afronden','Prüfung beenden','Finish Test') : _t('Bitir','Afronden','Beenden','Finish')) : _t('İleri','Volgende','Weiter','Next')))),
          ])),
        ]),
      ),
    );
  }

  Widget _option(Question q, int i, int? selected, bool showFeedback) {
    final isSelected = selected == i, isCorrect = showFeedback && i == q.correctIndex, isWrongSelected = showFeedback && isSelected && i != q.correctIndex;
    Color border = Colors.white12, bg = TxColors.surface, circle = const Color(0xFF1D2940);
    if (isCorrect) { border = TxColors.green; bg = const Color(0xFF0B2A22); circle = TxColors.green; }
    if (isWrongSelected) { border = TxColors.red; bg = const Color(0xFF2A1117); circle = TxColors.red; }
    if (widget.examMode && isSelected) { border = TxColors.blue; bg = const Color(0xFF0D2248); circle = TxColors.blue; }
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(borderRadius: BorderRadius.circular(17), onTap: showFeedback ? null : () => _choose(i), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(17), border: Border.all(color: border, width: isSelected || isCorrect ? 1.6 : 1)), child: Row(children: [Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: circle, shape: BoxShape.circle), child: Text(String.fromCharCode(65 + i), style: const TextStyle(fontWeight: FontWeight.w900))), const SizedBox(width: 12), Expanded(child: Text(q.options[i], style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3))), if (isCorrect) const Icon(Icons.check_rounded, color: TxColors.green), if (isWrongSelected) const Icon(Icons.close_rounded, color: TxColors.red)]))));
  }

  Widget _timerPill() { final m = secondsLeft ~/ 60, s = secondsLeft % 60; return Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: TxColors.red, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.timer_rounded, size: 16), const SizedBox(width: 5), Text('$m:${s.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w900))])); }

  Widget _resultView() {
    int correct = 0, wrong = 0;
    int penaltyPoints = 0, wrongFivePointQuestions = 0;
    final categories = <String, Map<String, int>>{};
    final wrongIndices = <int>[];
    final emptyIndices = <int>[];
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i], a = answers[i];
      final b = categories.putIfAbsent(q.category, () => {'correct': 0, 'wrong': 0, 'empty': 0});
      if (a == null) {
        b['empty'] = (b['empty'] ?? 0) + 1;
        emptyIndices.add(i);
        if (profile.passRuleType == PassRuleType.germanPenalty) {
          penaltyPoints += q.penaltyPoints;
          if (q.penaltyPoints == 5) wrongFivePointQuestions++;
        }
        continue;
      }
      if (a == q.correctIndex) {
        correct++;
        b['correct'] = (b['correct'] ?? 0) + 1;
      } else {
        wrong++;
        wrongIndices.add(i);
        b['wrong'] = (b['wrong'] ?? 0) + 1;
        if (profile.passRuleType == PassRuleType.germanPenalty) {
          penaltyPoints += q.penaltyPoints;
          if (q.penaltyPoints == 5) wrongFivePointQuestions++;
        }
      }
    }
    final empty = questions.length - correct - wrong;
    final rate = questions.isEmpty ? 0 : ((correct / questions.length) * 100).round();
    final fullExam = widget.examMode && questions.length == profile.fullExamQuestions;
    final passed = fullExam
        ? profile.passed(
            total: questions.length,
            correct: correct,
            penaltyPoints: penaltyPoints,
            wrongFivePointQuestions: wrongFivePointQuestions,
          )
        : rate >= 70;
    final wrongIds = wrongIndices.map((i) => questions[i].id).toList();
    final retryIds = [...wrongIndices, ...emptyIndices].map((i) => questions[i].id).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.examMode ? TxText.t('exam_result') : TxText.t('lessons'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            TxCard(
              child: Column(children: [
                const SizedBox(height: 8),
                RingProgress(value: rate / 100, center: '%$rate', caption: profile.id == 'de' && fullExam ? '$penaltyPoints FP' : TxText.t('stats'), size: 160),
                const SizedBox(height: 16),
                Text(
                  fullExam
                      ? (passed ? '${TxText.t('passed')} 🏆' : '${TxText.t('keep_studying')} 💪')
                      : (rate >= 70 ? '${TxText.t('passed')} 🏆' : '${TxText.t('keep_studying')} 💪'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: _resultNumber('$correct', TxText.t('correct'), TxColors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _resultNumber('$wrong', TxText.t('wrong'), TxColors.red)),
                  const SizedBox(width: 8),
                  Expanded(child: _resultNumber('$empty', TxText.t('empty'), TxColors.gold)),
                ]),
              ]),
            ),
            if (fullExam) ...[
              const SizedBox(height: 12),
              TxCard(
                color: passed ? const Color(0xFF0B2A22) : const Color(0xFF24161A),
                child: Row(children: [
                  Icon(passed ? Icons.verified_rounded : Icons.info_outline_rounded, color: passed ? TxColors.green : TxColors.gold),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${profile.flag} ${profile.localizedCountryName(AppSettingsService.instance.locale)} • ${profile.examAuthority}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(profile.passRuleSummary(AppSettingsService.instance.locale), style: const TextStyle(color: TxColors.muted, fontSize: 11, height: 1.35)),
                    if (profile.passRuleType == PassRuleType.germanPenalty)
                      Text(_t('Hata puanı: $penaltyPoints • yanlış 5 puanlık soru: $wrongFivePointQuestions','Strafpunten: $penaltyPoints • foute 5-puntsvragen: $wrongFivePointQuestions','Fehlerpunkte: $penaltyPoints • falsche 5-Punkte-Fragen: $wrongFivePointQuestions','Penalty points: $penaltyPoints • wrong 5-point questions: $wrongFivePointQuestions'), style: const TextStyle(color: TxColors.muted, fontSize: 11)),
                  ])),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            if (wrongIndices.isNotEmpty || emptyIndices.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFF25131B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TxColors.red.withValues(alpha: .42)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.fact_check_rounded, color: TxColors.red),
                    const SizedBox(width: 9),
                    Expanded(child: Text(
                      wrongIndices.isEmpty ? _t('$empty boş sorunu hemen inceleyebilirsin','$empty lege vragen kun je direct bekijken','$empty leere Fragen kannst du sofort prüfen','You can review $empty blank questions now') : _t('Bu testte ${wrongIndices.length} yanlışın var','Je hebt ${wrongIndices.length} fouten in deze test','Du hast ${wrongIndices.length} Fehler in diesem Test','You made ${wrongIndices.length} mistakes in this test'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    )),
                  ]),
                  const SizedBox(height: 7),
                  Text(
                    emptyIndices.isEmpty
                        ? _t('Ana sayfaya dönmeden, yanlış cevaplarını ve doğru açıklamaları aşağıda görebilirsin.','Bekijk je fouten en juiste uitleg hieronder zonder terug te gaan.','Sieh deine Fehler und richtigen Erklärungen direkt unten an.','Review your wrong answers and correct explanations below without leaving.')
                        : _t('${emptyIndices.length} boş sorun da tekrar setine eklenecek.','${emptyIndices.length} lege vragen worden ook aan de herhaalset toegevoegd.','${emptyIndices.length} leere Fragen werden ebenfalls zum Wiederholungsset hinzugefügt.','${emptyIndices.length} blank questions will also be added to the retry set.'),
                    style: const TextStyle(color: TxColors.muted, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 13),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: retryIds.isEmpty ? null : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: retryIds)),
                      ),
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(wrongIds.isEmpty ? _t('Boş Soruları Çöz','Lege vragen oefenen','Leere Fragen üben','Practice Blank Questions') : _t('Yanlış + Boş Soruları Tekrar Çöz','Fouten + lege vragen opnieuw','Fehler + leere Fragen wiederholen','Retry Wrong + Blank Questions')),
                    ),
                  ),
                ]),
              )
            else
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(color: const Color(0xFF0B2A22), borderRadius: BorderRadius.circular(20), border: Border.all(color: TxColors.green.withValues(alpha: .35))),
                child: Row(children: [const Icon(Icons.verified_rounded, color: TxColors.green), const SizedBox(width: 10), Expanded(child: Text(_t('Bu testte yanlış veya boş bırakmadın. Temiz sonuç! 🔥','Geen fouten of lege antwoorden. Perfect! 🔥','Keine Fehler oder leeren Antworten. Stark! 🔥','No wrong or blank answers. Clean result! 🔥'), style: const TextStyle(fontWeight: FontWeight.w900)))]),
              ),
            const SizedBox(height: 12),
            TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_t('Konu Bazlı Performans','Prestaties per onderwerp','Leistung nach Thema','Performance by Topic'), style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 15),
              ...categories.entries.map((e) {
                final c = e.value['correct'] ?? 0, w = e.value['wrong'] ?? 0, em = e.value['empty'] ?? 0, total = c + w + em;
                final value = total == 0 ? 0.0 : c / total;
                return _resultBar(_pretty(e.key), value, c, total);
              }),
            ])),
            if (wrongIndices.isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Text(_t('Hatalı Sorularım','Mijn fouten','Meine Fehler','My Mistakes'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                Text(_t('${wrongIndices.length} soru','${wrongIndices.length} vragen','${wrongIndices.length} Fragen','${wrongIndices.length} questions'), style: const TextStyle(color: TxColors.red, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 5),
              Text(_t('Seçtiğin cevap, doğru cevap ve açıklama aynı ekranda.','Je antwoord, het juiste antwoord en de uitleg staan op één scherm.','Deine Antwort, die richtige Antwort und Erklärung stehen auf einem Bildschirm.','Your answer, the correct answer and the explanation are shown together.'), style: const TextStyle(color: TxColors.muted, fontSize: 12)),
              const SizedBox(height: 11),
              ...wrongIndices.map((i) => _wrongReviewCard(i)),
            ],
            if (emptyIndices.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text(_t('Boş Bıraktıklarım','Leeg gelaten','Unbeantwortet','Left Blank'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                Text(_t('${emptyIndices.length} soru','${emptyIndices.length} vragen','${emptyIndices.length} Fragen','${emptyIndices.length} questions'), style: const TextStyle(color: TxColors.gold, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 9),
              ...emptyIndices.map((i) => _emptyReviewCard(i)),
            ],
            const SizedBox(height: 14),
            const Center(child: BannerAdSlot()),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.home_outlined), label: Text(_t('Geri Dön','Terug','Zurück','Go Back')))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  if (widget.examMode && questions.length == profile.fullExamQuestions) {
                    await AdService.instance.maybeShowInterstitialAtNaturalTransition();
                  }
                  if (!mounted) return;
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => QuestionSessionScreen(
                      examMode: widget.examMode,
                      questionCount: widget.questionCount ?? questions.length,
                      category: widget.category,
                      wrongOnly: widget.wrongOnly,
                      questionIds: widget.questionIds,
                      lessonId: widget.lessonId,
                    )),
                  );
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_t('Tekrar Dene','Opnieuw','Nochmal','Try Again')),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _wrongReviewCard(int i) {
    final q = questions[i];
    final selected = answers[i]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TxCard(
        color: const Color(0xFF161823),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 30, height: 30, alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFF3B1720), shape: BoxShape.circle), child: Text('${i + 1}', style: const TextStyle(color: TxColors.red, fontWeight: FontWeight.w900))),
            const SizedBox(width: 9),
            Expanded(child: Text(_pretty(q.category), style: const TextStyle(color: TxColors.muted, fontSize: 11, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 11),
          if (q.visualKey != null && signMap[q.visualKey] != null) ...[
            Center(child: TrafficSignVisual(sign: signMap[q.visualKey]!, size: 92)),
            const SizedBox(height: 11),
          ],
          Text(q.text, style: const TextStyle(fontWeight: FontWeight.w900, height: 1.35)),
          const SizedBox(height: 12),
          _answerLine(_t('Senin cevabın','Jouw antwoord','Deine Antwort','Your answer'), '${String.fromCharCode(65 + selected)}) ${q.options[selected]}', TxColors.red, Icons.close_rounded),
          const SizedBox(height: 7),
          _answerLine(_t('Doğru cevap','Juiste antwoord','Richtige Antwort','Correct answer'), '${String.fromCharCode(65 + q.correctIndex)}) ${q.options[q.correctIndex]}', TxColors.green, Icons.check_rounded),
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .035), borderRadius: BorderRadius.circular(13)),
            child: Text(q.explanation, style: const TextStyle(color: Color(0xFFD5DEEC), fontSize: 12, height: 1.45)),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: [
            TextButton.icon(onPressed: () => _showTeacherFor(q), icon: const Icon(Icons.psychology_alt_rounded), label: Text(TxText.t('smart_teacher'))),
            if (lessonMap[q.lessonId] != null)
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lessonMap[q.lessonId]!))),
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(_t('Dersi Aç','Open les','Lektion öffnen','Open Lesson')),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _emptyReviewCard(int i) {
    final q = questions[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (q.visualKey != null && signMap[q.visualKey] != null) ...[
          Center(child: TrafficSignVisual(sign: signMap[q.visualKey]!, size: 92)),
          const SizedBox(height: 10),
        ],
        Text('${i + 1}. ${q.text}', style: const TextStyle(fontWeight: FontWeight.w900, height: 1.35)),
        const SizedBox(height: 9),
        _answerLine(_t('Doğru cevap','Juiste antwoord','Richtige Antwort','Correct answer'), '${String.fromCharCode(65 + q.correctIndex)}) ${q.options[q.correctIndex]}', TxColors.green, Icons.check_rounded),
        const SizedBox(height: 8),
        Text(q.explanation, style: const TextStyle(color: TxColors.muted, fontSize: 12, height: 1.4)),
      ])),
    );
  }

  Widget _answerLine(String label, String answer, Color color, IconData icon) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Expanded(child: RichText(text: TextSpan(style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.white), children: [TextSpan(text: '$label: ', style: TextStyle(color: color, fontWeight: FontWeight.w900)), TextSpan(text: answer)]))),
    ],
  );

  void _showTeacherFor(Question q) {
    _openTeacherForQuestion(q);
  }

  Widget _resultNumber(String number, String label, Color color) => Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .035), borderRadius: BorderRadius.circular(14)), child: Column(children: [Text(number, style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: TxColors.muted, fontSize: 11))]));
  Widget _resultBar(String label, double value, int correct, int total) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [SizedBox(width: 105, child: Text(label, style: const TextStyle(fontSize: 12))), Expanded(child: LinearProgressIndicator(value: value, minHeight: 5, backgroundColor: Colors.white10, color: value >= .7 ? TxColors.green : value >= .5 ? TxColors.gold : TxColors.red)), const SizedBox(width: 8), Text('$correct/$total • %${(value * 100).round()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))]));

  String _pretty(String value) => profile.localizedCategoryLabel(value, AppSettingsService.instance.locale);

  String _difficulty(String value) {
    final v = value.toLowerCase();
    if (v == 'easy') return _t('KOLAY','MAKKELIJK','LEICHT','EASY');
    if (v == 'hard') return _t('ZOR','MOEILIJK','SCHWER','HARD');
    return _t('ORTA','GEMIDDELD','MITTEL','MEDIUM');
  }
}
