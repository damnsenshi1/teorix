import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/lesson.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../services/content_translation_service.dart';
import '../services/remote_content_service.dart';

class LessonRepository {
  Future<List<Lesson>> loadLessons({CountryProfile? profile, bool localizePreviews = true}) async {
    final active = profile ?? AppSettingsService.instance.country;
    final remote = await RemoteContentService.instance.loadPack(
      countryId: active.id, type: 'lessons', locale: active.primaryLocale,
    );
    final list = remote ??
        (jsonDecode(await rootBundle.loadString(
          'assets/data/lessons_${active.assetSuffix}.json',
        )) as List<dynamic>);
    var lessons = list.map((e) => Lesson.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    lessons.sort((a, b) {
      final cat = a.category.compareTo(b.category);
      return cat != 0 ? cat : a.order.compareTo(b.order);
    });
    final target = AppSettingsService.instance.contentLocale;
    if (localizePreviews && target != active.primaryLocale && ContentTranslationService.instance.supported) {
      lessons = await _localizePreviews(lessons, source: active.primaryLocale, target: target);
    }
    return lessons;
  }

  Future<List<Lesson>> _localizePreviews(List<Lesson> values, {required String source, required String target}) async {
    final translator = ContentTranslationService.instance;
    final titles = await translator.translateLines(values.map((e) => e.title).toList(), source: source, target: target);
    final modules = await translator.translateLines(values.map((e) => e.module).toList(), source: source, target: target);
    final summaries = await translator.translateLines(values.map((e) => e.summary).toList(), source: source, target: target);
    return List.generate(values.length, (i) {
      final l = values[i];
      return Lesson(
        id: l.id,
        category: l.category,
        module: modules[i],
        order: l.order,
        title: titles[i],
        minutes: l.minutes,
        summary: summaries[i],
        sections: l.sections,
        keyPoints: l.keyPoints,
        examTips: l.examTips,
        tags: l.tags,
      );
    });
  }

  Future<Lesson> localizeLesson(Lesson lesson, {CountryProfile? profile}) async {
    final active = profile ?? AppSettingsService.instance.country;
    final target = AppSettingsService.instance.contentLocale;
    if (target == active.primaryLocale || !ContentTranslationService.instance.supported) return lesson;
    final t = ContentTranslationService.instance;
    final module = await t.translate(lesson.module, source: active.primaryLocale, target: target);
    final title = await t.translate(lesson.title, source: active.primaryLocale, target: target);
    final summary = await t.translate(lesson.summary, source: active.primaryLocale, target: target);
    final sections = <LessonSection>[];
    for (final s in lesson.sections) {
      sections.add(LessonSection(
        heading: await t.translate(s.heading, source: active.primaryLocale, target: target),
        body: await t.translate(s.body, source: active.primaryLocale, target: target),
        bullets: await t.translateLines(s.bullets, source: active.primaryLocale, target: target),
      ));
    }
    return Lesson(
      id: lesson.id,
      category: lesson.category,
      module: module,
      order: lesson.order,
      title: title,
      minutes: lesson.minutes,
      summary: summary,
      sections: sections,
      keyPoints: await t.translateLines(lesson.keyPoints, source: active.primaryLocale, target: target),
      examTips: await t.translateLines(lesson.examTips, source: active.primaryLocale, target: target),
      tags: lesson.tags,
    );
  }
}
