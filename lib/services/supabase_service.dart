import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_config.dart';

class SupabaseService {
  static bool get configured =>
      AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabasePublishableKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!configured) return;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
      );
    } catch (_) {
      // Cloud setup must never block the local study experience.
    }
  }

  static SupabaseClient? get client {
    if (!configured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static User? get user => client?.auth.currentUser;
  static bool get signedInPermanently => user?.email?.isNotEmpty == true;

  static Future<void> signInAnonymouslyIfNeeded() async {
    final c = client;
    if (c == null || c.auth.currentSession != null) return;
    try {
      await c.auth.signInAnonymously();
    } catch (_) {
      // Local-only mode keeps app usable when anonymous auth is disabled.
    }
  }


  static const mobileAuthRedirect = 'com.senshilabs.teorix://login-callback/';

  static Future<String?> signInWithGoogle() async {
    final c = client;
    if (c == null) return 'cloud_not_configured';
    try {
      await c.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : mobileAuthRedirect,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'connection_error';
    }
  }

  static Future<String?> signInWithApple() async {
    final c = client;
    if (c == null) return 'cloud_not_configured';
    try {
      await c.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : mobileAuthRedirect,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'connection_error';
    }
  }

  static Future<String?> signInWithPassword({required String email, required String password}) async {
    final c = client;
    if (c == null) return 'cloud_not_configured';
    try {
      await c.auth.signInWithPassword(email: email.trim(), password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'connection_error';
    }
  }

  static Future<String?> signUp({required String email, required String password, required String displayName}) async {
    final c = client;
    if (c == null) return 'cloud_not_configured';
    try {
      await c.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: kIsWeb ? null : mobileAuthRedirect,
        data: {'display_name': displayName.trim()},
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'connection_error';
    }
  }

  static Future<String?> sendPasswordReset(String email) async {
    final c = client;
    if (c == null) return 'cloud_not_configured';
    try {
      await c.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb ? null : mobileAuthRedirect,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'connection_error';
    }
  }

  static Future<String?> updatePassword(String password) async {
    final c = client;
    if (c == null) return 'cloud_not_configured';
    try {
      await c.auth.updateUser(UserAttributes(password: password));
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'connection_error';
    }
  }

  static Future<String?> deleteCurrentAccount() async {
    final c = client;
    final current = c?.auth.currentUser;
    if (c == null || current == null || current.email?.isNotEmpty != true) {
      return 'account_not_available';
    }
    try {
      final response = await c.functions.invoke('delete-account');
      if (response.status >= 200 && response.status < 300) {
        try { await c.auth.signOut(); } catch (_) {}
        return null;
      }
      return 'delete_failed';
    } catch (_) {
      return 'delete_failed';
    }
  }

  static Future<void> signOut() async {
    try {
      await client?.auth.signOut();
    } catch (_) {}
  }
}
