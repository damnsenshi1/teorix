import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../services/content_translation_service.dart';
import '../services/remote_content_service.dart';

class QuestionRepository {
  Future<List<Question>> loadSeedQuestions({CountryProfile? profile}) async {
    final active = profile ?? AppSettingsService.instance.country;
    final remote = await RemoteContentService.instance.loadPack(
      countryId: active.id, type: 'questions', locale: active.primaryLocale,
    );
    final list = remote ??
        (jsonDecode(await rootBundle.loadString(
          'assets/data/questions_${active.assetSuffix}.json',
        )) as List<dynamic>);
    return list.map((e) => Question.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Question>> localizeQuestions(List<Question> questions, {CountryProfile? profile}) async {
    final active = profile ?? AppSettingsService.instance.country;
    final target = AppSettingsService.instance.contentLocale;
    if (target == active.primaryLocale || !ContentTranslationService.instance.supported || questions.isEmpty) return questions;
    final t = ContentTranslationService.instance;
    final out = <Question>[];
    for (final q in questions) {
      out.add(Question(
        id: q.id, lessonId: q.lessonId, category: q.category,
        text: await t.translate(q.text, source: active.primaryLocale, target: target),
        options: await t.translateLines(q.options, source: active.primaryLocale, target: target),
        correctIndex: q.correctIndex,
        explanation: await t.translate(q.explanation, source: active.primaryLocale, target: target),
        difficulty: q.difficulty, tags: q.tags, visualKey: q.visualKey, penaltyPoints: q.penaltyPoints,
      ));
    }
    return out;
  }

  List<Question> examFrom(List<Question> all, {int? count, CountryProfile? profile}) {
    final active = profile ?? AppSettingsService.instance.country;
    final wanted = count ?? active.fullExamQuestions;
    if (wanted == active.fullExamQuestions && all.length >= wanted) {
      final weighted = active.categories.where((c) => c.questionWeight != null).toList();
      if (weighted.isNotEmpty && weighted.fold<int>(0, (sum, c) => sum + (c.questionWeight ?? 0)) == wanted) {
        final selected = <Question>[];
        for (final spec in weighted) {
          selected.addAll(_takeFrom(all, spec.id, spec.questionWeight!));
        }
        selected.shuffle();
        if (selected.length == wanted) return selected;
      }
      // Country packs without a fixed category distribution use a balanced sample.
      final balanced = <Question>[];
      final nonEmptyCats = active.categories.where((c) => all.any((q) => q.category == c.id)).toList();
      if (nonEmptyCats.isNotEmpty) {
        final base = wanted ~/ nonEmptyCats.length;
        var remainder = wanted % nonEmptyCats.length;
        for (final spec in nonEmptyCats) {
          final take = base + (remainder-- > 0 ? 1 : 0);
          balanced.addAll(_takeFrom(all, spec.id, take));
        }
        if (balanced.length < wanted) {
          final used = balanced.map((e) => e.id).toSet();
          final rest = all.where((q) => !used.contains(q.id)).toList()..shuffle();
          balanced.addAll(rest.take(wanted - balanced.length));
        }
        balanced.shuffle();
        if (balanced.length >= wanted) return balanced.take(wanted).toList();
      }
    }
    final copy = [...all]..shuffle();
    return copy.take(wanted.clamp(1, copy.length).toInt()).toList();
  }

  List<Question> _takeFrom(List<Question> all, String category, int count) {
    final pool = all.where((q) => q.category == category).toList()..shuffle();
    return pool.take(count.clamp(0, pool.length).toInt()).toList();
  }

  List<Question> byCategory(List<Question> all, String category) =>
      all.where((q) => q.category == category).toList();

  List<Question> byLesson(List<Question> all, String lessonId) =>
      all.where((q) => q.lessonId == lessonId).toList();

  List<Question> byIds(List<Question> all, Iterable<String> ids) {
    final wanted = ids.toSet();
    return all.where((q) => wanted.contains(q.id)).toList();
  }
}
