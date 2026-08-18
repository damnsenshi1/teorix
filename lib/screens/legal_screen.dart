import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../widgets/tx_widgets.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  String _t(String tr, String nl, String de, String en) => TxText.pick(tr, nl, de, en);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_t('Gizlilik & Kullanım', 'Privacy & gebruik', 'Datenschutz & Nutzung', 'Privacy & Use'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _LegalHero(t: _t),
              const SizedBox(height: 12),
              _LegalCard(
                icon: Icons.school_rounded,
                title: _t('Eğitim içeriği', 'Studie-inhoud', 'Lerninhalte', 'Study content'),
                body: _t(
                  'TeoriX, sürücü adaylarının teori sınavına hazırlanmasına yardımcı olan bağımsız bir çalışma uygulamasıdır. Dersler ve sorular TeoriX için özgün hazırlanır; resmî sınav soru bankasının kopyası değildir. Kurallar zamanla değişebileceği için kritik bilgileri resmî kaynaklardan da kontrol etmelisin.',
                  'TeoriX is een onafhankelijke studie-app voor het theorie-examen. Lessen en vragen zijn originele TeoriX-oefeninhoud en geen kopie van een officiële vragenbank. Controleer belangrijke regels ook bij officiële bronnen, omdat regels kunnen veranderen.',
                  'TeoriX ist eine unabhängige Lern-App zur Vorbereitung auf die Theorieprüfung. Lektionen und Fragen sind eigene TeoriX-Übungsinhalte und keine Kopie amtlicher Fragenkataloge. Prüfe wichtige Regeln zusätzlich bei offiziellen Quellen, da sie sich ändern können.',
                  'TeoriX is an independent study app for driving-theory preparation. Lessons and questions are original TeoriX study material and are not copies of an official question bank. Check critical rules with official sources too because rules can change.',
                ),
              ),
              _LegalCard(
                icon: Icons.shield_outlined,
                title: _t('İlerlemen ve verilerin', 'Voortgang en gegevens', 'Fortschritt und Daten', 'Progress and data'),
                body: _t(
                  'Soru sonuçların, yanlışların, favorilerin, notların, çalışma serin ve tercihlerin temel olarak cihazında tutulur. Hesabını bağladığında ilerleme verilerini buluta yedekleyebilir ve geri yükleyebilirsin.',
                  'Je resultaten, fouten, favorieten, notities, reeks en voorkeuren worden in de basis op je apparaat opgeslagen. Met een gekoppeld account kun je voortgang in de cloud back-uppen en herstellen.',
                  'Ergebnisse, Fehler, Favoriten, Notizen, Serie und Einstellungen werden grundsätzlich auf deinem Gerät gespeichert. Mit einem verknüpften Konto kannst du deinen Fortschritt in der Cloud sichern und wiederherstellen.',
                  'Results, mistakes, favorites, notes, streak and preferences are stored primarily on your device. With a linked account, you can back up and restore progress in the cloud.',
                ),
              ),
              _LegalCard(
                icon: Icons.ads_click_rounded,
                title: _t('Reklamlar', 'Advertenties', 'Werbung', 'Ads'),
                body: _t(
                  'Free sürümde sınırlı reklam gösterilebilir. Tam ekran reklamlar soru veya sınav ortasında gösterilmez. Ödüllü reklamlar yalnızca sen seçtiğinde açılır ve ek deneme ya da ek Akıllı Öğretmen hakkı gibi bir fayda sağlar.',
                  'De Free-versie kan beperkte advertenties tonen. Volledige advertenties verschijnen niet midden in een vraag of examen. Beloningsadvertenties starten alleen wanneer jij ze kiest en geven bijvoorbeeld een extra examen of Slimme Leraar-gebruik.',
                  'Die Free-Version kann begrenzte Werbung enthalten. Vollbildwerbung erscheint nicht mitten in einer Frage oder Prüfung. Belohnungswerbung startet nur auf deinen Wunsch und gibt z. B. eine zusätzliche Prüfung oder Smarter-Lehrer-Nutzung.',
                  'The Free version may show limited ads. Full-screen ads are not shown in the middle of a question or test. Rewarded ads run only when you choose them and can grant an extra test or Smart Teacher use.',
                ),
              ),
              _LegalCard(
                icon: Icons.workspace_premium_outlined,
                title: _t('Plus, Pro ve satın alımlar', 'Plus, Pro en aankopen', 'Plus, Pro und Käufe', 'Plus, Pro and purchases'),
                body: _t(
                  'Plus tek seferlik statik avantajlar ve reklamsız kullanım içindir. Pro ise sürekli güncellenen kişiselleştirilmiş çalışma araçları içeren aboneliktir. Geçerli fiyat ve yenileme koşulları satın alma ekranında mağazadan alınır. Uygun satın alımları geri yükleyebilirsin.',
                  'Plus is een eenmalige aankoop voor statische voordelen en advertentievrij gebruik. Pro is een abonnement voor doorlopend bijgewerkte persoonlijke studietools. Actuele prijs- en verlengingsvoorwaarden komen uit de store. Geschikte aankopen kunnen worden hersteld.',
                  'Plus ist ein einmaliger Kauf für statische Vorteile und werbefreie Nutzung. Pro ist ein Abo für laufend aktualisierte persönliche Lernwerkzeuge. Aktuelle Preise und Verlängerungsbedingungen kommen aus dem Store. Geeignete Käufe können wiederhergestellt werden.',
                  'Plus is a one-time purchase for static benefits and ad-free use. Pro is a subscription for continuously updated personalized study tools. Current pricing and renewal terms come from the store. Eligible purchases can be restored.',
                ),
              ),
              _LegalCard(
                icon: Icons.health_and_safety_outlined,
                title: _t('İlk yardım notu', 'EHBO-opmerking', 'Erste-Hilfe-Hinweis', 'First-aid note'),
                body: _t(
                  'İlk yardım dersleri sınav hazırlığı içindir; gerçek bir acil durumda profesyonel sağlık hizmetinin yerini tutmaz. Bulunduğun yerdeki resmî acil yardım prosedürlerini uygula.',
                  'EHBO-lessen zijn bedoeld voor examenvoorbereiding en vervangen geen professionele medische hulp. Volg in een echte noodsituatie de officiële noodprocedures van jouw locatie.',
                  'Erste-Hilfe-Lektionen dienen der Prüfungsvorbereitung und ersetzen keine professionelle medizinische Hilfe. Befolge im Notfall die offiziellen Verfahren deines Aufenthaltsorts.',
                  'First-aid lessons are for test preparation and do not replace professional medical care. In a real emergency, follow the official emergency procedures where you are.',
                ),
              ),
              const SizedBox(height: 8),
              const Text('TeoriX • Senshi Labs', textAlign: TextAlign.center, style: TextStyle(color: TxColors.muted, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _LegalHero extends StatelessWidget {
  final String Function(String, String, String, String) t;
  const _LegalHero({required this.t});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF17253B), Color(0xFF101827)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(children: [
          const Icon(Icons.verified_user_rounded, color: TxColors.green, size: 38),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('Şeffaf ve anlaşılır kullanım', 'Duidelijk en transparant', 'Klar und transparent', 'Clear and transparent'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(t('Teknik servis adları yerine, verinin ve özelliklerin sana ne yaptığını açıkça anlatıyoruz.', 'We leggen duidelijk uit wat functies en gegevens voor jou doen, zonder technische servicetaal.', 'Wir erklären klar, was Funktionen und Daten für dich tun, statt technische Dienstnamen zu zeigen.', 'We explain what features and data do for you instead of exposing technical service names.'), style: const TextStyle(color: TxColors.muted, fontSize: 12, height: 1.4)),
          ])),
        ]),
      );
}

class _LegalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _LegalCard({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: TxColors.blue), const SizedBox(width: 9), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)))]),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(color: Color(0xFFD5DEEC), height: 1.5, fontSize: 12.5)),
        ])),
      );
}
