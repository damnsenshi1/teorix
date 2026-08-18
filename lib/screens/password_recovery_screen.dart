import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/app_settings_service.dart';
import '../services/supabase_service.dart';
import '../widgets/tx_widgets.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  final VoidCallback onDone;
  const PasswordRecoveryScreen({super.key, required this.onDone});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;

  String _t(String tr, String nl, String de, String en) => switch (AppSettingsService.instance.locale) {
        'nl' => nl,
        'de' => de,
        'en' => en,
        _ => tr,
      };

  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (password.text.length < 6 || password.text != confirm.text) {
      _snack(_t(
        'Şifreler aynı olmalı ve en az 6 karakter içermeli.',
        'Wachtwoorden moeten gelijk zijn en minimaal 6 tekens bevatten.',
        'Die Passwörter müssen übereinstimmen und mindestens 6 Zeichen lang sein.',
        'Passwords must match and contain at least 6 characters.',
      ));
      return;
    }
    setState(() => loading = true);
    final error = await SupabaseService.updatePassword(password.text);
    if (!mounted) return;
    setState(() => loading = false);
    if (error != null) {
      _snack(error);
      return;
    }
    _snack(_t('Şifren güncellendi.', 'Je wachtwoord is bijgewerkt.', 'Dein Passwort wurde aktualisiert.', 'Your password was updated.'));
    widget.onDone();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 42, 20, 28),
                shrinkWrap: true,
                children: [
                  const Center(child: TxLogo(size: 48)),
                  const SizedBox(height: 22),
                  Text(_t('Yeni Şifre Belirle', 'Nieuw wachtwoord instellen', 'Neues Passwort festlegen', 'Set a New Password'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(_t('Hesabın için yeni şifreni oluştur.', 'Maak een nieuw wachtwoord voor je account.', 'Erstelle ein neues Passwort für dein Konto.', 'Create a new password for your account.'), textAlign: TextAlign.center, style: const TextStyle(color: TxColors.muted)),
                  const SizedBox(height: 24),
                  TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: _t('Yeni şifre', 'Nieuw wachtwoord', 'Neues Passwort', 'New password'))),
                  const SizedBox(height: 12),
                  TextField(controller: confirm, obscureText: true, textInputAction: TextInputAction.done, onSubmitted: (_) => _save(), decoration: InputDecoration(labelText: _t('Yeni şifre tekrar', 'Herhaal nieuw wachtwoord', 'Neues Passwort wiederholen', 'Repeat new password'))),
                  const SizedBox(height: 18),
                  FilledButton.icon(onPressed: loading ? null : _save, icon: const Icon(Icons.lock_reset_rounded), label: Text(_t('Şifreyi Güncelle', 'Wachtwoord bijwerken', 'Passwort aktualisieren', 'Update Password'))),
                ],
              ),
            ),
          ),
        ),
      );
}
