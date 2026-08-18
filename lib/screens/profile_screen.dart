import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../services/app_settings_service.dart';
import '../services/entitlement_service.dart';
import '../services/ad_service.dart';
import '../services/local_progress_service.dart';
import '../services/sync_service.dart';
import '../services/supabase_service.dart';
import '../widgets/tx_widgets.dart';
import 'account_screen.dart';
import 'exam_plan_screen.dart';
import 'history_screen.dart';
import 'study_history_screen.dart';
import 'preferences_screen.dart';
import 'reminder_screen.dart';
import 'store_screen.dart';
import 'support_screen.dart';
import 'legal_screen.dart';
import 'country_language_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool pro = false;
  bool plus = false;
  String name = '';
  int historyCount = 0;

  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl,
        'de' => de,
        'en' => en,
        _ => tr,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entitlements = EntitlementService.instance;
    await entitlements.refresh();
    final h = await LocalProgressService().examHistory();
    if (!mounted) return;
    setState(() {
      pro = entitlements.pro;
      plus = entitlements.plus;
      name = AppSettingsService.instance.profileName;
      historyCount = h.length;
    });
  }

  Future<void> _editName() async {
    var draft = name;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(TxText.t('edit_name')),
        content: TextFormField(
          initialValue: name,
          autofocus: true,
          maxLength: 32,
          textInputAction: TextInputAction.done,
          onChanged: (v) => draft = v,
          onFieldSubmitted: (_) => Navigator.pop(dialogContext, draft.trim()),
          decoration: InputDecoration(hintText: TxText.t('name_hint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(TxText.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, draft.trim()), child: Text(TxText.t('save'))),
        ],
      ),
    );
    if (!mounted || value == null || value.length < 2) return;
    await AppSettingsService.instance.setProfileName(value);
    await SyncService.uploadProgress();
    await _load();
  }

  String get _planLabel => pro ? 'TeoriX Pro' : plus ? 'TeoriX Plus' : 'TeoriX Free';

  @override
  Widget build(BuildContext context) => SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              Row(children: [
                Text(TxText.t('profile'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesScreen()));
                    _load();
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ]),
              const SizedBox(height: 14),
              TxCard(
                child: Row(children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [TxColors.red, TxColors.purple]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.person_rounded, size: 34),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(
                        SupabaseService.signedInPermanently
                            ? _t('Hesabın korunuyor ve yedeklenebiliyor.','Je account is beveiligd en kan worden geback-upt.','Dein Konto ist gesichert und kann synchronisiert werden.','Your account is protected and can be backed up.')
                            : _t('Misafir kullanım • ilerleme bu cihazda tutulur','Gastmodus • voortgang staat op dit apparaat','Gastmodus • Fortschritt ist auf diesem Gerät','Guest mode • progress is stored on this device'),
                        style: const TextStyle(color: TxColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(_planLabel, style: TextStyle(color: pro ? TxColors.gold : plus ? TxColors.blue : TxColors.muted, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                  IconButton(onPressed: _editName, tooltip: TxText.t('edit_name'), icon: const Icon(Icons.edit_outlined)),
                ]),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
                  if (!context.mounted) return;
                  _load();
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: pro ? const [Color(0xFF5A3A08), Color(0xFF20170A)] : const [Color(0xFF491A76), Color(0xFF7B2CFF)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    const Icon(Icons.workspace_premium_rounded, color: TxColors.gold, size: 34),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(pro ? _t('TeoriX Pro Aktif','TeoriX Pro actief','TeoriX Pro aktiv','TeoriX Pro Active') : plus ? _t('TeoriX Plus Aktif','TeoriX Plus actief','TeoriX Plus aktiv','TeoriX Plus Active') : _t('Planını Yükselt','Upgrade je plan','Plan upgraden','Upgrade Your Plan'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      Text(
                        pro
                            ? _t('Gelişmiş çalışma araçları ve reklamsız kullanım açık.','Geavanceerde studietools en geen advertenties.','Erweiterte Lerntools und werbefrei.','Advanced study tools and ad-free use are active.')
                            : _t('Plus tek seferlik; Pro gelişmiş kişisel çalışma araçları sunar.','Plus is eenmalig; Pro biedt geavanceerde persoonlijke tools.','Plus ist einmalig; Pro bietet erweiterte persönliche Lerntools.','Plus is one-time; Pro adds advanced personal study tools.'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ])),
                    const Icon(Icons.chevron_right),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              _tile(Icons.badge_outlined, TxText.t('edit_name'), name, _editName),
              _tile(
                Icons.public_rounded,
                TxText.t('change_country'),
                '${AppSettingsService.instance.country.flag} ${AppSettingsService.instance.country.localizedCountryName(AppSettingsService.instance.locale)} • ${TxText.languageName(AppSettingsService.instance.locale)} • ${TxText.languageName(AppSettingsService.instance.contentLocale)}',
                () async {
                  final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CountryLanguageScreen()));
                  if (!context.mounted) return;
                  if (changed == true) setState(() {});
                  _load();
                },
              ),
              _tile(
                Icons.account_circle_outlined,
                TxText.t('cloud_progress'),
                SupabaseService.signedInPermanently
                    ? (SupabaseService.user?.email ?? '')
                    : _t('İstersen hesap açıp ilerlemeni koru','Maak een account om je voortgang te beschermen','Erstelle ein Konto, um deinen Fortschritt zu sichern','Create an account to protect your progress'),
                () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
                  if (!context.mounted) return;
                  _load();
                },
              ),
              _tile(Icons.notifications_none_rounded, TxText.t('notifications'), _t('Oku, sil veya tümünü temizle','Lezen, verwijderen of alles wissen','Lesen, löschen oder alles leeren','Read, delete or clear all'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              _tile(Icons.receipt_long_outlined, TxText.t('manage_membership'), _planLabel, () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())); if (!context.mounted) return; _load(); }),
              _tile(Icons.restore_rounded, TxText.t('restore_purchases'), _t('Daha önce aldığın hakları kontrol et','Controleer eerdere aankopen','Frühere Käufe prüfen','Check previous purchases'), () async {
                final ok = await EntitlementService.instance.restore();
                await _load();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? _t('Satın alımlar geri yüklendi.','Aankopen hersteld.','Käufe wiederhergestellt.','Purchases restored.') : _t('Geri yüklenecek satın alım bulunamadı veya mağaza bağlı değil.','Geen aankoop gevonden of store niet verbonden.','Kein Kauf gefunden oder Store nicht verbunden.','No purchase found or store is not connected.'))));
              }),
              _tile(Icons.history_rounded, _t('Deneme Geçmişi','Examengeschiedenis','Prüfungsverlauf','Test History'), '$historyCount', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
              _tile(Icons.timeline_rounded, _t('Çalışma Geçmişi','Studiegeschiedenis','Lernverlauf','Study History'), _t('Ders ve tekrar oturumlarını gör','Bekijk lessen en herhalingen','Lektionen und Wiederholungen ansehen','See lessons and review sessions'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyHistoryScreen()))),
              _tile(Icons.event_available_rounded, TxText.t('exam_plan'), _t('Sınav tarihi, günlük hedef ve çalışma planı','Examendatum, dagdoel en studieplan','Prüfungstermin, Tagesziel und Lernplan','Test date, daily target and study plan'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamPlanScreen()))),
              if (!pro && !plus)
                _tile(Icons.ondemand_video_rounded, TxText.t('reward_exam'), _t('Tamamen isteğe bağlı ödüllü reklam','Volledig optionele beloningsadvertentie','Völlig optionale Reward-Werbung','Completely optional rewarded ad'), () async {
                  if (kIsWeb && kDebugMode) {
                    await LocalProgressService().unlockExtraExamToday();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('Bonus deneme açıldı.','Bonus examen geopend.','Bonusprüfung freigeschaltet.','Bonus full test unlocked.'))));
                    return;
                  }
                  final earned = await AdService.instance.showRewarded();
                  if (earned) await LocalProgressService().unlockExtraExamToday();
                }),
              _tile(Icons.notifications_active_outlined, TxText.t('study_reminders'), _t('Günlük çalışma saatini ayarla','Stel je dagelijkse studietijd in','Tägliche Lernzeit einstellen','Set your daily study time'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderScreen()))),
              _tile(Icons.cloud_upload_outlined, _t('Şimdi Yedekle','Nu back-uppen','Jetzt sichern','Back Up Now'), _t('Mevcut ülke ilerlemesini hesabına kaydet','Sla de voortgang van dit land op','Fortschritt dieses Landes sichern','Save this country progress to your account'), () async {
                final msg = await SyncService.uploadProgress();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }),
              _tile(Icons.tune_rounded, TxText.t('ad_preferences'), _t('Gizlilik ve reklam tercihlerini yönet','Beheer privacy en advertentievoorkeuren','Datenschutz und Werbung verwalten','Manage privacy and ad preferences'), () async { await AdService.instance.showPrivacyOptions(); }),
              _tile(Icons.privacy_tip_outlined, _t('Gizlilik & Kullanım','Privacy & Gebruik','Datenschutz & Nutzung','Privacy & Use'), _t('İçerik, veriler ve reklam yaklaşımımız','Inhoud, gegevens en advertenties','Inhalte, Daten und Werbung','Content, data and advertising approach'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen()))),
              _tile(Icons.help_outline_rounded, _t('Yardım & Destek','Hulp & Ondersteuning','Hilfe & Support','Help & Support'), _t('SSS, soru bildirimi ve destek','FAQ, vragen melden en support','FAQ, Fragen melden und Support','FAQ, question reports and support'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
              const SizedBox(height: 18),
              const Center(child: Text('TeoriX • Senshi Labs • v1.3.2 Beta', style: TextStyle(color: TxColors.muted, fontSize: 12))),
            ],
          ),
        ),
      );

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: TxCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            onTap: onTap,
            leading: Icon(icon, color: TxColors.muted),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            subtitle: Text(subtitle, style: const TextStyle(color: TxColors.muted, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded, color: TxColors.muted),
          ),
        ),
      );
}
