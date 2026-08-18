import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/traffic_sign_repository.dart';
import '../models/traffic_sign.dart';
import '../services/app_settings_service.dart';
import '../services/entitlement_service.dart';
import '../widgets/traffic_sign_visual.dart';
import '../widgets/tx_widgets.dart';
import 'store_screen.dart';

class TrafficSignGameScreen extends StatefulWidget {
  final bool fullMode;
  const TrafficSignGameScreen({super.key, this.fullMode = false});

  @override
  State<TrafficSignGameScreen> createState() => _TrafficSignGameScreenState();
}

class _TrafficSignGameScreenState extends State<TrafficSignGameScreen> {
  bool loading = true;
  bool allowed = false;
  List<TrafficSignInfo> signs = [];
  List<TrafficSignInfo> rounds = [];
  List<String> options = [];
  int index = 0;
  int score = 0;
  String? selected;
  bool finished = false;

  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl, 'de' => de, 'en' => en, _ => tr,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plus = await EntitlementService.instance.currentPlus();
    final all = await TrafficSignRepository().load();
    if (!mounted) return;
    if (widget.fullMode && !plus) {
      setState(() { allowed = false; signs = all; loading = false; });
      return;
    }
    setState(() { allowed = true; signs = all; loading = false; });
    _start();
  }

  void _start() {
    if (signs.isEmpty) return;
    final copy = [...signs]..shuffle();
    final count = widget.fullMode ? min(20, copy.length) : min(5, copy.length);
    rounds = copy.take(count).toList();
    index = 0;
    score = 0;
    selected = null;
    finished = false;
    _buildOptions();
    if (mounted) setState(() {});
  }

  void _buildOptions() {
    if (rounds.isEmpty || index >= rounds.length) return;
    final current = rounds[index];
    final wrong = signs.where((s) => s.id != current.id && s.meaning != current.meaning).toList()..shuffle();
    options = [current.meaning, ...wrong.take(min(3, wrong.length)).map((e) => e.meaning)]..shuffle();
  }

  void _choose(String value) {
    if (selected != null) return;
    setState(() {
      selected = value;
      if (value == rounds[index].meaning) score++;
    });
  }

  void _next() {
    if (selected == null) return;
    if (index >= rounds.length - 1) {
      setState(() => finished = true);
      return;
    }
    setState(() {
      index++;
      selected = null;
      _buildOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: Text(_t('Tabela Oyunu', 'Bordenspel', 'Verkehrszeichen-Spiel', 'Traffic Sign Game'))),
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: TxCard(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.workspace_premium_rounded, color: TxColors.gold, size: 54),
            const SizedBox(height: 12),
            Text(_t('Tam Tabela Oyunu Plus ile açılır', 'Het volledige bordenspel is beschikbaar met Plus', 'Das komplette Zeichen-Spiel ist mit Plus verfügbar', 'The full sign game is available with Plus'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_t('Ücretsiz 5 soruluk tur her zaman açık. Plus tek seferlik satın alımdır ve reklamları da kaldırır.', 'De gratis ronde met 5 vragen blijft beschikbaar. Plus is een eenmalige aankoop en verwijdert ook advertenties.', 'Die kostenlose 5-Fragen-Runde bleibt verfügbar. Plus ist ein Einmalkauf und entfernt auch Werbung.', 'The free 5-question round stays available. Plus is a one-time purchase and also removes ads.'), textAlign: TextAlign.center, style: const TextStyle(color: TxColors.muted, fontSize: 12, height: 1.4)),
            const SizedBox(height: 14),
            FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())), child: const Text('TeoriX Plus')),
          ]))),
        )),
      );
    }
    if (rounds.isEmpty) return Scaffold(appBar: AppBar(), body: Center(child: Text(_t('Bu pakette tabela bulunamadı.', 'Geen borden in dit pakket.', 'Keine Zeichen in diesem Paket.', 'No signs found in this pack.'))));
    if (finished) return _result();
    final sign = rounds[index];
    return Scaffold(
      appBar: AppBar(title: Text(_t('Tabela Oyunu', 'Bordenspel', 'Verkehrszeichen-Spiel', 'Traffic Sign Game'))),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(children: [
            Text('${index + 1}/${rounds.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 10),
            Expanded(child: LinearProgressIndicator(value: (index + 1) / rounds.length, backgroundColor: Colors.white10, color: TxColors.red)),
            const SizedBox(width: 10),
            Text('⭐ $score', style: const TextStyle(color: TxColors.gold, fontWeight: FontWeight.w900)),
          ]),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          TxCard(child: Column(children: [
            TrafficSignVisual(sign: sign, size: 150),
            const SizedBox(height: 16),
            Text(_t('Bu işaret ne anlama geliyor?', 'Wat betekent dit bord?', 'Was bedeutet dieses Zeichen?', 'What does this sign mean?'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          ])),
          const SizedBox(height: 14),
          ...options.map((value) {
            final chosen = selected == value;
            final correct = selected != null && value == sign.meaning;
            final wrong = chosen && !correct;
            final color = correct ? TxColors.green : wrong ? TxColors.red : Colors.white12;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: InkWell(
                onTap: () => _choose(value),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: correct ? const Color(0xFF0B2A22) : wrong ? const Color(0xFF2A1117) : TxColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: color, width: chosen || correct ? 1.5 : 1)),
                  child: Row(children: [Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3))), if (correct) const Icon(Icons.check_rounded, color: TxColors.green), if (wrong) const Icon(Icons.close_rounded, color: TxColors.red)]),
                ),
              ),
            );
          }),
          if (selected != null) ...[
            const SizedBox(height: 5),
            TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sign.name, style: const TextStyle(fontWeight: FontWeight.w900)),
              if (sign.memoryTip.isNotEmpty) ...[const SizedBox(height: 6), Text(sign.memoryTip, style: const TextStyle(color: TxColors.muted, fontSize: 12, height: 1.4))],
            ])),
          ],
        ])),
        Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: FilledButton(onPressed: selected == null ? null : _next, child: Text(index == rounds.length - 1 ? _t('Bitir', 'Afronden', 'Beenden', 'Finish') : _t('Sonraki', 'Volgende', 'Weiter', 'Next'))))),
      ])),
    );
  }

  Widget _result() => Scaffold(
    appBar: AppBar(title: Text(_t('Tabela Oyunu Sonucu', 'Resultaat bordenspel', 'Ergebnis Zeichen-Spiel', 'Traffic Sign Game Result'))),
    body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(16), child: TxCard(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.emoji_events_rounded, color: TxColors.gold, size: 64),
      const SizedBox(height: 10),
      Text('$score / ${rounds.length}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text(_t('Tabela refleksini güçlendirmeye devam et.', 'Blijf je bordherkenning trainen.', 'Trainiere deine Zeichenerkennung weiter.', 'Keep sharpening your sign recognition.'), textAlign: TextAlign.center, style: const TextStyle(color: TxColors.muted)),
      const SizedBox(height: 15),
      FilledButton.icon(onPressed: _start, icon: const Icon(Icons.refresh_rounded), label: Text(_t('Tekrar Oyna', 'Opnieuw', 'Nochmal', 'Play Again'))),
    ]))))),
  );
}
