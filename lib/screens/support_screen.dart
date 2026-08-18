import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../services/local_progress_service.dart';
import '../services/sync_service.dart';
import '../widgets/tx_widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final progress = LocalProgressService();
  String _t(String tr, String nl, String de, String en) => TxText.pick(tr, nl, de, en);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_t('Yardım & Destek', 'Hulp & ondersteuning', 'Hilfe & Support', 'Help & Support'))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t('Sık Sorulanlar', 'Veelgestelde vragen', 'Häufige Fragen', 'Frequently Asked Questions'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 12),
            _Faq(
              _t('Sorular resmî sınav soruları mı?', 'Zijn dit officiële examenvragen?', 'Sind das amtliche Prüfungsfragen?', 'Are these official test questions?'),
              _t('Hayır. TeoriX özgün çalışma soruları kullanır. Amaç sınav konularını öğretmek ve pratik yaptırmaktır.', 'Nee. TeoriX gebruikt originele oefenvragen om onderwerpen te leren en te oefenen.', 'Nein. TeoriX verwendet eigene Übungsfragen zum Lernen und Trainieren der Prüfungsthemen.', 'No. TeoriX uses original practice questions to teach and practice test topics.'),
            ),
            _Faq(
              _t('İlerlemem silinir mi?', 'Raak ik mijn voortgang kwijt?', 'Geht mein Fortschritt verloren?', 'Will I lose my progress?'),
              _t('İlerlemen cihazda kaydedilir. Hesabını bağladığında temel ilerlemeni buluta yedekleyip geri yükleyebilirsin.', 'Je voortgang wordt op het apparaat opgeslagen. Met een gekoppeld account kun je basisvoortgang in de cloud back-uppen en herstellen.', 'Dein Fortschritt wird auf dem Gerät gespeichert. Mit einem verknüpften Konto kannst du den Basisfortschritt in der Cloud sichern und wiederherstellen.', 'Your progress is stored on the device. With a linked account, you can back up and restore core progress in the cloud.'),
            ),
            _Faq(
              _t('Satın alım başka cihazda açılır mı?', 'Werkt mijn aankoop op een ander apparaat?', 'Funktioniert mein Kauf auf einem anderen Gerät?', 'Can I use my purchase on another device?'),
              _t('Uygun satın alımlar, aynı mağaza/hesapla “Satın Alımları Geri Yükle” üzerinden yeniden kontrol edilebilir.', 'Geschikte aankopen kunnen met hetzelfde store-account via “Aankopen herstellen” opnieuw worden gecontroleerd.', 'Geeignete Käufe können mit demselben Store-Konto über „Käufe wiederherstellen“ erneut geprüft werden.', 'Eligible purchases can be checked again with the same store account using “Restore Purchases”.'),
            ),
          ])),
          const SizedBox(height: 12),
          TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t('Yerel hata raporları', 'Lokale foutrapporten', 'Lokale Fehlerberichte', 'Local issue reports'), style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(_t('Soru ekranındaki “Hata bildir” ile gönderdiğin raporların bir kopyası cihazda da tutulur.', 'Een kopie van rapporten die je via “Meld fout” verstuurt, blijft ook op het apparaat.', 'Eine Kopie der über „Fehler melden“ gesendeten Berichte bleibt auch auf dem Gerät.', 'A copy of reports sent through “Report issue” is also kept on the device.'), style: const TextStyle(color: TxColors.muted)),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: progress.localReports(),
              builder: (_, s) => Text(_t('${s.data?.length ?? 0} rapor kayıtlı', '${s.data?.length ?? 0} rapporten opgeslagen', '${s.data?.length ?? 0} Berichte gespeichert', '${s.data?.length ?? 0} reports saved'), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ])),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final data = await progress.exportSnapshot();
              if (!context.mounted) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(_t('Tanılama Özeti', 'Diagnostisch overzicht', 'Diagnoseübersicht', 'Diagnostics Summary')),
                  content: SizedBox(width: 560, child: SingleChildScrollView(child: SelectableText(SyncService.prettyJson(data), style: const TextStyle(fontSize: 11)))),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(_t('Kapat', 'Sluiten', 'Schließen', 'Close')))],
                ),
              );
            },
            icon: const Icon(Icons.bug_report_outlined),
            label: Text(_t('Tanılama Verisini Gör', 'Diagnostische gegevens bekijken', 'Diagnosedaten anzeigen', 'View Diagnostics Data')),
          ),
        ]),
      );
}

class _Faq extends StatelessWidget {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
  @override
  Widget build(BuildContext context) => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        children: [Align(alignment: Alignment.centerLeft, child: Text(a, style: const TextStyle(color: TxColors.muted, height: 1.45)))],
      );
}
