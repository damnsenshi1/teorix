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

class AccountScreen extends StatefulWidget {
  final bool onboarding;
  const AccountScreen({super.key, this.onboarding = false});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool loading = false;
  StreamSubscription<AuthState>? _authSubscription;

  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl,
        'de' => de,
        'en' => en,
        _ => tr,
      };


  @override
  void initState() {
    super.initState();
    final client = SupabaseService.client;
    if (client != null) {
      _authSubscription = client.auth.onAuthStateChange.listen(
        (data) async {
          if (data.event != AuthChangeEvent.signedIn || !SupabaseService.signedInPermanently) return;
          await EntitlementService.instance.identifySupabaseUser();
          await SyncService.uploadProgress();
          if (!mounted) return;
          if (widget.onboarding) {
            Navigator.pop(context, true);
          } else {
            setState(() {});
          }
        },
        onError: (_) {},
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      _snack(_t('Geçerli e-posta ve en az 6 karakter şifre gir.','Vul een geldig e-mailadres en een wachtwoord van minimaal 6 tekens in.','Gib eine gültige E-Mail und ein Passwort mit mindestens 6 Zeichen ein.','Enter a valid email and a password of at least 6 characters.'));
      return;
    }
    setState(() => loading = true);
    final error = register
        ? await SupabaseService.signUp(email: email.text, password: password.text, displayName: AppSettingsService.instance.profileName)
        : await SupabaseService.signInWithPassword(email: email.text, password: password.text);
    if (!mounted) return;
    setState(() => loading = false);
    if (error != null) {
      _snack(error == 'cloud_not_configured'
          ? _t('Bulut hesabı henüz bağlanmadı. bulut ayarları eklendiğinde burası aktif olacak.','Cloud account is nog niet geconfigureerd.','Cloud-Konto ist noch nicht konfiguriert.','Cloud account is not configured yet.')
          : error == 'connection_error'
              ? _t('Bağlantı kurulamadı.','Verbinding mislukt.','Verbindung fehlgeschlagen.','Connection failed.')
              : error);
      return;
    }
    await EntitlementService.instance.identifySupabaseUser();
    await SyncService.uploadProgress();
    if (!mounted) return;
    _snack(register
        ? _t('Hesabın oluşturuldu. E-posta doğrulaması açıksa gelen kutunu kontrol et.','Account aangemaakt. Controleer je e-mail als bevestiging is ingeschakeld.','Konto erstellt. Prüfe deine E-Mail, falls Bestätigung aktiv ist.','Account created. Check your email if confirmation is enabled.')
        : _t('Hesabına giriş yapıldı ve ilerlemen yedeklendi.','Je bent ingelogd en je voortgang is opgeslagen.','Angemeldet und Fortschritt gesichert.','Signed in and progress backed up.'));
    if (widget.onboarding && SupabaseService.signedInPermanently) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {});
  }

  Future<void> _forgotPassword() async {
    final value = email.text.trim();
    if (!value.contains('@')) {
      _snack(_t('Önce e-posta adresini gir.','Vul eerst je e-mailadres in.','Gib zuerst deine E-Mail-Adresse ein.','Enter your email address first.'));
      return;
    }
    setState(() => loading = true);
    final error = await SupabaseService.sendPasswordReset(value);
    if (!mounted) return;
    setState(() => loading = false);
    if (error != null) {
      _snack(error == 'connection_error'
          ? _t('Bağlantı kurulamadı.','Verbinding mislukt.','Verbindung fehlgeschlagen.','Connection failed.')
          : error);
      return;
    }
    _snack(_t('Şifre yenileme bağlantısı e-postana gönderildi.','De link om je wachtwoord te resetten is verzonden.','Der Link zum Zurücksetzen des Passworts wurde gesendet.','Password reset link sent to your email.'));
  }

  Future<void> _google() async {
    setState(() => loading = true);
    final error = await SupabaseService.signInWithGoogle();
    if (!mounted) return;
    setState(() => loading = false);
    if (error != null) {
      _snack(error == 'cloud_not_configured'
          ? _t('Bulut hesabı henüz bağlanmadı.','Cloudaccount is nog niet geconfigureerd.','Cloud-Konto ist noch nicht konfiguriert.','Cloud account is not configured yet.')
          : error == 'connection_error'
              ? _t('Bağlantı kurulamadı.','Verbinding mislukt.','Verbindung fehlgeschlagen.','Connection failed.')
              : error);
      return;
    }
    if (SupabaseService.signedInPermanently) {
      await EntitlementService.instance.identifySupabaseUser();
      await SyncService.uploadProgress();
      if (!mounted) return;
      if (widget.onboarding) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {});
    } else {
      _snack(_t(
        'Google girişini tarayıcıda tamamla. TeoriX’e döndüğünde hesabın bağlanır.',
        'Rond Google-login af in de browser. Na terugkeer wordt je account gekoppeld.',
        'Schließe die Google-Anmeldung im Browser ab. Danach wird dein Konto verbunden.',
        'Finish Google sign-in in the browser. Your account will be linked when you return.',
      ));
    }
  }

  Future<void> _apple() async {
    setState(() => loading = true);
    final error = await SupabaseService.signInWithApple();
    if (!mounted) return;
    setState(() => loading = false);
    if (error != null) {
      _snack(error == 'cloud_not_configured'
          ? _t('Bulut hesabı henüz bağlanmadı.','Cloudaccount is nog niet geconfigureerd.','Cloud-Konto ist noch nicht konfiguriert.','Cloud account is not configured yet.')
          : error == 'connection_error'
              ? _t('Bağlantı kurulamadı.','Verbinding mislukt.','Verbindung fehlgeschlagen.','Connection failed.')
              : error);
      return;
    }
    if (SupabaseService.signedInPermanently) {
      await EntitlementService.instance.identifySupabaseUser();
      await SyncService.uploadProgress();
      if (!mounted) return;
      if (widget.onboarding) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {});
    } else {
      _snack(_t(
        'Apple girişini tamamla. TeoriX’e döndüğünde hesabın bağlanır.',
        'Rond Apple-login af. Na terugkeer wordt je account gekoppeld.',
        'Schließe die Apple-Anmeldung ab. Danach wird dein Konto verbunden.',
        'Finish Apple sign-in. Your account will be linked when you return.',
      ));
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_t('Hesabı Sil', 'Account verwijderen', 'Konto löschen', 'Delete Account')),
        content: Text(_t(
          'Bu işlem bulut hesabını ve hesapla ilişkili bulut ilerlemeni kalıcı olarak siler. Cihazındaki yerel çalışma verileri otomatik silinmez. Bu işlem geri alınamaz.',
          'Hiermee worden je cloudaccount en gekoppelde cloudvoortgang permanent verwijderd. Lokale studiegegevens op dit apparaat worden niet automatisch verwijderd. Dit kan niet ongedaan worden gemaakt.',
          'Dadurch werden dein Cloud-Konto und der zugehörige Cloud-Fortschritt dauerhaft gelöscht. Lokale Lerndaten auf diesem Gerät werden nicht automatisch gelöscht. Dies kann nicht rückgängig gemacht werden.',
          'This permanently deletes your cloud account and linked cloud progress. Local study data on this device is not automatically deleted. This cannot be undone.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(TxText.t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t('Kalıcı Olarak Sil', 'Permanent verwijderen', 'Dauerhaft löschen', 'Delete Permanently')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => loading = true);
    final error = await SupabaseService.deleteCurrentAccount();
    if (!mounted) return;
    setState(() => loading = false);
    if (error != null) {
      _snack(_t(
        'Hesap silinemedi. İnternet bağlantını kontrol et veya daha sonra tekrar dene.',
        'Account kon niet worden verwijderd. Controleer je verbinding en probeer later opnieuw.',
        'Konto konnte nicht gelöscht werden. Prüfe deine Verbindung und versuche es später erneut.',
        'Account could not be deleted. Check your connection and try again later.',
      ));
      return;
    }
    await EntitlementService.instance.detachAccountIdentity();
    if (!mounted) return;
    _snack(_t('Bulut hesabın silindi.', 'Je cloudaccount is verwijderd.', 'Dein Cloud-Konto wurde gelöscht.', 'Your cloud account was deleted.'));
    setState(() {});
  }

  Future<void> _signOut() async {
    await EntitlementService.instance.detachAccountIdentity();
    await SupabaseService.signOut();
    if (!mounted) return;
    setState(() {});
  }

  void _snack(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    final configured = SupabaseService.configured;
    final user = SupabaseService.user;
    final permanent = SupabaseService.signedInPermanently;
    return Scaffold(
      appBar: AppBar(title: Text(TxText.t('cloud_progress'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TxCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(permanent ? Icons.verified_user_rounded : Icons.person_outline_rounded, color: permanent ? TxColors.green : TxColors.blue),
              const SizedBox(width: 10),
              Expanded(child: Text(permanent
                  ? _t('Hesabın korunuyor','Je account is beveiligd','Dein Konto ist gesichert','Your account is protected')
                  : _t('Misafir modundasın','Je gebruikt gastmodus','Du bist im Gastmodus','You are using guest mode'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
            ]),
            const SizedBox(height: 9),
            Text(permanent
                ? (user?.email ?? '')
                : _t('Soru çözmeye hesap açmadan devam edebilirsin. Hesap oluşturursan ilerlemeni telefon değiştirince geri getirebilirsin.','Je kunt zonder account blijven oefenen. Met een account kun je je voortgang later herstellen.','Du kannst ohne Konto weiterlernen. Mit Konto kannst du deinen Fortschritt wiederherstellen.','You can keep studying without an account. Create one to restore progress after changing phones.'),
                style: const TextStyle(color: TxColors.muted, height: 1.4)),
          ])),
          const SizedBox(height: 12),
          if (!configured)
            TxCard(child: Text(_t('Geliştirme modunda bulut ayarları boş. Uygulama yerel olarak tam çalışır; bulut anahtarlarını eklediğinde hesap ekranı otomatik aktif olur.','Cloudinstellingen zijn leeg in development. De app blijft lokaal werken.','Cloud-Einstellungen sind im Development leer. Die App funktioniert lokal weiter.','Cloud settings are empty in development. The app remains fully usable locally.'), style: const TextStyle(color: TxColors.muted, height: 1.45)))
          else if (permanent) ...[
            FilledButton.icon(onPressed: () async { _snack(await SyncService.uploadProgress()); }, icon: const Icon(Icons.cloud_upload_outlined), label: Text(_t('Şimdi Yedekle','Nu back-uppen','Jetzt sichern','Back Up Now'))),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: () async { _snack(await SyncService.restoreProgress()); }, icon: const Icon(Icons.cloud_download_outlined), label: Text(_t('Buluttan Geri Yükle','Herstellen uit cloud','Aus Cloud wiederherstellen','Restore from Cloud'))),
            const SizedBox(height: 10),
            TextButton.icon(onPressed: _signOut, icon: const Icon(Icons.logout_rounded), label: Text(TxText.t('sign_out'))),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: loading ? null : _deleteAccount,
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(_t('Hesabımı Sil','Mijn account verwijderen','Mein Konto löschen','Delete My Account')),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: loading ? null : _google,
              icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: Text(_t('Google ile Devam Et','Doorgaan met Google','Mit Google fortfahren','Continue with Google')),
            ),
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: loading ? null : _apple,
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                icon: const Icon(Icons.apple_rounded),
                label: Text(_t('Apple ile Devam Et','Doorgaan met Apple','Mit Apple fortfahren','Continue with Apple')),
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(_t('veya','of','oder','or'), style: const TextStyle(color: TxColors.muted, fontSize: 11)),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(_t('Giriş Yap','Inloggen','Anmelden','Sign In'))),
                ButtonSegment(value: true, label: Text(_t('Hesap Oluştur','Account maken','Konto erstellen','Create Account'))),
              ],
              selected: {register},
              onSelectionChanged: (v) => setState(() => register = v.first),
            ),
            const SizedBox(height: 14),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: _t('E-posta','E-mail','E-Mail','Email'))),
            const SizedBox(height: 10),
            TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: _t('Şifre','Wachtwoord','Passwort','Password'))),
            if (!register)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading ? null : _forgotPassword,
                  child: Text(_t('Şifremi unuttum','Wachtwoord vergeten','Passwort vergessen','Forgot password')),
                ),
              ),
            const SizedBox(height: 6),
            FilledButton(onPressed: loading ? null : _submit, child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(register ? _t('Hesap Oluştur','Account maken','Konto erstellen','Create Account') : _t('Giriş Yap','Inloggen','Anmelden','Sign In'))),
          ],
        ],
      ),
    );
  }
}
