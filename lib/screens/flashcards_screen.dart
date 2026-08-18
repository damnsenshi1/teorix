import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../data/lesson_repository.dart';
import '../models/lesson.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../widgets/tx_widgets.dart';
import 'lesson_detail_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  final String? initialCategory;
  const FlashcardsScreen({super.key, this.initialCategory});
  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<_MemoryCard> all = [];
  String category = 'Tümü';
  int index = 0;
  bool reveal = false;
  bool loading = true;

  CountryProfile get profile => AppSettingsService.instance.country;
  List<String> get categories => ['Tümü', ...profile.categories.map((e) => e.id)];

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory ?? 'Tümü';
    _load();
  }

  Future<void> _load() async {
    final lessons = await LessonRepository().loadLessons(profile: profile);
    final cards = <_MemoryCard>[];
    for (final lesson in lessons) {
      for (var i = 0; i < lesson.keyPoints.length; i++) {
        cards.add(_MemoryCard(lesson: lesson, point: lesson.keyPoints[i], tip: lesson.examTips.isEmpty ? '' : lesson.examTips[i % lesson.examTips.length]));
      }
    }
    cards.shuffle(Random());
    if (!mounted) return;
    setState(() { all = cards; loading = false; index = 0; reveal = false; });
  }

  List<_MemoryCard> get cards => category == 'Tümü' ? all : all.where((c) => c.lesson.category == category).toList();

  void _next() {
    final list = cards;
    if (list.isEmpty) return;
    setState(() { index = (index + 1) % list.length; reveal = false; });
  }

  void _previous() {
    final list = cards;
    if (list.isEmpty) return;
    setState(() { index = (index - 1 + list.length) % list.length; reveal = false; });
  }

  void _shuffle() {
    setState(() { all.shuffle(Random()); index = 0; reveal = false; });
  }

  @override
  Widget build(BuildContext context) {
    final list = cards;
    if (index >= list.length && list.isNotEmpty) index = 0;
    return Scaffold(
      appBar: AppBar(title: Text(TxText.pick('Hızlı Tekrar Kartları','Snelle herhaalkaarten','Schnelle Lernkarten','Quick Review Cards')), actions: [IconButton(onPressed: _shuffle, tooltip: TxText.pick('Karıştır','Schudden','Mischen','Shuffle'), icon: const Icon(Icons.shuffle_rounded))]),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF18294A), Color(0xFF111A2B)]), borderRadius: BorderRadius.circular(22), border: Border.all(color: TxColors.blue.withValues(alpha: .32))),
                    child: Row(children: [
                      const Icon(Icons.style_rounded, color: TxColors.blue, size: 34),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(TxText.pick('Dersleri ezber değil, kısa tekrarlarla pekiştir','Versterk je kennis met korte herhalingen, niet alleen uit het hoofd leren','Festige Wissen mit kurzen Wiederholungen statt nur Auswendiglernen','Reinforce lessons with short reviews instead of rote memorization'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(TxText.pick('Kartı oku, dokun ve hangi dersten geldiğini + sınav ipucunu gör.','Lees de kaart, tik en bekijk de les + examentip.','Karte lesen, antippen und Lektion + Prüfungstipp sehen.','Read the card, tap it, and see its lesson + test tip.'), style: const TextStyle(color: TxColors.muted, fontSize: 11.5, height: 1.4)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: categories.map(_chip).toList())),
                  const SizedBox(height: 18),
                  if (list.isEmpty)
                    TxCard(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(TxText.pick('Bu kategoride tekrar kartı bulunamadı.','Geen herhaalkaarten in deze categorie.','Keine Lernkarten in dieser Kategorie.','No review cards in this category.')))))
                  else ...[
                    Text('${index + 1} / ${list.length}', textAlign: TextAlign.center, style: const TextStyle(color: TxColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 9),
                    GestureDetector(
                      onTap: () => setState(() => reveal = !reveal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        constraints: const BoxConstraints(minHeight: 330),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: reveal ? const [Color(0xFF241746), Color(0xFF111A2B)] : const [Color(0xFF13243D), Color(0xFF0D1728)]),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: reveal ? TxColors.purple.withValues(alpha: .55) : TxColors.blue.withValues(alpha: .4)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 24, offset: const Offset(0, 12))],
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(reveal ? Icons.lightbulb_rounded : Icons.psychology_alt_rounded, color: reveal ? TxColors.gold : TxColors.blue, size: 44),
                          const SizedBox(height: 18),
                          Text(list[index].point, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, height: 1.45, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 18),
                          if (!reveal)
                            Text(TxText.pick('Ders bağlantısını ve sınav ipucunu görmek için karta dokun','Tik om de leslink en examentip te zien','Tippe für Lektionslink und Prüfungstipp','Tap to see the lesson link and test tip'), textAlign: TextAlign.center, style: const TextStyle(color: TxColors.muted, fontSize: 11.5))
                          else ...[
                            Container(height: 1, color: Colors.white10),
                            const SizedBox(height: 16),
                            Text(list[index].lesson.title, textAlign: TextAlign.center, style: const TextStyle(color: TxColors.purple, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 6),
                            Text(list[index].tip, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD7DEEA), height: 1.4, fontSize: 12.5)),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: list[index].lesson))),
                              icon: const Icon(Icons.menu_book_rounded),
                              label: Text(TxText.pick('Dersi Aç','Open les','Lektion öffnen','Open Lesson')),
                            ),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(onPressed: _previous, icon: const Icon(Icons.chevron_left_rounded), label: Text(TxText.pick('Önceki','Vorige','Zurück','Previous')))),
                      const SizedBox(width: 10),
                      Expanded(child: FilledButton.icon(onPressed: _next, icon: const Icon(Icons.chevron_right_rounded), label: Text(TxText.pick('Sonraki','Volgende','Weiter','Next')))),
                    ]),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _chip(String value) {
    final selected = value == category;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() { category = value; index = 0; reveal = false; }),
        label: Text(_pretty(value)),
        selectedColor: TxColors.blue.withValues(alpha: .25),
        side: BorderSide(color: selected ? TxColors.blue : Colors.white10),
        labelStyle: TextStyle(color: selected ? Colors.white : TxColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _pretty(String value) => value == 'Tümü' ? TxText.pick('Tümü','Alles','Alle','All') : profile.localizedCategoryLabel(value, AppSettingsService.instance.locale);

}

class _MemoryCard {
  final Lesson lesson;
  final String point;
  final String tip;
  const _MemoryCard({required this.lesson, required this.point, required this.tip});
}
