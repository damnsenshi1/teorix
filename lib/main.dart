import 'package:flutter/material.dart';
import 'app.dart';
import 'services/ad_service.dart';
import 'services/entitlement_service.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/app_settings_service.dart';
import 'services/app_update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsService.instance.initialize();
  await SupabaseService.initialize();
  await EntitlementService.instance.initialize();
  await NotificationService.instance.initialize();
  await AppUpdateService.instance.initialize(checkOnStart: true);
  runApp(const TeoriXApp());
  AdService.instance.initialize();
}
