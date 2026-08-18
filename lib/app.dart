import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'screens/country_language_screen.dart';
import 'screens/auth_choice_screen.dart';
import 'screens/password_recovery_screen.dart';
import 'screens/profile_name_screen.dart';
import 'services/app_settings_service.dart';
import 'services/supabase_service.dart';

class TeoriXApp extends StatefulWidget {
  const TeoriXApp({super.key});

  @override
  State<TeoriXApp> createState() => _TeoriXAppState();
}

class _TeoriXAppState extends State<TeoriXApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool passwordRecovery = false;

  @override
  void initState() {
    super.initState();
    final client = SupabaseService.client;
    if (client != null) {
      _authSubscription = client.auth.onAuthStateChange.listen(
        (data) {
          if (!mounted) return;
          if (data.event == AuthChangeEvent.passwordRecovery) {
            setState(() => passwordRecovery = true);
          }
        },
        onError: (_) {},
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TeoriX',
        theme: buildTeoriXTheme(),
        home: passwordRecovery
            ? PasswordRecoveryScreen(
                onDone: () {
                  if (mounted) setState(() => passwordRecovery = false);
                },
              )
            : settings.profileName.isEmpty
                ? const ProfileNameScreen(onboarding: true)
                : !settings.accountChoiceComplete
                    ? const AuthChoiceScreen()
                    : settings.onboardingComplete
                        ? HomeShell(
                            key: ValueKey(
                              'shell-${settings.countryId}-${settings.locale}-${settings.contentLocale}',
                            ),
                          )
                        : const CountryLanguageScreen(onboarding: true),
      ),
    );
  }
}
