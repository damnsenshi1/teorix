import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/theme.dart';
import '../services/app_settings_service.dart';
import '../widgets/tx_widgets.dart';

class ProfileNameScreen extends StatefulWidget {
  final bool onboarding;
  const ProfileNameScreen({super.key, this.onboarding = false});

  @override
  State<ProfileNameScreen> createState() => _ProfileNameScreenState();
}

class _ProfileNameScreenState extends State<ProfileNameScreen> {
  late final TextEditingController controller;
  String? error;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: AppSettingsService.instance.profileName);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = controller.text.trim();
    if (value.length < 2) {
      setState(() => error = TxText.t('name_required'));
      return;
    }
    await AppSettingsService.instance.setProfileName(value.characters.take(32).toString());
    if (!mounted) return;
    if (!widget.onboarding) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  Text(TxText.t('name_title'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(TxText.t('name_help'), textAlign: TextAlign.center, style: const TextStyle(color: TxColors.muted, height: 1.45)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: TxText.t('name_hint'),
                      errorText: error,
                      prefixIcon: const Icon(Icons.person_rounded),
                      filled: true,
                      fillColor: TxColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(onPressed: _save, icon: const Icon(Icons.arrow_forward_rounded), label: Text(TxText.t('continue'))),
                ],
              ),
            ),
          ),
        ),
      );
}
