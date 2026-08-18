import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../services/app_settings_service.dart';
import '../services/entitlement_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../widgets/tx_widgets.dart';
import 'account_screen.dart';

class AuthChoiceScreen extends StatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen> {
  bool loading = false;
  StreamSubscription<AuthState>? _authSubscription;

  String _t(String tr, String nl, String de, String en) =>
      TxText.pick(tr, nl, de, en);

  @override
  void initState() {
    super.initState();
    final client = SupabaseService.client;
    if (client != null) {
      _authSubscription = client.auth.onAuthStateChange.listen(
        (data) {
          if (data.event == AuthChangeEvent.signedIn && SupabaseService.signedInPermanently) {
            _finishExistingLogin();
          }
        },
        onError: (_) {},
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishExistingLogin());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _finishExistingLogin() async {
    if (!SupabaseService.signedInPermanently || !mounted) return;
    await EntitlementService.instance.identifySupabaseUser();
    await SyncService.uploadProgress();
    await AppSettingsService.instance.completeAccountChoice();
  }

  Future<void> _continueAsGuest() async {
    setState(() => loading = true);
    await AppSettingsService.instance.completeAccountChoice();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _openEmail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountScreen(onboarding: true)),
    );
    if (!mounted) return;
    if (SupabaseService.signedInPermanently) {
      await _finishExistingLogin();
    }
  }

  Future<void> _google() async {
    if (!SupabaseService.configured) {
      _snack(_t(
        'Google girişi bulut ayarları bağlandıktan sonra aktif olacak. Şimdilik misafir olarak devam edebilirsin.',
        'Google-login wordt actief zodra de cloudconfiguratie is gekoppeld. Je kunt nu als gast doorgaan.',
        'Google-Anmeldung wird nach dem Verbinden der Cloud-Konfiguration aktiv. Du kannst vorerst als Gast fortfahren.',
        'Google sign-in becomes available after cloud configuration is connected. You can continue as a guest for now.',
      ));
      return;
    }
    setState(() => loading = true);
    final error = await SupabaseService.signInWithGoogle();
    if (!mounted) return;
    setState(() => loading = false);
    if (error != null) {
      _snack(_authError(error));
      return;
    }
    if (SupabaseService.signedInPermanently) {
      await _finishExistingLogin();
      return;
    }
    _snack(_t(
      'Google girişini tarayıcıda tamamla. TeoriX’e döndüğünde hesabın otomatik bağlanır.',
      'Rond Google-login af in de browser. Wanneer je terugkeert naar TeoriX wordt je account automatisch gekoppeld.',
      'Schließe die Google-Anmeldung im Browser ab. Nach der Rückkehr zu TeoriX wird dein Konto automatisch verbunden.',
      'Finish Google sign-in in the browser. Your account will be linked automatically when you return to TeoriX.',
    ));
  }

  Future<void> _apple() async {
    if (!SupabaseService.configured) return;
    setState(() => loading = true);
    final error = await SupabaseService.signInWithApple();
    if (!mounted) return;
    setState(() => loading = false);
    if (error != null) {
      _snack(_authError(error));
      return;
    }
    if (SupabaseService.signedInPermanently) {
      await _finishExistingLogin();
    }
  }

  String _authError(String error) => error == 'cloud_not_configured'
      ? _t('Bulut hesabı henüz yapılandırılmadı.', 'Cloudaccount is nog niet geconfigureerd.', 'Cloud-Konto ist noch nicht konfiguriert.', 'Cloud account is not configured yet.')
      : error == 'connection_error'
          ? _t('Bağlantı kurulamadı.', 'Verbinding mislukt.', 'Verbindung fehlgeschlagen.', 'Connection failed.')
          : error;

  void _snack(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final showApple = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
              shrinkWrap: true,
              children: [
                const Center(child: TxLogo(size: 48)),
                const SizedBox(height: 20),
                Text(
                  _t('İlerlemeni nasıl koruyalım?', 'Hoe wil je je voortgang bewaren?', 'Wie möchtest du deinen Fortschritt sichern?', 'How should we protect your progress?'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 9),
                Text(
                  _t(
                    'Hesap zorunlu değil. Misafir olarak hemen başlayabilir, daha sonra hesabını bağlayabilirsin.',
                    'Een account is niet verplicht. Je kunt direct als gast beginnen en later je account koppelen.',
                    'Ein Konto ist nicht erforderlich. Du kannst sofort als Gast starten und es später verbinden.',
                    'An account is optional. Start as a guest now and link an account later.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TxColors.muted, height: 1.45),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: loading ? null : _google,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: Text(_t('Google ile Devam Et', 'Doorgaan met Google', 'Mit Google fortfahren', 'Continue with Google')),
                ),
                if (showApple) ...[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: loading ? null : _apple,
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    icon: const Icon(Icons.apple_rounded),
                    label: Text(_t('Apple ile Devam Et', 'Doorgaan met Apple', 'Mit Apple fortfahren', 'Continue with Apple')),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: loading ? null : _openEmail,
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: Text(_t('E-posta ile Devam Et', 'Doorgaan met e-mail', 'Mit E-Mail fortfahren', 'Continue with Email')),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: loading ? null : _continueAsGuest,
                  icon: const Icon(Icons.person_outline_rounded),
                  label: Text(_t('Misafir Olarak Devam Et', 'Doorgaan als gast', 'Als Gast fortfahren', 'Continue as Guest')),
                ),
                const SizedBox(height: 18),
                TxCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cloud_done_outlined, color: TxColors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _t(
                            'Hesap bağlarsan yanlışların, seri günlerin ve çalışma ilerlemen buluta yedeklenebilir. Misafir verilerin daha sonra hesabına aktarılır.',
                            'Met een account kunnen fouten, streaks en studievoortgang in de cloud worden opgeslagen. Gastgegevens kunnen later worden overgezet.',
                            'Mit einem Konto können Fehler, Serien und Lernfortschritt in der Cloud gesichert werden. Gastdaten können später übernommen werden.',
                            'Linking an account can back up mistakes, streaks and study progress to the cloud. Guest progress can be merged later.',
                          ),
                          style: const TextStyle(color: TxColors.muted, height: 1.4, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                if (loading) ...[
                  const SizedBox(height: 18),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
