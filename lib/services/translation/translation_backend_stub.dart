class TranslationBackend {
  bool get supported => false;

  Future<bool> prepare({required String source, required String target}) async =>
      source == target;

  Future<String> translate(
    String text, {
    required String source,
    required String target,
  }) async => text;
}
