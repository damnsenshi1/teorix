import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/traffic_sign.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../services/remote_content_service.dart';
import '../services/content_translation_service.dart';

class TrafficSignRepository {
  Future<List<TrafficSignInfo>> load({CountryProfile? profile}) async {
    final active = profile ?? AppSettingsService.instance.country;
    final remote = await RemoteContentService.instance.loadPack(
      countryId: active.id, type: 'traffic_signs', locale: active.primaryLocale,
    );
    final list = remote ??
        (jsonDecode(await rootBundle.loadString(
          'assets/data/traffic_signs_${active.assetSuffix}.json',
        )) as List<dynamic>);
    var signs = list.map((e) => TrafficSignInfo.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final target = AppSettingsService.instance.contentLocale;
    if (target != active.primaryLocale && ContentTranslationService.instance.supported) {
      final t = ContentTranslationService.instance;
      final localized = <TrafficSignInfo>[];
      for (final sign in signs) {
        localized.add(TrafficSignInfo(
          id: sign.id,
          group: await t.translate(sign.group, source: active.primaryLocale, target: target),
          name: await t.translate(sign.name, source: active.primaryLocale, target: target),
          meaning: await t.translate(sign.meaning, source: active.primaryLocale, target: target),
          shape: sign.shape,
          symbol: sign.symbol,
          memoryTip: await t.translate(sign.memoryTip, source: active.primaryLocale, target: target),
        ));
      }
      signs = localized;
    }
    return signs;
  }
}
