import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationBackend {
  bool get supported => defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  TranslateLanguage? _lang(String code) => switch (code) {
        'tr' => TranslateLanguage.turkish,
        'nl' => TranslateLanguage.dutch,
        'de' => TranslateLanguage.german,
        'en' => TranslateLanguage.english,
        _ => null,
      };

  Future<bool> prepare({required String source, required String target}) async {
    if (source == target) return true;
    if (!supported) return false;
    final src = _lang(source);
    final dst = _lang(target);
    if (src == null || dst == null) return false;
    try {
      final manager = OnDeviceTranslatorModelManager();
      final srcReady = await manager.isModelDownloaded(src.bcpCode) ||
          await manager.downloadModel(src.bcpCode);
      final dstReady = await manager.isModelDownloaded(dst.bcpCode) ||
          await manager.downloadModel(dst.bcpCode);
      return srcReady && dstReady;
    } catch (_) {
      return false;
    }
  }

  Future<String> translate(
    String text, {
    required String source,
    required String target,
  }) async {
    if (text.trim().isEmpty || source == target || !supported) return text;
    final src = _lang(source);
    final dst = _lang(target);
    if (src == null || dst == null) return text;
    final ready = await prepare(source: source, target: target);
    if (!ready) return text;
    final translator = OnDeviceTranslator(
      sourceLanguage: src,
      targetLanguage: dst,
    );
    try {
      return await translator.translateText(text);
    } catch (_) {
      return text;
    } finally {
      translator.close();
    }
  }
}
