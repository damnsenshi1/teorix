import 'package:flutter_test/flutter_test.dart';
import 'package:teorix/data/lesson_repository.dart';
import 'package:teorix/data/question_repository.dart';
import 'package:teorix/data/traffic_sign_repository.dart';
import 'package:teorix/models/country_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all country packs load and every lesson has practice questions', () async {
    for (final profile in CountryCatalog.all) {
      final lessons = await LessonRepository().loadLessons(profile: profile);
      final questions = await QuestionRepository().loadSeedQuestions(profile: profile);
      final signs = await TrafficSignRepository().load(profile: profile);

      expect(lessons.length, greaterThanOrEqualTo(profile.id == 'tr' ? 110 : 30), reason: profile.id);
      expect(questions.length, greaterThanOrEqualTo(profile.id == 'tr' ? 700 : 180), reason: profile.id);
      expect(signs.length, greaterThanOrEqualTo(profile.id == 'tr' ? 50 : 8), reason: profile.id);
      expect(lessons.every((l) => l.sections.length >= 2), isTrue, reason: profile.id);
      expect(lessons.every((l) => l.keyPoints.length >= 2), isTrue, reason: profile.id);
      expect(lessons.every((l) => l.examTips.isNotEmpty), isTrue, reason: profile.id);
      expect(questions.every((q) => q.options.length == 4), isTrue, reason: profile.id);
      expect(questions.every((q) => q.explanation.trim().isNotEmpty), isTrue, reason: profile.id);

      for (final lesson in lessons) {
        final linked = questions.where((q) => q.lessonId == lesson.id).length;
        expect(linked, greaterThanOrEqualTo(4), reason: '${profile.id}/${lesson.id} has only $linked questions');
      }

      final ids = questions.map((q) => q.id).toList();
      final texts = questions.map((q) => q.text.trim().toLowerCase()).toList();
      expect(ids.toSet().length, ids.length, reason: '${profile.id} duplicate ids');
      expect(texts.toSet().length, texts.length, reason: '${profile.id} duplicate question text');

      final categoryIds = profile.categories.map((c) => c.id).toSet();
      expect(questions.every((q) => categoryIds.contains(q.category)), isTrue, reason: '${profile.id} invalid category');
      expect(lessons.every((l) => categoryIds.contains(l.category)), isTrue, reason: '${profile.id} invalid lesson category');

      final signIds = signs.map((s) => s.id).toSet();
      expect(questions.where((q) => q.visualKey != null).every((q) => signIds.contains(q.visualKey)), isTrue, reason: '${profile.id} bad visual link');
    }
  });

  test('Turkey full mock exam follows 23-12-9-6 distribution', () async {
    final repo = QuestionRepository();
    final all = await repo.loadSeedQuestions(profile: CountryCatalog.turkey);
    final exam = repo.examFrom(all, count: CountryCatalog.turkey.fullExamQuestions, profile: CountryCatalog.turkey);
    expect(exam.length, 50);
    expect(exam.where((q) => q.category == 'Trafik ve Cevre').length, 23);
    expect(exam.where((q) => q.category == 'Ilk Yardim').length, 12);
    expect(exam.where((q) => q.category == 'Arac Teknigi').length, 9);
    expect(exam.where((q) => q.category == 'Trafik Adabi').length, 6);
  });

  test('Netherlands pack uses the eight CBR study areas configured by TeoriX', () async {
    final all = await QuestionRepository().loadSeedQuestions(profile: CountryCatalog.netherlands);
    final present = all.map((q) => q.category).toSet();
    expect(present, containsAll(CountryCatalog.netherlands.categories.map((e) => e.id)));
    final exam = QuestionRepository().examFrom(all, profile: CountryCatalog.netherlands);
    expect(exam.length, 50);
  });

  test('Germany practice exam has 30 questions and 10 class-B supplementary items', () async {
    final repo = QuestionRepository();
    final all = await repo.loadSeedQuestions(profile: CountryCatalog.germany);
    final exam = repo.examFrom(all, profile: CountryCatalog.germany);
    expect(exam.length, 30);
    expect(exam.where((q) => q.category == 'Klasse B Zusatzstoff').length, 10);
    expect(exam.every((q) => q.penaltyPoints >= 2 && q.penaltyPoints <= 5), isTrue);
  });

  test('United Kingdom pack uses 50-question 57-minute multiple-choice practice', () async {
    final all = await QuestionRepository().loadSeedQuestions(profile: CountryCatalog.unitedKingdom);
    final exam = QuestionRepository().examFrom(all, profile: CountryCatalog.unitedKingdom);
    expect(exam.length, 50);
    expect(CountryCatalog.unitedKingdom.examMinutes, 57);
    expect(CountryCatalog.unitedKingdom.passCorrectCount, 43);
    expect(CountryCatalog.unitedKingdom.hasHazardPerception, isTrue);
    expect(CountryCatalog.unitedKingdom.hazardPassScore, 44);
  });

  test('California pack is explicitly a practice simulation', () async {
    final all = await QuestionRepository().loadSeedQuestions(profile: CountryCatalog.california);
    final exam = QuestionRepository().examFrom(all, profile: CountryCatalog.california);
    expect(exam.length, CountryCatalog.california.fullExamQuestions);
    expect(CountryCatalog.california.formatNote.toLowerCase(), contains('practice simulation'));
  });
}
