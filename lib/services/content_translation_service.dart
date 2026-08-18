import 'translation/translation_backend_stub.dart'
    if (dart.library.io) 'translation/translation_backend_mlkit.dart';

class ContentTranslationService {
  ContentTranslationService._();
  static final instance = ContentTranslationService._();

  final TranslationBackend _backend = TranslationBackend();
  final Map<String, String> _memory = {};

  bool get supported => _backend.supported;

  Future<bool> prepare({required String source, required String target}) =>
      _backend.prepare(source: source, target: target);

  Future<String> translate(
    String text, {
    required String source,
    required String target,
  }) async {
    if (text.trim().isEmpty || source == target || !supported) return text;
    final key = '$source>$target::$text';
    final cached = _memory[key];
    if (cached != null) return cached;
    final result = await _backend.translate(
      text,
      source: source,
      target: target,
    );
    _memory[key] = result;
    return result;
  }

  Future<List<String>> translateLines(
    List<String> lines, {
    required String source,
    required String target,
    int chunkSize = 40,
  }) async {
    if (source == target || !supported || lines.isEmpty) return [...lines];
    final output = <String>[];
    for (var start = 0; start < lines.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, lines.length);
      for (final line in lines.sublist(start, end)) {
        output.add(await translate(line, source: source, target: target));
      }
    }
    return output;
  }
}
