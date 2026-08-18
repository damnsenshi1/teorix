import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../data/lesson_repository.dart';
import '../data/question_repository.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../services/local_progress_service.dart';
import '../widgets/tx_widgets.dart';
import 'question_session_screen.dart';
import 'lesson_detail_screen.dart';

class WrongsScreen extends StatefulWidget {
  const WrongsScreen({super.key});
  @override
  State<WrongsScreen> createState() => _WrongsScreenState();
}

class _WrongsScreenState extends State<WrongsScreen> {
  final progress = LocalProgressService();
  CountryProfile get profile => AppSettingsService.instance.country;
  List<Question> items = [];
  Map<String, Lesson> lessonMap = {};
  Map<String, Map<String, dynamic>> answerDetails = {};
  Set<String> favorites = {};
  String category = 'Tümü';
  String query = '';
  bool loading = true;

  List<String> get filters => ['Tümü', ...profile.categories.map((e) => e.id)];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await progress.wrongIds();
    final all = await QuestionRepository().loadSeedQuestions(profile: profile);
    final lessons = await LessonRepository().loadLessons(profile: profile);
    final favs = await progress.favoriteIds();
    final details = await progress.answerDetails();
    if (!mounted) return;
    setState(() {
      items = all.where((q) => ids.contains(q.id)).toList();
      lessonMap = {for (final l in lessons) l.id: l};
      favorites = favs;
      answerDetails = details;
      loading = false;
    });
  }

  Future<void> _fav(String id) async {
    await progress.toggleFavorite(id);
    await _load();
  }

  List<Question> get shown {
    final q = query.trim().toLowerCase();
    return items.where((item) {
      if (category != 'Tümü' && item.category != category) return false;
      if (q.isEmpty) return true;
      final lesson = lessonMap[item.lessonId];
      return '${item.text} ${item.tags.join(' ')} ${lesson?.title ?? ''} ${lesson?.module ?? ''}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = shown;
    return Scaffold(
      appBar: AppBar(title: Text(TxText.t('wrong_book'))),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _summary(),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => query = v),
                      decoration: InputDecoration(
                        hintText: TxText.pick('Yanlışlarında ara...','Zoek in je fouten...','In deinen Fehlern suchen...','Search your mistakes...'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: TxColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: filters.map(_filterChip).toList()),
                    ),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      _emptyState()
                    else if (visible.isEmpty)
                      TxCard(child: Padding(padding: const EdgeInsets.all(22), child: Center(child: Text(TxText.pick('Bu filtrede yanlış soru bulunamadı.','Geen fouten in dit filter.','Keine Fehler in diesem Filter.','No mistakes found in this filter.')))))
                    else ...[
                      Row(children: [
                        Expanded(child: Text(TxText.pick('Tekrar bekleyen sorular','Vragen voor herhaling','Fragen zur Wiederholung','Questions to Review'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                        Text('${visible.length}', style: const TextStyle(color: TxColors.red, fontWeight: FontWeight.w900)),
                      ]),
                      const SizedBox(height: 10),
                      ...visible.map(_wrongCard),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: visible.map((e) => e.id).toList())));
                            _load();
                          },
                          icon: const Icon(Icons.replay_rounded),
                          label: Text(category == 'Tümü' ? TxText.pick('Tüm Yanlışları Tekrar Çöz','Alle fouten opnieuw oefenen','Alle Fehler wiederholen','Retry All Mistakes') : TxText.pick('Bu Konudaki Yanlışları Çöz','Fouten in dit onderwerp oefenen','Fehler in diesem Thema üben','Practice Mistakes in This Topic')),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _summary() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2A151D), Color(0xFF111A2B)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: TxColors.red.withValues(alpha: .35)),
        ),
        child: Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: TxColors.red.withValues(alpha: .15), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.fact_check_rounded, color: TxColors.red, size: 28)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(TxText.pick('Yanlışını gör, nedenini öğren, tekrar çöz','Bekijk je fout, leer waarom en probeer opnieuw','Fehler ansehen, Ursache verstehen, erneut lösen','See your mistake, learn why, and retry'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(items.isEmpty ? TxText.pick('Yanlış yaptığın sorular burada otomatik birikir.','Foute antwoorden worden hier automatisch verzameld.','Falsche Antworten werden hier automatisch gesammelt.','Questions you miss are collected here automatically.') : TxText.pick('${items.length} soru tekrar bekliyor. Doğru yaptığında defterden otomatik çıkar.','${items.length} vragen wachten op herhaling. Na een goed antwoord verdwijnen ze automatisch.','${items.length} Fragen warten auf Wiederholung. Nach einer richtigen Antwort verschwinden sie automatisch.','${items.length} questions are waiting for review. They are removed automatically after you answer correctly.'), style: const TextStyle(color: TxColors.muted, fontSize: 11.5, height: 1.4)),
          ])),
        ]),
      );

  Widget _filterChip(String value) {
    final selected = category == value;
    final count = value == 'Tümü' ? items.length : items.where((q) => q.category == value).length;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => category = value),
        label: Text('${_pretty(value)} ($count)'),
        selectedColor: TxColors.red.withValues(alpha: .25),
        side: BorderSide(color: selected ? TxColors.red : Colors.white10),
        labelStyle: TextStyle(color: selected ? Colors.white : TxColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _wrongCard(Question q) {
    final fav = favorites.contains(q.id);
    final lesson = lessonMap[q.lessonId];
    final detail = answerDetails[q.id];
    final selected = (detail?['selectedIndex'] as num?)?.toInt();
    final selectedValid = selected != null && selected >= 0 && selected < q.options.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TxCard(
        color: const Color(0xFF141B2A),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: TxColors.red.withValues(alpha: .13), borderRadius: BorderRadius.circular(99)), child: Text(_pretty(q.category), style: const TextStyle(color: TxColors.red, fontSize: 10, fontWeight: FontWeight.w800))),
            const SizedBox(width: 7),
            Expanded(child: Text(lesson?.title ?? TxText.pick('Konu testi','Onderwerptest','Thementest','Topic test'), overflow: TextOverflow.ellipsis, style: const TextStyle(color: TxColors.muted, fontSize: 10.5))),
            IconButton(onPressed: () => _fav(q.id), visualDensity: VisualDensity.compact, icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: TxColors.gold)),
          ]),
          const SizedBox(height: 7),
          Text(q.text, style: const TextStyle(fontWeight: FontWeight.w900, height: 1.35)),
          if (selectedValid) ...[
            const SizedBox(height: 11),
            _answerLine(TxText.pick('Son cevabın','Je laatste antwoord','Deine letzte Antwort','Your last answer'), '${String.fromCharCode(65 + selected)}) ${q.options[selected]}', TxColors.red, Icons.close_rounded),
          ],
          const SizedBox(height: 7),
          _answerLine(TxText.pick('Doğru cevap','Juiste antwoord','Richtige Antwort','Correct answer'), '${String.fromCharCode(65 + q.correctIndex)}) ${q.options[q.correctIndex]}', TxColors.green, Icons.check_rounded),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .035), borderRadius: BorderRadius.circular(12)),
            child: Text(q.explanation, style: const TextStyle(color: Color(0xFFD5DEEC), fontSize: 11.5, height: 1.45)),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 4, runSpacing: 4, children: [
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: [q.id])));
                _load();
              },
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text(TxText.pick('Tekrar Çöz','Opnieuw oefenen','Erneut lösen','Retry')),
            ),
            if (lesson != null)
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson))),
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: Text(TxText.pick('Dersi Aç','Open les','Lektion öffnen','Open Lesson')),
              ),
            if (lesson != null)
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionSessionScreen(lessonId: q.lessonId, questionCount: 10))),
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: Text(TxText.pick('Ders Testi','Lestoets','Lektionstest','Lesson Test')),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _answerLine(String label, String answer, Color color, IconData icon) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.4), children: [TextSpan(text: '$label: ', style: TextStyle(color: color, fontWeight: FontWeight.w900)), TextSpan(text: answer)]))),
        ],
      );

  Widget _emptyState() => TxCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(children: [
            const Icon(Icons.verified_rounded, color: TxColors.green, size: 58),
            const SizedBox(height: 14),
            Text(TxText.pick('Yanlış defterin temiz','Je foutenboek is leeg','Dein Fehlerheft ist leer','Your mistake book is clean'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(TxText.pick('Soru çözdükçe yanlış cevapların burada otomatik birikir. Doğru tekrar yaptığında listeden çıkar.','Tijdens het oefenen worden fouten hier automatisch verzameld en na een goed herhaalantwoord verwijderd.','Beim Üben werden Fehler hier automatisch gesammelt und nach einer richtigen Wiederholung entfernt.','As you practice, mistakes collect here automatically and disappear after a correct retry.'), textAlign: TextAlign.center, style: const TextStyle(color: TxColors.muted, height: 1.4)),
          ]),
        ),
      );

  String _pretty(String value) => value == 'Tümü' ? TxText.pick('Tümü','Alles','Alle','All') : profile.localizedCategoryLabel(value, AppSettingsService.instance.locale);

}
