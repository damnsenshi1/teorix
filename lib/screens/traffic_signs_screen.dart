import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/traffic_sign_repository.dart';
import '../models/traffic_sign.dart';
import '../services/app_settings_service.dart';
import '../widgets/tx_widgets.dart';
import '../widgets/traffic_sign_visual.dart';
import 'traffic_sign_game_screen.dart';

class TrafficSignsScreen extends StatefulWidget {
  const TrafficSignsScreen({super.key});

  @override
  State<TrafficSignsScreen> createState() => _TrafficSignsScreenState();
}

class _TrafficSignsScreenState extends State<TrafficSignsScreen> {
  final Future<List<TrafficSignInfo>> _future = TrafficSignRepository().load();
  String query = '';
  String group = '';

  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl, 'de' => de, 'en' => en, _ => tr,
      };

  @override
  Widget build(BuildContext context) {
    final allLabel = _t('Tümü', 'Alles', 'Alle', 'All');
    return Scaffold(
      appBar: AppBar(title: Text(_t('Trafik İşaretleri', 'Verkeersborden', 'Verkehrszeichen', 'Traffic Signs'))),
      body: FutureBuilder<List<TrafficSignInfo>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          final groups = <String>{allLabel, ...all.map((e) => e.group)}.toList();
          final activeGroup = group.isEmpty ? allLabel : group;
          final shown = all.where((s) {
            final q = query.trim().toLowerCase();
            final groupOk = activeGroup == allLabel || s.group == activeGroup;
            final queryOk = q.isEmpty || '${s.name} ${s.meaning} ${s.group} ${s.memoryTip}'.toLowerCase().contains(q);
            return groupOk && queryOk;
          }).toList();
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF18263A), Color(0xFF101827)]),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.traffic_rounded, color: TxColors.red, size: 38),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_t('${all.length} İşaretlik Kütüphane', '${all.length} borden', '${all.length} Verkehrszeichen', '${all.length} Traffic Signs'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
                      const SizedBox(height: 4),
                      Text(_t('Şekli gör, anlamını öğren, hafıza ipucuyla pekiştir.', 'Bekijk de vorm, leer de betekenis en onthoud de tip.', 'Form ansehen, Bedeutung lernen und mit Merkhilfe festigen.', 'See the shape, learn the meaning and reinforce it with a memory tip.'), style: const TextStyle(color: TxColors.muted, fontSize: 12)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrafficSignGameScreen())),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(_t('Ücretsiz 5', 'Gratis 5', 'Kostenlose 5', 'Free 5')),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrafficSignGameScreen(fullMode: true))),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: Text(_t('Tam Oyun • Plus', 'Volledig • Plus', 'Komplett • Plus', 'Full Game • Plus')),
                  )),
                ]),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: InputDecoration(
                    hintText: _t('İşaret veya anlam ara...', 'Zoek bord of betekenis...', 'Zeichen oder Bedeutung suchen...', 'Search sign or meaning...'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: TxColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: groups.map((g) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      selected: activeGroup == g,
                      label: Text(g),
                      onSelected: (_) => setState(() => group = g),
                    ),
                  )).toList()),
                ),
                const SizedBox(height: 14),
                ...shown.map(_card),
                if (shown.isEmpty)
                  TxCard(child: Padding(padding: const EdgeInsets.all(18), child: Center(child: Text(_t('Aramana uygun işaret bulunamadı.', 'Geen passend bord gevonden.', 'Kein passendes Zeichen gefunden.', 'No matching sign found.'))))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(TrafficSignInfo s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TxCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TrafficSignVisual(sign: s),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 3),
              Text(s.group, style: const TextStyle(color: TxColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(height: 9),
              Text(s.meaning, style: const TextStyle(height: 1.4, fontSize: 12)),
              if (s.memoryTip.isNotEmpty) ...[
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: TxColors.gold.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.lightbulb_rounded, color: TxColors.gold, size: 16),
                    const SizedBox(width: 7),
                    Expanded(child: Text(s.memoryTip, style: const TextStyle(color: TxColors.muted, fontSize: 11, height: 1.35))),
                  ]),
                ),
              ],
            ])),
          ]),
        ),
      );
}
