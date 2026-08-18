import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';
import 'app_settings_service.dart';

class LocalProgressService {
  static const _wrongKey = 'wrong_question_ids';
  static const _favoriteKey = 'favorite_question_ids';
  static const _examCountKey = 'exam_count';
  static const _correctKey = 'correct_count';
  static const _wrongCountKey = 'wrong_count';
  static const _answeredKey = 'answered_count';
  static const _lastExamDayKey = 'last_exam_day';
  static const _todayExamCountKey = 'today_exam_count';
  static const _rewardedBonusDayKey = 'rewarded_bonus_day_v10';
  static const _rewardedBonusCountKey = 'rewarded_bonus_count_v10';
  static const _categoryStatsKey = 'category_stats_v2';
  static const _lessonStatsKey = 'lesson_stats_v10';
  static const _completedLessonsKey = 'completed_lessons_v10';
  static const _lastExamResultKey = 'last_exam_result_v2';
  static const _examHistoryKey = 'exam_history_v4';
  static const _dailySolvedKey = 'daily_solved_v2';
  static const _studyDaysKey = 'study_days_v2';
  static const _notesKey = 'question_notes_v4';
  static const _reportsKey = 'question_reports_v4';
  static const _dailyGoalKey = 'daily_goal_v4';
  static const _examDateKey = 'exam_date_v4';
  static const _reminderEnabledKey = 'reminder_enabled_v4';
  static const _reminderHourKey = 'reminder_hour_v4';
  static const _reminderMinuteKey = 'reminder_minute_v4';
  static const _readNotificationsKey = 'read_notifications_v4';
  static const _dismissedNotificationsKey = 'dismissed_notifications_v12';
  static const _studyHistoryKey = 'study_history_v10';
  static const _teacherDayKey = 'teacher_day_v10';
  static const _teacherUseKey = 'teacher_use_v10';
  static const _teacherBonusKey = 'teacher_bonus_v10';
  static const _answerDetailsKey = 'answer_details_v11';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();
  String _key(String base) => '${base}_${AppSettingsService.instance.countryId}';

  Future<Set<String>> wrongIds() async =>
      (await _prefs).getStringList(_key(_wrongKey))?.toSet() ?? <String>{};

  Future<Set<String>> favoriteIds() async =>
      (await _prefs).getStringList(_key(_favoriteKey))?.toSet() ?? <String>{};

  Future<bool> isFavorite(String questionId) async =>
      (await favoriteIds()).contains(questionId);

  Future<void> markAnswer(
    String questionId,
    bool correct, {
    String? category,
    String? lessonId,
    int? selectedIndex,
    int? correctIndex,
  }) async {
    final prefs = await _prefs;
    final wrongs = prefs.getStringList(_key(_wrongKey))?.toSet() ?? <String>{};
    if (correct) {
      wrongs.remove(questionId);
      await prefs.setInt(_key(_correctKey), (prefs.getInt(_key(_correctKey)) ?? 0) + 1);
    } else {
      wrongs.add(questionId);
      await prefs.setInt(_key(_wrongCountKey), (prefs.getInt(_key(_wrongCountKey)) ?? 0) + 1);
    }
    await prefs.setInt(_key(_answeredKey), (prefs.getInt(_key(_answeredKey)) ?? 0) + 1);
    await prefs.setStringList(_key(_wrongKey), wrongs.toList());

    if (selectedIndex != null && correctIndex != null) {
      final details = await answerDetails();
      details[questionId] = {
        'selectedIndex': selectedIndex,
        'correctIndex': correctIndex,
        'correct': correct,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (details.length > 1200) {
        final entries = details.entries.toList()
          ..sort((a, b) => (a.value['updatedAt'] ?? '').toString().compareTo((b.value['updatedAt'] ?? '').toString()));
        for (final e in entries.take(details.length - 1200)) {
          details.remove(e.key);
        }
      }
      await prefs.setString(_key(_answerDetailsKey), jsonEncode(details));
    }

    if (category != null) {
      final all = await categoryStats();
      final current = Map<String, int>.from(all[category] ?? const {'correct': 0, 'wrong': 0});
      final key = correct ? 'correct' : 'wrong';
      current[key] = (current[key] ?? 0) + 1;
      all[category] = current;
      await prefs.setString(_key(_categoryStatsKey), jsonEncode(all));
    }

    if (lessonId != null && lessonId.isNotEmpty) {
      final all = await lessonStats();
      final current = Map<String, int>.from(all[lessonId] ?? const {'correct': 0, 'wrong': 0});
      final key = correct ? 'correct' : 'wrong';
      current[key] = (current[key] ?? 0) + 1;
      all[lessonId] = current;
      await prefs.setString(_key(_lessonStatsKey), jsonEncode(all));
    }
    await _registerSolvedToday(prefs);
  }

  Future<Map<String, Map<String, int>>> lessonStats() async {
    final raw = (await _prefs).getString(_key(_lessonStatsKey));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return decoded.map((key, value) => MapEntry(
            key,
            Map<String, int>.from((value as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()))),
          ));
    } catch (_) {
      return {};
    }
  }

  Future<Set<String>> completedLessonIds() async =>
      (await _prefs).getStringList(_key(_completedLessonsKey))?.toSet() ?? <String>{};

  Future<void> setLessonCompleted(String lessonId, bool completed) async {
    final prefs = await _prefs;
    final values = prefs.getStringList(_key(_completedLessonsKey))?.toSet() ?? <String>{};
    completed ? values.add(lessonId) : values.remove(lessonId);
    await prefs.setStringList(_key(_completedLessonsKey), values.toList());
  }

  Future<bool> isLessonCompleted(String lessonId) async =>
      (await completedLessonIds()).contains(lessonId);

  Future<void> toggleFavorite(String questionId) async {
    final prefs = await _prefs;
    final values = prefs.getStringList(_key(_favoriteKey))?.toSet() ?? <String>{};
    values.contains(questionId) ? values.remove(questionId) : values.add(questionId);
    await prefs.setStringList(_key(_favoriteKey), values.toList());
  }

  Future<Map<String, Map<String, dynamic>>> answerDetails() async {
    final raw = (await _prefs).getString(_key(_answerDetailsKey));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>?> answerDetailFor(String questionId) async =>
      (await answerDetails())[questionId];

  Future<void> saveNote(String questionId, String note) async {
    final prefs = await _prefs;
    final map = await notes();
    if (note.trim().isEmpty) {
      map.remove(questionId);
    } else {
      map[questionId] = note.trim();
    }
    await prefs.setString(_key(_notesKey), jsonEncode(map));
  }

  Future<Map<String, String>> notes() async {
    final raw = (await _prefs).getString(_key(_notesKey));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<String> noteFor(String questionId) async => (await notes())[questionId] ?? '';

  Future<void> reportQuestion(String questionId, String reason, {String? detail}) async {
    final prefs = await _prefs;
    final list = await localReports();
    list.add({
      'id': '${DateTime.now().microsecondsSinceEpoch}',
      'questionId': questionId,
      'reason': reason,
      'detail': detail ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_key(_reportsKey), jsonEncode(list.takeLast(100).toList()));
  }

  Future<List<Map<String, dynamic>>> localReports() async {
    final raw = (await _prefs).getString(_key(_reportsKey));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> registerExamResult({
    required int total,
    required int correct,
    required int wrong,
    required int empty,
    required Map<String, Map<String, int>> categories,
    int penaltyPoints = 0,
    int wrongFivePointQuestions = 0,
    bool countTowardsDailyLimit = true,
  }) async {
    final prefs = await _prefs;
    final today = _today();
    if (prefs.getString(_key(_lastExamDayKey)) != today) {
      await prefs.setString(_key(_lastExamDayKey), today);
      await prefs.setInt(_key(_todayExamCountKey), 0);
    }
    if (countTowardsDailyLimit) {
      await prefs.setInt(_key(_todayExamCountKey), (prefs.getInt(_key(_todayExamCountKey)) ?? 0) + 1);
    }
    await prefs.setInt(_key(_examCountKey), (prefs.getInt(_key(_examCountKey)) ?? 0) + 1);
    final activeCountry = AppSettingsService.instance.country;
    final result = {
      'id': '${DateTime.now().microsecondsSinceEpoch}',
      'countryId': activeCountry.id,
      'total': total,
      'correct': correct,
      'wrong': wrong,
      'empty': empty,
      'score': total == 0 ? 0 : ((correct / total) * 100).round(),
      'penaltyPoints': penaltyPoints,
      'wrongFivePointQuestions': wrongFivePointQuestions,
      'passed': activeCountry.passed(total: total, correct: correct, penaltyPoints: penaltyPoints, wrongFivePointQuestions: wrongFivePointQuestions),
      'completedAt': DateTime.now().toIso8601String(),
      'categories': categories,
    };
    await prefs.setString(_key(_lastExamResultKey), jsonEncode(result));
    final history = await examHistory();
    history.insert(0, result);
    await prefs.setString(_key(_examHistoryKey), jsonEncode(history.take(100).toList()));
  }

  Future<Map<String, dynamic>?> lastExamResult() async {
    final raw = (await _prefs).getString(_key(_lastExamResultKey));
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> examHistory() async {
    final raw = (await _prefs).getString(_key(_examHistoryKey));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }


  Future<void> registerStudySession({
    required String mode,
    required int total,
    required int correct,
    required int wrong,
    required int empty,
    String? category,
    String? lessonId,
    List<String> questionIds = const [],
    List<String> wrongQuestionIds = const [],
  }) async {
    final prefs = await _prefs;
    final history = await studyHistory();
    history.insert(0, {
      'id': '${DateTime.now().microsecondsSinceEpoch}',
      'mode': mode,
      'total': total,
      'correct': correct,
      'wrong': wrong,
      'empty': empty,
      'score': total == 0 ? 0 : ((correct / total) * 100).round(),
      'category': category,
      'lessonId': lessonId,
      'questionIds': questionIds,
      'wrongQuestionIds': wrongQuestionIds,
      'completedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_key(_studyHistoryKey), jsonEncode(history.take(150).toList()));
  }

  Future<List<Map<String, dynamic>>> studyHistory() async {
    final raw = (await _prefs).getString(_key(_studyHistoryKey));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> todayExamCount() async {
    final prefs = await _prefs;
    final today = _today();
    if (prefs.getString(_key(_lastExamDayKey)) != today) return 0;
    return prefs.getInt(_key(_todayExamCountKey)) ?? 0;
  }

  Future<int> rewardedBonusCountToday() async {
    final prefs = await _prefs;
    if (prefs.getString(_key(_rewardedBonusDayKey)) != _today()) return 0;
    return prefs.getInt(_key(_rewardedBonusCountKey)) ?? 0;
  }

  Future<void> unlockExtraExamToday() async {
    final prefs = await _prefs;
    final today = _today();
    if (prefs.getString(_key(_rewardedBonusDayKey)) != today) {
      await prefs.setString(_key(_rewardedBonusDayKey), today);
      await prefs.setInt(_key(_rewardedBonusCountKey), 0);
    }
    final current = prefs.getInt(_key(_rewardedBonusCountKey)) ?? 0;
    await prefs.setInt(_key(_rewardedBonusCountKey), (current + 1).clamp(0, AppConfig.maxRewardedExamBonusesPerDay).toInt());
  }

  Future<bool> hasRewardedUnlockToday() async => (await rewardedBonusCountToday()) > 0;


  Future<int> teacherUsesToday() async {
    final prefs = await _prefs;
    if (prefs.getString(_key(_teacherDayKey)) != _today()) return 0;
    return prefs.getInt(_key(_teacherUseKey)) ?? 0;
  }

  Future<int> teacherBonusToday() async {
    final prefs = await _prefs;
    if (prefs.getString(_key(_teacherDayKey)) != _today()) return 0;
    return prefs.getInt(_key(_teacherBonusKey)) ?? 0;
  }

  Future<void> consumeTeacherUse() async {
    final prefs = await _prefs;
    final today = _today();
    if (prefs.getString(_key(_teacherDayKey)) != today) {
      await prefs.setString(_key(_teacherDayKey), today);
      await prefs.setInt(_key(_teacherUseKey), 0);
      await prefs.setInt(_key(_teacherBonusKey), 0);
    }
    await prefs.setInt(_key(_teacherUseKey), (prefs.getInt(_key(_teacherUseKey)) ?? 0) + 1);
  }

  Future<void> unlockTeacherUseToday() async {
    final prefs = await _prefs;
    final today = _today();
    if (prefs.getString(_key(_teacherDayKey)) != today) {
      await prefs.setString(_key(_teacherDayKey), today);
      await prefs.setInt(_key(_teacherUseKey), 0);
      await prefs.setInt(_key(_teacherBonusKey), 0);
    }
    final current = prefs.getInt(_key(_teacherBonusKey)) ?? 0;
    await prefs.setInt(_key(_teacherBonusKey), (current + 1).clamp(0, AppConfig.maxRewardedTeacherBonusesPerDay).toInt());
  }

  Future<Map<String, int>> stats() async {
    final prefs = await _prefs;
    return {
      'examCount': prefs.getInt(_key(_examCountKey)) ?? 0,
      'correct': prefs.getInt(_key(_correctKey)) ?? 0,
      'wrong': prefs.getInt(_key(_wrongCountKey)) ?? 0,
      'answered': prefs.getInt(_key(_answeredKey)) ?? 0,
    };
  }

  Future<Map<String, Map<String, int>>> categoryStats() async {
    final raw = (await _prefs).getString(_key(_categoryStatsKey));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return decoded.map((key, value) => MapEntry(
            key,
            Map<String, int>.from((value as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()))),
          ));
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, int>> dailySolvedMap() async {
    final raw = (await _prefs).getString(_key(_dailySolvedKey));
    if (raw == null) return {};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return map.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<int> todaySolved() async => (await dailySolvedMap())[_today()] ?? 0;

  Future<int> streak() async {
    final prefs = await _prefs;
    final days = prefs.getStringList(_key(_studyDaysKey))?.toSet() ?? <String>{};
    if (days.isEmpty) return 0;
    var cursor = DateTime.now();
    if (!days.contains(_dateKey(cursor))) cursor = cursor.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(_dateKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  // Profile identity belongs to the app/account, not to a country pack.
  Future<String> profileName() async => AppSettingsService.instance.profileName;
  Future<void> setProfileName(String value) async => AppSettingsService.instance.setProfileName(value);

  Future<int> dailyGoal() async => (await _prefs).getInt(_key(_dailyGoalKey)) ?? 20;
  Future<void> setDailyGoal(int value) async =>
      (await _prefs).setInt(_key(_dailyGoalKey), value.clamp(5, 200).toInt());

  Future<DateTime?> examDate() async {
    final raw = (await _prefs).getString(_key(_examDateKey));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setExamDate(DateTime? value) async {
    final prefs = await _prefs;
    if (value == null) {
      await prefs.remove(_key(_examDateKey));
    } else {
      await prefs.setString(_key(_examDateKey), value.toIso8601String());
    }
  }

  // The reminder is an app-level preference. Country changes only change the
  // timezone used for the same chosen local clock time.
  Future<bool> reminderEnabled() async => (await _prefs).getBool(_reminderEnabledKey) ?? false;
  Future<int> reminderHour() async => (await _prefs).getInt(_reminderHourKey) ?? 19;
  Future<int> reminderMinute() async => (await _prefs).getInt(_reminderMinuteKey) ?? 0;
  Future<void> setReminder({required bool enabled, required int hour, required int minute}) async {
    final prefs = await _prefs;
    await prefs.setBool(_reminderEnabledKey, enabled);
    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);
  }

  Future<Set<String>> readNotificationIds() async =>
      (await _prefs).getStringList(_key(_readNotificationsKey))?.toSet() ?? <String>{};
  Future<void> markNotificationRead(String id) async {
    final prefs = await _prefs;
    final ids = prefs.getStringList(_key(_readNotificationsKey))?.toSet() ?? <String>{};
    ids.add(id);
    await prefs.setStringList(_key(_readNotificationsKey), ids.toList());
  }

  Future<void> markAllNotificationsRead(Iterable<String> values) async =>
      (await _prefs).setStringList(_key(_readNotificationsKey), values.toSet().toList());

  Future<Set<String>> dismissedNotificationIds() async =>
      (await _prefs).getStringList(_key(_dismissedNotificationsKey))?.toSet() ?? <String>{};

  Future<void> dismissNotification(String id) async {
    final prefs = await _prefs;
    final ids = prefs.getStringList(_key(_dismissedNotificationsKey))?.toSet() ?? <String>{};
    ids.add(id);
    await prefs.setStringList(_key(_dismissedNotificationsKey), ids.toList());
  }

  Future<void> dismissAllNotifications(Iterable<String> values) async {
    final prefs = await _prefs;
    final ids = prefs.getStringList(_key(_dismissedNotificationsKey))?.toSet() ?? <String>{};
    ids.addAll(values);
    await prefs.setStringList(_key(_dismissedNotificationsKey), ids.toList());
  }

  Future<void> resetProgress({bool keepSettings = true}) async {
    final prefs = await _prefs;
    final suffix = '_${AppSettingsService.instance.countryId}';
    final keys = prefs.getKeys().where((k) => k.endsWith(suffix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<Map<String, dynamic>> exportSnapshot() async => {
        'schemaVersion': 12,
        'countryId': AppSettingsService.instance.countryId,
        'uiLocale': AppSettingsService.instance.locale,
        'contentLocale': AppSettingsService.instance.contentLocale,
        'stats': await stats(),
        'categoryStats': await categoryStats(),
        'lessonStats': await lessonStats(),
        'completedLessons': (await completedLessonIds()).toList(),
        'wrongs': (await wrongIds()).toList(),
        'favorites': (await favoriteIds()).toList(),
        'notes': await notes(),
        'answerDetails': await answerDetails(),
        'examHistory': await examHistory(),
        'studyHistory': await studyHistory(),
        'dailySolved': await dailySolvedMap(),
        'profileName': await profileName(),
        'dailyGoal': await dailyGoal(),
        'examDate': (await examDate())?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    final prefs = await _prefs;
    final statsMap = Map<String, dynamic>.from(snapshot['stats'] as Map? ?? const {});
    await prefs.setInt(_key(_examCountKey), (statsMap['examCount'] as num?)?.toInt() ?? 0);
    await prefs.setInt(_key(_correctKey), (statsMap['correct'] as num?)?.toInt() ?? 0);
    await prefs.setInt(_key(_wrongCountKey), (statsMap['wrong'] as num?)?.toInt() ?? 0);
    await prefs.setInt(_key(_answeredKey), (statsMap['answered'] as num?)?.toInt() ?? 0);

    Future<void> jsonField(String snapshotKey, String storageKey) async {
      final value = snapshot[snapshotKey];
      if (value != null) await prefs.setString(_key(storageKey), jsonEncode(value));
    }

    Future<void> listField(String snapshotKey, String storageKey) async {
      final value = snapshot[snapshotKey];
      if (value is List) await prefs.setStringList(_key(storageKey), value.map((e) => e.toString()).toList());
    }

    await jsonField('categoryStats', _categoryStatsKey);
    await jsonField('lessonStats', _lessonStatsKey);
    await jsonField('notes', _notesKey);
    await jsonField('answerDetails', _answerDetailsKey);
    await jsonField('examHistory', _examHistoryKey);
    await jsonField('studyHistory', _studyHistoryKey);
    await jsonField('dailySolved', _dailySolvedKey);
    await listField('completedLessons', _completedLessonsKey);
    await listField('wrongs', _wrongKey);
    await listField('favorites', _favoriteKey);

    final history = snapshot['examHistory'];
    if (history is List && history.isNotEmpty) {
      await prefs.setString(_key(_lastExamResultKey), jsonEncode(history.first));
    }
    final daily = snapshot['dailySolved'];
    if (daily is Map) {
      final days = daily.keys.map((e) => e.toString()).toList()..sort();
      await prefs.setStringList(_key(_studyDaysKey), days);
    }
    final goal = (snapshot['dailyGoal'] as num?)?.toInt();
    if (goal != null) await setDailyGoal(goal);
    final examDateValue = snapshot['examDate']?.toString();
    if (examDateValue != null && examDateValue.isNotEmpty) {
      await setExamDate(DateTime.tryParse(examDateValue));
    }
  }

  Future<void> _registerSolvedToday(SharedPreferences prefs) async {
    Map<String, dynamic> map = {};
    final raw = prefs.getString(_key(_dailySolvedKey));
    if (raw != null) {
      try {
        map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    final today = _today();
    map[today] = ((map[today] as num?)?.toInt() ?? 0) + 1;
    if (map.length > 60) {
      final keys = map.keys.toList()..sort();
      for (final k in keys.take(map.length - 60)) {
        map.remove(k);
      }
    }
    await prefs.setString(_key(_dailySolvedKey), jsonEncode(map));
    final days = prefs.getStringList(_key(_studyDaysKey))?.toSet() ?? <String>{};
    days.add(today);
    final sorted = days.toList()..sort();
    final compact = sorted.length > 180 ? sorted.sublist(sorted.length - 180) : sorted;
    await prefs.setStringList(_key(_studyDaysKey), compact);
  }

  String _today() => _dateKey(DateTime.now());
  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

extension _TakeLast<E> on List<E> {
  Iterable<E> takeLast(int count) => length <= count ? this : sublist(length - count);
}
