import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../services/content_translation_service.dart';
import '../services/local_progress_service.dart';
import '../services/notification_service.dart';
import '../widgets/tx_widgets.dart';
import 'home_shell.dart';

class CountryLanguageScreen extends StatefulWidget {
  final bool onboarding;
  const CountryLanguageScreen({super.key, this.onboarding = false});

  @override
  State<CountryLanguageScreen> createState() => _CountryLanguageScreenState();
}

class _CountryLanguageScreenState extends State<CountryLanguageScreen> {
  late String countryId;
  late String locale;
  late String contentLocale;
  bool preparing = false;

  String _tx(String key) => TxText.forLocale(key, locale);
  String _pick(String tr, String nl, String de, String en) => switch (locale) {
        'tr' => tr,
        'nl' => nl,
        'de' => de,
        _ => en,
      };

  static const languages = [
    ('tr', '🇹🇷', 'Türkçe'),
    ('nl', '🇳🇱', 'Nederlands'),
    ('de', '🇩🇪', 'Deutsch'),
    ('en', '🇬🇧', 'English'),
  ];

  @override
  void initState() {
    super.initState();
    countryId = AppSettingsService.instance.countryId;
    locale = AppSettingsService.instance.locale;
    contentLocale = AppSettingsService.instance.contentLocale;
  }

  Future<void> _prepareTranslation({bool showMessage = true}) async {
    final selected = CountryCatalog.byId(countryId);
    if (contentLocale == selected.primaryLocale) return;
    if (kIsWeb) {
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tx('web_translation_note'))));
      }
      return;
    }
    setState(() => preparing = true);
    final ok = await ContentTranslationService.instance.prepare(source: selected.primaryLocale, target: contentLocale);
    if (!mounted) return;
    setState(() => preparing = false);
    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tx(ok ? 'translation_ready' : 'translation_failed'))));
    }
  }

  Future<void> _save() async {
    final selected = CountryCatalog.byId(countryId);
    await AppSettingsService.instance.setCountry(countryId, resetLocaleToPrimary: false);
    await AppSettingsService.instance.setLocale(locale);
    await AppSettingsService.instance.setContentLocale(contentLocale);
    if (contentLocale != selected.primaryLocale) await _prepareTranslation(showMessage: false);

    final progress = LocalProgressService();
    if (await progress.reminderEnabled()) {
      await NotificationService.instance.scheduleDaily(
        hour: await progress.reminderHour(),
        minute: await progress.reminderMinute(),
      );
    }
    if (widget.onboarding) await AppSettingsService.instance.completeOnboarding();
    if (!mounted) return;
    if (widget.onboarding) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  Widget _languageChips({required String value, required ValueChanged<String> onChanged}) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: languages.map((item) {
          final (code, flag, name) = item;
          return ChoiceChip(
            selected: value == code,
            onSelected: (_) => setState(() => onChanged(code)),
            label: Text('$flag  $name'),
          );
        }).toList(),
      );

  @override
  Widget build(BuildContext context) {
    final selected = CountryCatalog.byId(countryId);
    return Scaffold(
      appBar: widget.onboarding ? null : AppBar(title: Text(_tx('change_country'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
          children: [
            if (widget.onboarding) ...[
              const Center(child: TxLogo(size: 42)),
              const SizedBox(height: 18),
              const Text('TeoriX', textAlign: TextAlign.center, style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Driving Theory • Senshi Labs', textAlign: TextAlign.center, style: TextStyle(color: TxColors.muted)),
              const SizedBox(height: 26),
            ],
            Text(_tx('choose_country'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(_tx('practice_notice'), style: const TextStyle(color: TxColors.muted, height: 1.4, fontSize: 12)),
            const SizedBox(height: 14),
            ...CountryCatalog.all.map((country) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() {
                      countryId = country.id;
                      if (!country.supportedLocales.contains(contentLocale)) contentLocale = country.primaryLocale;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: countryId == country.id ? const Color(0xFF162A45) : TxColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: countryId == country.id ? TxColors.blue : Colors.white10, width: countryId == country.id ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        Text(country.flag, style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(country.localizedCountryName(locale), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 3),
                          Text('${country.localizedLicenseLabel(locale)} • ${country.examAuthority}', style: const TextStyle(color: TxColors.muted, fontSize: 11)),
                          const SizedBox(height: 3),
                          Text(country.localizedFormatNote(locale), style: const TextStyle(color: TxColors.muted, fontSize: 10)),
                        ])),
                        if (countryId == country.id) const Icon(Icons.check_circle_rounded, color: TxColors.green),
                      ]),
                    ),
                  ),
                )),
            const SizedBox(height: 18),
            Text(_tx('choose_language'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            _languageChips(value: locale, onChanged: (v) => locale = v),
            const SizedBox(height: 20),
            Text(_tx('choose_content_language'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(_tx('content_language_help'), style: const TextStyle(color: TxColors.muted, fontSize: 11, height: 1.4)),
            const SizedBox(height: 10),
            _languageChips(value: contentLocale, onChanged: (v) => contentLocale = v),
            if (contentLocale != selected.primaryLocale) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: preparing ? null : () => _prepareTranslation(),
                icon: preparing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.translate_rounded),
                label: Text(_tx('download_translation')),
              ),
              if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_tx('web_translation_note'), style: const TextStyle(color: TxColors.gold, fontSize: 10, height: 1.4)),
                ),
            ],
            const SizedBox(height: 18),
            TxCard(child: Row(children: [
              Text(selected.flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_tx('country_pack')}: ${selected.localizedCountryName(locale)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(_pick('${selected.fullExamQuestions} soru • ${selected.examMinutes} dk • ${selected.passRuleSummary(locale)}','${selected.fullExamQuestions} vragen • ${selected.examMinutes} min • ${selected.passRuleSummary(locale)}','${selected.fullExamQuestions} Fragen • ${selected.examMinutes} Min. • ${selected.passRuleSummary(locale)}','${selected.fullExamQuestions} questions • ${selected.examMinutes} min • ${selected.passRuleSummary(locale)}'), style: const TextStyle(color: TxColors.muted, fontSize: 11, height: 1.35)),
                const SizedBox(height: 3),
                Text('${_tx('app_language')}: ${TxText.languageName(locale)} • ${_tx('study_language')}: ${TxText.languageName(contentLocale)}', style: const TextStyle(color: TxColors.muted, fontSize: 10)),
                if (selected.hasHazardPerception) ...[
                  const SizedBox(height: 4),
                  Text(_tx('hazard_note'), style: const TextStyle(color: TxColors.gold, fontSize: 10)),
                ],
              ])),
            ])),
            const SizedBox(height: 22),
            FilledButton.icon(onPressed: preparing ? null : _save, icon: const Icon(Icons.arrow_forward_rounded), label: Text(_tx('continue'))),
          ],
        ),
      ),
    );
  }
}
