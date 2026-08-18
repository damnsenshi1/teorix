import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_config.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../services/app_settings_service.dart';
import '../services/entitlement_service.dart';
import '../widgets/tx_widgets.dart';
import 'legal_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool loading = true;
  List<TxStorePackage> packages = [];

  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl, 'de' => de, 'en' => en, _ => tr,
      };


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await EntitlementService.instance.loadPackages();
    if (mounted) setState(() { packages = list; loading = false; });
  }

  TxStorePackage? _package(String productId) {
    for (final p in packages) {
      if (p.productId == productId) return p;
    }
    return null;
  }

  String _price(String productId, String debugPrice) => _package(productId)?.priceString ?? debugPrice;

  Future<void> _buy(String productId, {required bool debugPro, required bool debugPlus}) async {
    final p = _package(productId);
    if (p == null) {
      if (kDebugMode) {
        await EntitlementService.instance.setDebugEntitlements(pro: debugPro, plus: debugPlus);
        if (mounted) setState(() {});
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('Mağaza ürünleri henüz bağlanmadı.','Storeproducten zijn nog niet gekoppeld.','Store-Produkte sind noch nicht verbunden.','Store products are not configured yet.'))));
      }
      return;
    }
    final ok = await EntitlementService.instance.buyPackage(p);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? _t('Satın alma tamamlandı.','Aankoop voltooid.','Kauf abgeschlossen.','Purchase completed.') : _t('Satın alma tamamlanamadı.','Aankoop kon niet worden voltooid.','Kauf konnte nicht abgeschlossen werden.','Purchase could not be completed.'))));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final country = AppSettingsService.instance.countryId;
    final ent = EntitlementService.instance;
    return Scaffold(
      appBar: AppBar(title: const TxLogo(size: 24)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF221339), Color(0xFF11192A)]),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: TxColors.gold.withValues(alpha: .35)),
              ),
              child: Column(children: [
                const Icon(Icons.workspace_premium_rounded, color: TxColors.gold, size: 58),
                const SizedBox(height: 8),
                const Text('TeoriX Pro', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(TxText.t('pricing_note'), textAlign: TextAlign.center, style: const TextStyle(color: TxColors.muted, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 14),
            _planCard(
              title: 'TeoriX Free',
              badge: 'FREE',
              price: '0',
              description: TxText.t('free_features'),
              accent: TxColors.green,
              button: null,
            ),
            const SizedBox(height: 10),
            _planCard(
              title: 'TeoriX Plus',
              badge: TxText.t('one_time').toUpperCase(),
              price: _price(AppConfig.plusLifetimeProductId, AppConfig.debugSuggestedPlus(country)),
              description: TxText.t('plus_features'),
              accent: TxColors.blue,
              button: () => _buy(AppConfig.plusLifetimeProductId, debugPro: false, debugPlus: true),
            ),
            const SizedBox(height: 10),
            _planCard(
              title: 'TeoriX Pro • ${TxText.t('monthly')}',
              badge: 'PRO',
              price: _price(AppConfig.proMonthlyProductId, AppConfig.debugSuggestedMonthly(country)),
              description: TxText.t('pro_features'),
              accent: TxColors.purple,
              button: () => _buy(AppConfig.proMonthlyProductId, debugPro: true, debugPlus: true),
            ),
            const SizedBox(height: 10),
            _planCard(
              title: 'TeoriX Pro • ${TxText.t('yearly')}',
              badge: _t('EN AVANTAJLI','BESTE KEUZE','BESTER WERT','BEST VALUE'),
              price: _price(AppConfig.proYearlyProductId, AppConfig.debugSuggestedYearly(country)),
              description: TxText.t('pro_features'),
              accent: TxColors.gold,
              button: () => _buy(AppConfig.proYearlyProductId, debugPro: true, debugPlus: true),
            ),
            const SizedBox(height: 14),
            TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_t('Free / Plus / Pro','Free / Plus / Pro','Free / Plus / Pro','Free / Plus / Pro'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 12),
              _row(_t('Temel dersler ve normal açıklamalar','Basislessen en normale uitleg','Grundlektionen und normale Erklärungen','Core lessons & normal explanations'), 'Free', TxColors.green),
              _row(_t('Günde 3 tam deneme + 3 akıllı açıklama','3 volledige examens + 3 slimme uitleg per dag','3 vollständige Prüfungen + 3 smarte Erklärungen pro Tag','3 full tests + 3 smart explanations per day'), 'Free', TxColors.green),
              _row(_t('Reklamsız + tam tabela oyunu','Geen advertenties + volledig bordenspel','Werbefrei + komplettes Zeichen-Spiel','No ads + full sign game'), 'Plus', TxColors.blue),
              _row(_t('Günde 6 tam deneme + 8 akıllı açıklama','6 volledige examens + 8 slimme uitleg per dag','6 vollständige Prüfungen + 8 smarte Erklärungen pro Tag','6 full tests + 8 smart explanations per day'), 'Plus', TxColors.blue),
              _row(_t('Sınırsız tam deneme','Onbeperkte volledige examens','Unbegrenzte vollständige Prüfungen','Unlimited full tests'), 'Pro', TxColors.purple),
              _row(_t('Kişiye özel yanlış denemeleri','Persoonlijke foutentests','Persönliche Fehlertests','Personal mistake tests'), 'Pro', TxColors.purple),
              _row(_t('Gelişmiş hazırlık analizi','Uitgebreide voorbereidingsanalyse','Erweiterte Bereitschaftsanalyse','Advanced readiness analysis'), 'Pro', TxColors.purple),
              _row(_t('Akıllı Öğretmen • gelişmiş kullanım','Slimme Leraar • uitgebreid gebruik','Smarter Lehrer • erweiterte Nutzung','Smart Teacher • advanced use'), 'Pro', TxColors.purple),
              _row(_t('Son 48 Saat modu','Laatste 48 Uur-modus','Letzte 48 Stunden','Final 48 Hours mode'), 'Pro', TxColors.purple),
            ])),
            const SizedBox(height: 10),
            const SizedBox(height: 6),
            Text(
              _t(
                'Satın alma işlemi mağaza hesabın üzerinden yapılır. Pro aboneliği seçilen döneme göre yenilenebilir; güncel fiyat ve koşullar ödeme onay ekranında gösterilir.',
                'Aankopen verlopen via je store-account. Pro kan volgens de gekozen periode worden verlengd; actuele prijs en voorwaarden staan op het bevestigingsscherm.',
                'Käufe erfolgen über dein Store-Konto. Pro kann je nach gewähltem Zeitraum verlängert werden; aktuelle Preise und Bedingungen stehen im Bestätigungsbildschirm.',
                'Purchases are processed by your store account. Pro may renew according to the selected period; current price and terms are shown on the purchase confirmation screen.',
              ),
              key: const ValueKey('privacy_legal_paywall_note_v121'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: TxColors.muted, fontSize: 10.5, height: 1.45),
            ),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen())),
                icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                label: Text(_t('Gizlilik ve Kullanım Koşulları','Privacy en gebruiksvoorwaarden','Datenschutz und Nutzungsbedingungen','Privacy & Terms')),
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () async {
                final ok = await ent.restore();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? _t('Satın alımlar geri yüklendi.','Aankopen hersteld.','Käufe wiederhergestellt.','Purchases restored.') : _t('Mağaza bağlantısı henüz hazır değil.','Storeverbinding is nog niet klaar.','Store-Verbindung ist noch nicht bereit.','Store connection is not ready yet.'))));
              },
              icon: const Icon(Icons.restore_rounded),
              label: Text(TxText.t('restore_purchases')),
            ),
            if (kDebugMode) ...[
              const Divider(height: 28),
              const Text('DEBUG ONLY', textAlign: TextAlign.center, style: TextStyle(color: TxColors.muted, fontSize: 10)),
              Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
                TextButton(onPressed: () => ent.setDebugEntitlements(pro: false, plus: false), child: const Text('Free')),
                TextButton(onPressed: () => ent.setDebugEntitlements(pro: false, plus: true), child: const Text('Plus')),
                TextButton(onPressed: () => ent.setDebugEntitlements(pro: true, plus: true), child: const Text('Pro')),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _planCard({required String title, required String badge, required String price, required String description, required Color accent, VoidCallback? button}) => TxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(99)), child: Text(badge, style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w900)))]),
          const SizedBox(height: 7),
          Text(price, style: TextStyle(color: accent, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(description, style: const TextStyle(color: TxColors.muted, height: 1.4)),
          if (button != null) ...[const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton(onPressed: button, child: Text(title)))],
        ]),
      );

  Widget _row(String title, String plan, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Icon(Icons.check_circle_rounded, color: color, size: 18), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))), Text(plan, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))]),
      );
}
